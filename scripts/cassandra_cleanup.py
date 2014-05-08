#!/usr/bin/env python

# Examples:./cassandra_cleanup.py -k -d
#           (uses all default values, and deletes all keyspaces and orphaned dirs)
#          ./cassandra_cleanup.py -k -d -t 60 -b stqa
#           (and deletes all keyspaces and orphaned dirs, that starts with stqa, older than 60 mins)

import optparse
import os
import re
import subprocess
import sys
import time

from cassandra.cluster import Cluster

DESC = """This script run on localhost and does the following:
Drops leaked keyspaces older than time provided in minutes,
Deletes orphaned keyspace directories from Cassandra's data directory."""

class CassandraCleanup(object):

    def __init__(self, cassandra_dir='/var/lib/cassandra/data'):

        self.options = None
        self.args = None
        self._ParseOpts()
        self.cassandra_dir = cassandra_dir
        self.machines_list = self._CreateMachineList()
        self.host = self.machines_list[0]
        self.cluster = Cluster([self.host])
        self.session = self.cluster.connect()

    def _CreateMachineList(self):
        """Returns list of machines to cleanup."""
        return [str(x) for x in self.options.machines.split(',')]

    def ExecuteShell(self, cmd):
        """ Execute a bash command on localhost or remote machine using ssh."""

        if self.host != '127.0.0.1':
            REMOTE_COMMAND = ['ssh', '-t', '-Ap 2772', '-oStrictHostKeyChecking=no'
                       , self.host, 'sudo' , cmd]

            print '==== Running: ' + ' '.join(REMOTE_COMMAND)
            ssh_proc = subprocess.Popen(REMOTE_COMMAND
                                 , stdout=subprocess.PIPE
                                 , stderr=subprocess.STDOUT
                                 , close_fds=True)
            lines = ssh_proc.stdout.readlines()
            for line in lines:
                print line.rstrip()
            ssh_proc.wait()
            return lines
        else:
            COMMAND = 'sudo ' + cmd
            return os.system("%s" % COMMAND)

    def _ListSubDirs(self, path, olderThanMins, basename):
        """ Returns a list of subdirectories older than time provided."""

        olderThanMins *= 60 # convert minutes to seconds
        current = int(time.time()) # current time
        try:
            subdirs = [ d for d in os.listdir(path) if os.path.isdir(os.path.join(path, d))
                                                       & d.startswith(basename)]
            olderdirs = [ d for d in subdirs 
                          if (current - os.path.getmtime(os.path.join(path, d))) > olderThanMins]
        except Exception: # Ignore any errors
            print Exception()

        return olderdirs

    def Keyspaces(self, pattern=None):
        """Returns a list of the available keyspaces matching a pattern.
        If pattern is none returns all keyspaces.
        """

        try:
            rows = self.session.execute("""SELECT keyspace_name FROM system.schema_keyspaces""")
        except Exception:
            print Exception()

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
                print Exception()

    def DropLeakedKeyspaces(self):
        """Drops keyspaces starting with basename provided and older than minutes provided"""

        if ((len(self.machines_list) > 1) & (self.options.delete_keyspaces == True)):
            print 'Deleting of keyspaces on remote machine is not supported.'
            print 'Deleting only on 127.0.0.1.'

        if self.session == None:
            self.cluster = Cluster([self.host])
            self.session = self.cluster.connect()

        print ('==== Dropping leaked keyspaces older than %s mins on %s machine.'
               % (self.options.minutes, self.host))

        p = re.compile(r'^' + self.options.basename + r'_(\d+)_*')
        now = int(time.time())
        for keyspace in self.Keyspaces(p):
            timestamp = int(p.match(keyspace).group(1))
            # for keyspaces older than minutes provided
            if (now - timestamp > int(self.options.minutes) * 60):
                self._DropKeyspaceIfExists(keyspace)

        if self.options.delete_orphandirs == False:
            self.session.shutdown()
            self.cluster.shutdown()

        print '==== Running nodetool flush'
        self.ExecuteShell('nodetool flush')

        print '==== Running nodetool repair'
        self.ExecuteShell('nodetool repair')

        return True

    def DeleteOrphanDirs(self):
        """ Deletes orphaned keyspace directories.

        Orphan directories: Directories not deleted by Cassandra after dropping associated keyspace.
        """

        for machine in self.machines_list:
            self.host = machine
            if self.session == None:
                self.cluster = Cluster([self.host])
                self.session = self.cluster.connect()

            print ('==== Deleting all orphaned directories under %s on %s'
                   ' machine, older than %s minutes...'
                   % (self.cassandra_dir, self.host, self.options.minutes))

            existingKeyspaces = self.Keyspaces()
            olderDirs = self._ListSubDirs(self.cassandra_dir, int(self.options.minutes)
                                          , self.options.basename)

            dirsToDelete = [ d for d in olderDirs if d not in existingKeyspaces]

            for olddir in dirsToDelete:
                d = os.path.join(self.cassandra_dir, olddir)
                print 'Deleting ', d
                self.ExecuteShell('rm -rf %s' % d)

            if self.session != None:
                self.session.shutdown()
                self.cluster.shutdown()

        return True

    def _ParseOpts(self):
        """ Parses all the commandline options provided and returns the options."""

        parser = optparse.OptionParser(description=DESC, usage='%%prog [options]\n\n%s' % __doc__)
        parser.add_option('-?', action='help', help=optparse.SUPPRESS_HELP)
        parser.add_option('-b', '--basename', dest='basename'
                        , default='testcqldb'
                        , help='Basename of keyspaces to delete.[%default] ')
        parser.add_option('-d', '--directory', dest='delete_orphandirs'
                        , default=False, action='store_true'
                        , help='Delete empty directories. [%default]')
        parser.add_option('-k', '--keyspace', dest='delete_keyspaces'
                        , default=False, action='store_true'
                        , help='Delete keyspaces.[%default].'
                        + 'Only keyspaces on 127.0.0.1 can be deleted.')
        parser.add_option('-m', '--machines', dest='machines'
                        , default='127.0.0.1'
                        , help='Comma seperated list of machines')
        parser.add_option('-t', '--time', dest='minutes'
                        , default='1440'
                        , help='Time in minutes.[%default] ')

        (self.options, self.args) = parser.parse_args()

        if len(sys.argv[1:]) == 0:
            parser.print_help()


if __name__ == '__main__':

    s = CassandraCleanup()
    if s.options.delete_keyspaces == True:
        s.DropLeakedKeyspaces()
    if s.options.delete_orphandirs == True:
        s.DeleteOrphanDirs()
