#!/usr/bin/env python

import os
import glob
import timeit
import time
import sys
import importlib

from testconfig import config

from multiprocessing.dummy import Pool as ThreadPool
from multiprocessing import Process

from framework.common.logger import LOGGER
from framework.performance.nwcore_devices_manager import NwCoreDeviceManager
from framework.driver.http.httpdriver import HttpDriver
from framework.utils.ssh.tunnel_util import SshTunnel

import framework.performance.metrics.worker
from framework.performance.metrics.worker import __all__, cls_members

def class_for_name(module_name, class_name):
    # load the module, will raise ImportError if module cannot be loaded
    m = importlib.import_module(module_name)
    # get the class, will raise AttributeError if class cannot be found
    c = getattr(m, class_name)
    print(c)
    return c

for i in range(len(__all__)):
    loaded_class = class_for_name('framework.performance.metrics.worker.{}'.format(__all__[i]), '{}'.format(cls_members[i]))

LOGGER.setLevel('DEBUG')

def convert(word):
    return ''.join(x.capitalize() or '_' for x in word.split('_'))

def InitThread(host_stat_dict):
    """ Initializes the metrics collection thread on the dict specified

        Sample dict:
         {'10.101.59.231': [TopEsaStat, MpStat, DfStat, IoStat, FreeStat, GcStat
                            , MongoStat]}
    """

    thread_list = list()
    test_out_dir = '.'
    module_prefix = 'framework.performance.metrics.worker'
    print(type(host_stat_dict))
    for host, classes in host_stat_dict.items():
        stat_out_dir = os.path.join(test_out_dir, host)
        if not isinstance(classes, list):
            raise Exception('Invalid input')
        for _class in classes:
            module_name = '{}.{}.{}'.format(module_prefix, _class, convert(_class))
            LOGGER.debug('module_name: {}'.format(module_name))
            thread_list.append(eval(module_name)(node=host, interval=interval
                                    , name=convert(_class)
                                    , count=count, timeout=timeout
                                    , test_out_dir=stat_out_dir
                                    , outfile='{}_result'.format(_class)))
    LOGGER.debug('Threads list: {}'.format(thread_list))
    return thread_list

if __name__ == '__main__':

    start_time = timeit.default_timer()
    print([i for i in sys.modules.keys() if i.startswith('framework')])
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
    # net_stat_conc = framework.performance.metrics.worker.net_stat.NetStat(node='10.101.59.241', interval=interval
    #                         , name='NetStatConc'
    #                         , count=count, timeout=timeout
    #                         , test_out_dir='.'
    #                         , outfile='net_stat_conc_result')
    # time.sleep(600)
    # inspect.getmembers(sys.modules[], lambda member: member.__module__ == __name__ and inspect.isclass)
    # InitThread(host_stat_dict={'10.101.59.231': ['top_esa_stat', 'mp_stat', 'df_stat'
    #                                              , 'io_stat', 'free_stat', 'gc_stat', 'mongo_stat']})
    InitThread(host_stat_dict={'10.101.59.241': ['top_stat', 'mp_stat', 'df_stat'
                                                 , 'io_stat', 'free_stat', 'nw_core_stat']})
