#!/usr/bin/env python

# python/ctf/esa/test/postgres_db_test_util.py

"""Alert DB administration tools."""

import datetime
import os
import pipes
import psycopg2 as pg

from psycopg2.extensions import adapt
import re
import subprocess
import socket
import time

from ctf.framework.logger import LOGGER
LOGGER.setLevel('DEBUG')

# PostgresSQL Server listen Port
SERVER_PORT = 5432

ADMIN_USER = 'enrichment'

# List of tables in the AlertDb.
_TABLE_LIST = ['ORGCHART']

# SQL for creating the schema (tables, etc.)
_SQL_CREATE_SCHEMA = """
CREATE TABLE ORGCHART (
    id TEXT,
    name TEXT,
    department TEXT,
    location TEXT,
    extension TEXT,
    supervisor TEXT,
    reports TEXT
);
"""

# Used by AlertDb.CreateUser to create a user and grant necessary permissions.
_SQL_CREATE_USER = """
CREATE USER %(user)s;
GRANT ALL ON %(tables)s TO %(user)s;
"""
#CREATE USER %(user)s WITH PASSWORD %(password)s;

class Error(Exception):
    """Base class for exceptions raised by this module."""
    pass


class ConfError(Error):
    """Configuration error raised by this module."""
    pass


class ShellError(Error):
    """Raised when shell command fails."""
    pass


class PostgresDB(object):
    """Administrative interface to the Alert DB.

    Properties:
        conf: Universal conf object
    """

    @property
    def dbname(self):
        return self.__dbname

    @property
    def serverport(self):
        return self.__serverport

    def __init__(self, dbdir):
        """Initializes an PostgresDB object.

        Args:
            conf: Universal conf object
        """
        self.dbdir = dbdir
        self.__dbname = self._MakeDbName()
        self.__serverport = SERVER_PORT
        self.Install()

    def Install(self):
        """Script which performs install of AlertDb, including a new PostgreSQL server."""
        self.Init()
        self.Start()
        self.Status()
        time.sleep(5)
        self.CreateUser()

        # Loop while retrying CreateDb, since there is a race with the server starting.
        num_tries = 0
        max_tries = 30
        while num_tries < max_tries:
            try:
                self.CreateDb()
                break
            except Exception, exc:
                LOGGER.debug_exception(exc)
                num_tries += 1
                LOGGER.warn('Retrying CreateDb after %d tries', num_tries)
                time.sleep(1)

        self.CreateSchema()
        self.Verify()

    def PgVersion(self):
        """Prints the PostgreSQL version information.

        Returns:
            (major, minor, subminor) as tuple of int
        """
        pg_ctl = subprocess.Popen(['pg_ctl', '--version']
                                  , stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        stdout, stderr = pg_ctl.communicate()
        if pg_ctl.returncode:
            raise ShellError('Unable to determine PostgreSQL version (%d):\n%s'
                             % (pg_ctl.returncode, stderr))
        else:
            match = re.match(r'.*PostgreSQL.*(\d+)\.(\d+)\.(\d+).*', stdout)
            if not match:
                raise ShellError('Unrecognized PostgreSQL version output: %s' % stdout)
            else:
                version = tuple([int(x) for x in match.groups()])
                print '%d.%d.%d' % version
                return version

    def Init(self):
        """Initializes a new PostgreSQL server file system repository."""
        db_dir = self._GetDbDir()
        self.ExecShell('initdb', '--pgdata', db_dir)

    def Start(self, log_path=None):
        """Launches the PostgreSQL server processes."""
        db_dir = self._GetDbDir()
        log_path = os.path.join(db_dir, 'postgresql.log')
        self.ExecShell('pg_ctl', '--pgdata', db_dir, '--log', log_path, 'start')

    def Status(self):
        """Prints status of the PostgreSQL server."""
        db_dir = self._GetDbDir()
        self.ExecShell('pg_ctl', '--pgdata', db_dir, 'status')

    def Stop(self):
        """Shuts down the PostgreSQL server processes (pending connections closed)."""
        db_dir = self._GetDbDir()
        self.ExecShell('pg_ctl', '--pgdata', db_dir, 'stop')

    def CreateDb(self):
        """Creates the PostgreSQL database that will contain the Alert DB."""
        self.ExecShell('createdb', '--port', self.serverport, '--owner', ADMIN_USER, self.dbname)

    def ListDb(self):
        """Lists the PostgreSQL databases."""
        self.ExecShell('psql', '--port', self.serverport, '--list')

    def DropDb(self):
        """Drops the database."""
        self.ExecShell('dropdb', '--port', self.serverport, self.dbname)

    def CreateSchema(self):
        """Creates a new database schema (tables, etc.) based on the connection stats."""
        sql = _SQL_CREATE_SCHEMA % locals()
        self.ExecShell('psql', '--port', self.serverport, '--command', sql, self.dbname)

    def CreateUser(self):
        """Creates the PostgreSQL user as configured in the conf."""
        user = ADMIN_USER
        #password = adapt(ADMIN_USER)
        #tables = ', '.join(_TABLE_LIST)
        #sql = _SQL_CREATE_USER % locals()
        #self.ExecShell('psql', '--port', self.serverport, '--command', sql, self.dbname)
        self.ExecShell('createuser', '--port', self.serverport
                       , '--createdb', '--superuser', '--echo', user)

    def DropUser(self):
        """Drops the PostgreSQL user."""
        self.ExecShell('dropuser', '--port', self.serverport, ADMIN_USER)

    def Verify(self):
        """Verifies that the database configuration is correct.

        Attempts to connect to the database and check the schema.
        """
        conn = self._Connect()
        conn.close()
        return

    def CreateTestDb(self):
        """Creates a new database schema in a TestDb.

        Assumes that this AlertDb is constructed with the configuration produced by TestDb.conf.
        """
        sql = _SQL_CREATE_SCHEMA % locals()
        conn = self._Connect()
        try:
            conn.set_isolation_level(pg.extensions.ISOLATION_LEVEL_AUTOCOMMIT)
            cur = conn.cursor()
            try:
                LOGGER.debug('Executing SQL:\n%s', sql)
                cur.execute(sql)
            finally:
                cur.close()
        finally:
            conn.close()

    # Protected:

    def _GetDbDir(self):
        return self.dbdir

    def _MakeDbName(self, basename='testdb'):
        """Constructs a database name using an heuristic which guarantees uniqueness.

        Args:
            basename: Prefix of the database name (str)

        Returns:
            Name of a database (str)
        """
        now = datetime.datetime.now()
        timestamp = now.strftime('%y%m%d%H%M%S')
        hostname = socket.gethostname()
        tokens = hostname.split('.', 1)
        hostname = tokens[0]
        pid = os.getpid()
        serial = 1
        return '%(basename)s_%(timestamp)s_%(hostname)s_%(pid)d_%(serial)d' % locals()

    def _Connect(self):
        """Connects to the PostgreSQL database specified in the conf.

        Returns:
            pg.connection object

        Raises:
            pg.Error if unable to connect
        """
        kwargs = dict(database=self.dbname, host='localhost'
                      , port=self.serverport, user=ADMIN_USER)
        kwargs['password'] = ADMIN_USER

        LOGGER.debug('Connecting to PostgreSQL: %s', kwargs)
        conn = pg.connect(**kwargs)
        return conn

    def ExecShell(self, *args, **kwargs):
        """Executes a shell subprocess.

        Args:
            args: Command-line, as individual arguments (list of str)
            kwargs:
                quote_args: If True (which is the default), args will be escaped (with pipes.quote); if
                        False, then caller must ensure that args survive the shell.

        Raises:
            ShellError if exit code is nonzero
        """
        quote_args = kwargs.get('quote_args', True)
        if quote_args:
            transform = pipes.quote
        else:
            transform = lambda x: x
        cmd = ' '.join([transform(str(x)) for x in args])
        LOGGER.debug('ExecShell: %s', cmd)
        popen = subprocess.Popen(cmd, shell=True, close_fds=True)
        popen.wait()
        if popen.returncode:
            raise ShellError('Shell command failed (%d): %s' % (popen.returncode, cmd))


"""
if __name__ == '__main__':
    p = PostgresDB(dbdir='/usr/local/var/postgres1')
    p.PgVersion()
    sql = []
    sql.append("INSERT INTO ORGCHART values ('Bill', 'Sales')")
    sql.append("INSERT INTO ORGCHART values ('Fred', 'Marketing')")
    sql.append('SELECT * FROM ORGCHART')
    for i in sql:
        p.ExecShell('psql', '--port', p.serverport, '--command', i, p.dbname)
    p.ListDb()
    p.DropDb()
    p.ListDb()
"""