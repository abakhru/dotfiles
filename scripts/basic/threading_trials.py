#!/usr/bin/env python

import threading
import time
import timeit
import logging

logging.basicConfig(level=logging.DEBUG,
                    format='(%(threadName)-10s) %(message)s',)

class MyThreadWithArgs(threading.Thread):

    def __init__(self, group=None, target=None, name=None,
                 args=(), kwargs=None, verbose=None):
        threading.Thread.__init__(self, group=group, target=target, name=name)
        self.args = args
        self.kwargs = kwargs
        self.start_time = timeit.default_timer()
        self.timeout = 1 * 60
        self.interval = 5

    def run(self):
        logging.debug('running with %s and %s', self.args, self.kwargs)
        while ((timeit.default_timer() - self.start_time) < self.timeout):
            current_time = timeit.default_timer()
            logging.debug('[{}] Executing run with args: {} & kwargs: {}'
                          .format(timeit.default_timer()
                                  , self.args, self.kwargs))
            try:
                time.sleep(self.interval - (timeit.default_timer() - current_time))
            except TimeoutError:
                pass
        self.finish()
        return

    def finish(self):
        logging.debug('finishing')


threads_list = list()
for i in range(10):
    t = MyThreadWithArgs(args=(i,), kwargs={'a':'A', 'b':'B'})
    t.setDaemon(True)
    t.start()
    threads_list.append(t)

[w.join() for w in threads_list]
