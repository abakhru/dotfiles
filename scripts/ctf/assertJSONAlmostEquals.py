#!/usr/bin/env python

import os
import simplejson as json

from ctf.framework import ctf_unittest
from ctf.framework.logger import LOGGER


LOGGER.setLevel('DEBUG')


class AssertJSON(ctf_unittest.TestCase):
    """def setUp(self):
        LOGGER.debug('==== Inside setUp function ===')
        self.mongo_ignorefields = ['module_id', 'statement', '_id'
                                   , 'esa_time', 'esa_id', 'time', 'timestamp']
        self.rabbit_ignorefields = ['esa_time', 'carlos.event.signature.id'
                                    , 'carlos.event.timestamp']
        self.outfile = 'test_multiple_esa_up_and_down_mongo.json'
        self.knowngoodfile = 'testdata/esa_server_launch_test.py/TwoESAServersLaunchTest/'\
                             + 'test_multiple_esa_up_and_down/knowngood/test_multiple_esa_up_and_down_mongo.json'
    """

    # class attributes
    mongo_ignorefields = ['module_id', 'statement', '_id'
                          , 'esa_time', 'esa_id', 'time', 'timestamp']
    rabbit_ignorefields = ['esa_time', 'carlos.event.signature.id'
                           , 'carlos.event.timestamp']
    mongo_file = 'test_single_alert_generation_mongo.json'
    rabbit_file = 'test_single_alert_generation_rabbit.json'
    out_dir = '/Users/bakhra/source/server-ready/python/ctf/esa/o/basic_test.py/' \
              'BasicESATest/test_single_alert_generation'
    kg_dir = '/Users/bakhra/source/server-ready/python/ctf/esa/testdata/' \
             'basic_test.py/BasicESATest/test_single_alert_generation/knowngood/'
    mongo_knowngoodfile = os.path.join(kg_dir, mongo_file)
    mongo_outfile = os.path.join(out_dir, mongo_file)
    rabbit_knowngoodfile = os.path.join(kg_dir, rabbit_file)
    rabbit_outfile = os.path.join(out_dir, rabbit_file)

    @classmethod
    def setUpClass(cls):
        LOGGER.debug('==== Inside setUpClass function ===')
        super(AssertJSON, cls).setUpClass()

    @classmethod
    def tearDownClass(cls):
        LOGGER.debug('=== Inside tearDownClass')

    # def tearDown(self):
    #    LOGGER.debug('=== Inside tearDown')

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
                # pprint(messages_ordered)
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
        LOGGER.debug('==== Launching test_mongodb_files')
        self.assertJSONFileAlmostEqualsKnownGood(self.mongo_knowngoodfile, self.mongo_outfile
                                                 , ignorefields=self.mongo_ignorefields
                                                 , sort_field='engineUri')

    def test_rabbitmq_files(self):
        LOGGER.debug('==== Launching test_rabbitmq_files')
        self.assertJSONFileAlmostEqualsKnownGood(self.rabbit_knowngoodfile, self.rabbit_outfile
                                                 , ignorefields=self.rabbit_ignorefields)

    def test_Mongodb_files(self):
        LOGGER.debug('==== Launching test_Mongodb_files')
        self.assertJSONFileAlmostEqualsKnownGood(self.mongo_knowngoodfile, self.mongo_outfile
                                                 , ignorefields=self.mongo_ignorefields
                                                 , sort_field='engineUri')

    def test_Rabbitmq_files(self):
        LOGGER.debug('==== Launching test_Rabbitmq_files')
        self.assertJSONFileAlmostEqualsKnownGood(self.rabbit_knowngoodfile, self.rabbit_outfile
                                                 , ignorefields=self.rabbit_ignorefields)


if __name__ == '__main__':
    unittest.main()
