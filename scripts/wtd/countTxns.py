#!/usr/bin/env python

import os
import gzip
import sys
import time

file = './shard_51.log.gz'

# for python 2.6 only
class myGzipFile(gzip.GzipFile):
    def __enter__(self):
        if self.fileobj is None:
            raise ValueError("I/O operation on closed GzipFile object")
        return self

    def __exit__(self, *args):
        self.close()

#file = '/var/opt/sears_with_scorelets/2012/03-Mar/08/00:00/sb08/shard_sorted.log.gz'
file = sys.argv[1]

count = 0
# calculating the execution time
start_time = time.time()
with myGzipFile(file, 'rb') as f:
    for lines in f:
        if lines.startswith('t'):
            count += 1
            #print lines

print time.time() - start_time, "seconds"
f.close()
print 'total txns: ', count
