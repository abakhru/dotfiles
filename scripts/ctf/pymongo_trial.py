#!/usr/bin/env python

import pymongo

from bson import BSON
from bson import json_util

try:
    conn = pymongo.MongoClient('localhost')
    print 'Connected successfully!!!'
except pymongo.errors.ConnectionFailure, e:
    print "Could not connect to MongoDB: %s" % e

if conn is not None:
    db = conn.esa
    db.authenticate('esa', 'esa', source='esa')

    ruleIdentifier = "3b11ec5e-7570-4be5-84da-5fdb641cfa42"

    doc = db["alert"].find_one({'module_id': ruleIdentifier})
    f = open('/Users/bakhra/source/esa2/python/ctf/esa/o/basic_test.py/BasicESATest/test_up_and_down/test.json', 'wb')
    print json_util.dumps(doc, sort_keys=True, indent=4, default=json_util.default)

    f.write(json_util.dumps(doc, sort_keys=True, indent=4, default=json_util.default))
    f.close()
    conn.close()
