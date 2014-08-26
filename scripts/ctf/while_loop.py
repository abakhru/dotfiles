#!/usr/bin/env python

from bson import json_util
from thirdparty import simplejson as json
from ctf.framework.logger import LOGGER

def _prettyDumpJsonToFile(data, outfile='t'):
    """ Pretty print and writes JSON output to file name provided."""
    with open(outfile, 'w') as _file:
        _file.write('[\n')
        _file.write('[\n')
        for i in data:
            json_formatted_doc = json_util.dumps(json.loads(i), sort_keys=False, indent=4
                                                 , default=json_util.default)
            LOGGER.info('RabbitMQ Alert notification in JSON format:\n%s', json_formatted_doc)
            _file.write(json_formatted_doc)
            if i is not data[-1]:
                _file.write(',\n')
        _file.write('\n]')
        _file.write('\n]')
    return


list1 = ['{"carlos.event.signature.id": "00dfbf20-2ab3-452f-85de-1066ddfcec23", "carlos.event.device.vendor": "RSA", "carlos.event.device.product": "Event Stream Analysis", "carlos.event.name": "", "carlos.event.timestamp": "2014-09-24 20:40:13", "carlos.event.severity": 5, "carlos.event.device.version": "10.5.0.0-SNAPSHOT", "events": [{"f": 11, "value": "somevalue000000000", "t": "true", "esa_time": 1411591213275, "id": 1, "event_source_id": "Test:1"}]}']
list2 = ['{"carlos.event.signature.id": "00dfbf20-2ab3-452f-85de-1066ddfcec23", "carlos.event.device.vendor": "RSA", "carlos.event.device.product": "Event Stream Analysis", "carlos.event.name": "", "carlos.event.timestamp": "2014-09-24 20:40:13", "carlos.event.severity": 5, "carlos.event.device.version": "10.5.0.0-SNAPSHOT", "events": [{"f": 11, "value": "somevalue000000000", "t": "true", "esa_time": 1411591213275, "id": 2, "event_source_id": "Test:2"}]}']
message_json_list = list1 + list2
_prettyDumpJsonToFile(message_json_list)
