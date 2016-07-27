#!/usr/bin/env python

import time
import sys
import logging
import socket
import stomp

# the stomp module uses logging so to stop it complaining
# we initialise the logger to log to the console
logging.basicConfig()
# logging.setLevel('DEBUG')
# first argument is the que path
queue = '/topic/incidents/new'
# defaults for local stompserver instance
hosts = [('localhost', 8080)]


# we want the script to keep running

def run_server():
    while 1:
        time.sleep(20)


class listener(object):
    """define the event handlers"""

    # if we recieve an error from the server
    def on_error(self, headers, message):
        print('received an error %s' % message)

    # if we retrieve a message from the server
    def on_message(self, headers, message):
        print('received a message %s' % message)


# do we have a connection to the server?
connected = False
while not connected:
    # try and connect to the stomp server
    # sometimes this takes a few goes so we try until we succeed
    try:
        conn = stomp.Connection(host_and_ports=hosts, vhost='/rsa/sa')
        # register out event handler above
        conn.set_listener('response', listener())
        conn.start()
        conn.connect()
        # subscribe to the names que
        conn.subscribe(destination=queue, id=1, ack='auto')
        connected = True
    except socket.error:
        pass

# we have a connection so keep the script running
if connected:
    run_server()
