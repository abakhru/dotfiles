#!/usr/bin/env python

def test_var_args(f_arg, **kwargs):
    print
    "first normal arg:", f_arg
    print
    'kwrags: ', kwargs
    for key, value in kwargs.iteritems():
        print('%s: %s' % (key, value))
    program = kwargs.get('program', 'NwLogDecoder')
    print
    'PROGRAM:', program


test_var_args('test', program='ABC', name='aaaa', lang='python', testname='test', value='adfasdfasdfsadf')
