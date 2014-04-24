#!/usr/bin/python

# This script run on localhost and does the following:
#     - drops leaked keyspaces older than 24 hours.
#     - deletes empty keyspaces directories from Cassandra's data directory.

import re
import subprocess
import time

from cassandra.cluster import Cluster
from optparse import OptionParser

OPTS = OptionParser(usage='%%prog [options]\n\n%s' % __doc__)

OPTS.add_option('-k', '--keyspace', dest='delete_keyspaces'
                , default=False, action='store_true'
                , help='Delete keyspaces older than 24 hours [%default]')
OPTS.add_option('-d', '--directory', dest='delete_emptydirs'
                , default=False, action='store_true'
                , help='Delete empty directories older than 24 hours [%default]')
OPTS.add_option('-m', '--machines', dest='machines'
                , default='127.0.0.1'
                , help='comma seperated list of machines')

(options, args) = OPTS.parse_args()

# list of machines to cleanup
machines_list = [str(x) for x in options.machines.split(',')]

if ((len(options.machines)) & (options.delete_keyspaces == True)):
    print 'Deleting of keyspaces on remote machine is not supported.'
    print 'Only keyspaces on 127.0.0.1 can be deleted.'

C8_DATA_DIR = '/var/lib/cassandra/data/'

class CassandraCleanup(object):

    def __init__(self, host, cassandra_dir=C8_DATA_DIR):
        self.host = host
        self.cassandra_dir = cassandra_dir
        self.cluster = None
        self.session = None

    def CassandraSetup(self):
        self.cluster = Cluster([self.host])
        self.session = self.cluster.connect()

    def ExecuteShell(self, cmd):
        """ Execute a bash command on localhost or remote machine using ssh."""

        COMMAND = ['ssh', '-t', '-Ap 2772', '-oStrictHostKeyChecking=no'
                   , self.host, 'sudo' , cmd]

        print ('==== Running: %s' % COMMAND)
        popen = subprocess.Popen(COMMAND
                                 , stdout=subprocess.PIPE
                                 , stderr=subprocess.STDOUT
                                 , close_fds=True)
        lines = popen.stdout.readlines()
        for line in lines:
            print line.rstrip()
        popen.wait()

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

    def _DropKeyspaceIfExists(self, keyspace=None):
        """Drops silvertail prefixed keyspace if it exists"""

        if keyspace in self.Keyspaces():
            print ('==== Dropping keyspace %s' % keyspace)
            self.session.execute("""DROP KEYSPACE %s""" % keyspace)

    def DropLeakedKeyspaces(self, basename='testcqldb'):
        """Drops keyspaces starting with testcqldb basename and older than 24 hours"""

        p = re.compile(r'^' + basename + r'_(\d+)_*')
        now = int(time.time())
        for keyspace in self.Keyspaces(p):
            timestamp = int(p.match(keyspace).group(1))
            # for keyspaces older than 24 hours
            if (now - timestamp > 24 * 60 * 60):
                print('==== Drop old leaked keyspace ' + keyspace)
                self._DropKeyspaceIfExists(keyspace)


if __name__ == '__main__':

    for slave in machines_list:

        slaveSession = CassandraCleanup(slave)
        if (options.delete_keyspaces == True):

            slaveSession.CassandraSetup()
            print ('==== Dropping leaked keyspaces older than 24 hours on %s machine.' % slave)
            slaveSession.DropLeakedKeyspaces()

            print '==== Running nodetool for repair if necessary'
            slaveSession.ExecuteShell('nodetool repair')

            slaveSession.session.shutdown()
            slaveSession.cluster.shutdown()

        if (options.delete_emptydirs == True):

            print ('==== Deleting all empty directories under %s on %s machine...'
                   % (slaveSession.cassandra_dir, slaveSession.host))
            slaveSession.ExecuteShell('find %s -type d -mtime +1 -empty -print -delete'
                                      % slaveSession.cassandra_dir)
