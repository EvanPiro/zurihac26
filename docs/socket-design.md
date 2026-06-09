# Socket Design

## Requirements

TCP server supporting 1 way multicast.

## Threads

- message producer thread that generates messages and pushes them to the message channel
- message consumer thread that consumes next message in channel and sends it to all all connected websockets
- TCP server that manages socket connections 
