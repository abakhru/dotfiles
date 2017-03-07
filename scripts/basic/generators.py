#!/usr/bin/env python

import random


def lottery():
    # returns 6 numbers between 1 and 40
    for i in range(6):
        yield random.randint(1, 40)

    # returns a 7th number between 1 and 15
    yield random.randint(1, 15)


# for random_number in lottery():
#     print('And the next number is... %d!' % random_number)

a = [1, 2, 3, 4, 5]
print([i for i in iter(a)])
