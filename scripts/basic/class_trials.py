#!/usr/bin/env python

A = 'amit'
B = 'bakhru'

class BaseClass(object):
    def __init__(self, first=A, last=B, rank='AAA'):   # you're using named parameters, declare them as named one.
        self.first = first
        self.last = last
        self.rank = rank

class DerivedClass(BaseClass):   # don't forget to declare inheritance
    def __init__(self, rank='Z', *args, **kwargs):    # in args, kwargs, there will be all parameters you don't care, but needed for baseClass
        super(DerivedClass, self).__init__(rank=rank, *args, **kwargs)

b1 = DerivedClass()
print b1.first
print b1.last
print b1.rank
