#!/usr/bin/env python

import os
import ssl
import pexpect


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
        try:
            self.connection = pexpect.spawnu('ssh %s@%s' % (self.user, self.host))
            _f_out = open('ssh.log', 'w')
            self.connection.logfile = _f_out
            # NOTE: uncomment below line to enable connection level logging, extremely verbose
            # import sys; self.connection.logfile = sys.stdout
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
        except Exception as e:
            print(e)
            raise ConnectionError('Unable to Connect to Host %s@%s' % (self.user, self.host))

    def Exec(self, command, prompt=r'#', timeout=60):
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
            _before = self.connection.before
            self.connection.sendline(command)
            self.connection.expect(prompt, timeout=timeout)
            print('==== before: %s' % self.connection.before)
            print('==== after: %s' % self.connection.after)
            response = self.connection.before
            print(response)
            return response
        except:
            print("Exception was thrown")
            print("debug information:")
            print(str(self.connection))



class NwConsoleHarness(object):
    """NwConsole harness that allow executing NWSDK commands and returns the result."""

    PROMPT_PATTERN = r'>'

    def __init__(self, host='localhost', program=None, user='root', password=None
                 , rest_user='admin', rest_password=None, port=50004, ssl=True
                 , sdk_node='decoder'):
        """Initializes an NwConsole object.

        Args:
            host: the IP where NwConsole client is installed (str)
            program: name of the netwitness program (str)
            user: username for ssh access to the host (str)
            password: password for ssh access to the host (str)
            rest_user: username to access Netwitness program REST API (str)
            rest_password: password to access Netwitness program REST API (str)
            port: Netwitness program server port value (int)
            ssl: connect with ssl enabled (bool)
            sdk_node: NWSDK name of the component (str)
        """

        self.host = host
        self.port = port
        self.program = program
        self.use_ssl = ssl
        self.rest_user = rest_user
        self.rest_password = rest_password
        self.sdk_node = sdk_node
        print('Launching NwConsole Client for "%s" program on host "%s"'
              % (self.program, self.host))
        self.nwconsole = SshCommandClient(host, user, password)
        output = self.nwconsole.Exec('NwConsole', self.PROMPT_PATTERN)
        print('===Output:\n%s', output)
        print('===Output List:\n%s', output.split('\n'))
        output_list = output.split('\n')
        output_list = [t.replace('\r', '') for t in output_list]
        for i in output_list:
            print("===='%s'====" % i)
        print('===Output List length: ===%s===', len(output_list))
        self.Login()

    def __get_output(self, response):
        """Returns the exact output from NwConsole command execution output"""

        return response.strip().replace('[', '').replace(']', '')

    def Exec(self, command, prompt=None, timeout=30):
        """Executes the command provided in NwConsole prompt"""

        print('[NwConsole] Inside Exec')
        if prompt is None:
            prompt = self.PROMPT_PATTERN
        return self.nwconsole.Exec(command, prompt=prompt, timeout=timeout)

    def Login(self):
        """ Login to Netwitness Component using NWSDK API calls through NwConsole.

        Args:
            ssl: ssl is enabled or not.
            rest_user: rest API access username (str)
            rest_password:  rest API access password (str)

        Returns:
            True: If login successful
            False: Otherwise
        """

        if self.use_ssl:
            login_cmd = ('login %s:%s:ssl %s %s'
                         % (self.host, self.port, self.rest_user, self.rest_password))
        else:
            login_cmd = ('login %s:%s %s %s'
                         % (self.host, self.port, self.rest_user, self.rest_password))
        # import pdb; pdb.set_trace()
        # login_cmd = 'help'
        print('login_cmd: ===%s===' % login_cmd)
        # self.PROMPT_PATTERN = r'*>'
        output = self.Exec(login_cmd, prompt=[r'>$', r'>', r'\x1b[6n>', r'*>'], timeout=10)
        print('==== Complete output: %s', output)
        output = output.split('\n')
        output = [t.replace('\r', '') for t in output]
        print('==== Complete LIST replaces \r output: %s', output)
        output = output[1:-1]
        print('==== Complete LIST output: %s', output)
        print('[NwConsole] Login output: %s', output)
        if 'Successfully logged in' in output[0]:
            print('[NwConsole] Login Successful for \'%s\' program', self.program)
            return True
        elif 'Invalid username or password' in output:
            return False
        return False


if __name__ == '__main__':
    # replace the existing host ip, with a working LogDecoder IP below, if connection fails
    p = NwConsoleHarness(host='10.101.216.135', program='decoder', password='netwitness'
                         , rest_password='netwitness', port=50002, sdk_node='decoder', ssl=False)
