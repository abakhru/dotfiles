import json
import os

import pytest

from framework.common.logger import LOGGER


def pytest_generate_tests(metafunc):
    # called once per each test function
    funcarglist = metafunc.cls.params[metafunc.function.__name__]
    argnames = sorted(funcarglist[0])
    metafunc.parametrize(argnames, [[funcargs[name] for name in argnames]
                                    for funcargs in funcarglist])


class TestClass:

    # a map specifying multiple argument sets for a test method
    test_path = ('/Users/amit1/src/automation/unite/tests'
                 '/backend/analytics/testdata/basic_test.py/BasicAnalyticsTest/test_single_alert')
    test_input = os.path.join(test_path, 'json_input.txt')
    test_expected = 'google.com'

    params = {
        'test_A': [dict(input=test_input, expected=test_expected)],
        'test_B': [dict(a=11, b=0)],
    }

    def test_A(self, input, expected):
        with open(input) as f:
            actual = f.readlines()
        actual = json.loads(actual[0])['alias_host']
        LOGGER.debug('actual: {}'.format(actual))
        assert expected in actual

    def test_B(self, a, b):
        pytest.raises(ZeroDivisionError, "a/b")
