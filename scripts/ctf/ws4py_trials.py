#!/usr/bin/env python

from ws4py.client.threadedclient import WebSocketClient


class EchoClient(WebSocketClient):
    def opened(self):
       for i in range(0, 200, 25):
          self.send("*" * i)

    def closed(self, code, reason):
       print(("Closed down", code, reason))

    def received_message(self, m):
       print("=> %d %s" % (len(m), str(m)))

try:
    ws = EchoClient('ws://localhost:8080/response', protocols=['stomp'])
    ws.connect()
except KeyboardInterrupt:
   ws.close()
