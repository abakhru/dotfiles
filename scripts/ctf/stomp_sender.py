#!/usr/bin/env python

import time
import sys
import logging
import socket
import stomp

# the stomp module uses logging so to stop it complaining
# we initialise the logger to log to the console
logging.basicConfig()
# first argument is the queue
queue = '/threat/incidents'
# second argument is the message to send
message = '{"data":[],"request":{"stream":{"limit":100000},"sort":[{"field":"prioritySort","descending":true}],"filter":[{"field":"statusSort","value":1,"isNull":false}]},"meta":{"total":0},"code":0}'
# defaults for local stompserver instance
hosts=[('localhost', 8080)]
# do we have a connection to the server?
connected = False

while not connected:
    try:
        # connect to the stompserver
        conn = stomp.Connection(host_and_ports=hosts)
        conn.start()
        conn.connect()
        # send the message
        conn.send(body=message, destination=queue)
        # disconnect from the stomp server
        conn.disconnect()
        connected = True
    except socket.error:
        pass
