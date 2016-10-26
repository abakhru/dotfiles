#!/usr/bin/env python

import time

from framework.common.logger import LOGGER
from framework.utils.ssh.ssh_util import SSHConnection
from framework.utils.ssh.tunnel_util import SshTunnel
from productlib.microservice.response_service import ResponseService

LOGGER.setLevel('DEBUG')


if __name__ == '__main__':
    s = SshTunnel('10.101.217.122', 'root', 'netwitness')
    s.Open([5672])
    s.Close()
