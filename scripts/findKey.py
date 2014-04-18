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

data = json.loads(json_txt)
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
    for k, v in a.iteritems():
        if k == key:
            b[k] = v
            #print k, ":", v

#findKey(data, 'IP Changed')
findKey(data, 'first')
print b