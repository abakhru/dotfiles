#!/usr/bin/env python

from pyjolokia import Jolokia

# Enter the jolokia url
j4p = Jolokia('http://localhost:8778/jolokia/')
# Put in the type, the mbean, or other options. Check the jolokia users guide for more info
# This then will return back a python dictionary of what happend to the request
data = j4p.request(type = 'read', mbean='com.rsa.netwitness.esa:type=Service,subType=Status,id=service', attribute='Status')
print data['value']
