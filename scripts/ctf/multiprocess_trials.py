#!/usr/bin/env python

import re
import requests
import timeit

from functools import partial
from multiprocessing.dummy import Pool as ThreadPool


def get_session_rate(host, port):
    url = ('http://%s:%s/database/stats/session.rate' % (host, port))
    result = requests.get(url, auth=('admin', 'netwitness'))
    return re.findall(r'<string>(\d+)</string>', result.text)[0]


def get_session_cnt(host, port=50102):
    url = ('http://%s:%s/database/stats/session.total' % (host, port))
    result = requests.get(url, auth=('admin', 'netwitness'))
    return re.findall(r'<string>(\d+)</string>', result.text)[0]


start_time = timeit.default_timer()
print(start_time)
# Make the Pool of workers
pool = ThreadPool(6)
# Open the urls in their own threads and return the results
ld_rates = pool.starmap(get_session_rate, [('10.101.59.237', 50102), ('10.101.59.238', 50102), ('10.101.59.239', 50102)])
conc_rates = pool.starmap(get_session_rate, [('10.101.59.240', 50105), ('10.101.59.241', 50105), ('10.101.59.242', 50105)])
#close the pool and wait for the work to finish
pool.close()
pool.join()
print(ld_rates)
print(conc_rates)
print(timeit.default_timer() - start_time)
