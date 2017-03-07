"""
Module showing how doctests can be included with source code
Each '>>>' line is run as if in a python shell, and counts as a test.
The next line, if not '>>>' is the expected output of the previous line.
If anything doesn't match exactly (including trailing spaces), the test fails.
"""
import unittest2


def multiply(a, b):
    # doctest
    """
        >>> multiply(4, 3)
        12
        >>> multiply('a', 3)
        'aaa'
    """
    return a * b


def setup_module(module):
    print("\nsetup_module      module:%s" % module.__name__)


def teardown_module(module):
    print("\nteardown_module   module:%s" % module.__name__)


class TestPyTestFixtures(unittest2.TestCase):

    def setUp(self):
        print("\nsetup             class:{}".format(self.__class__.__name__))

    def tearDown(self):
        print("teardown          class:{}".format(self.__class__.__name__))

    @classmethod
    def setUpClass(cls):
        print("setUpClass       class:%s" % cls.__name__)

    @classmethod
    def tearDownClass(cls):
        print("\ntearDownClass    class:%s" % cls.__name__)

    def test_numbers_3_4(self):
        print('test_numbers_3_4  <============================ actual test code')
        assert multiply(3, 4) == 12

    def test_strings_a_3(self):
        print('test_strings_a_3  <============================ actual test code')
        assert multiply('a', 3) == 'aaa'

    def test_numbers_5_6(self):
        print('test_numbers_5_6  <============================ actual test code')
        assert multiply(5, 6) == 30

    def test_strings_b_2(self):
        print('test_strings_b_2  <============================ actual test code')
        assert multiply('b', 2) == 'bb'
