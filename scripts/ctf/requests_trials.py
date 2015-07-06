#!/usr/bin/env python

import requests
import re
import json
import pprint
import decimal
import xml.etree.ElementTree

def _get_status():
    url = 'http://10.101.217.21:50102/database/stats/status'
    response = requests.get(url, auth=('admin', 'netwitness'))
    print response.text
    root = xml.etree.ElementTree.fromstring(response.text)
    return root[0].text

print _get_status()

# with open('module_mem_stats', 'a+', buffering=1) as f:
#     f.write('time' + ', ' + 'noise rate' + ', ' + 'target rate' + ', '
#             + 'VIRT' + ', ' + 'RES' + ', ' + '%CPU' + '\n')
#
# for i in xrange(100):
#     result = _get_status()
