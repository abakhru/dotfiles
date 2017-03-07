#!/usr/bin/env python
import os
import random

import sortedcontainers

sentence = 'the brown brown fox jumps over the lazy dog amit brown amit'
words = sentence.split()
word_lengths = {word: len(word) for word in words if word != "the"}
print('dict with "word: len(word)": {}'.format(word_lengths))
word_count = {word: words.count(word) for word in words}
print('dict with "word: count(word)": {}'.format(word_count))
print('[sortedcontainers]: {}'.format(sortedcontainers.SortedDict(word_count)))

print('Sorted by Values: {}'.format(dict(sorted(word_count.items(), key=lambda x: x[1], reverse=False))))
print('Sorted by Values in reverse: {}'.format(dict(sorted(word_count.items(), key=lambda x: x[1], reverse=True))))
print('Sorted by Keys: {}'.format(dict(sorted(word_count.items(), key=lambda x: x[0]))))
print('Sorted by Keys in reverse: {}'.format(dict(sorted(word_count.items(), key=lambda x: x[0], reverse=True))))

print('Odd numbers: {}'.format([i for i in range(3, 58) if i % 2 != 0]))
print('Even numbers: {}'.format([i for i in range(3, 58) if i % 2 == 0]))

n = 456
print(int(str(n)[::-1]))

a = [4, 5, 6, 7, 8, 1, 0, 2, 9]
print(list(sortedcontainers.SortedList(a))[::-1])


def binary_search(alist, item):
    first = 0
    last = len(alist) - 1
    found = False
    while first <= last and not found:
        mid_point = (first + last) // 2
        if alist[mid_point] == item:
            found = True
        else:
            if item < a[mid_point]:
                last = mid_point - 1
            else:
                first = mid_point + 1
    return found


print('==== [binary_search] value: {}'.format(binary_search(sortedcontainers.SortedList(a), 8)))


def print_directory_contents(sPath):
    """
    This function takes the name of a directory
    and prints out the paths files within that
    directory as well as any files contained in
    contained directories.

    This function is similar to os.walk. Please don't
    use os.walk in your answer. We are interested in your
    ability to work with nested structures.
    """

    for child in os.listdir(sPath):
        cPath = os.path.join(sPath, child)
        if not os.path.isdir(cPath):
            print_directory_contents(cPath)
        else:
            print(cPath)


def f1(lIn):
    l1 = sorted(lIn)
    l2 = [i for i in l1 if i < 0.5]
    return [i * i for i in l2]


def f2(lIn):
    l1 = [i for i in lIn if i < 0.5]
    l2 = sorted(l1)
    return [i * i for i in l2]


def f3(lIn):
    l1 = [i * i for i in lIn]
    l2 = sorted(l1)
    return [i for i in l1 if i < (0.5 * 0.5)]


import cProfile

lIn = [random.random() for i in range(100000)]
print('=== f1 ====')
cProfile.run('f1(lIn)')
print('=== f2 ====')
cProfile.run('f2(lIn)')
print('=== f3 ====')
cProfile.run('f3(lIn)')
