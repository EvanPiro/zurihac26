module HasSockets where

import Control.Exception (SomeException)
import Control.Monad (forever, void)
import Control.Monad.IO.Class (MonadIO (..))
import Control.Monad.Reader (MonadReader (ask), ReaderT (runReaderT))
import Data.ByteString.Char8 qualified as BS
import Network.Run.TCP (runTCPServer)
import Network.Socket (Socket)
import Network.Socket.ByteString (sendAll)
import System.Random (randomIO)
import UnliftIO (MonadUnliftIO (withRunInIO), TVar, UnliftIO (unliftIO), atomically, finally, handle, newTChanIO, newTVarIO, readTChan, readTVar, waitAny, writeTChan, writeTVar)
import UnliftIO.Async (async)
import UnliftIO.Concurrent (threadDelay)
import UnliftIO.STM (TChan)

class HasSockets m where
    addSocket :: Socket -> m ()
    removeSocket :: Socket -> m ()
    broadcast :: String -> m ()
    send :: Socket -> String -> m ()
