#!/usr/bin/env python

import datetime
import os
import pymongo
import socket
import subprocess
import time
from pprint import pprint

from bson import BSON
from bson import json_util
from ctf.framework.logger import LOGGER
LOGGER.setLevel('DEBUG')

class MongoDBClientMixins(object):
    """ MongoDBClient utilities that allow extracting alerts from mongo using pymongo.
    """

    @property
    def db(self):
        return self.__db

    def __init__(self, host='localhost', port=27017
                 , db_name='esa', db_user='esa', db_pass='esa', source='esa'):

        LOGGER.debug('Connecting to MongoDb...')
        self.db_name = db_name
        try:
            self.conn = pymongo.MongoClient(host, port)
            LOGGER.debug('Connected to MongoDB successfully!!!')
        except pymongo.errors.ConnectionFailure, e:
            LOGGER.error('Could not connect to MongoDB: %s', e)
            exit(0)

        if self.conn is not None:
            self.__db = self.conn[self.db_name]
            if not self.db.authenticate(db_user, db_pass, source=source):
                LOGGER.error('Unable to authenticate to MongoDB')
                return

            LOGGER.debug('Authenticated to MongoDb for \'%s\' database', source)

    def PrettyDumpJson(self, doc_list, outfile):
        """ Pretty print and writes JSON output to file name provided."""
        with open(outfile, 'wb') as _file:
            json_formatted_doc = json_util.dumps(doc_list, sort_keys=False, indent=4
                                                 , default=json_util.default)
            LOGGER.debug('[MongoDB] Generated Alert notification in JSON form:\n%s'
                         , json_formatted_doc)
            _file.write(json_formatted_doc)
            return

    def get_alerts_count(self, collection_name='alert', expectedNumAlerts=1
                         , moduleId=None, retry_interval=1, no_of_retries=3):
        """Extract alerts count from mongodb based on moduleId.

        Args:
            collection_name: name of the mongodb collection. (default=alert)
            expectedNumAlerts: expected number of alerts.
            moduleId: list of unique module ids of deployed epl rules.
            retry_interval: retry get_alerts_count after number of seconds specified.
            no_of_retries: number of retries to do.

        Returns:
            Total Count of alerts for each moduleId provided.
        """

        final_count = 0
        try:
            if moduleId is None:
                alerts_count = 0
                __no_of_retries = no_of_retries
                while alerts_count != expectedNumAlerts and __no_of_retries is not 0:
                    alerts_count = self.db[collection_name].find().count()
                    if alerts_count != expectedNumAlerts:
                        LOGGER.debug('[MongoDB] Not Got expected number of alerts, trying again.!!')
                        time.sleep(retry_interval)
                        __no_of_retries -= 1
                final_count = alerts_count
            else:
                for _id in moduleId:
                    __no_of_retries = no_of_retries
                    alerts_count = 0
                    while alerts_count != expectedNumAlerts and __no_of_retries is not 0:
                        alerts_count = self.db[collection_name].find({'module_id' : _id}).count()
                        if alerts_count != expectedNumAlerts:
                            LOGGER.debug('[MongoDB] Not Got expected number of alerts'
                                         + ', trying again.!!')
                            time.sleep(retry_interval)
                            __no_of_retries -= 1
                    final_count += alerts_count

            LOGGER.debug('[MongoDB] Total Alerts Count: %s', final_count)
            return final_count
        except pymongo.errors.OperationFailure as e:
            LOGGER.error('[MongoDB] Unable to extract alert count.')
            LOGGER.error(e)
            return None

    def get_alerts(self, collection_name='alert', expectedNumAlerts=1, moduleId=None
                   , sort_field='events.esa_time', retry_interval=1, no_of_retries=3):
        """Extract alerts from mongodb based on moduleId.

        Args:
            collection_name: name of the mongodb collection.
            expectedNumAlerts: expected number of alerts.
            moduleId: list of unique module ids of deployed epl rules.
            sort_field: generated alerts will be sorted on this field.
            retry_interval: retry get_alerts after number of seconds specified.
            no_of_retries: number of retries to do.

        Returns:
            List of alerts_list for each moduleId provided.
        """

        final_doc_list = []
        try:
            if moduleId is None:
                __no_of_retries = no_of_retries
                alerts_list = []
                while len(alerts_list) != expectedNumAlerts and __no_of_retries is not 0:
                    alerts_list = list(self.db[collection_name].find().sort(sort_field, 1))
                    if len(alerts_list) != expectedNumAlerts:
                        LOGGER.debug('[MongoDB] Not Got expected number of output, trying again.!!')
                        time.sleep(retry_interval)
                        __no_of_retries -= 1
                final_doc_list.append(alerts_list)
            else:
                for _id in moduleId:
                    __no_of_retries = no_of_retries
                    alerts_list = []
                    while len(alerts_list) != expectedNumAlerts and __no_of_retries is not 0:
                        alerts_list = list(self.db[collection_name].find(\
                                           {'module_id' : _id}).sort(sort_field, 1))
                        if len(alerts_list) != expectedNumAlerts:
                            LOGGER.debug('[MongoDB] Not Got expected number of output'
                                         + ', trying again.!!')
                            time.sleep(retry_interval)
                            __no_of_retries -= 1
                    final_doc_list.append(alerts_list)
            return final_doc_list
        except pymongo.errors.OperationFailure as e:
            LOGGER.error('[MongoDB] Unable to extract alerts')
            LOGGER.error(e)
            return []

    def cleanup_mongo(self, collection_name='alert'):
        """Removes all documents from the provided collection_name."""
        LOGGER.debug('[MongoDB] Cleaning all documents in \'%s\' collection.', collection_name)
        try:
            self.db[collection_name].remove({})
        except Exception as e:
            LOGGER.error('[MongoDB] Cleanup Failed.')
            LOGGER.error(e)

    def close(self):
        try:
            self.conn.close()
        except Exception as e:
            LOGGER.error(e)

    def drop_database(self):
        LOGGER.debug('Dropping database \'%s\'', self.db_name)
        self.conn.drop_database(self.db_name)


class DataScienceUtil(object):
    """ Class that contains DataScience setup utilities."""

    @property
    def mongo_client(self):
        return self.__mongo_client

    @mongo_client.setter
    def mongo_client(self, value):
        self.__mongo_client = value

    def __init__(self):
        self.__mongo_client = None

    def _enable_db_access(self, db_name='ds', db_user='esa', db_pass='esa'):
        """Assigns read/write access to esa user for db_name database provided

        Args:
            db_name: name of the database to assign read/write permissions
            db_user: db user who will get the read/write access
            db_pass: db user's password
        """
        cmd = ('mongo admin -u admin -p netwitness --eval \"db.getSiblingDB(\''
               + db_name + '\').createUser({user: \'' + db_user + '\', pwd: \''
               + db_pass + '\', roles: [\'readWrite\', \'dbAdmin\']})\"')
        LOGGER.debug('Launching command:\n%s', cmd)
        p = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True)
        status = p.communicate()[0].strip()
        LOGGER.debug('Output: %s', status)
        a = status.split('\n')
        LOGGER.debug('=========%s', a[2])

    def config_data_science_db(self):
        """Sets up DataScience db in mongo with required permissions and sample data."""

        # creating unique DataScience db name
        database_name = self.MakeUniqueName(basename='ds')
        self.__mongo_client = MongoDBClientMixins(db_name=database_name)
        self.mongo_client.cleanup_mongo(collection_name='watchlists')
        collection = self.mongo_client.db.watchlists
        collection.insert({"_id": "EXEC_BATCH_rsa", "model_id": "suspiciousDomains_1",
                           "key": "rsa.com", "score": 4, "model_name": " Suspicious Domains",
                           "group_name": "domain"})
        output = list(self.mongo_client.db['watchlists'].find())
        json_output = json_util.dumps(output, sort_keys=False, indent=4, default=json_util.default)
        LOGGER.debug('Inserted data in \'%s\' database:\n%s' % (database_name, json_output))
        self._enable_db_access(db_name=database_name)
        #self.assertIn('model_id', json_output)
        #os.system('mongo %s -u esa -p esa' % database_name)

    def mongo_client_teardown(self):
        if self.mongo_client is not None:
            # cleans up any existing document in watchlist collection inside ds db
            self.mongo_client.cleanup_mongo(collection_name='watchlists')
            self.mongo_client.drop_database()
            self.mongo_client.close()

    def MakeUniqueName(self, basename='testdb'):
        """Constructs a unique name using an heuristic which guarantees uniqueness.

        Args:
            basename: Prefix of the name (str)

        Returns:
            A unique Name based on basename provided (str)
        """
        now = datetime.datetime.now()
        timestamp = now.strftime('%y%m%d%H%M%S')
        hostname = socket.gethostname()
        tokens = hostname.split('.', 1)
        hostname = tokens[0]
        pid = os.getpid()
        serial = 1
        return '%(basename)s_%(timestamp)s_%(hostname)s_%(pid)d_%(serial)d' % locals()


if __name__ == '__main__':

    s = DataScienceUtil()
    s.config_data_science_db()
    #p.mongo_client_teardown()
    #p = MongoDBClientMixins(db_name=db_name)

    #p.get_alerts(collection_name='watchlists', sort_field='model_name')
    #a = list(p.db['watchlists'].find())
    #for key in a[0].iterkeys():
    #    print key
    #p.cleanup_mongo()
    #p.PrettyDumpJson(p.get_alerts(moduleId='test_global_uri_module_set'), 'consumed_mongo.json')
    #print 'Total alerts received:', p.get_alert_count()
    #p.close()
