#!/usr/bin/env python

import os
import glob
import timeit
import time
import sys

from testconfig import config

from multiprocessing.dummy import Pool as ThreadPool
from multiprocessing import Process

from framework.common.logger import LOGGER
from framework.performance.nwcore_devices_manager import NwCoreDeviceManager
from framework.driver.http.httpdriver import HttpDriver
from framework.utils.ssh.tunnel_util import SshTunnel

import framework.performance.metrics.worker
from framework.performance.metrics.worker import __all__, cls_members
# from framework.performance.metrics.worker import *
# __all__ = __all__.sort()
# cls_members = cls_members.sort()
print(__all__)
print(cls_members)
for i in range(len(__all__)):
    stmt = 'from framework.performance.metrics.worker.{} import {}'.format(__all__[i], cls_members[i])
    print(stmt)
    stmt

LOGGER.setLevel('DEBUG')


if __name__ == '__main__':

    start_time = timeit.default_timer()
    print(sys.modules)
    # p = NwCoreDeviceManager(publish=True, use_existing_conc_data=False)
    # p = HttpDriver(host='10.101.216.253', port=50102, auth=('admin', 'netwitness'))
    # print(p.connected)
    # response = p.Get('/database/stats/status')
    # print(response.text)
    # p.InitLDConHarnesses()
    # ssh_tunnel = SshTunnel('10.101.59.231', 'root', 'netwitness')
    # ssh_tunnel.Open(ports=[5672])
    interval = config['performance']['interval']
    timeout = config['performance']['duration']
    count = int(timeout / interval)
    net_stat_conc = NetStat(node='10.101.59.241', interval=interval
                            , name='NetStatConc'
                            , count=count, timeout=timeout
                            , test_out_dir='.'
                            , outfile='net_stat_conc_result')
    # time.sleep(600)
    # inspect.getmembers(sys.modules[], lambda member: member.__module__ == __name__ and inspect.isclass)
