#!/usr/bin/env python

import os
import re
import subprocess
import time

from cassandra.cluster import Cluster
from optparse import OptionParser

DESC = """This script run on localhost and does the following:
drops leaked keyspaces older than 24 hours,
deletes empty keyspaces directories from Cassandra's data directory."""

class CassandraCleanup(object):

    def __init__(self, cassandra_dir='/var/lib/cassandra/data'):

        self.options = self._ParseOpts()
        self.cassandra_dir = cassandra_dir
        self.cluster = None
        self.session = None
        self.machines_list = self._CreateMachineList()
        self.host = None
        self.cluster = Cluster([self.host])
        self.session = self.cluster.connect()

    def _CreateMachineList(self):
        """Returns list of machines to cleanup."""
        return [str(x) for x in self.options.machines.split(',')]

    def ExecuteShell(self, cmd):
        """ Execute a bash command on localhost or remote machine using ssh."""

        #COMMAND = ['ssh', '-t', '-Ap 2772', '-oStrictHostKeyChecking=no'
        #           , self.host, 'sudo' , cmd]
        if self.host != '127.0.0.1':
            COMMAND = ['ssh', '-t', '-Ap 2772', '-oStrictHostKeyChecking=no'
                       , self.host, 'sudo' , cmd]
        else:
            COMMAND = ['sudo' , cmd]

        print '==== Running: ' + ' '.join(COMMAND)
        ssh = subprocess.Popen(COMMAND
                                 , stdout=subprocess.PIPE
                                 , stderr=subprocess.PIPE
                                 , shell=False
                                 , close_fds=True)
        lines = ssh.stdout.readlines()
        for line in lines:
            print line.rstrip()
        ssh.wait()
        
        return lines[0].rstrip()

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
            try:
                print ('==== Dropping keyspace %s' % keyspace)
                self.session.execute("""DROP KEYSPACE %s""" % keyspace)
                return True
            except Exception:
                #print exception()
                pass

    def DropLeakedKeyspaces(self):
        """Drops keyspaces starting with testcqldb basename and older than 24 hours"""
        if ((len(self.machines_list) > 1) & (self.options.delete_keyspaces == True)):
            print 'Deleting of keyspaces on remote machine is not supported.'
            print 'Deleting only on 127.0.0.1.'
        
        self.host = self.machines_list[0]
        print ('==== Dropping leaked keyspaces older than %s mins on %s machine.'
               % (self.options.minutes, self.host))
        
        p = re.compile(r'^' + self.options.basename + r'_(\d+)_*')
        now = int(time.time())
        for keyspace in self.Keyspaces(p):
            timestamp = int(p.match(keyspace).group(1))
            # for keyspaces older than 24 hours
            if (now - timestamp > int(self.options.minutes) * 60):
                if(self._DropKeyspaceIfExists(keyspace)):
                    self.ExecuteShell('rm -rf %s' % (os.path.join(self.cassandra_dir, keyspace)))
        
        self.session.shutdown()
        self.cluster.shutdown()

        print '==== Running nodetool for repair if necessary'
        self.ExecuteShell('nodetool flush')

        print '==== Running nodetool for repair if necessary'
        self.ExecuteShell('nodetool repair')

    def _ParseOpts(self):
        """ Parses all the commandline options provided and returns the options."""
        OPTS = OptionParser(description=DESC, usage='%%prog [options]\n\n%s' % __doc__)
        OPTS.add_option('-b', '--basename', dest='basename'
                        , default='testcqldb'
                        , help='Basename of keyspaces to delete.[%default] ')
        OPTS.add_option('-d', '--directory', dest='delete_emptydirs'
                        , default=False, action='store_true'
                        , help='Delete empty directories. [%default]')
        OPTS.add_option('-k', '--keyspace', dest='delete_keyspaces'
                        , default=False, action='store_true'
                        , help='Delete keyspaces.[%default].'
                        + 'Only keyspaces on 127.0.0.1 can be deleted.')
        OPTS.add_option('-m', '--machines', dest='machines'
                        , default='127.0.0.1'
                        , help='Comma seperated list of machines')
        OPTS.add_option('-t', '--time', dest='minutes'
                        , default='1440'
                        , help='Time in minutes.[%default] ')
        
        (options, args) = OPTS.parse_args()
        return options

    def DeleteEmptyDirs(self):
        for machine in self.machines_list:
            self.host = machine
            print ('==== Deleting all empty directories under %s on %s'
                   ' machine, older than %s minutes...'
                   % (self.cassandra_dir, self.host, self.options.minutes))
            #self.ExecuteShell('find %s -type d -mmin +%d -empty -print -delete'
            #                          % (self.cassandra_dir, int(self.options.minutes)))
            existingKeyspaces = self.Keyspaces()
            emptyDirs = self.ExecuteShell('find %s -maxdepth 2 -type d -mmin +%d -empty |grep %s'
                                          % (self.cassandra_dir, int(self.options.minutes)
                                             , self.options.basename))

            for dir in emptyDirs:
                if dir in existingKeyspaces:
                    continue
                else:
                    self.ExecuteShell('rm -rf %s' % os.path.join(self.cassandra_dir, dir))
            
            print emptyDirs
            print existingKeyspaces

if __name__ == '__main__':

    s = CassandraCleanup()
    #if len(sys.argv[1:])==0: 
    if s.options.delete_keyspaces == True:
        s.DropLeakedKeyspaces()
    if s.options.delete_emptydirs == True:
        s.DeleteEmptyDirs()