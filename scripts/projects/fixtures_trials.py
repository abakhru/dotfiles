from pprint import pprint

import pytest

from driver.mongodb.mongodb import MongoDBDriver
from framework.common.logger import LOGGER
# from framework.common.testcase import TestCase
# from framework.common.testcase import TestCase

LOGGER.setLevel('DEBUG')


@pytest.fixture(scope='module', params=[1, 2])
# @pytest.fixture(params=[1])
def cheese_db(request):
    print('\n[setup] cheese_db, connect to db')
    # code to connect to your db
    mongo_client = MongoDBDriver(database_name='esa', username='esa', password='esa')
    alerts = mongo_client.GetAlerts()
    # print('\n-----------------')
    # print('fixturename : %s' % request.fixturename)
    # print('scope       : %s' % request.scope)
    # print('function    : %s' % request.function.__name__)
    # print('cls         : %s' % request.cls)
    # print('module      : %s' % request.module.__name__)
    # print('fspath      : %s' % request.fspath)
    # print('-----------------')

    def tearDown():
        print('\n[teardown] cheese_db finalizer, disconnect from db')
        mongo_client.Close()

    request.addfinalizer(tearDown)
    return alerts


# @pytest.mark.usefixtures(cheese_db)
class TestMongoAlerts:

    def test_cheese_database(self, cheese_db):
        print('in test_cheese_database()')
        # pprint(cheese_db)
        print('==== time: {}'.format(cheese_db[0]['time']))

    def test_brie(self, cheese_db):
        print('in test_brie()')
        assert cheese_db[0]['engineUri'] == 'default'

    def test_camenbert(self, cheese_db):
        print('in test_camenbert()')
        assert cheese_db[2]['event_source_id'] == '3:Test'
