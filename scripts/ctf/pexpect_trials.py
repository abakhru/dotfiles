#!/usr/bin/env python

import pexpect
import sys
import time
from thirdparty import simplejson

__pexpect = None
PROMPT_PATTERN = '>'
cmd = '/Users/bakhra/source/esa2/client/target/appassembler/bin/esa-client --profiles carlos'

def searchKey(output, key):
    a = output.split('{')
    json_data_list = []
    for i in a:
        if '}' in i:
            json_txt = i.split('}')
            json_txt[0] = '{' + json_txt[0] + '}'
            #print '===='
            #print json_txt[0]
            json_data_list.append(simplejson.loads(json_txt[0]))
    print json_data_list
    print json_data_list[1][key]
    return json_data_list[1][key]

__pexpect = pexpect.spawn(cmd)#, env=env)
__pexpect.logfile = sys.stdout
__pexpect.debug = 1
__pexpect.expect(PROMPT_PATTERN,timeout=10)
__pexpect.sendline('carlos-connect')
__pexpect.expect(PROMPT_PATTERN,timeout=10)
__pexpect.sendline('cd source/message')
__pexpect.expect(PROMPT_PATTERN,timeout=10)
__pexpect.sendline('epl-module-get')
__pexpect.expect(PROMPT_PATTERN,timeout=10)
result = __pexpect.before
a = searchKey(result, 'identifier')
print 'identifier: ', a
__pexpect.sendline('quit')
__pexpect.expect(pexpect.EOF)
__pexpect.terminate(force=True)

if 'NumEvents' in json_data:
    print 'NumEvents: ', json_data['NumEvents']
