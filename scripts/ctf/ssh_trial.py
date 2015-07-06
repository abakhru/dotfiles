#!/usr/bin/env python

import pexpect
from common.framework.logger import LOGGER


class SShCommandClient(object):
    """Ssh utility that allows executing commands on a specified host.

    Connection is established on init and maintained until close.
    """

    def __init__(self, host, user='root', password='netwitness', timeout=120):
        """Initializes Ssh object per host.

        For password less login skip password argument.
        """

        self.host = host
        self.child = pexpect.spawnu('ssh %s@%s' % (user, host))
        import sys; self.child.logfile = sys.stdout
        index = self.child.expect([r'[Pp]assword:', r'yes/no', r'#'], timeout=timeout)
        if index == 0:
            self.child.sendline(password)
        elif index == 1:
            self.child.sendline('yes')
            self.child.expect(r'[Pp]assword:', timeout=timeout)
            self.child.sendline(password)
            self.child.expect('#', timeout=timeout)
        elif index == 2:
            pass

    def command(self, command, prompt='#', timeout=60):
        """Send a command and return the response.

        Args:
            command - the command to be sent (str)
            prompt - the expected prompt after command execution (regex)

        Returns:
            response - the response after command execution
        """
        try:
            self.child.sendline(command)
            self.child.expect(prompt, timeout=timeout)
            response = self.child.before
            LOGGER.debug(response)
            return response
        except pexpect.TIMEOUT as e:
            LOGGER.error(str(e))
            pass

    def close(self):
        """Close the ssh connection"""
        try:
            self.child.close()
        except OSError:
            pass


if __name__ == '__main__':
    p = SShCommandClient('10.101.216.133')
    p.command('head 3Kusers_5Kfail_then_1Ksucess.txt')
    p.close()
