#!/usr/bin/env python

import json

from json.decoder import JSONDecodeError
from pprint import pprint

with open('./file2') as f:
    try:
        data = json.load(f)
        pprint(data)
    except JSONDecodeError as e:
        data = list()
        for line in f:
            data.append(json.loads(line))
        pprint(data)
        # print(json.dumps(data))
