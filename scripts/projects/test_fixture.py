import pytest

# from framework.common.testcase import TestCase


@pytest.fixture()
def after():
    print('\nAfter each test')
    data = {'foo': 1, 'bar': 2, 'baz': 3}
    return data


# @pytest.mark.usefixtures('before', 'after')
# class TestFixtures(TestCase):
#
#     @pytest.fixture()
#     def before(self):
#         print('\nbefore each test')
#         data = {'foo': 1, 'bar': 2, 'baz': 3}
#         return data
#
#     @pytest.mark.usefixtures('before', 'after')
#     def test_1(self):
#         print('test_1()')
#         print(self.before)
#         assert self.before['foo'] == 1

def test_2(after):
    print('test_2()')
    print(after)
    assert after['foo'] == 1
