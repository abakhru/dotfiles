#!/usr/bin/env python

import os

from framework.common.logger import LOGGER

LOGGER.setLevel('DEBUG')


def RenameStatFiles(_dir):
    """Renames all file in test case output dir, adds .txt suffix"""

    all_files = [os.path.join(r, f) for r, d, fs in os.walk(_dir) for f in fs]
    LOGGER.debug('All files: %s', all_files)
    for f in all_files:
        _file = os.path.join(_dir, f)
        if os.path.isdir(_file):
            LOGGER.debug('==== %s is a Dir, skipping', _file)
            pass
        elif 'json' in f or 'txt' in f or 'xlsx' in f:
            LOGGER.debug("==== %s contains 'json/txt', skipping", _file)
            pass
        else:
            os.rename(_file, _file + '.txt')
    LOGGER.debug('Final dir contents: %s', os.listdir(_dir))


RenameStatFiles('/Users/bakhra/tmp/test_uba_with_qba')
