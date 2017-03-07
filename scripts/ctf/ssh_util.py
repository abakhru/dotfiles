#!/usr/bin/env python

# unify/framework/utils/ssh_util.py

import datetime
import paramiko
import re
import time
import timeit

from framework.common.logger import LOGGER
from paramiko.ssh_exception import SSHException
from sshtunnel import SSHTunnelForwarder


LOGGER.setLevel('DEBUG')


class SSHConnectionException(Exception):
    """A Base Exception for All SSHConnection related Exceptions"""

    def __init__(self, message):
        super(SSHConnectionException, self).__init__('SSHConnectionException: %s' % message)


class SFTPException(Exception):
    """A Base Exception for All SFTP related Exceptions"""

    def __init__(self, message):
        super(SFTPException, self).__init__('SFTPException: %s' % message)


class SSHConnection(object):
    """Create an SSH client connection to a server and execute commands"""

    def __init__(self, host, username, password, port=22, compress=True, timeout=60):
        """Initialize the SSHConnection Object

        Args:
            host: Host name or address to connect (str)
            username: Username to authentication (str)
            password: Password for authentication (str)
            port: ssh port to connect (int)
            compress: Enable or disable compression (bool)
            timeout: timeout value in seconds for SSH connection to succeed (int)
        """

        self.host = host
        self.username = username
        self.password = password
        self.port = port
        self.ssh = None
        self.transport = None
        self.compress = compress
        self.bufsize = 65536
        self.sftp_live = False
        self.sftp = None
        self.timeout = timeout
        self.Connect()
        self._home_dir = self.Exec(command='pwd')

    def __del__(self):
        self.close()

    @property
    def home_dir(self):
        return self._home_dir

    def Connect(self):
        """Make an SSH Connection to the host

        Raises:
            SSHConnectionException
        """

        LOGGER.debug('Connecting %s@%s:%d', self.username, self.host, self.port)
        self.ssh = paramiko.SSHClient()
        self.ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        try:
            self.ssh.connect(hostname=self.host, port=self.port, username=self.username
                             , password=self.password, banner_timeout=self.timeout)
            self.transport = self.ssh.get_transport()
            self.transport.use_compression(self.compress)
            LOGGER.debug('SSH Connection Succeeded to Host: %s', self.host)
        except SSHException as e:
            self.transport = None
            LOGGER.error('SSH Connection failed to Host: %s ERROR: %s', self.host, str(e))
            raise SSHException(message='ConnectionError %s' % e)
        if self.transport is None:
            raise ChannelException(message='No Transport to Host %s' % self.host)

    def Exec(self, command, input_data=None, timeout=300):
        """Execute a command with optional input data

        Args:
            command: The command to run (str)
            input_data:  The input data (dict)
            timeout : The timeout in seconds (int)

        Returns:
            The the output (stdout and stderr combined) (str)
        """

        LOGGER.debug("Executing command: '%s'", command)
        if not self.connected():
            LOGGER.error('No connection/transport to host:%s', self.host)
            raise SSHConnectionException(message='No Transport to Host %s' % self.host)
        # Initialize the session.
        session = self.transport.open_session()
        session.set_combine_stderr(True)
        session.get_pty()
        session.exec_command(command)
        output = self._run_poll(session, timeout, input_data)
        status = session.recv_exit_status()
        # LOGGER.debug('Command Execution Status %d', status)
        LOGGER.debug('Output:\n%s',output)
        return output

    def connected(self):
        """Connection Status

        Returns:
            True if connected or false otherwise (bool)
        """

        return self.transport is not None

    def _run_poll(self, session, timeout, input_data):
        """Poll until the command completes

        Args:
            session: The session (obj)
            timeout: The timeout in seconds (int)
            input_data: The input data (dict)

        Returns:
            Returns the output (str)
        """

        max_seconds = timeout
        # Poll until completion or timeout, we are not directly use the stdout file descriptor
        # because it stalls at 64K bytes (65536).
        timeout_flag = False
        start = datetime.datetime.now()
        start_secs = time.mktime(start.timetuple())
        output = ''
        session.setblocking(0)
        while True:
            if session.recv_ready():
                data = session.recv(self.bufsize)
                str_data = data.decode(encoding='UTF-8')
                # LOGGER.debug('Output Data Received %s', str_data)
                output += str_data
                if session.send_ready():
                    # We received a potential prompt. this could be made to work more like pexpect
                    # with pattern matching where key is the prompt matcher.
                    # (lazy unique key implementation as of now we can put a better pattern
                    # matcher) This is a minimal handler for blocking command executions
                    if input_data is not None:
                        for input_key, input_value in input_data.items():
                            if input_key in str_data:
                                LOGGER.debug('Sending input data %s', input_value)
                                session.send('%s\n' % input_value)
            if session.exit_status_ready():
                break
            # Timeout check
            now = datetime.datetime.now()
            now_secs = time.mktime(now.timetuple())
            et_secs = now_secs - start_secs
            if et_secs > max_seconds:
                timeout_flag = True
                break
            time.sleep(0.200)
        if session.recv_ready():
            data = session.recv(self.bufsize)
            output += data.decode(encoding='UTF-8')
        if timeout_flag:
            output += 'ERROR: Command Execution timeout after %d seconds\n' % timeout
            session.close()
        return output

    def close(self):
        if self.connected():
            self.transport.close()
            if self.sftp:
                self.sftp.close()

    # SFTP methods to transfer files between remote systems

    def _sftp_connect(self):
        """Establish the SFTP connection."""

        if not self.sftp_live:
            self.sftp = paramiko.SFTPClient.from_transport(self.transport)
            if self.sftp:
                self.sftp_live = True
            else:
                raise SFTPException('Unable to get SFTP Connection')

    def get_file(self, from_file_path, to_file_path):
        """Copy a file from Remote host to local host

        Args:
            from_file_path: Path from the file to be copied (str)
            to_file_path: Path where the file to be copied (str)
        """

        self._sftp_connect()
        LOGGER.debug('Getting File:%s From %s To:%s', from_file_path, self.host, to_file_path)
        return self.sftp.get(from_file_path, to_file_path)

    def put_file(self, from_file_path, to_file_path):
        """Copy a file from the local host to the remote host

        Args:
            from_file_path: Path from the file to be copied (str)
            to_file_path: Path where the file to be copied (str)
        """

        self._sftp_connect()
        LOGGER.debug('Copying File:%s To %s:%s', from_file_path, self.host, to_file_path)
        return self.sftp.put(from_file_path, to_file_path)

    def make_temp(self, file_content):
        """Makes a temp file

        Args:
            file_content: the content to be saved in a temp file (str)
        """

        temp_file = self.Exec('mktemp')
        self.Exec("echo '%s' > %s" % (file_content, temp_file))
        return temp_file

    def remove_file(self, f_name):
        """Deletes a remote file.

        Args:
            f_name: name fo the remote file to be deleted(str)
        """

        command = 'rm -f %s' % f_name
        self.Exec(command)

    def get_service_pid(self, service):
        """ Gets the pid of Linux service specified.

        Args:
            service: name of linux service (str)
        """

        command = 'service %s status' % service
        result = self.Exec(command)
        pid = re.findall(r'\d+', result)[0]
        return pid

    def copy_file(self, source_file, destination_file, operation='to_local', timeout=360):
        """Copy a file from the local host to the remote host.

        Args:
            source_file: source file path (str)
            destination_file: destination file path (str)
            operation: to_local/to_remote (str)
                - to_local : copy from remote to local
                - to_remote: copy from local to remote
            timeout: timeout value in seconds (int)
        """

        if operation == 'to_local':
            self.get_file(source_file, destination_file)
        elif operation == 'to_remote':
            self.put_file(source_file, destination_file)

    def assert_remote_file_exists(self, file_path):
        """Assert if a file exists on remote host

        Args:
            file_path: File path to check (str)
        """
        LOGGER.debug('Verifying if \'%s\' file exists on \'%s\'', file_path, self.host)
        output = self.Exec('test -f %s ; echo $?' % file_path).strip()
        if output is '1':
            return False
        if output == '0':
            return True


class SshTunnel(object):
    """SSH utility to create an SSH Tunnel to the specified ports from a Host"""

    def __init__(self, host, username, password, timeout=120):
        """Initializes the SSHTunnelUtil with required properties

        Args:
            host: Host from where the SSH Tunnel should be established (str)
            username: Username to authenticate to host (str)
            password: Password to authenticate to host (str)
            timeout: Timeout seconds to wait for tunneling (int)
        """

        self.host = host
        self.username = username
        self.password = password
        self.timeout = timeout
        self.tunnel = None

    def Open(self, ports):
        """Creates SSH Tunnel so that service is accessible locally.

        Args:
            ports: A list of ports to establish the tunneling (list)

        Raises:
            Exception if ports are not opened
        """

        remote_bind_address_list = []
        local_bind_address_list = []
        for port in ports:
            remote_bind_address = ('localhost', port)
            local_bind_address = ('', port)
            remote_bind_address_list.append(remote_bind_address)
            local_bind_address_list.append(local_bind_address)
        LOGGER.debug('Opening ports: %s on local host fromm remote %s', ports, self.host)
        try:
            self.tunnel = SSHTunnelForwarder(ssh_address_or_host=(self.host, 22)
                                             , ssh_username=self.username
                                             , ssh_password=self.password
                                             , local_bind_addresses=local_bind_address_list
                                             , remote_bind_addresses=remote_bind_address_list)
            self.tunnel.start()
            LOGGER.debug('Local Ports Opened: %s', self.tunnel.local_bind_ports)
        except Exception as e:
            LOGGER.error('OpenTunnelError %s', e)
            raise Exception('SSHTunnelError: {0}'.format(e))

    def Close(self):
        """Close the SSH tunnel"""

        try:
            if self.tunnel:
                self.tunnel.stop()
                LOGGER.info('Tunnel Closed Successfully')
        except Exception as msg:
            raise Exception('SSHTunnelCloseError: {0}'.format(msg))


if __name__ == '__main__':

    start_time = timeit.default_timer()
    p = SSHConnection('10.101.217.21', 'root', 'netwitness')
    p.Exec('uname -na')
    p.close()
    print(timeit.default_timer() - start_time)
