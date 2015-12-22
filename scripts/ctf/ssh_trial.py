#!/usr/bin/env python

import os
import pexpect
from common.framework.logger import LOGGER

LOGGER.setLevel('DEBUG')


class SshCommandClient(object):
    """Ssh utility that allows executing remote commands on a specified host.

    Connection is established on init and maintained until close.
    """

    def __init__(self, host, user=None, password=None, timeout=120):
        """Initializes SSH object for the host specified.

        Args:
            host: hostname to establish SSH connection to (str)
            user: username to connection with (str)
            password: password of the username (str)
            timeout: wait for SSH connection to establish in seconds (int)

        Handles three types of SSH connections:
            - new SSH connection
            - with password
            - without password.
        """

        self.host = host
        self.user = user
        self.password = password
        self.connection = pexpect.spawnu('ssh %s@%s' % (self.user, self.host))
        # import sys; self.child.logfile = sys.stdout
        index = self.connection.expect([r'[Pp]assword:', r'yes/no', r'#'], timeout=timeout)
        if index == 0:
            self.connection.sendline(self.password)
            self.connection.expect(r'#', timeout=timeout)
        elif index == 1:
            self.connection.sendline('yes')
            self.connection.expect(r'[Pp]assword:', timeout=timeout)
            self.connection.sendline(self.password)
            self.connection.expect(r'#', timeout=timeout)
        elif index == 2:
            pass

    def Exec(self, command, prompt='#', timeout=60):
        """Send a command and return the response.

        Args:
            command - the command to be sent (str)
            prompt - the expected prompt after command execution (regex)
            timeout - wait before command execution finishes in seconds (int)

        Returns:
            response - the response after command execution

        Raises:
            pexpect.ExceptionPexpect: for command execution timeout or EOF
        """
        try:
            self.connection.sendline(command)
            self.connection.expect(prompt, timeout=timeout)
            response = self.connection.before
            LOGGER.debug(response)
            return response
        except pexpect.ExceptionPexpect as msg:
            raise pexpect.ExceptionPexpect('Reached an expected state during \'%s\' command '
                                           'execution: %s' % (command, msg))

    def close(self):
        """Close the ssh connection"""
        try:
            self.connection.close(force=1)
        except pexpect.ExceptionPexpect as msg:
            raise pexpect.ExceptionPexpect('This should never happen.\n%s' % msg)

    def make_temp(self, file_content):
        """Makes a temp file.

        Args:
            file_content: the content to be saved in a temp file (str)
        """
        temp_file = self.Exec('mktemp', '#')
        self.Exec('echo "%s" > %s' % (file_content, temp_file.split('\n')[1][:-1]), '#')
        return temp_file.split('\n')[1][:-1]

    def remove_file(self, f_name):
        """Deletes a remote file.

        Args:
            f_name: name fo the remote file to be deleted(str)
        """
        command = 'rm -f %s' % f_name
        self.Exec(command, '#')

    def get_service_pid(self, service):
        """ Gets the pid of Linux service specified.

        Args:
            service: name of linux service (str)
        """
        command = 'service %s status' % service
        result = self.Exec(command, '#')
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
        cmd = None
        if operation == 'to_local':
            # verifying source file exists
            assert self.assert_remote_file_exists(source_file)
            cmd = 'scp %s@%s:%s %s' % (self.user, self.host, source_file, destination_file)
        elif operation == 'to_remote':
            # verifying source file exists
            assert os.path.exists(source_file)
            cmd = 'scp %s %s@%s:%s' % (source_file, self.user, self.host, destination_file)

        LOGGER.debug('Executing command: %s', cmd)
        try:
            self.connection = pexpect.spawnu(cmd)
            index = self.connection.expect([r'[Pp]assword:', r'yes/no', pexpect.EOF]
                                           , timeout=timeout)
            if index == 0:
                self.connection.sendline(self.password)
                self.connection.expect(pexpect.EOF, timeout=timeout)
            elif index == 1:
                self.connection.sendline('yes')
                self.connection.expect(r'[Pp]assword:', timeout=timeout)
                self.connection.sendline(self.password)
                self.connection.expect(pexpect.EOF, timeout=timeout)
            elif index == 2:
                return True
        except pexpect.ExceptionPexpect as e:
            raise pexpect.ExceptionPexpect('Error execution command \'%s\' with exception: %s'
                                           % (cmd, e))

    def assert_remote_file_exists(self, file_path):
        LOGGER.debug('Verifying if \'%s\' file exists on \'%s\'' % (file_path, self.host))
        output = self.Exec('test -f %s ; echo $?' % file_path).split('\n')[1].strip()
        if output is '1':
            return False
        if output == '0':
            return True


if __name__ == '__main__':
    p = SshCommandClient('10.101.59.231', 'root', 'netwitness')
    # p.copy_file(destination_file='/opt/rsa/esa/logs/esa.log_' + p.host
    #             , source_file=os.path.join('/Users/bakhra/src/scripts/ctf'
    #                                             , 'esa.log_' + p.host)
    #             , operation='to_remote')
    print(p.assert_remote_file_exists('/opt/rsa/esa/logs/esa.log'))
    p.close()
