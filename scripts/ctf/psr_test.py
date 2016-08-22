#!/usr/bin/env python

import os
import timeit
import time

from testconfig import config

from multiprocessing.dummy import Pool as ThreadPool
from multiprocessing import Process

from framework.common.logger import LOGGER
# from framework.performance.nwcore_devices_manager import NwCoreDeviceManager
from framework.driver.http.httpdriver import HttpDriver
from framework.utils.ssh.tunnel_util import SshTunnel


LOGGER.setLevel('DEBUG')

if __name__ == '__main__':

    start_time = timeit.default_timer()
    # p = NwCoreDeviceManager(publish=True, use_existing_conc_data=False)
    # p = HttpDriver(host='10.101.216.253', port=50102, auth=('admin', 'netwitness'))
    # print(p.connected)
    # response = p.Get('/database/stats/status')
    # print(response.text)
    # p.InitLDConHarnesses()
    ssh_tunnel = SshTunnel('10.101.59.231', 'root', 'netwitness')
    ssh_tunnel.Open(ports=[5672])
    time.sleep(600)
