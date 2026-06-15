{-# LANGUAGE LambdaCase #-}

module HasLogger where

data LogLevel
    = Emerg
    | Alert
    | Crit
    | Err
    | Warning
    | Notice
    | Info
    | Debug
    deriving (Eq, Ord)

instance Show LogLevel where
    show =
        \case
            Emerg -> "emerg"
            Alert -> "alert"
            Crit -> "crit"
            Err -> "err"
            Warning -> "warning"
            Notice -> "notice"
            Info -> "info"
            Debug -> "debug"

class HasLogger m where
    getMaxLogLevel :: m LogLevel
    log :: LogLevel -> String -> m ()
