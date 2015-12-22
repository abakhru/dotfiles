#!/usr/bin/env python

import multiprocessing as mp

def f(name):
    print('hello', name)

if __name__ == '__main__':
    mp.set_start_method('spawn')
    for i in ['bob', 'amit', 'bakhru']:
        q = mp.Queue()
        p = mp.Process(target=f, args=(i,))
        p.start()
        print(q.get())
        p.join()
