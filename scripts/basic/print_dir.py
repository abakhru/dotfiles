#!/usr/bin/env python

import os


class Exercise(object):

    def __init__(self, dir_name='.'):
        self.dir_name = dir_name

    def print_dir_contents(self, dir_name=None):
        if dir_name is None:
            dir_name = self.dir_name
        for schild in os.listdir(dir_name):
            schild_path = os.path.join(dir_name, schild)
            if os.path.isdir(schild_path):
                self.print_dir_contents(schild_path)
            else:
                print(schild_path)


if __name__ == '__main__':
    suite_path = '/Users/amit1/Dropbox/Amit'
    # s = Exercise('/Users/amit1/Dropbox/Amit')
    # s.print_dir_contents()
    # print([os.path.join(r, f) for r, d, fs in os.walk(suite_path) for f in fs])
    A0 = dict(zip(('a', 'b', 'c', 'd', 'e'), (1, 2, 3, 4, 5)))
    A1 = range(10)
    A2 = sorted([i for i in A1 if i in A0])
    A3 = sorted([A0[s] for s in A0])
    A4 = [i for i in A1 if i in A3]
    A5 = {i: i * i for i in A1}
    A6 = [{i: i * i} for i in A1]
