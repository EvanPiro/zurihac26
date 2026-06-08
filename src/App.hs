{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE StandaloneDeriving #-}
{-# LANGUAGE TypeApplications #-}

module App where

import Control.Concurrent (threadDelay)
import Control.Concurrent.Async (async, waitAny)
import Control.Concurrent.STM
import Control.Exception (SomeException, finally, handle)
import Control.Monad (forever, void)
import Control.Monad.IO.Class (MonadIO (..))
import Control.Monad.Reader (MonadReader (ask), ReaderT (runReaderT))
import Data.ByteString.Char8 qualified as BS
import Network.Run.TCP (runTCPServer)
import Network.Socket (Socket)
import Network.Socket.ByteString (sendAll)
import System.Random (randomIO)

type MsgChan = TChan String
type SockStore = TVar [Socket]

data Config = Config
    { chan :: MsgChan
    , sockets :: SockStore
    }

mkConfig :: IO Config
mkConfig =
    Config <$> newTChanIO <*> newTVarIO []

type App = ReaderT Config IO ()

runApp :: IO ()
runApp =
    mkConfig >>= runReaderT app

app :: App
app = do
    (Config{chan, sockets}) <- ask
    liftIO $ do
        subsTr <- async $ runSubServer sockets
        producerTr <- async $ producer chan
        broadcastTr <- async $ broadcast chan sockets
        void $
            waitAny $
                [ subsTr
                , producerTr
                , broadcastTr
                ]

producer :: MsgChan -> IO ()
producer chan = forever $ do
    num <- liftIO $ randomIO :: IO Int
    let msg = "random number is " <> show num <> "\n"
    putStrLn $ "message pushed: " <> msg
    atomically $ writeTChan chan msg
    threadDelay 1_000_000

broadcast :: MsgChan -> SockStore -> IO ()
broadcast chan' store = forever $ do
    (msg, sks) <- atomically $ do
        msg' <- readTChan chan'
        sks' <- readTVar store
        pure (msg', sks')
    putStrLn $ "sending to sockets: " <> (show $ length sks)
    mapM (flip (send store) msg) sks

send :: SockStore -> Socket -> String -> IO ()
send store sock msg =
    handle
        ( \(e :: SomeException) -> do
            putStrLn $ show e
            removeSock store sock
        )
        (sendAll sock $ BS.pack msg)

runSubServer :: SockStore -> IO ()
runSubServer store =
    runTCPServer (Just "127.0.0.1") "3000" $ connectSock store

connectSock :: SockStore -> Socket -> IO ()
connectSock store sock =
    (`finally` removeSock store sock) $ do
        sendAll sock "You've been connected!\n"
        putStrLn $ "socket added" <> show sock
        atomically $ do
            socks <- readTVar store
            writeTVar store (sock : socks)
        forever $ threadDelay maxBound

removeSock :: SockStore -> Socket -> IO ()
removeSock store sock = do
    putStrLn $ "removing the socket: " <> show sock
    atomically $ do
        socks <- readTVar store
        let newSocks = filter (\s -> s /= sock) socks
        writeTVar store newSocks
