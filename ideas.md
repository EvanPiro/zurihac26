# Ideas

haskell debugging tools


## haskell developer command line chat CLI/protocol

```
hchat <channel>
> evan: yo
> ashwin: yo

-- wild idea
hchat --src .
```

## Haskell CLI for automating dev tasks
```
hcli add module
hli add test
```

## Ideas Graph Organiziation


## Property Testing Out of the Box


## Migrant, improve rollbacks

https://github.com/tdammers/migrant

## aeson ts client generation


## Servant Client

missing tutorial URL: https://docs.servant.dev/en/stable/tutorial/Client.html

## Servant Typescript

module tree symmetery for typescript client gen

## Repl Workflow Tooling

develop modules straight from REPL

## Nix closure size analysis tools

pi chart for a closure, what deps are shared, what are sole.

## GHC Control.Current.STM doc is wrong
```
serve :: TChan Message -> Client -> IO loop
serve broadcastChan client = do
    myChan <- dupTChan broadcastChan
    forever $ do
        message <- readTChan myChan
        send client message
```

## HLS plugin for GHC-style notes
https://github.com/haskell/haskell-language-server/issues/2964
