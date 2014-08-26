#!/usr/bin/env python

import unittest

class Palindrome(object):

    def check_palindrome(self, word=None):
        if word is None:
            print 'Please provide a word to check for palindrome.'
            return False

        word_list = list(word)
        temp_list = []
        for i in reversed(xrange(len(word))):
            temp_list.append(word[i])

        if word_list == temp_list:
            print('\'%s\' word is a palindrome' % word)
            return True
        else:
            print('\'%s\' word is NOT a palindrome' % word)
            return False


class PalindromeTest(unittest.TestCase):

    def setUp(self):
        self.palindrome = Palindrome()

    def test_1(self):
        self.assertTrue(self.palindrome.check_palindrome('dad'))

    def test_3(self):
        self.assertFalse(self.palindrome.check_palindrome('hello'))

    def test_4(self):
        self.assertTrue(self.palindrome.check_palindrome('saippuakalasalakauppias'))

    def test_5(self):
        self.assertTrue(self.palindrome.check_palindrome('tattarrattat'))

    def test_6(self):
        self.assertFalse(self.palindrome.check_palindrome('Diaper'))

    def test_7(self):
        self.assertTrue(self.palindrome.check_palindrome('otto'))

    def test_8(self):
        self.assertTrue(self.palindrome.check_palindrome('mom'))

    def test_9(self):
        self.assertFalse(self.palindrome.check_palindrome())

if __name__ == '__main__':
    unittest.mainse()
