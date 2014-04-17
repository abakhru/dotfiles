#!/usr/bin/python

import re
import optparse
import time

from optparse import OptionParser, Option, OptionValueError

slave_list = ['localhost']

class MyOption(Option):

    ACTIONS = Option.ACTIONS + ('extend',)
    STORE_ACTIONS = Option.STORE_ACTIONS + ('extend',)
    TYPED_ACTIONS = Option.TYPED_ACTIONS + ('extend',)
    ALWAYS_TYPED_ACTIONS = Option.ALWAYS_TYPED_ACTIONS + ('extend',)

    def take_action(self, action, dest, opt, value, values, parser):
        if action == 'extend':
            lvalue = value.split(',')
            values.ensure_value(dest, []).extend(lvalue)
        else:
            Option.take_action(
                self, action, dest, opt, value, values, parser)


OPTS = OptionParser(option_class=MyOption, usage='%%prog [options]\n\n%s' % __doc__)

OPTS.add_option('-k', '--keyspace', dest='delete_keyspaces'
                , default=False, action='store_true'
                , help='Delete keyspaces older than 24 hours [%default]')
OPTS.add_option('-d', '--directory', dest='delete_emptydirs'
                , default=False, action='store_true'
                , help='Delete empty directories older than 24 hours [%default]')
OPTS.add_option('-m', '--machines', dest='machine_list'
                , action='extend'
                , help='comma seperated list of machines')

(options, args) = OPTS.parse_args()


if (options.delete_keyspaces == True):
    print 'keyspace: ', options.delete_keyspaces
if (options.delete_emptydirs == True):
    print 'directories: ', options.delete_emptydirs
if options.machine_list:
    print slave_list + options.machine_list
