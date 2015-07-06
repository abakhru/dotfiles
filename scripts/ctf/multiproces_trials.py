#!/usr/bin/env python

import multiprocessing as mp

from mctf.framework import harness as mctf_harness

# Define an output queue
output = mp.Queue()


# define a example function
def rand_string():
    """ Generates a random string of numbers, lower- and uppercase chars. """
    _ssh = mctf_harness.SshCommandClient('10.101.59.231', user='root', password=None)
    print _ssh
    cmd = 'top -b -d 1 -n 1|egrep \'java\''
    # for i in xrange(self.count):
    # result = _ssh.command(cmd, '#', timeout=40)
    output.put(cmd)


def cube(x):
    return x**3

# Setup a list of processes that we want to run
# processes = [mp.Process(target=rand_string, args=(15, output)) for x in range(6)]
# processes = [mp.Process(target=rand_string) for x in range(2)]
# print processes
pool = mp.Pool(processes=6)
# results = [pool.apply(cube, args=(x,)) for x in range(9,15)]
# results = pool.map(cube, range(9,15))
results = [pool.apply_async(cube, args=(x,)) for x in range(9, 15)]
# print results
output = [p.get() for p in results]
print(output)

# Run processes
# for p in processes:
#    p.start()

# Exit the completed processes
# for p in processes:
#    print 'p = ', p
#    p.join()

# Get process results from the output queue
# results = [output.get() for p in processes]

# print(results)
