#!/usr/bin/env python

import os
import pexpect
import re
import sys
import time

from ctf.framework.logger import LOGGER
from thirdparty import simplejson as json
from bson import json_util

LOGGER.setLevel('DEBUG')

class ESAClientHarness(object):
    """Harness for the ESA Client interactive command-line shell.

    The ESAClient is a spring shell application that can be used interactively to manipulate the
    ESAServer configuration. Here, we interact with it via the third-party pexpect Python library.
    This allows us to launch the ESAClient once, and then continue using it throughout our test as
    necessary.

    We extend ProcessHarness here, but are forced to override some of the functionality, because
    that class assumes we launch and manage the process with subprocess.popen. Here, we need to
    manage the process instead with pexpect. Ideally, we could factor some of the common logic in
    ProcessHarness into a common class, and then subclass a Popen version and a Pexpect version.
    """

    PROGRAM = 'ESAClient'
    PROMPT_PATTERN = '>'
    PEXPECT_TIMEOUT = 5

    def __init__(self, binary_path=None):
        binary_path = '/Users/bakhra/source/saeng-5631-forwarding-notification/client/target/appassembler/bin/esa-client'
        cmd = binary_path + ' --profiles carlos'

        self.__pexpect = pexpect.spawn(cmd)
        self.__fout = open('esaclient.log','wb')
        self.__pexpect.logfile = self.__fout
        self.__pexpect.expect(self.PROMPT_PATTERN, 25)

    def Terminate(self):
        """Terminate ESAClient.

        Send the quit command to terminate gracefully, wait for the EOF so we know the quit command
        is complete, then make sure the process is terminated.
        """
        self.__pexpect.sendline('quit')
        self.__pexpect.expect(pexpect.EOF, self.PEXPECT_TIMEOUT)
        self.__pexpect.terminate(force=True)
        self.__fout.close()

    def _removeColorCodes(self, output, cmd=None):
        """ Removes extra lines and constructs proper JSON objects.

        Returns list of json objects.
        """
        try:
            # removes first and last line
            output = '\n'.join(output.split('\n')[1:-1])
            # removes color codes
            r = re.compile("\033\[[0-9;]+m")
            output = r.sub('', output)
            if 'carlos-connect' in cmd:
                data = output[output.index('Remote') : ]
            elif 'epl-module-get' in cmd:
                # constructing JSON objects
                r = re.compile("\r{")
                data = r.sub('{', output)
                r = re.compile("}\r")
                data = r.sub('}', data)
                r = re.compile("}\n{")
                data = r.sub('},\n{', data)
                data = '[ ' + data + ' ]'
                output_dict = json.loads(data)
                data = output_dict
            else:
                data = output
            return data
        except Exception as e:
            LOGGER.error(e)
            return []

    def Exec(self, cmd, timeout=PEXPECT_TIMEOUT):
        """Send a cmd to the ESAClient and return the response.

        Use pexpect to send the specified command, and then wait for ESAClient to present the
        prompt indicating that the command is complete.

        Returns: List of JSON objects.
        """
        LOGGER.debug('Launching esa-client cmd:\n%s', cmd)
        self.__pexpect.sendline(cmd)
        self.__pexpect.expect(self.PROMPT_PATTERN, timeout)
        if 'script' not in cmd:
            output_list_dicts = self._removeColorCodes(self.__pexpect.before, cmd=cmd)
            LOGGER.debug('Output:\n%s', output_list_dicts)
            return output_list_dicts

if __name__ == '__main__':
    p = ESAClientHarness()
    p.Exec('carlos-connect')
    p.Exec('cd source/mess')
    p.Exec('get .')
    p.Exec('epl-module-set --eplFile %s --debug true'
            % '/Users/bakhra/source/server-ready/python/ctf/corelation/testdata/forward_notification_test.py/ForwardNotificationCarlosTest/test_leaf_five_failures_forward/test.epl')
    p.Exec('epl-module-get')
    p.Exec('cd ../../../pipeline/mess')
    p.Exec('set Enabled --value true')
    p.Exec('invoke start')
    p.Exec('get .')
    p.Exec('cd ../../../alert/notifica')
    p.Exec('get .')
    p.Exec('notification-provider-set-forward distribution --exchange esa.csc --defaultHeaders \"esa.event.type=Event\" --type HEADERS --vhost \"/rsa/sa\"')
    p.Exec('notification-instance-set-forward forwardInstance')
    p.Exec('notification-provider-get')
    p.Exec('notification-instance-get')
    p.Terminate()
