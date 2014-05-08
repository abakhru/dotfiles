#!/usr/bin/env python

import os
import gzip
import sys
from multiprocessing import Pool

file = '/sts/custdata/sears_unified/06/00:00/shard_ff.log.gz'

if os.path.exists(file):
    print 'file is good'
else:
    sys.exit(0)

pool = Pool(5)
with open(file) as f:
    #line = f.read()
    pool.map(func, iter(partial(f.readlines, 8192), []), chunksize=1)
    print func

f.close()
#print 'total txns: ', count
