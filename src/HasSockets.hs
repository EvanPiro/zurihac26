module HasSockets where

import Network.Socket (Socket)

class HasSockets m where
    addSocket :: Socket -> m ()
    removeSocket :: Socket -> m ()
    broadcast :: String -> m ()
    send :: Socket -> String -> m ()
