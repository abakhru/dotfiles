#!/usr/bin/env python

import time
import cassandra

from cassandra.cluster import Cluster

class CassandraUtils(object):

    def __init__(self, option=None):
        #self.cluster = Cluster(['lab9.silvertailsystems.com'])
        self.cluster = Cluster(['127.0.0.1'])
        self.session = self.cluster.connect()
        self.option = option

    def Keyspaces(self, pattern=None):
        """Returns a list of the available keyspaces matching a pattern.
        If pattern is none returns all keyspaces. 
        """
        rows = self.session.execute("""SELECT keyspace_name FROM system.schema_keyspaces""")
        if pattern is None:
            keyspaces = [row[0] for row in rows]
        else:
            keyspaces = [row[0] for row in rows if pattern.match(row[0]) ]
        return keyspaces

    def DropKeyspaceIfExists(self, pattern='silvertail'):
        """Drops silvertail prefixed keyspace if it exists"""
        keyspaces = self.Keyspaces() 
        for keyspace in keyspaces:
            if keyspace.startswith(pattern):
                print ('==== Dropping keyspace %s' % keyspace)
                self.session.execute("""DROP KEYSPACE %s""" % keyspace)

    def MakeKeyspaceName(self, basename='silvertail'):
        """Constructs a unique keyspace name based on basename."""
        epoch_time = int(time.time())
        keyspace = '%s_%d' % (basename, epoch_time)
        return keyspace.lower()

    def CreateKeyspace(self, keyspace=None):
        """ Creates a keyspace."""

        if keyspace == None:
            keyspace = self.MakeKeyspaceName()

        print ('==== Creating new keyspace %s' % keyspace)
        result = self.session.execute("""CREATE KEYSPACE %s
                             WITH replication = {'class': 'SimpleStrategy', 'replication_factor': '1'}
                             """ % keyspace)
        print ('==== Created keyspace: %s' % keyspace)
        return keyspace

    def tearDown(self):
        self.session.shutdown()
        self.cluster.shutdown()

"""
if __name__ == '__main__':
    c = CassandraUtils()
    c.DropKeyspaceIfExists()
    c.CreateKeyspace('amit')
    c.tearDown()
"""
