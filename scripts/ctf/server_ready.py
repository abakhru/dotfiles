#!/usr/bin/env python

import errno
import sys
import time

from pyjolokia import Jolokia
from socket import *


def GetJolokiaRequest(type='read', mbean=None, attribute=None):
    # Enter the jolokia url
    j4p = Jolokia('http://localhost:8778/jolokia/')
    # Put in the type, the mbean, or other options. Check the jolokia users guide for more info
    # This then will return back a python dictionary of what happend to the request
    data = j4p.request(type='read', mbean=mbean, attribute=attribute)
    return data['value']

def _currentTime():
    return int(round(time.time()))

def WaitforReady(host='localhost', port=50036, timeout=30):
    """ timeout in milliseconds."""

    currentTime = _currentTime()

    while (timeout > (_currentTime() - currentTime)):
        time_diff = _currentTime() - currentTime
        print time_diff
        try:
            status = GetJolokiaRequest(mbean='com.rsa.netwitness.esa:type=Service,subType=Status,id=service', attribute='Status')
            if status == 'Running':
                return True
        except:
            time.sleep(1)

    print "Timeout exceeded.. Cannot connect."
    return False

print '====', WaitforReady()
