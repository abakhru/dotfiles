#!/usr/bin/python

#NOTE: make sure the shard file you are modifying has same name after modification.

from random import randint

r = open('/Users/bakhra/tmp/us3240/unique_pages.log', 'r')
#r = open('/Users/bakhra/tmp/us3240/t', 'r')
w = open('/Users/bakhra/tmp/us3240/t', 'w')
#w = open('/Users/bakhra/tmp/us3240/t1', 'w')

for line in r.readlines():
    # random number generator between limits
    i = randint(0,500)
    page_name = 'page=/listCatalog/page' + str(i)
    if 'REQUEST' in line:
        a = line.split('&')
        #print a[1]
        a[1] = page_name
        line = '&'.join(a)
        #print line
        w.write(line)
    elif line.startswith('t'):
        #t23:59:41.295   STTX    ip=206.75.36.132
        new_ip = '77.88.99.100'
        a = line.split('=')
        #print a[1]
        a[1] = new_ip
        line = '='.join(a)
        #print line
        w.write(line + '\n')
    elif 'USER' in line:
        #D23:59:40.957>..USER>...guid=3b86b782faae10fa5b32e565aa34a427
        print line
        same_user = 'user3'
        a = line.split('guid=')
        a[1] = same_user
        line = 'id='.join(a)
        print line
        w.write(line + '\n')
    else:
        w.write(line)

r.close()
w.close()
