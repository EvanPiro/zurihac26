{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE StandaloneDeriving #-}
{-# LANGUAGE TypeApplications #-}

module App where

import Control.Exception (SomeException)
import Control.Monad (forever, void)
import Control.Monad.IO.Class (MonadIO (..))
import Control.Monad.Reader (MonadReader (ask), ReaderT (runReaderT), asks)
import Data.ByteString.Char8 qualified as BS
import HasChan (HasChan (..))
import HasLogger (HasLogger (getLogLevel, log), LogLevel (..))
import HasSockets (HasSockets (..))
import Network.Run.TCP (runTCPServer)
import Network.Socket (Socket)
import Network.Socket.ByteString (sendAll)
import System.Random (randomIO)
import UnliftIO (MonadUnliftIO (withRunInIO), TVar, UnliftIO (unliftIO), atomically, finally, handle, newTChanIO, newTVarIO, readTChan, readTVar, waitAny, writeTChan, writeTVar)
import UnliftIO.Async (async)
import UnliftIO.Concurrent (threadDelay)
import UnliftIO.STM (TChan)
import Prelude hiding (log)

appLogLevel :: LogLevel
appLogLevel = Warning

type MsgChan = TChan String
type SockStore = TVar [Socket]

data Config = Config
    { channel :: MsgChan
    , sockets :: SockStore
    , logLevel :: LogLevel
    }

mkConfig :: IO Config
mkConfig =
    Config <$> newTChanIO <*> newTVarIO [] <*> pure appLogLevel

newtype App r = App {unApp :: ReaderT Config IO r}
    deriving (Functor, Applicative, Monad, MonadIO, MonadUnliftIO, MonadReader Config)

type AppM m = (HasSockets m, MonadIO m, MonadUnliftIO m, HasChan m, HasLogger m)

instance HasSockets App where
    addSocket sock = do
        (Config{sockets}) <- ask
        liftIO $ do
            sendAll sock "You've been connected!\n"
        log Info $ "socket added" <> show sock
        atomically $ do
            socks <- readTVar sockets
            writeTVar sockets (sock : socks)

    removeSocket sock = do
        (Config{sockets}) <- ask
        log Alert $ "removing the socket: " <> show sock
        atomically $ do
            socks <- readTVar sockets
            let newSocks = filter (\s -> s /= sock) socks
            writeTVar sockets newSocks

    broadcast msg = do
        (Config{sockets}) <- ask
        sks <- atomically $ readTVar sockets
        log Info $ "sending to sockets: " <> (show $ length sks)
        mapM_ send' sks
      where
        send' sock = withRunInIO $ \run ->
            handle
                ( \(e :: SomeException) -> do
                    putStrLn $ show e
                    run (removeSocket sock)
                )
                (sendAll sock $ BS.pack msg)
    send sock msg =
        liftIO $ sendAll sock $ BS.pack msg

instance HasChan App where
    readChan = do
        chan <- asks channel
        atomically $ readTChan chan
    writeChan msg = do
        chan <- asks channel
        atomically $ writeTChan chan msg

instance HasLogger App where
    getLogLevel = asks logLevel
    log logLevel msg = do
        maxLevel <- getLogLevel
        if logLevel <= maxLevel
            then
                liftIO $
                    putStrLn $
                        "[" <> show logLevel <> "] " <> msg
            else
                pure ()

runApp :: IO ()
runApp =
    mkConfig >>= (runReaderT $ unApp app)

app :: (AppM m) => m ()
app = do
    subsTr <- async $ runSubServer
    producerTr <- async $ writeWorker
    broadcastTr <- async $ readWorker
    void $
        waitAny $
            [ subsTr
            , producerTr
            , broadcastTr
            ]

writeWorker :: (AppM m) => m ()
writeWorker =
    forever $ do
        num <- randNum
        let msg = "hello, this is a message" <> show num <> "\n"
        log Info $ "message pushed: " <> msg
        writeChan msg
        threadDelay 1_000_000

randNum :: (MonadIO m, MonadUnliftIO m) => m Int
randNum = randomIO

readWorker :: (AppM m) => m ()
readWorker = forever $ do
    msg <- readChan
    broadcast msg

runSubServer :: (AppM m) => m ()
runSubServer =
    withRunInIO $ \run ->
        runTCPServer (Just "127.0.0.1") "3000" (\sock -> run (connectSock sock))

connectSock :: (AppM m) => Socket -> m ()
connectSock sock =
    (`finally` removeSocket sock) $ do
        liftIO $
            do
                sendAll sock "You've been connected!\n"
                putStrLn $ "socket added" <> show sock
        addSocket sock
        forever $ threadDelay maxBound
