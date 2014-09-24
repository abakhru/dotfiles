#!/usr/bin/env python

#from ctf.framework import ctf_unittest

import unittest

from thirdparty import simplejson as json
from pprint import pprint

class AssertJSON(unittest.TestCase):

    def setUp(self):
        self.outfile = 'o/basic_test.py/BasicESATest/test_multiple_alerts_in_rabbitmq/test_multiple_alerts_in_rabbitmq_rabbit.json'
        self.knowngoodfile = 'testdata/basic_test.py/BasicESATest/test_multiple_alerts_in_rabbitmq/knowngood/test_multiple_alerts_in_rabbitmq_rabbit.json'

    def assertJSONFileAlmostEqualsKnownGood(self, knowngoodfile, outfile, ignorefields=[]):
        """Assert the threat group file is almost equal to the known good

        ARGS:
            outfile: The path/file name of the test output threat group file(filename)
            knowngoodfile: The path/file name of the known good threat group file(filename)
            ignorefields: A comma seperated list of fields to ignore for the comparison.
        """

        json_comparison_list = []
        for _file in [knowngoodfile, outfile]:
            json_data = open(_file, 'rb')
            data = json.load(json_data)
            json_data.close()
            json_comparison_list.append(data)
        print 'json_comparison_list of lists:\n'
        for i in json_comparison_list:
            print i
            print '===='

        final_list = []
        for i in json_comparison_list:
            for j in i:
                _dict = {}
                for k, v in j.iteritems():
                    if k in ignorefields:
                        print 'ignoring key:', k
                        continue
                    else:
                        if isinstance(v, list):
                            d = {a: b for a, b in v[0].iteritems() if a not in ignorefields}
                            v = [d]
                        elif isinstance(v, dict):
                            d = {a: b for a, b in v.iteritems() if a not in ignorefields}
                            v = d
                        _dict[k] = v
                final_list.append(_dict)
        print 'final list: %d\n' % len(final_list)
        pprint(final_list)
        return self.assertEqual(final_list[0], final_list[1])

    def test_files(self):
        self.assertJSONFileAlmostEqualsKnownGood(self.knowngoodfile, self.outfile
                                                 , ignorefields=['esa_time'
                                                 , 'carlos.event.signature.id'
                                                 , 'carlos.event.timestamp'])


if __name__ == '__main__':
    unittest.main()
