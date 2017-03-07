#!/usr/bin/env python

import json
import pexpect
import re
import unittest as testcase
from bson import json_util
from ctf.framework.logger import LOGGER

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
    PROMPT_PATTERN = r'carlos.*jmx.*>'
    # PROMPT_PATTERN = '>'
    PEXPECT_TIMEOUT = 5

    def __init__(p, binary_path=None):
        binary_path = '/Users/bakhra/source/server-ready/client/target/appassembler/bin/esa-client'
        cmd = binary_path + ' --profiles carlos'

        p.__pexpect = pexpect.spawn(cmd)
        p.__fout = open('esaclient.log', 'wb')
        p.__pexpect.logfile = p.__fout
        p.__pexpect.expect(p.PROMPT_PATTERN, 25)

    def Terminate(p):
        """Terminate ESAClient.

        Send the quit command to terminate gracefully, wait for the EOF so we know the quit command
        is complete, then make sure the process is terminated.
        """
        p.__pexpect.sendline('quit')
        p.__pexpect.expect(pexpect.EOF, p.PEXPECT_TIMEOUT)
        p.__pexpect.terminate(force=True)
        p.__fout.close()

    def _removeColorCodes(p, output, cmd=None):
        """ Removes extra lines and constructs proper JSON objects.

        Returns list of json objects.
        """
        try:
            # removes first and last line
            output = '\n'.join(output.split('\n')[1:-1])
            # removes color codes
            r = re.compile("\033\[[0-9;]+m")
            output = r.sub('', output)

            if 'script' in cmd:
                if 'carlos-connect' in cmd:
                    data = output[output.index('Remote'):]

            if 'carlos-connect' in cmd:
                data = output[output.index('Remote'):]
            elif 'epl-module-get' in cmd or 'query' in cmd:
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

    def Exec(p, cmd, timeout=PEXPECT_TIMEOUT):
        """Send a cmd to the ESAClient and return the response.

        Use pexpect to send the specified command, and then wait for ESAClient to present the
        prompt indicating that the command is complete.

        Returns: List of JSON objects.
        """
        LOGGER.debug('Launching esa-client cmd:\n%s', cmd)
        p.__pexpect.sendline(cmd)
        if 'carlos-connect' in cmd or 'script' in cmd:
            p.__pexpect.expect('>', timeout)
        else:
            p.__pexpect.expect(p.PROMPT_PATTERN, timeout)
        output_list_dicts = p._removeColorCodes(p.__pexpect.before, cmd=cmd)
        LOGGER.debug('Output:\n%s', output_list_dicts)
        return output_list_dicts

    def AddAmqpSource(p, value=None):
        """ Adds AMQP source url.

        Args:
            value: list of amqp url or urls.
        """
        if value is None:
            value = ["amqp://esa.events?EventType=Event&Source=Test&IdField=id"]

        if not isinstance(value, list):
            value = list(value)

        LOGGER.debug('Adding AMQP source uri: %s', value)
        p.Exec('cd /Workflow/Source/messageBusSource')
        for url in value:
            p.Exec('invoke addAmqpSource --param %s' % url)
        return

    def ControlMessageBusPipeline(p, value=True):
        """ Enables/Disables messageBus pipeline.

        Args:
            value: True to enable the pipeline(Default)
                   False to disable the pipeline.
        """
        loc = '/Workflow/Pipeline/messageBus'
        if value:
            LOGGER.info('Enabling messageBus pipeline')
        else:
            LOGGER.info('Disabling messageBus pipeline')

        p.Exec('cd %s' % loc)
        p.Exec('set Enabled --value %s' % value)
        p.Exec('invoke start')
        return

    def verify_module_exists(p, module_name, output):
        for k, v in output.iteritems():
            print 'k: ', k
            print 'v: ', v
            if item['module']['identifier'] is module_name:
                return True
        return False


if __name__ == '__main__':
    p = ESAClientHarness()
    # p.Exec('script /Users/bakhra/source/esa/python/ctf/esa/testdata/multi_esper_engines_test.py/MultiEsperEnginesTest/test_global_epl_module_rm/setup.cmds')
    # output = p.Exec('epl-module-get')
    # print '===='
    # print output
    # print '====='
    # print p.verify_module_exists('test_global_epl_module_rm', output)
    # output = p.Exec('epl-module-rm test_global_epl_module_rm')
    # output = p.Exec('epl-module-get')
    # print '===='
    # print output
    # print '====='
    # print p.verify_module_exists('test_global_epl_module_rm', output)
    p.Exec('carlos-connect')
    # p.Exec('cd source/mess')
    # p.Exec('get .')
    # p.Exec('epl-module-set --eplFile %s --debug true'
    #        % '/Users/bakhra/source/server-ready/python/ctf/corelation/testdata/forward_notification_test.py/ForwardNotificationCarlosTest/test_leaf_five_failures_forward/test.epl')
    # p.Exec('epl-module-get')
    # p.Exec('cd pipeline/mess')
    # p.Exec('set Enabled --value true')
    # p.Exec('invoke start')
    # p.Exec('get .')
    # p.Exec('cd ../../../alert/notifica')
    # p.Exec('get .')
    # p.Exec('notification-provider-set-forward distribution --exchange esa.csc --defaultHeaders \"esa.event.type=Event\" --type HEADERS --vhost \"/rsa/sa\"')
    # p.Exec('notification-instance-set-forward forwardInstance')
    # p.Exec('notification-provider-get')
    # p.Exec('notification-instance-get')

    output = p.Exec('enrichment-data-query --query \"select * from IPUserMap\" '
                    + 'ip_user_map')
    # LOGGER.debug('==== output: %s', output[1])
    # pprint(output[1])
    # json_output = json.loads(output[1])
    json_formatted_doc = json_util.dumps(output, sort_keys=False, indent=4
                                         , default=json_util.default)
    LOGGER.debug('==== JSON output: %s', json_formatted_doc)
    # p.assertIn('query_response', json_output.keys())
    # pprint(json_formatted_doc)
    testcase.assertIn('Fred', json_formatted_doc)
    # LOGGER.debug('==========\n', json_output[0])

    # LOGGER.info(json_output[0]['query_response'])
    # print type(json_output[0]['query_response'])
    # p.assertEqual(expected_cnt, actual_cnt)

    # p.Exec('enrichment-data-reset ip_user_map')
    # p.Exec('enrichment-data-query --query \"select * from IPUserMap\" ip_user_map')

    p.Terminate()
