#!/usr/bin/env python

import asyncore
import os
import signal
import smtpd
import subprocess
import sys

from ctf.framework.logger import LOGGER
LOGGER.setLevel('DEBUG')


class DummySMTPServer(object):
    """ DummySMTPServer for testing email notifications."""

    def __init__(self, host='localhost', port=2500):
        self.host = host
        self.port = port
        self.pid = None
        self.smtpd = None

    def PreLaunch(self):
        # Killing running stale smtpd-server instance if any
        p = subprocess.Popen("ps -ef|grep smtpd|grep -v grep |awk '{print $2}'|tail -1"
                             , stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True)
        pid = p.communicate()[0].strip()

        if pid:
            LOGGER.debug('Killing Existing stale smtp-server pid: %s.', pid)
            self.ShutDown(pid)

    def preexec_function(self):
        os.setpgrp()

    def Launch(self):
        """ Launches Dummy SMTP Server."""
        LOGGER.debug('Launching Dummy SMTP server.')
        cmd = 'python -m smtpd -n -c DebuggingServer ' + self.host + ':' + str(self.port)
        self.smtpd = subprocess.Popen(args = cmd
                                      , stdout=subprocess.PIPE
                                      , stderr=subprocess.PIPE
                                      , shell=True
                                      , universal_newlines = True
                                      , preexec_fn=self.preexec_function)
        self.smtpd.communicate()
        LOGGER.debug('pid of smtp server: %s', self.smtpd.pid)
        self.pid = self.smtpd.pid

    def ShutDown(self, pid=None):
        if pid is None:
            pid = self.pid
        LOGGER.debug('Shutting Down SMTP server pid: %s', pid)
        subprocess.Popen('kill -9 %s', int(pid))


if __name__ == '__main__':
    p = DummySMTPServer()
    p.PreLaunch()
    p.Launch()
    import time
    LOGGER.debug('sleeping for 1 seconds')
    time.sleep(1)
    p.ShutDown()
