#!/usr/bin/env python

import sortedcontainers


a = [1, 2, 4, 4]


def check_sum_pair(a_list=a, _sum=8):
    i = len(a_list) - 1
    for j in range(len(a_list) - 1):
        if a_list[i] + a_list[j] == _sum:
            return True
    return False


# print(check_sum_pair())

"""
A(input string) = "egoogle"
B(order string) = "dog"
Output = "ooggele"
"""


def process_strings(input_string, order_string):
    output = list()
    for i in range(len(order_string)):
        for j in range(len(input_string)):
            if order_string[i] == input_string[j]:
                output.append(input_string[j])
    output += [i for i in input_string if i not in order_string]
    return ''.join(output)


def better_process_strings(input_string, order_string):
    """
        A(input string) = "egoogle" | ‘eeggloo’
        B(order string) = "dog"
        Output = "ooggele"
    """
    output = list()
    sorted_input = sortedcontainers.SortedList(input_string)
    for i in range(len(order_string)):
        mid_point = len(sorted_input) // 2
        left_half = sorted_input[:mid_point]
        right_half = sorted_input[mid_point:]
        if order_string[i] in left_half and order_string[i] in right_half:
            output.extend([j for j in input_string if order_string[i] == j])
        else:
            if order_string[i] in left_half:
                output.extend([j for j in left_half if order_string[i] == j])
            elif order_string[i] in right_half:
                output.extend([j for j in right_half if order_string[i] == j])

    output += [i for i in input_string if i not in order_string]
    return ''.join(output)

print(better_process_strings(input_string='egoogle', order_string='dog'))
