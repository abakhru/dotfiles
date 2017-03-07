#!/usr/bin/env python

from multiprocessing.dummy import Pool

import multiprocessing

import logging
import requests
import unittest2


class ConcurrentRequests(unittest2.TestCase):

    @classmethod
    def setUpClass(cls):
        cls.num_of_requests = 100
        # cls.url = 'http://code.tutsplus.com/'
        cls.url = 'http://127.0.0.1:15672'
        cls.session = requests.Session()
        cls.session.trust_env = False

    def make_requests(self, url):
        result = self.session.get(url)
        # import pdb; pdb.set_trace()
        # print('{}: {}'.format('a', result.status_code))
        print('{}: {}'.format(multiprocessing.current_process().name, result.status_code))
        # if result.status_code != '200':
        #     raise requests.ConnectionError('request failed')

    def test_1(self):
        # multiprocessing.log_to_stderr()
        # logger = multiprocessing.get_logger()
        # logger.setLevel(logging.DEBUG)
        try:
            pool = Pool(self.num_of_requests)
            # pool.apply_async(self.make_requests, [self.url for _ in range(self.num_of_requests)])
            pool.map(self.make_requests, [self.url for _ in range(self.num_of_requests)])
            pool.join()
            pool.close()
        except:
            pass
