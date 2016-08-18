#!/usr/bin/env python

import simplejson as json

config = None

with open('/Users/bakhra/default.json') as config_file:
    config = json.load(config_file)
