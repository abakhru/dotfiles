#!/usr/bin/env python

import re
import requests
import timeit

from functools import partial
from multiprocessing.dummy import Pool as ThreadPool



class LogDecoderConcentratorStat(object):
    """LogDecoder and Concentrator stats using REST API calls"""

    def __init__(self, ld_node, c_node, interval, timeout,
                 outfile='ld_stat_result'
                 , noise_rate=0, trigger_rate=0, count=0, c_node_port=50105, ld_node_port=50102):

        threading.Thread.__init__(self, group, target, name, *args, **kwargs)
        self.stop = threading.Event()
        self.interval = interval
        self.timeout = timeout
        self.ld_node = ld_node
        self.ld_node_port = ld_node_port
        self.c_node = c_node
        self.c_node_port = c_node_port
        self.inj_node = inj_node
        self.noise_rate = noise_rate
        self.trigger_rate = trigger_rate
        self.count = count
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
        stats = data
        with open(self.outfile, 'a+') as f:
            for i in range(len(stats)):
                f.write(str(time.strftime("%Y-%b-%d %H:%M:%S")) + ', '
                        + str(stats[i][0]) + ', '
                        + str(stats[i][1]) + ', '
                        + str(stats[i][2]) + ', '
                        + str(stats[i][3]) + '\n')


class WorkerThreadPool(object):
    # start_time = timeit.default_timer()

    def __init__():
        # Make the Pool of workers
        pool = ThreadPool(4)
    # # Open the urls in their own threads and return the results
    # ld_rates = pool.starmap(get_session_rate, [('10.101.59.237', 50102), ('10.101.59.238', 50102), ('10.101.59.239', 50102)])
    # conc_rates = pool.starmap(get_session_rate, [('10.101.59.240', 50105), ('10.101.59.241', 50105), ('10.101.59.242', 50105)])
    def close():
        #close the pool and wait for the work to finish
        pool.close()
        pool.join()

    # print(timeit.default_timer() - start_time)

if __name__ == __main__:
    p = LogDecoderConcentratorStat()
    w = WorkerThreadPool()
