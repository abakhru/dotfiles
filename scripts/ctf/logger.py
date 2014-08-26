#!/usr/bin/env python

import os
import sys
#import logging
from ctf.framework.logger import LOGGER, LogStream

LOGGER.setLevel('DEBUG')

os.system('rm debug')
LogStream.Register(open("debug","w"))
LOGGER.debug(LOGGER.handlers)
LOGGER.debug("bla bla")
LOGGER.info('aaaaaaaaaaaaaa')
