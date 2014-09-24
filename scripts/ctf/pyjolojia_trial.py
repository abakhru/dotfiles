#!/usr/bin/env python

import time

from ctf.framework.logger import LOGGER
from pyjolokia import Jolokia

LOGGER.setLevel('DEBUG')


class PyJolokiaMixins(object):
    """ Mixin utilities to get values from JVM using jolokia."""

    def __init__(self, host='localhost', port=8778):
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
            LOGGER.debug('%s: %s', attribute, data['value'])
            return data['value']

    def PostJolokiaRequest(self, mbean=None, attribute=None, path=None, value=None):
        data = self.j4p.request(type='write', mbean=mbean
                                , attribute=attribute, path=path, value=value)
        if 'value' in data:
            LOGGER.debug('%s: %s', attribute, data['value'])
            return data['value']

    def SearchJolokiaRequest(self, mbean=None, attribute=None, path=None, value=None):
        data = self.j4p.request(type='search', mbean=mbean
                                , attribute=attribute, path=path, value=value)
        if 'value' in data:
            LOGGER.debug('%s: %s', attribute, data['value'])
            return data['value']

    def ExecJolokiaRequest(self, mbean=None, operation=None, arguments=None):
        data = self.j4p.request(type='exec', mbean=mbean
                                , operation=operation, arguments=arguments)
        LOGGER.debug(data)
        if 'value' in data:
            LOGGER.debug('%s: %s', attribute, data['value'])
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
        mbean = 'com.rsa.netwitness.esa:type=Service,subType=Status,id=service'
        attribute = 'Status'
        return self.GetJolokiaRequest(mbean=mbean, attribute=attribute)

    def getModuleId(self):
        """ To get module id."""
        mbean = 'com.rsa.netwitness.esa:type=CEP,subType=Module,id=configuration'
        attribute = 'ModuleIdentifiers'
        return self.GetJolokiaRequest(mbean, attribute)

    def assertForwardNotificationType(self):
        mbean = 'com.rsa.netwitness.esa:type=Alert,subType=Notification,id=notificationEngine'
        attribute = 'SupportedNotificationTypes'
        data = self.GetJolokiaRequest(mbean=mbean, attribute=attribute)
        if 'FORWARD' in data:
            return True
        return False

    def controlMessageBusPipeline(self, value='true'):
        mbean = 'com.rsa.netwitness.esa:type=Workflow,subType=Pipeline,id=messageBus'
        attribute = 'Enabled'
        self.PostJolokiaRequest(mbean=mbean, attribute=attribute, value=value)
        self.ExecJolokiaRequest(mbean=mbean, operation='start')
        if LOGGER.getEffectiveLevel() is 10:
            self.GetJolokiaRequest(mbean=mbean, attribute=attribute)

    def addAmqpSource(self, value=None):
        """ Adds AMQP source url.

        Args:
            value: list of amqp url or urls.
        """
        if value is None:
            value = [ "amqp://esa.events?EventType=TestEvent&Source=Test&IdField=id" ]
        mbean = 'com.rsa.netwitness.esa:type=Workflow,subType=Source,id=messageBusSource'
        self.ExecJolokiaRequest(mbean=mbean, operation='addAmqpSource', arguments=value)
        if LOGGER.getEffectiveLevel() is 10:
            self.GetJolokiaRequest(mbean=mbean, attribute='ConfiguredSources')

    def epl_module_ops(self, epl_file=None, module_id='abc', operation='set'):
        """ Performs epl module operations set/get/rm.

        Args:
            operation: get/set/rm epl module operation
            module_id: module_id for epl module to be set
            epl_file: epl_file to deploy
        value = [ "{
                    \"identifier\" : \"60854fa3-198a-409a-991b-70dd56c142c7\",
                    \"epl\" : \"@Audit @RSAAlert select * from Event;\\n\",
                    \"debug\" : \"true\",
                    \"notification_binding\" : [ {\"provider_id\" : \"debug\"} ]}" ]
        """
        mbean = 'com.rsa.netwitness.esa:type=CEP,subType=Module,id=configuration'
        attribute = 'SerializedModules'

        if operation is 'set':
            module_id = module_id + '_' + str(int(round(time.time())))
            if epl_file is None:
                LOGGER.debug('Please provide an epl file to deploy.!')
                return False
            # reading the rule from epl_file
            with open(epl_file) as f:
                # constructing JSON object of rule and then deploy.
                value = ["{ \"identifier\" : \"" + module_id
                          + "\", \"epl\" : \"" + f.read()
                          + "\", \"debug\" : \"true\" ,"#}" ]
                          + "\"notification_binding\": [ {\"provider_id\" : \"debug\"} ] }" ]

                LOGGER.debug('\nvalue: %s', value)
                self.PostJolokiaRequest(mbean=mbean, attribute=attribute, value=value)
                """for module in self.GetJolokiaRequest(mbean=mbean, attribute=attribute):
                """
                LOGGER.debug(self.getModuleId())
                if module_id in self.getModuleId():
                    #LOGGER.debug(module)
                    return True
                else:
                    LOGGER.error('%s not deployed.', module_id)
                    return False

        # not working yet
        elif operation is 'rm':
            value = [ "{}" ]
            self.PostJolokiaRequest(mbean=mbean, attribute=attribute, value=value)

        if LOGGER.getEffectiveLevel() is 10 or operation is 'get':
            _list = self.GetJolokiaRequest(mbean=mbean, attribute=attribute)
            for i in _list:
                if module_id in i:
                    print i


if __name__ == '__main__':
    p = PyJolokiaMixins()
    #p.serverStatus()
    #p.assertForwardNotificationType()
    #p.controlMessageBusPipeline()
    #p.addAmqpSource()
    #file = '/Users/bakhra/tmp/t/corelation/testdata/forward_notification_test.py/ForwardNotificationCarlosTest/test_leaf_five_failures_forward/test.epl'
    #file = '/Users/bakhra/tmp/t/corelation/testdata/forward_notification_test.py/ForwardNotificationCarlosTest/test_leaf_deduped_forward/test1.epl'
    file = '/Users/bakhra/source/server-ready/python/ctf/esa/testdata/basic_test.py/BasicESATest/test_up_and_down/test.epl'
    p.epl_module_ops(epl_file=file)
    p.epl_module_ops(operation='get', module_id='abc')
    #p.epl_module_ops(operation='rm')
