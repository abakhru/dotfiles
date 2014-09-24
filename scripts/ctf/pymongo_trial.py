#!/usr/bin/env python

import pymongo
import time


from bson import BSON
from bson import json_util
from ctf.framework.logger import LOGGER
LOGGER.setLevel('DEBUG')

class MongoDBClientMixins(object):
    """ MongoDBClient utilities that allow extracting alerts from mongo using pymongo.
    """

    def __init__(self, host='localhost', db_name='esa', db_user='esa', db_pass='esa'):
        LOGGER.debug('Connectiong to MongoDb...')

        try:
            self.conn = pymongo.MongoClient(host)
            LOGGER.debug('Connected to MongoDB successfully!!!')
        except pymongo.errors.ConnectionFailure, e:
            LOGGER.error('Could not connect to MongoDB: %s' % e)

        if self.conn is not None:
            self.db = self.conn.esa
            if not self.db.authenticate(db_user, db_pass, source=db_name):
                LOGGER.error('Unable to authenticate to MongoDB')
                return

            LOGGER.debug('Authenticated to MongoDb')

    def get_alerts(self, collection_name='alert', moduleId=None, sort_field='time'):
        """Extract alerts from mongodb based on moduleId.

        Returns a list of alerts related to provided moduleId.
        """

        moduleId = moduleId
        __no_of_retries = 3
        doc = []

        try:
            """
            if moduleId is None:
                doc = list(self.db[collection_name].find().sort(sort_field, 1))
            else:
                doc = list(self.db[collection_name].find({'module_id' : moduleId}).sort(sort_field, 1))
            """
            while not len(doc) and __no_of_retries is not 0:
                if moduleId is None:
                    doc = list(self.db[collection_name].find().sort(sort_field, 1))
                else:
                    doc = list(self.db[collection_name].find(
                               {'module_id' : moduleId}).sort(sort_field, 1))
                if not len(doc):
                    LOGGER.debug('Got No outut, trying again.!!')
                    time.sleep(0.3)
                    __no_of_retries -= 1
            return doc
        except Exception as e:
            LOGGER.error('Unable to extract alerts')
            LOGGER.error(e)
            return None

    def cleanup_mongo(self, collection_name='alert'):
        """Removes all documents from the alert collection"""
        LOGGER.info('Cleaning all alerts from MongoDb')
        try:
            self.db[collection_name].remove({})
        except Exception as e:
            LOGGER.error('Unable to cleanup mongo')
            LOGGER.error(e)

    def close(self):
        try:
            self.conn.close()
        except:
            pass

if __name__ == '__main__':
    p = MongoDBClientMixins()
    for item in p.get_alerts(moduleId='4ec428d8-a7a5-4a69-83ef-975ab1786cc0'):
        print '===='
        print item
        print '===='
    p.close()