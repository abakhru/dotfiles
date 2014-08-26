#!/usr/bin/env python

import asyncore
import smtpd
import threading

#from eTest.constants import *
from ctf.framework.logger import LOGGER
LOGGER.setLevel('DEBUG')


class SimpleSMTPServer(smtpd.SMTPServer):

    def __init__(self, localaddr, remoteaddr, filename='smtpserver.out', logMails=True):
        smtpd.SMTPServer.__init__(self, localaddr, remoteaddr)
        try:
            self.fp = open(filename, 'w')
            self.logMails = logMails
            self.count = 0
            LOGGER.info('SMTP Server Started Successfully')
        except:
            pass

    def process_message(self, peer, mailfrom, rcpttos, data):
        self.count = self.count + 1
        if self.fp:
            self.fp.write('SimpleSMTPServer: Message count = %d\n' % self.count)
            if self.logMails:
                self.fp.write(data)
                self.fp.write('\n**************\n')
            self.fp.flush()

    def closeLogFp(self):
        LOGGER.info('Closing File Pointer')
        self.fp.close()

class SimpleSMTPServerRunner:

    def __init__(self, port=1025, logfilename='smtpserver.out'):
        self.exit = 0
        self.port = port
        self.logfilename = logfilename

    def kickoff(self):
        server = SimpleSMTPServer((str(getServerIP()), self.port), None, filename=self.logfilename)
        while not self.exit:
            asyncore.loop(timeout=1.0, use_poll=False, count=1)
            server.closeLogFp()
        LOGGER.info('SMTP Server Stopped')

    def start(self):
        LOGGER.info('Starting the Server')
        threading.Thread(target=self.kickoff).start()

    def stop(self):
        LOGGER.info('Stopping the Server')
        self.exit = 1

    def getServerIP():
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(('corpinba8.corp.emc.com', 80))
        localip = s.getsockname()[0]
        return localip

    def sampleSendEmail(logMesgs=False):
        import smtplib
        import email.utils
        from email.mime.text import MIMEText

        # Create the message
        msg = MIMEText('This is the body of the message.')
        msg['To'] = email.utils.formataddr(('CTF-Auto', 'amit.bakhru@rsa.com'))
        msg['From'] = email.utils.formataddr(('CTF-Auto', 'amit.bakhru@rsa.com'))
        msg['Subject'] = '[CTF] Auto Simple test message'

        server = smtplib.SMTP(getServerIP(), 1025)
        if logMesgs:
            server.set_debuglevel(True) # show communication with the server
        try:
            server.sendmail('amit.bakhru@rsa.com', ['amit.bakhru@rsa.com'], msg.as_string())
        finally:
            server.quit()
