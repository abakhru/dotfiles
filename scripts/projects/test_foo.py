import unittest2
import pytest


# def inc(x):
#     return x + 1
#
#
# def test_numbers_3_4():
#     # assert True == False
#     assert inc(3) == 4
#
#
# def test_inc_number():
#     assert inc(4545) == 4546


class AcceptC(object):

    def __init__(self):
        self.minimum = 30
        self.maximum = 40


class TestAcceptC(unittest2.TestCase):

    def setUp(self):
        self.accept = AcceptC()

    @pytest.mark.parametrize("minimum, maximum, expected_min, expected_max"
                             , [
                                ("13", "5", 30, 40),
                                ("30", "40", 30, 40),
                               ])
    def test_init_returns_correct_results(self, minimum, maximum, expected_min, expected_max):
        expected_min = self.accept.minimum
        expected_max = self.accept.maximum
        self.assertEqual(minimum, expected_min)
        self.assertEqual(maximum, expected_max)


if __name__ == '__main__':
    unittest2.main()
