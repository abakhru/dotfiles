#!/usr/bin/env python

#import secure_smtpd
import ssl
import smtpd
import asyncore
import socket, signal, time, sys

#from smtp_channel import SMTPChannel
from asyncore import ExitNow
from multiprocessing import Process, Queue
from Queue import Empty
from ssl import SSLError
from smtpd import SMTPServer

from ctf.framework.logger import LOGGER
LOGGER.setLevel('DEBUG')


class ProcessPool(object):

    def __init__(self, func, process_count=5):
        self.func = func
        self.process_count = process_count
        self.queue = Queue()
        self._create_processes()

    def _create_processes(self):
        for i in range(0, self.process_count):
            process = Process(target=self.func, args=[self.queue])
            process.daemon = True
            process.start()


class SSLSMTPServer(SMTPServer):
#class SSLSMTPServer(object):

    def __init__(self, localaddr, remoteaddr, ssl=False, certfile=None, keyfile=None
                 , ssl_version=ssl.PROTOCOL_SSLv23, require_authentication=False
                 , credential_validator=None, maximum_execution_time=30, process_count=5):
        SMTPServer.__init__(self, localaddr, remoteaddr)
        self.certfile = certfile
        self.keyfile = keyfile
        self.ssl_version = ssl_version
        self.subprocesses = []
        self.require_authentication = require_authentication
        self.credential_validator = credential_validator
        self.ssl = ssl
        self.maximum_execution_time = maximum_execution_time
        self.process_count = process_count
        self.process_pool = None

    def handle_accept(self):
        self.process_pool = ProcessPool(self._accept_subprocess, process_count=self.process_count)
        self.close()

    def _accept_subprocess(self, queue):
        while True:
            try:
                self.socket.setblocking(1)
                pair = self.accept()
                map = {}

                if pair is not None:

                    LOGGER.info('_accept_subprocess(): smtp connection accepted within subprocess.')

                    newsocket, fromaddr = pair
                    newsocket.settimeout(self.maximum_execution_time)

                    if self.ssl:
                        newsocket = ssl.wrap_socket(
                            newsocket,
                            server_side=True,
                            certfile=self.certfile,
                            keyfile=self.keyfile,
                            ssl_version=self.ssl_version,
                        )
                    channel = SMTPChannel(
                        self,
                        newsocket,
                        fromaddr,
                        require_authentication=self.require_authentication,
                        credential_validator=self.credential_validator,
                        map=map
                    )

                    LOGGER.info('_accept_subprocess(): starting asyncore within subprocess.')

                    asyncore.loop(map=map)

                    LOGGER.error('_accept_subprocess(): asyncore loop exited.')
            except (ExitNow, SSLError):
                self._shutdown_socket(newsocket)
                LOGGER.info('_accept_subprocess(): smtp channel terminated asyncore.')
            except Exception, e:
                self._shutdown_socket(newsocket)
                LOGGER.error('_accept_subprocess(): uncaught exception: %s' % str(e))

    def _shutdown_socket(self, s):
        try:
            s.shutdown(socket.SHUT_RDWR)
            s.close()
        except Exception, e:
            LOGGER.error('_shutdown_socket(): failed to cleanly shutdown socket: %s' % str(e))


    def run(self):
        asyncore.loop()
        if hasattr(signal, 'SIGTERM'):
            def sig_handler(signal,frame):
                LOGGER.info("Got signal %s, shutting down." % signal)
                sys.exit(0)
            signal.signal(signal.SIGTERM, sig_handler)
        while 1:
            time.sleep(1)


if __name__ == '__main__':
    server = SSLSMTPServer(('0.0.0.0', 1025),
                            None,
                            #require_authentication=True,
                            #ssl=True,
                            #certfile='examples/server.crt',
                            #keyfile='examples/server.key',
                            #credential_validator=FakeCredentialValidator(),
                            maximum_execution_time = 1.0
                            )

    server.run()
