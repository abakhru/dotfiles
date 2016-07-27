#!/usr/bin/env python

import websocket
import logging

_logger = logging.getLogger('websocket')
_logger.setLevel(logging.DEBUG)


if __name__ == "__main__":
    websocket.enableTrace(True)
    ws = websocket.create_connection("ws://127.0.0.1:8080/response")#, subprotocols=["stomp"])
    print("Sending 'Hello, World'...")
    ws.send("Hello, World")
    print("Sent")
    print("Receiving...")
    result = ws.recv()
    print("Received {}".format(result))
    ws.close()
