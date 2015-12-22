#!/usr/bin/env python

import os
import json

f = open('/Users/bakhra/temp_bang_psr.json')
ips_list = list()
config = json.load(f)
for k, v in config['servers'].items():
    if isinstance(v, dict):
        for k1, v1 in v.items():
            if isinstance(v1, list) and k1 == 'ip':
                if len(v1) > 0 and v1[0] != '':
                    ips_list.extend(v1)
print(ips_list)
for i in ips_list:
   print(i, end=',')
