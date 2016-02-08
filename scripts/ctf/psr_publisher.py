#!/usr/bin/env python

""" PSR publisher threads """

import os
import timeit

from multiprocessing.dummy import Pool as ThreadPool
from multiprocessing import Process

from framework.common.logger import LOGGER
from framework.common.harness import SshCommandClient
from performance.framework.harness import InjectorRpmHarness

LOGGER.setLevel('DEBUG')

class PSR_Publisher(object):

    def __init__(self, host, username, password, dst_host, data_path, rate, publish_duration):
        a = InjectorRpmHarness(host, username, password)
        a.Publish(dst_host, data_path, rate, publish_duration)
        a.StopPublish()


if __name__ == '__main__':

    import simplejson as json
    with open('/Users/bakhra/default.json') as config_file:
        config = json.load(config_file)

    timeout = 60 * config['performance']['duration']
    epl_count = config['performance']['epl_count']
    interval = config['performance']['interval']
    esa_nodes = config['servers']['esa']['ip']
    ld_nodes = config['servers']['logdecoder']['ip']
    cr_nodes = config['servers']['concentrator']['ip']
    injector_ips = config['servers']['injector']['ip']
    publish_data = config['performance']['data']
    LOGGER.debug('publish_data: %s', publish_data)

    start_time = timeit.default_timer()
    pool_tuple = list()
    for i in list(publish_data.keys()):
        if publish_data[i]['rate'] > 0:
            for j in range(len(injector_ips)):
                pool_tuple.append((injector_ips[j], 'root', 'netwitness', ld_nodes[j], publish_data[i]['file'], publish_data[i]['rate'], 60))

    LOGGER.debug('pool tuple: %s', pool_tuple)
    # pool = ThreadPool(9)
    # pool.starmap(PSR_Publisher, pool_tuple)
    # print(pool)
    # pool.join()
    # pool.close()
    pool = list()
    for i in pool_tuple:
        pool.append(Process(target=PSR_Publisher, args=(i)))
    print(pool)
    for _thread in pool:
        _thread.start()
    LOGGER.debug('All threads status after start list: %s', pool)
    for _thread in pool:
        _thread.join()
    LOGGER.debug('All threads status after join list: %s', pool)
    print(timeit.default_timer() - start_time)
