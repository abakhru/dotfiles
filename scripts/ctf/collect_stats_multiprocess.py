#!/usr/bin/env python

import os
import re
import requests
import threading
import time
import timeit

from functools import partial
from multiprocessing.dummy import Pool as ThreadPool
from framework.common.logger import LOGGER

HOST_USERNAME = 'root'
HOST_PASSWORD = 'netwitness'
REST_USERNAME = 'admin'
REST_PASSWORD = 'netwitness'

LOGGER.setLevel('DEBUG')


class LogDecoderConcentratorStat(object):
    """LogDecoder and Concentrator stats using REST API calls"""

    def __init__(self, ld_node, c_node, interval, timeout,
                 outfile='ld_stat_result', c_node_port=50105, ld_node_port=50102):

        self.interval = interval
        self.timeout = timeout
        self.ld_node = ld_node
        self.ld_node_port = ld_node_port
        self.c_node = c_node
        self.c_node_port = c_node_port
        self.outfile = outfile
        self.rest_user = REST_USERNAME
        self.rest_pass = REST_PASSWORD
        with open(self.outfile, 'a+') as f:
            f.write('time' + ', '
                    + 'LogDecoderRate' + ', '
                    + 'LogDecoderCnt' + ', '
                    + 'ConcentratorRate' + ', '
                    + 'ConcentratorCnt' + ', '
                    + '\n')

    def get_session_rate(self, host, port):
        url = ('http://%s:%s/database/stats/session.rate' % (host, port))
        result = requests.get(url, auth=(self.rest_user, self.rest_pass))
        return re.findall(r'<string>(\d+)</string>', result.text)[0]

    def get_session_cnt(self, host, port):
        url = ('http://%s:%s/database/stats/session.total' % (host, port))
        result = requests.get(url, auth=(self.rest_user, self.rest_pass))
        return re.findall(r'<string>(\d+)</string>', result.text)[0]

    def report(self, data):
        print('data: %s' % data)
        stats = data
        with open(self.outfile, 'a+') as f:
            for i in range(len(stats)):
                f.write(str(time.strftime("%Y-%b-%d %H:%M:%S")) + ', '
                        + str(stats[i]) + ', '
                        + str(stats[i]) + ', '
                        + str(stats[i]) + ', '
                        + str(stats[i]) + '\n')


class WorkerThreadPool(object):

    def __init__(self, obj):
        self.start_time = timeit.default_timer()
        self.instance_list = obj
        self.pool = ThreadPool(8)
        self.run()
        self.close()

    def run(self):
        while (timeit.default_timer() - self.start_time) < self.instance_list[0].timeout:
            current_time = timeit.default_timer()
            ld_tuple = list()
            c_tuple = list()
            for i in range(len(self.instance_list)):
                ld_tuple.append((self.instance_list[i].ld_node, 50102))
                c_tuple.append((self.instance_list[i].c_node, 50105))
                ld_rates = self.pool.starmap(self.instance_list[i].get_session_rate, ld_tuple)
                conc_rates = self.pool.starmap(self.instance_list[i].get_session_rate, c_tuple)
                ld_session_cnt = self.pool.starmap(self.instance_list[i].get_session_cnt, ld_tuple)
                c_session_cnt = self.pool.starmap(self.instance_list[i].get_session_cnt, c_tuple)
            LOGGER.debug('ld_rates: %s', ld_rates)
            LOGGER.debug('conc_rates: %s', conc_rates)
            LOGGER.debug('ld_session_cnt: %s', ld_session_cnt)
            LOGGER.debug('c_session_cnt: %s', c_session_cnt)
            self.instance_list[0].report([ld_rates, ld_session_cnt, conc_rates, c_session_cnt])
            time.sleep(self.instance_list[0].interval - (timeit.default_timer() - current_time))

    def close(self):
        self.pool.close()
        self.pool.join()


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
    noise_inj_nodes = config['servers']['injector']['ip']
    trigger_inj_nodes = config['servers']['injector']['ip']

    obj_list = list()
    start_time = timeit.default_timer()
    for i in range(len(ld_nodes)):
        p = LogDecoderConcentratorStat(ld_node=ld_nodes[i], c_node=cr_nodes[i], interval=5, timeout=60, outfile=os.path.join('./t', 'ld_stat_result%s' % i))
        obj_list.append(p)
    w = WorkerThreadPool(obj_list)
    print(timeit.default_timer() - start_time)
