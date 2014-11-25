#!/usr/bin/env python

import time

from ctf.framework.logger import LOGGER
from pyjolokia import Jolokia
from thirdparty import simplejson as json
from pprint import pprint
import unittest

LOGGER.setLevel('DEBUG')

class JolokiaMixins(unittest.TestCase):
    """ Mixin utilities to get values from JVM using jolokia."""

    def __init__(self, host='localhost', port=8779):
        url = ('http://%s:%d/jolokia/' % (host, port))
        try:
            self.j4p = Jolokia(url)
        except e:
            LOGGER.error(e)

    def GetJolokiaRequest(self, mbean=None, attribute=None, path=None):
        """ Gets the value of mbean specified.

        Args:
            mbean: name of the mbean
            attribute: attribute name to get value of.
            path: if attribute has additional path, then path name to that attribute.

        Returns:
            Returns the value of mbean, attribute, path.
        """
        data = self.j4p.request(type='read', mbean=mbean, attribute=attribute, path=path)
        if 'value' in data:
            return data['value']

    def PostJolokiaRequest(self, mbean=None, attribute=None, path=None, value=None):
        """ Sets the value of mbean specified.

        Args:
            mbean: name of the mbean
            attribute: attribute name to set value of.
            path: if attribute has additional path, then path name to that attribute.
            value: new value of the attribute to set.

        Returns:
            Returns the previous value of mbean, attribute, path.
        """
        data = self.j4p.request(type='write', mbean=mbean
                                , attribute=attribute, path=path, value=value)
        if 'value' in data:
            return data['value']

    def SearchJolokiaRequest(self, mbean=None, attribute=None, path=None, value=None):
        """ Searches MBean attribute of the provided bean."""
        data = self.j4p.request(type='search', mbean=mbean
                                , attribute=attribute, path=path, value=value)
        if 'value' in data:
            LOGGER.debug('%s: %s', attribute, data['value'])
            return data['value']

    def ExecJolokiaRequest(self, mbean=None, operation=None, arguments=None):
        """ Executes the JMX operation on defined mbean.

        Args:
            mbean: name of the bean
            operation: JMX operation to perform.
            arguments: any argument values to be provided to operation.
        """
        data = self.j4p.request(type='exec', mbean=mbean
                                , operation=operation, arguments=arguments)
        if 'value' in data:
            return data['value']

    def ControlJolokiaAgent(self, java_process_pid=0, command=None
                            , host='127.0.0.1', port=8778):
        """ Controls starting and stopping of attaching jolokia agent to any java pid.

        Args:
            java_process_pid: process id of the java process to attach jolokia agent to.
            command: stop/start jolokia JVM agent.
            host: if you want to enable remote access to jolokia provide IP address.
            port: port on which jolokia agent will be accessible. (default=8778)

        Attaching a jolokia agent gives HTTP access to all JMX objects of the java process.
        """
        if 'stop' in command:
            LOGGER.debug('Stopping jolokia JVM agent for esa-server PID %d', java_process_pid)
        else:
            LOGGER.debug('Starting jolokia JVM agent for esa-server PID %d', java_process_pid)

        p = subprocess.Popen('which java', stdout=subprocess.PIPE
                             , stderr=subprocess.PIPE, shell=True)
        java_binary_path = p.communicate()[0].strip()
        if not java_binary_path:
            java_binary_path = '/usr/bin/java'
        else:
            java_binary_path = str(java_binary_path)

        # setting javaagent to Jolokia JVM agent for JMX details access.
        jolokia_agent_lib = os.path.join('..', 'tools', 'jolokia-jvm-1.2.2-agent.jar')
        cmd = java_binary_path + ' -jar ' + jolokia_agent_lib + ' '\
              + '--host ' + host + ' --port ' + str(port) + ' '\
              + command + ' ' + str(java_process_pid)
        LOGGER.debug('Launching command: \"%s\"', cmd)
        p = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True)
        output = p.communicate()
        LOGGER.debug(output[0])
        return

    def serverStatus(self):
        """ Returns esa-server running status."""
        mbean = 'com.rsa.netwitness.esa:type=Service,subType=Status,id=service'
        attribute = 'Status'
        return self.GetJolokiaRequest(mbean=mbean, attribute=attribute)

    def GetModuleId(self):
        """ To get the list of deployed module ids."""
        mbean = 'com.rsa.netwitness.esa:type=CEP,subType=Module,id=configuration'
        attribute = 'ModuleIdentifiers'
        modules_list = self.GetJolokiaRequest(mbean, attribute)
        LOGGER.debug('List of deployed EPL modules: %s', modules_list)
        return modules_list

    def ControlMessageBusPipeline(self, value=True):
        """ Enables/Disables messageBus pipeline.

        Args:
            value: True to enable the pipeline(Default)
                   False to disable the pipeline.
        """
        mbean = 'com.rsa.netwitness.esa:type=Workflow,subType=Pipeline,id=messageBus'
        attribute = 'Enabled'
        if value:
            LOGGER.debug('Enabling messageBus pipeline')
        else:
            LOGGER.debug('Disabling messageBus pipeline')
        self.PostJolokiaRequest(mbean=mbean, attribute=attribute, value=value)

    def AddAmqpSource(self, value=None):
        """ Adds AMQP source url.

        Args:
            value: list of amqp url or urls.
        """
        if value is None:
            value = [ "amqp://esa.events?EventType=Event&Source=Test&IdField=id" ]
        mbean = 'com.rsa.netwitness.esa:type=Workflow,subType=Source,id=messageBusSource'
        LOGGER.debug('Adding AMQP source uri: %s', value)
        self.ExecJolokiaRequest(mbean=mbean, operation='addAmqpSource', arguments=value)
        LOGGER.debug('AFTER: %s', self.GetJolokiaRequest(mbean=mbean, attribute='ConfiguredSources'))

    def epl_module_get(self, module_id=None):
        """ Performs epl module operation get on module_id provided.

        Args:
            operation: get deployed epl modules.
            module_id: module_id for epl module to be get. All if nothing specified.

        Returns: List of deployed epl modules in JSON format.
        """
        mbean = 'com.rsa.netwitness.esa:type=CEP,subType=Module,id=configuration'
        attribute = 'SerializedModules'
        if module_id is None:
            LOGGER.info('Getting all deployed epls.')
            module_id = ''

        epl_modules_list = []
        serialized_modules_list = self.GetJolokiaRequest(mbean=mbean, attribute=attribute)
        for module in serialized_modules_list:
            __module = json.loads(module)
            for k, v in __module.iteritems():
                if k == 'identifier':
                    if module_id in v:
                        epl_modules_list.append(__module)
        return epl_modules_list

    def epl_module_set(self, epl_file=None, module_id='abc'):
        """ Performs epl module operations set operation.

        Args:
            epl_file: epl_file to deploy
            module_id: module_id for epl module to be set/get

        Returns: True if deployment successful, False otherwise.
        """
        mbean = 'com.rsa.netwitness.esa:type=CEP,subType=Module,id=configuration'
        attribute = 'SerializedModules'

        module_id = module_id + '_' + str(int(round(time.time())))
        if epl_file is None:
            LOGGER.error('Please provide an epl file to deploy.!')
            return False
        # reading the rule from epl_file
        with open(epl_file) as f:
            # constructing list of dict object of epl rule, adding debug provider by default.
            epl = [{"identifier": module_id,\
                      "epl": f.read(),\
                      "debug": True,\
                      "notification_binding": [{"provider_id" : "debug"}]
                      }]
            # converting list of dict to JSON Array object
            epl_json = json.dumps(epl, sort_keys=False)
            LOGGER.debug('Deploying module\n%s', epl_json)
            self.PostJolokiaRequest(mbean=mbean, attribute=attribute, value=epl_json)
            if module_id in self.GetModuleId():
                LOGGER.debug('Deployment successful')
                return True
            LOGGER.error('%s EPL Module deployment failed.', epl_json)
            return False


if __name__ == '__main__':
    p = JolokiaMixins()
    #p.serverStatus()
    #p.assertForwardNotificationType()
    #p.controlMessageBusPipeline()
    #p.addAmqpSource()
    #file = '/Users/bakhra/tmp/t/corelation/testdata/forward_notification_test.py/ForwardNotificationCarlosTest/test_leaf_five_failures_forward/test.epl'
    #file = '/Users/bakhra/tmp/t/corelation/testdata/forward_notification_test.py/ForwardNotificationCarlosTest/test_leaf_deduped_forward/test1.epl'
    #file = '/Users/bakhra/source/server-ready/python/ctf/esa/testdata/basic_test.py/BasicESATest/test_up_and_down/test.epl'
    #print p.epl_module_set(epl_file=file)
    #print p.epl_module_get(module_id='default-system-flow')
    #a = p.epl_module_get(module_id='abc')
    #a = p.epl_module_get(module_id='abc_1412036487')
    #a = p.epl_module_get(module_id='default')
    #a = p.epl_module_get()
    #pprint(a)
    #print 'length of a:', len(a)
    #p.epl_module_ops(operation='rm')
    #carlos_url_path = p.GetJolokiaRequest(mbean='com.rsa.netwitness.esa:type'
    #                                                     + '=Service,subType=Monitor'
    #                                                     + ',id=connections'
    #                                                     , attribute='ServerEndpoints')
    #LOGGER.debug('Actual Carlos listner port: %s', carlos_url_path[0].split(':')[2].split('?')[0])

    #carlos_url_path = p.GetJolokiaRequest(mbean='com.rsa.netwitness.esa:type'
    #                                           + '=Service,subType=Monitor'
    #                                           + ',id=transport'
    #                                     , attribute='Address'
    #                                     , path='uRLPath')
    #print 'carlos_url_path: ', carlos_url_path
    #actual_rmiport = carlos_url_path.split(':')[2].split('/')[0]
    #LOGGER.debug('Actual RMI listner port: %s', actual_rmiport)
    #self.assertEqual(expected_rmi_port, actual_rmiport)
    data = p.GetJolokiaRequest(mbean='com.rsa.netwitness.esa:type=CEP'
                              + ',subType=Engine,id=esperEngines'
                              , attribute='AvailableTypes')
    #LOGGER.debug(data)
    for key in data.iteritems():
        print key[0]    
        print '==='
