#!/usr/bin/env python

import os
import sys

from ctf.framework.logger import LOGGER, LogStream
from ctf.framework import harness

if __name__ == '__main__':
    if len(sys.argv) > 1:
        a = harness.PubRabbitMQ(eventType='TestEvent', logdir='.')
        a.publish(input_file=sys.argv[1])
    else:
        LOGGER.error('Please provide a input file')
