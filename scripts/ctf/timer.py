#!/usr/bin/env python

import os
import time
import timeit

class Timer(object):

    def __init__(self, timeout=60, interval=5):
        current_time = timeit.default_timer()
        print('Starting Timer for %s seconds' % timeout)
        while (timeit.default_timer() - current_time) < timeout:
            current_time = timeit.default_timer()
            print(timeit.default_timer())
            end_time = timeit.default_timer()
            time.sleep(interval - (end_time - current_time))
        print('Timer Done')

if __name__ == '__main__':
    p = Timer()
