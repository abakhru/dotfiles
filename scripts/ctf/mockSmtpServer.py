#!/usr/bin/env python

import asyncore
import re
import smtpd
import threading

class MockSMTPServer(smtpd.SMTPServer, threading.Thread):
    '''
    A mock SMTP server. Runs in a separate thread so can be started from
    existing test code.
    '''

    def __init__(self, hostname, port):
        threading.Thread.__init__(self)
        smtpd.SMTPServer.__init__(self, (hostname, port), None)
        self.daemon = True
        self.received_messages = []
        self.start()

    def run(self):
        asyncore.loop()

    def process_message(self, peer, mailfrom, rcpttos, data):
        self.received_messages.append(data)
        print self.received_messages

    def reset(self):
        self.received_messages = []

    # helper methods for assertions in test cases

    def received_message_matching(self, template):
        for message in self.received_messages:
            if re.match(template, message): return True
        return False

    def received_messages_count(self):
        return len(self.received_messages)


if __name__ == '__main__':
    # create the server -- will start automatically
    mock_server = MockSMTPServer("localhost", 25025)
    mock_server.run()

    #send a test message
    #import smtplib
    #client = smtplib.SMTP("localhost", 25025)
    #fromaddr = "test.sender@mydomain.com"
    #toaddrs = ["test.recipient1@mydomain.com", "test.recipient2@mydomain.com"]
    #content = "test message content"
    #msg = "From: %s\r\nTo: %s\r\n\r\n%s" % (fromaddr, ", ".join(toaddrs), content)
    #client.sendmail(fromaddr, toaddrs, msg)
    #client.quit()

    # verify that the message has been recieved
    #assert(mock_server.received_message_matching("From: .*\\nTo: .*\\n+.+tent"))

    # reset the server to be ready for a new test
    #mock_server.reset()
    #assert(mock_server.received_messages_count() == 0)