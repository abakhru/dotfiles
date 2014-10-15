#!/usr/bin/env python

import unittest
from collections import OrderedDict

from ctf.framework.logger import LOGGER
from thirdparty import simplejson as json
from pprint import pprint

LOGGER.setLevel('DEBUG')

class AssertJSON(unittest.TestCase):

    def setUp(self):
        self.mongo_ignorefields = ['module_id', 'statement', '_id', 'esa_time', 'esa_id', 'time', 'timestamp']
        self.rabbit_ignorefields = ['esa_time', 'carlos.event.signature.id', 'carlos.event.timestamp']
        self.outfile = 'test_multiple_esa_up_and_down_mongo.json'
        self.knowngoodfile = 'testdata/esa_server_launch_test.py/TwoESAServersLaunchTest/'\
                             + 'test_multiple_esa_up_and_down/knowngood/test_multiple_esa_up_and_down_mongo.json'

    def assertJSONFileAlmostEqualsKnownGood(self, knowngoodfile, outfile, ignorefields=None):
        """Assert two JSON file provided is almost equal.

        Args:
            knowngoodfile: The path/file name of the known good JSON file(filename)
            outfile: The path/file name of the test output JSON file(filename)
            ignorefields: A comma seperated list of Variable fields to ignore from comparison.
        """

        self.maxDiff = None
        flag = False
        if ignorefields is None:
            ignorefields = []

        json_comparison_list = []
        for _file in [knowngoodfile, outfile]:
            json_raw_data = open(_file, 'rb')
            data = json.load(json_raw_data)
            json_raw_data.close()
            # sorting the JSON Array(list of dicts) with the event_source_id field's value.
            messages_ordered = sorted(data[0], key=lambda k: k['events'][0]['event_source_id'])
            json_comparison_list.append(messages_ordered)

        knowngood_final_list = []
        output_final_list = []

        for i in json_comparison_list:
            final_list = []
            for j in i:
                _dict = {}
                for k, v in j.iteritems():
                    if k in ignorefields:
                        # making only the Variable value empty, to make sure field is atleast present.
                        _dict[k] = ''
                    else:
                        if isinstance(v, list):
                            _d = {}
                            for a, b in v[0].iteritems():
                                if a in ignorefields:
                                    b = ''
                                _d[a] = b
                            v = [_d]
                        elif isinstance(v, dict):
                            _d = {}
                            for a, b in v.iteritems():
                                if a in ignorefields:
                                    b = ''
                                _d[a] = b
                            v = _d
                        _dict[k] = v
                final_list.append(_dict)
            if len(knowngood_final_list) == 0:
                knowngood_final_list = final_list
            elif len(output_final_list) == 0:
                output_final_list = final_list

        if len(knowngood_final_list) == len(output_final_list):
            for i in xrange(0, len(knowngood_final_list)):
                LOGGER.debug('')
                LOGGER.debug('kg item #%i:\n%s', i, knowngood_final_list[i])
                LOGGER.debug('actual item #%i:\n%s', i, output_final_list[i])
                self.assertEqual(knowngood_final_list[i], output_final_list[i])
            return True
        return False

    def test_mongodb_files(self):
        self.outfile = '/Users/bakhra/source/scripts/ctf/test_multiple_esa_up_and_down_mongo.json'
        self.knowngoodfile = 'testdata/esa_server_launch_test.py/TwoESAServersLaunchTest/'\
                             + 'test_multiple_esa_up_and_down/knowngood/test_multiple_esa_up_and_down_mongo.json'
        self.assertJSONFileAlmostEqualsKnownGood(self.knowngoodfile, self.outfile
                                                 , ignorefields=self.mongo_ignorefields)

    def test_rabbitmq_files(self):
        self.outfile = 'o/basic_test.py/BasicESATest/test_multiple_alerts_generation/test_multiple_alerts_generation_rabbit.json'
        self.knowngoodfile = 'testdata/basic_test.py/BasicESATest/test_multiple_alerts_generation/knowngood/test_multiple_alerts_generation_rabbit.json'
        self.assertJSONFileAlmostEqualsKnownGood(self.knowngoodfile, self.outfile
                                                 , ignorefields=self.rabbit_ignorefields)

if __name__ == '__main__':
    unittest.main()
