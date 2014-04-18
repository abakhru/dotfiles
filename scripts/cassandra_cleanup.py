#!/usr/bin/python
# This script run on localhost and does the following:
#     - drops leaked keyspaces older than 1 week.
#     - deletes empty keyspaces directories from Cassandra's data directory
# Run as root/sudo.

import os
import sys
import cassandra
import commands

from cassandra.cluster import Cluster

# list of machines to cleanup
slave_list = ['localhost',]

C8_DATA_DIR = '/var/lib/cassandra/data'

class CassandraCleanup(object):
    
    def __init__(self, host=None, dir=C8_DATA_DIR)
        self.host = host
        self.cassandra_dir = dir
        self.cluster = Cluster([self.host])
        self.session = cluster.connect()

    def ExecuteShell(self, cmd):
        """ Execute a bash command."""
        print ('Running: %s' % cmd)
        output = commands.getoutput(cmd)
        print output
        return output
    
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
    
    def RemoveEmptyFolders(self, path):
        """Drops keyspaces starting with basename and older than 1 week"""
    
        if not os.path.isdir(path):
            print 'Path provided is not a directory'
            return
    
        # remove empty subfolders
        files = os.listdir(path)
        if len(files):
            for f in files:
                fullpath = os.path.join(path, f)
                if os.path.isdir(fullpath):
                    RemoveEmptyFolders(fullpath)
    
        # if folder empty, delete it
        files = os.listdir(path)
        if len(files) == 0:
            print "Removing empty folder:", path
            os.rmdir(path)
    
    def _DropKeyspaceIfExists(self, keyspace=None):
        """Drops silvertail prefixed keyspace if it exists"""
    
        if keyspace in self.Keyspaces():
        try:
            print ('Dropping keyspace %s' % keyspace)
            self.session.execute("""DROP KEYSPACE %s""" % keyspace)
        except e:
            # this extra check is to handle a possible race condition between
            # the check if exists and the drop operation
            if keyspace in self.Keyspaces():
                raise e
    
    def DropLeakedKeyspaces(self, basename='testcqldb'):
        """Drops keyspaces starting with testcqldb basename and older than 24 hours"""
    
        try:
            p = re.compile(r'^' + basename + r'_(\d+)_.*$')
            now = int(time.time())
            for keyspace in self.Keyspaces(p):
                timestamp = int(p.match(keyspace).group(1))
                # for keyspaces older than 24 hours
                if (now - timestamp > 24 * 60 * 60):
                # for keyspaces older than 1 week
                #if (now - timestamp > 168 * 60 * 60):
                    print('Drop old leaked keyspace ' + keyspace)
                    self._DropKeyspaceIfExists(keyspace)
        except Exception:
            pass


if __name__ == '__main__':

    for slave in range(len(slaves):
    
        slaveSession = CassandraCleanup(slave)
        print 'Dropping leaked keyspaces older than 1 week'
        slaveSession.DropLeakedKeyspaces():
    
        slaveSession.session.shutdown()
        slaveSession.cluster.shutdown()
    
        print ('Deleting all empty directories under %s...' % slaveSession.cassandra_dir)
        slaveSession.ExecuteShell('ssh %s \"sudo find %s -type d -empty -delete\"' 
                                  % (slaveSession.host, slaveSession.cassandra_dir))
    
        print 'Running nodetool for repair if necessary'
        slaveSession.ExecuteShell('ssh %s \"sudo nodetool repair\"' % slaveSession.host)
