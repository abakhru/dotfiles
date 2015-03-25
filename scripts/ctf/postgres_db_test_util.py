#!/usr/bin/env python

# python/ctf/esa/test/postgres_db_test_util.py

"""PostgresSQL Server DB administration tools."""

import os
import pipes
import psycopg2 as pg

import re
import subprocess
import time

from ctf.framework.logger import LOGGER

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
        dbname: name of the database to be used for test
        serverport: postgres server port number
    """

    @property
    def dbname(self):
        return self.__dbname

    @property
    def serverport(self):
        return self.__serverport

    def __init__(self, db_dir, db_name):
        """Initializes an PostgresDB object.

        Args:
            dbdir: postgres db directory
        """
        self.bindir = ''
        p = subprocess.Popen('which psql', stdout=subprocess.PIPE
                             , stderr=subprocess.PIPE, shell=True)
        binary_dir = p.communicate()[0].strip()
        if not binary_dir:
            self.bindir = '/usr/local/bin'  # Linux path
            if sys.platform == 'darwin':  # On a mac
                self.bindir = '/usr/local/bin/'
        else:
            self.bindir = binary_dir[: binary_dir.index('psql')]

        self.VerifyBinaryExists()
        self.dbdir = db_dir
        self.__dbname = db_name
        self.__serverport = SERVER_PORT
        self.Install()

    def VerifyBinaryExists(self):
        if (os.path.exists(os.path.join(self.bindir, 'pg_ctl')) and
            os.path.exists(os.path.join(self.bindir, 'initdb')) and
            os.path.exists(os.path.join(self.bindir, 'createdb')) and
            os.path.exists(os.path.join(self.bindir, 'dropdb')) and
            os.path.exists(os.path.join(self.bindir, 'createuser')) and
            os.path.exists(os.path.join(self.bindir, 'dropuser'))):
            return True
        else:
            return False

    def Install(self):
        """Script which performs install of AlertDb, including a new PostgreSQL server."""
        if not os.path.isdir(self.dbdir):
            os.makedirs(self.dbdir)
            self.Init()

        if not self.Status():
            LOGGER.debug('PostgreSQL server is not running, starting it.')
            self.Start()

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
                LOGGER.debug(exc)
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
        pg_ctl = subprocess.Popen([self.bindir + 'pg_ctl', '--version']
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

    def Status(self):
        """ Checks the postgres SQL server running status"""
        cmd = self.bindir + 'pg_ctl -D ' + self.dbdir + ' status | head -1'
        p = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True)
        status = p.communicate()[0].strip()
        LOGGER.debug('posrgres status: %s', status)
        if 'PID' in status:
            LOGGER.debug('PostgreSQL server is already running')
            return True
        return False

    def Init(self):
        """Initializes a new PostgreSQL server file system repository."""
        self.ExecShell(self.bindir + 'initdb', '--pgdata', self.dbdir)

    def Start(self, log_path=None):
        """Launches the PostgreSQL server processes."""
        if log_path is None:
            log_path = os.path.join(self.dbdir, 'postgresql.log')
        self.ExecShell(self.bindir + 'pg_ctl', '--pgdata', self.dbdir, '--log', log_path, 'start')

    def Stop(self):
        """Shuts down the PostgreSQL server processes (pending connections closed)."""
        self.ExecShell(self.bindir + 'pg_ctl', '--pgdata', self.dbdir, 'stop')

    def CreateDb(self):
        """Creates the PostgreSQL database that will contain the Alert DB."""
        self.ExecShell(self.bindir + 'createdb', '--port', self.serverport, '--owner', ADMIN_USER, self.dbname)

    def ListDb(self):
        """Lists the PostgreSQL databases."""
        self.ExecShell(self.bindir + 'psql', '--port', self.serverport, '--list')

    def DropDb(self):
        """Drops the database."""
        self.ExecShell(self.bindir + 'dropdb', '--port', self.serverport, self.dbname)

    def CreateSchema(self):
        """Creates a new database schema (tables, etc.) based on the connection stats."""
        sql = _SQL_CREATE_SCHEMA % locals()
        self.ExecShell(self.bindir + 'psql', '--port', self.serverport, '--command', sql, self.dbname)

    def CreateUser(self):
        """Creates the PostgreSQL user as configured in the conf."""
        user = ADMIN_USER
        self.ExecShell(self.bindir + 'createuser', '--port', self.serverport
                       , '--createdb', '--superuser', '--echo', user)

    def DropUser(self):
        """Drops the PostgreSQL user."""
        self.ExecShell(self.bindir + 'dropuser', '--port', self.serverport, ADMIN_USER)

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
                quote_args: If True (which is the default), args will be escaped (with pipes.quote);
                            If False, then caller must ensure that args survive the shell.

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

if __name__ == '__main__':
    p = PostgresDB(dbdir='/usr/local/var/postgres')
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
