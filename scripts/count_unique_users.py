#!/usr/bin/env python

import collections
import gzip

f = gzip.open('/Users/amit/source/shard_51.log.gz', 'r')

all_user_list = []

for line in f.readlines():
    if 'USER' in line:
        if 'guid' in line:
        #    continue
        #else:
                #D23:59:40.957>..USER>...guid=3b86b782faae10fa5b32e565aa34a427
                #print line
                a = line.split('guid=')
                # creating a list with all uid
                all_user_list.append(a[1].rstrip())

#print all_user_list
f.close()
#print all_user_list
# creating a dict with uid: uid length
dict_len = {}
for i in all_user_list:
	dict_len[i] = len(i)

#print dict_len
# dictionary sorted by length of the key string
a = collections.OrderedDict(sorted(dict_len.items(), key=lambda t: len(t[0]), reverse=True))
#print a
# print top 10 users with largest length
i = 0
for key in a.iterkeys():
	print ('uid: %s ; length: %s' % (key, str(a[key])))
	i += 1
	if i == 10:
		break