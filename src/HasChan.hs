module HasChan where

class HasChan m where
    readChan :: m String
    writeChan :: String -> m ()
