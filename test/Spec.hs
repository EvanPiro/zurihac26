module Main where

import Lib (hello)

main :: IO ()
main =
  if hello == "Hello, Haskell!"
    then putStrLn "Tests passed."
    else error "Expected hello to return \"Hello, Haskell!\"."
