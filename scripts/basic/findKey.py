#!/usr/bin/python
import json

json_txt = """
{
    "profileHistory": {
        "begin": null,
        "end": null,
        "sessions": [
            {
                "counts": {
                    "IP Changed": 2
                },
                "first": "2011-07-21T01:41:45.561Z"
            }
        ]
    }
}
"""
json_txt = """
{
  "ConfiguredSources" : [ "amqp://esa.events?EventType=TestEvent&Source=Test&IdField=id" ],
  "CountsByEventType" : [ ],
  "Dirty" : false,
  "DroppedBadType" : 0,
  "DroppedDisabled" : 0,
  "DroppedInvalidPayload" : 0,
  "DroppedMessages" : 0,
  "DroppedMissingField" : 0,
  "Enabled" : true,
  "Name" : "messageBusSource",
  "NumEvents" : 0,
  "Uri" : "esa.events?amqp.exchange_declaration.durable=true",
  "Valid" : true,
  "WorkUnitProcessingRate" : 0,
  "WorkUnitsProcessed" : 0,
  "WorkflowName" : "messageBus"
}
"""

data = json.loads(json_txt)
if 'NumEvents' in data:
    print
    data['NumEvents']
""""
def findKey(json_data, search):
    DictOut = {}
    for key, value in json_data.iteritems():
        print 'iter: %s' % key
        if isinstance(value, dict): 
            findKey(value, search)
        elif isinstance(value, list):
            for i in value:
                findKey(i, search)
        else:
            if (key == search):
                print '%s: %s' % (search, value)
                DictOut[key] = value
                return DictOut

    print 'result for \'%s\': %s' % (key, value)
    #return DictOut

b = {}
b = findKey(data, 'IP Changed')
#b = findKey(data, 'first')
print "===="
print b
#print b['IP Changed']

"""


def JSONtoDict(json_data, Dictout):
    for key, value in json_data.iteritems():
        if isinstance(value, dict):
            JSONtoDict(value, Dictout)
        elif isinstance(value, list):
            for i in value:
                JSONtoDict(i, Dictout)
        else:
            Dictout[key] = value


b = {}


def findKey(json_data, key):
    a = {}
    JSONtoDict(json_data, a)
    print
    a[k]
    for k, v in a.iteritems():
        if k == key:
            b[k] = v
            print
            k, ":", v


# findKey(data, 'IP Changed')
findKey(data, u'NumEvents')
print
b
