#!/usr/bin/env python

import datetime
import os
import pymongo
import socket
import subprocess
import time
import sys
from pprint import pprint

from bson import BSON
from bson import json_util
from framework.common.logger import LOGGER
LOGGER.setLevel('DEBUG')



class MongoDBClientMixins(object):
    """ MongoDBClient utilities that allow extracting alerts from mongo using pymongo."""

    def __init__(self, host='localhost', port=27017,
                 db_name='esa', db_user='esa', db_pass='esa', source='esa'):
        LOGGER.debug('Connecting to MongoDb...')

        try:
            self.conn = pymongo.MongoClient(host, port)
            LOGGER.debug('Connected to MongoDB successfully!!!')
        except pymongo.errors.ConnectionFailure as e:
            LOGGER.error('Could not connect to MongoDB: %s', str(e))
            exit(0)

        if self.conn is not None:
            self.db = self.conn[db_name]
            # if not self.db.authenticate(db_user, db_pass, source=source):
            #     LOGGER.error('Unable to authenticate to MongoDB')
            #     return

            LOGGER.debug('Authenticated to MongoDb')

    def PrettyDumpMongo(self, doc_list, outfile):
        """ Pretty print and write Mongo output to a file using the bson/json tools."""

        with open(outfile, 'wb') as _file:
            json_formatted_doc = json_util.dumps(doc_list, sort_keys=False, indent=4
                                                 , default=json_util.default)
            LOGGER.debug('[MongoDB] Generated Alert notification in JSON form:\n%s'
                         , json_formatted_doc)
            _file.write(bytes(json_formatted_doc, 'UTF-8'))
            return

    def InsertIntoCollectionFromJSON(self, json_array, collection_name='alert', *args, **kwargs):
        """Inserts JSON elements into collection

        Args:
            json_array: array of json objects to insert(json)
            collection: collection to insert into (str)

        Returns:
            list of _id values corresponding to document(s) inserted
        """
        log_msg = ('Inserting %d items in collection %s' % (len(json_array), collection_name))
        LOGGER.debug(log_msg)
        id_list = self.db[collection_name].insert(json_array, *args, **kwargs)
        LOGGER.debug('Got %d ids as a result', len(id_list))
        return id_list

    def get_alerts(self, collection_name='alert', expectedNumAlerts=1, moduleId=None
                   , sort_field='events.esa_time', timeout=60):
        """Extract alerts from mongodb based on moduleId.

        Args:
            collection_name: name of the mongodb collection.
            expectedNumAlerts: expected number of alerts.
            moduleId: list of unique module ids of deployed epl rules.
            sort_field: generated alerts will be sorted on this field.
            timeout: The amount of time to wait for all the alerts to be returned (seconds)

        Returns:
            List of alerts_list for each moduleId provided.
        """

        alerts_list = []
        endtime = time.time() + timeout
        query = {}
        if moduleId:
            query = {'module_id': {'$in': moduleId}}
        while len(alerts_list) < expectedNumAlerts and time.time() < endtime:
            try:
                alerts_list = list(self.db[collection_name].find(query).sort(sort_field, 1))
            except pymongo.errors.OperationFailure as e:
                LOGGER.error('[MongoDB] Unable to extract alerts')
                LOGGER.error(e)
            wake_time = time.time() + 1
            while wake_time > time.time():
                pass
        LOGGER.debug('[MongoDB] Found {0} alerts.'.format(len(alerts_list)))
        if len(alerts_list) < expectedNumAlerts:
            LOGGER.error('[MongoDB] Timeout reached when trying to retrieve alerts.')
        return alerts_list

    def get_alerts_count(self, collection_name='alert', expectedNumAlerts=1
                         , moduleId=None, timeout=60):
        """Extract alerts count from mongodb based on moduleId.

        Args:
            collection_name: name of the mongodb collection. (default=alert)
            expectedNumAlerts: expected number of alerts.
            moduleId: list of unique module ids of deployed epl rules.
            timeout: The amount of time to wait for all the alerts to be returned (seconds)

        Returns:
            Total Count of alerts for each moduleId provided.
        """

        return len(self.get_alerts(collection_name=collection_name
                                   , expectedNumAlerts=expectedNumAlerts, moduleId=moduleId
                                   , timeout=timeout))

    def cleanup_mongo(self, collection_name='alert', id_list=None, **kwargs):
        """Removes all documents or specified documents by id from the provided collection_name.

        Note:
            If the record does not exist/wrong document specified removal mongo will still return
        err: None

        Args:
            collection: collection from where the documents are to be removed (str)
            id_list: list of document ids [{"_id": "<id>"}])to remove (dict)

        Returns:
            whether or not removal of all items was successful (bool)
        """
        status_list = []
        return_status = True
        if id_list:
            for json_item in id_list:
                try:
                    status = self.db[collection_name].remove(json_item, **kwargs)
                    status_list.append(status)
                except Exception as e:
                    err_msg = ('[MongoDB] Cleanup Failed. status %s' % status_list[-1])
                    LOGGER.error(err_msg)
                    LOGGER.error(e)
                    return_status = False
                # format: {u'connectionId': 333, u'ok': 1.0, u'err': None, u'n': 1}
                if status['err'] is not None:
                    return_status = False
        else:
            LOGGER.debug('[MongoDB] Cleaning all documents in \'%s\' collection.', collection_name)
            try:
                status = self.db[collection_name].remove({})
                status_list.append(status)
            except pymongo.errors.OperationFailure as e:
                LOGGER.error('[MongoDB] Cleanup Failed.')
                LOGGER.error(e)
                return_status = False

        log_msg = ('Removal result: %s' % status_list)
        LOGGER.debug(log_msg)
        return return_status

    def close(self):
        try:
            self.conn.close()
        except pymongo.errors.ConnectionFailure as e:
            LOGGER.error(e)


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
        mongo_cmd = 'mongo'
        p = subprocess.Popen('which %s' % (mongo_cmd, ), stdout=subprocess.PIPE
                             , stderr=subprocess.PIPE, shell=True)
        mongo_path = p.communicate()[0].strip()
        if not mongo_path:
            mongo_path = '/usr/bin/mongo'  # Linux path
            if sys.platform.lower() == 'darwin':  # On a mac
                mongo_path = '/usr/local/bin/mongo'

        # Mongo never needs sudo from Mac, and only when not root on Linux
        if ((sys.platform.lower() != 'darwin') and (os.getuid() != 0)):
            mongo_cmd = 'sudo ' + mongo_path
        mongo_cmd = mongo_path

        cmd = (mongo_cmd + ' admin -u admin -p netwitness --eval \"db.getSiblingDB(\''
               + db_name + '\').createUser({user: \'' + db_user + '\', pwd: \''
               + db_pass + '\', roles: [\'readWrite\', \'dbAdmin\']})\"')
        LOGGER.debug('Launching command:\n%s', cmd)
        p = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True)
        status = p.communicate()[0].strip()
        LOGGER.debug('Output: %s', status)
        a = status.split('\n')
        LOGGER.debug('==== Status in list form:\n%s', a)
        #self.assertIn('Successfully', a)
        return

    def config_data_science_db(self):
        """Sets up DataScience db in mongo with required permissions and sample data."""

        # creating unique DataScience db name
        database_name = self.MakeUniqueName(basename='ds')
        # creates the ds db if not already present
        self.__mongo_client = MongoDBClientMixins(db_name=database_name)
        self.mongo_client.cleanup_mongo(collection_name='watchlists')
        collection = self.mongo_client.db.watchlists
        collection.insert({"_id": "EXEC_BATCH_rsa", "model_id": "suspiciousDomains_1",
                           "key": "rsa.com", "score": 4, "model_name": " Suspicious Domains",
                           "group_name": "domain"})
        output = list(self.mongo_client.db['watchlists'].find())
        json_output = json_util.dumps(output, sort_keys=False, indent=4, default=json_util.default)
        LOGGER.debug('Inserted data in \'%s\' database:\n%s', database_name, json_output)
        #self.assertIn('model_id', json_output)
        # assigns read/write access to esa user for new database.
        self._enable_db_access(db_name=database_name)
        os.system('mongo %s -u esa -p esa' % database_name)
        return

    def mongo_client_teardown(self):
        if self.mongo_client is not None:
            # cleans up any existing document in watchlist collection inside ds db
            self.mongo_client.cleanup_mongo(collection_name='watchlists')
            if sys.platform.lower() == 'darwin':
                self.mongo_client.drop_database()
            else:
                os.system('mongo ' + self.database_name + ' --eval "db.dropDatabase();" --verbose')
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

    #s = DataScienceUtil()
    s = MongoDBClientMixins(host='10.40.13.142', db_name='im', db_user='im', db_pass='im', source='im')
    #s.config_data_science_db()
    #p.mongo_client_teardown()
    #p = MongoDBClientMixins(db_name=db_name)

    print(s.get_alerts(collection_name='aggregation_rule'))#, sort_field='model_name')
    #a = list(p.db['watchlists'].find())
    #for key in a[0].iterkeys():
    #    print key
    #s.cleanup_mongo()
    #p.PrettyDumpJson(p.get_alerts(moduleId='test_global_uri_module_set'), 'consumed_mongo.json')
    #print 'Total alerts received:', p.get_alert_count()
    #p.close()
    # moduleId=['esa.types.system', 'esa.types.source', 'esa.types.enrichment'
    #                        , 'd28ecf2d-81da-4980-b1e8-fd30f867d93a'
    #                        , 'f66c111d-69cd-4354-99ec-023b2cac2f58'
    #                        , 'deed0a24-a5d6-412e-bd7a-efa71e8df886']
    #s.get_alerts_count(moduleId=moduleId, expectedNumAlerts=6)
    # a = s.get_alerts(moduleId=moduleId, expectedNumAlerts=6)
    #pprint(a)
    s.close()
