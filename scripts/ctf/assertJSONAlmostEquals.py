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

    def assertJSONFileAlmostEqualsKnownGood(self, knowngoodfile, outfile, ignorefields=None
                                            , sort_field='event_source_id'):
        """Assert two JSON file provided is almost equal.

        Args:
            knowngoodfile: The path/file name of the known good JSON file(filename)
            outfile: The path/file name of the test output JSON file(filename)
            ignorefields: A comma separated list of Variable fields to ignore from comparison.
            sort_field: sort the output file based on the field provided
                        By default, events will be sorted based on event_source_id
        """
        # to enable showing maximum diffs.
        self.maxDiff = None

        if ignorefields is None:
            ignorefields = []
        json_comparison_list = []
        for _file in [knowngoodfile, outfile]:
            json_raw_data = open(_file, 'rb')
            data = json.load(json_raw_data)
            json_raw_data.close()
            # sorting the JSON Array(list of dicts) with the event_source_id field's value.
            if sort_field == 'event_source_id':
                messages_ordered = sorted(data[0], key=lambda k: k['events'][0]['event_source_id'])
            elif sort_field == 'engineUri':
                _data = sorted(data[0], key=lambda k: k['engineUri'])
                messages_ordered = sorted(_data, key=lambda k: k['events'][0]['event_source_id'])
                pprint(messages_ordered)
            json_comparison_list.append(messages_ordered)

        knowngood_final_list = []
        output_final_list = []

        for i in json_comparison_list:
            final_list = []
            for j in i:
                _dict = {}
                for k, v in j.iteritems():
                    if k in ignorefields:
                        # making only the Variable value empty,
                        # to make sure field is atleast present.
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
            else:
                output_final_list = final_list

        # asserting number of expected and actual alerts are same.
        self.assertEqual(len(knowngood_final_list), len(output_final_list))
        if len(knowngood_final_list) == len(output_final_list):
            for i in xrange(0, len(knowngood_final_list)):
                self.assertEqual(knowngood_final_list[i], output_final_list[i])
            return True
        return False

    def test_mongodb_files(self):
        self.outfile = '/Users/bakhra/source/server-ready/python/ctf/esa/o/enrichment_test.py/EnrichmentTest/test_same_exchange_same_source_all_espers/test_same_exchange_same_source_all_espers_mongo.json'
        self.knowngoodfile = '/Users/bakhra/source/server-ready/python/ctf/esa/testdata/enrichment_test.py/EnrichmentTest/test_same_exchange_same_source_all_espers/knowngood/test_same_exchange_same_source_all_espers_mongo.json'
        self.assertJSONFileAlmostEqualsKnownGood(self.knowngoodfile, self.outfile
                                                 , ignorefields=self.mongo_ignorefields
                                                 , sort_field='engineUri')

    def test_rabbitmq_files(self):
        self.outfile = 'o/basic_test.py/BasicESATest/test_multiple_alerts_generation/test_multiple_alerts_generation_rabbit.json'
        self.knowngoodfile = 'testdata/basic_test.py/BasicESATest/test_multiple_alerts_generation/knowngood/test_multiple_alerts_generation_rabbit.json'
        self.assertJSONFileAlmostEqualsKnownGood(self.knowngoodfile, self.outfile
                                                 , ignorefields=self.rabbit_ignorefields)

if __name__ == '__main__':
    unittest.main()
