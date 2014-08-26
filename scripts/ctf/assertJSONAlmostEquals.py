#!/usr/bin/env python

from thirdparty import simplejson
from pprint import pprint

def assertJSONFileAlmostEqualsKnownGood(knowngoodfile, outfile, ignorefields=''):
    """Assert the threat group file is almost equal to the known good

    ARGS:
        outfile: The path/file name of the test output threat group file(filename)
        knowngoodfile: The path/file name of the known good threat group file(filename)
        ignorefields: A comma seperated list of fields to ignore for the comparison.
    """

    comparison = []
    for file in [outfile, knowngoodfile]:
        json_data=open(file)
        data = simplejson.load(json_data)
        json_data.close()
        #pprint(data)
        comparison.append(data)
    final_list = []
    for i in comparison:
        dict1 = {}
        for k,v in i.iteritems():
            if k in ignorefields:
                continue
            else:
                dict1[k] = v
                print 'key:', k
                print 'value:', v
        final_list.append(dict1)
    pprint(final_list)

assertJSONFileAlmostEqualsKnownGood('testdata/basic_test.py/BasicESATest/test_up_and_down/knowngood/test_up_and_down.json'
                                    , 'o/basic_test.py/BasicESATest/test_up_and_down/test_up_and_down.json'
                                    , ignorefields=['module_id', 'statement', '_id', 'esa_id', 'time', 'timestamp'])
