#!/usr/bin/env python

import os
import time

def load(left_side, right_side, length, _time):
    x = 0
    y = ""
    print("\r")
    while x < length:
        space = length - len(y)
        space = " " * space
        z = left_side + y + space + right_side
        print("\r", z,)
        y += "█"
        time.sleep(_time)
        x += 1
    # cls()

print("loading something awesome")
load("|", "|", 10, .01)
