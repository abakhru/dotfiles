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

# calculating the execution time
start_time = time.time()

#S00:29:59.347   IP Session Start Time   {"val":1311208139631}
#S00:29:59.347   IP Changed      {"prev":"101.123.165.27","disterritoriality":{"detail":"unknown","val":-1},"divergence":1}

with myGzipFile(file, 'rb') as f:
    for lines in f:
        if (lines.startswith('S')) & ('IP' in lines):
            a = lines.split('\t')
            print lines
            print 'scorelet_name: ', a[1]
            print 'scorelet_value: ', a[2]

print time.time() - start_time, "seconds"
f.close()
print 'total txns: ', count
