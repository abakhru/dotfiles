#!/usr/bin/env python

import os
import itertools
import json
import pickle

from pprint import pprint

from framework.common.logger import LOGGER
from productlib.mongodb.response import ResponseMongoDB

LOGGER.setLevel('DEBUG')

def change_keys(obj):
    new_obj = obj
    for k in new_obj.items():
        if hasattr(obj[k], '__getitem__'):
            change_keys(obj[k])
        if '$' in k:
            obj[k.replace('$oid', '\u0024oid')] = obj[k]
            del obj[k]

def main(file_path):
    with open(file_path) as f:
        json_array = json.load(f)
    print(json_array['_id'])
    n_json_array = change_keys(json_array)
    pprint(n_json_array['_id'])

if __name__ == '__main__':
    file_path = ('/Users/bakhra/src/automation/unite/tests/backend/response/'
                 'testdata/basic_incidents_test.py/BasicIncidentsTest/test_esa_incident_creation/esa_rule.json')
    # p = ResponseMongoDB(host='10.101.217.122', db_name='im', )
    # p.InsertRulesDataIntoDatabase(file_path=file_path)
    main(file_path)
