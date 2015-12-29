#!/usr/bin/env python

import os

from framework.common.logger import LOGGER

LOGGER.setLevel('DEBUG')


def RenameStatFiles(_dir):
    """Renames all file in test case output dir, adds .txt suffix"""

    LOGGER.debug('All files: %s', os.listdir(_dir))
    for f in os.listdir(_dir):
        _file = os.path.join(_dir, f)
        if os.path.isdir(_file):
            LOGGER.debug('==== %s is a Dir', _file)
            pass
        elif 'json' in f or 'txt' in f:
            LOGGER.debug("==== %s contains 'json/txt'", _file)
            pass
        else:
            os.rename(_file, _file + '.txt')
    LOGGER.debug('Final dir contents: %s', os.listdir(_dir))


RenameStatFiles('/Users/bakhra/src/esa/unify/performance/esa/o/cache_persist_test.py/CachePersistTestCase/test_real_world_usage_cache')
