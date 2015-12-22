#!/usr/bin/env python

import time

from framework.common.logger import LOGGER
from pyjolokia import Jolokia
import simplejson as json
from pprint import pprint
import unittest
import os

from bson import json_util


LOGGER.setLevel('DEBUG')

# class JolokiaMixins(unittest.TestCase):
class JolokiaMixins(object):
    """ Mixin utilities to get values from JVM using jolokia."""

    test_name = 'test_per_esper_module_stats'
    ENGINES_LIST = ['default', 'test', 'global']

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

    def test_per_esper_module_stats(self):
        """Verifies the modules stats in per esper engines MBean.

        Expectation is deployed, enabled, disabled and total modules stats are accurate in,
        "com.rsa.netwitness.esa:type=CEP,subType=Module,id=*ModuleStats" MBean
        """

        #self.PublishEventAndWait()
        #self.assertEventProcessed(expectedNumEvents=3)
        #self.assertMongoAlertCount(ruleid=[self.test_name], expectedNumAlerts=3)
        self.moduleIdentifier = self.GetModuleId()

        # asserting all EPL modules, including disabled ones are deployed.
        mbean = 'com.rsa.netwitness.esa:type=CEP,subType=Module,id=configuration'
        data = self.GetJolokiaRequest(mbean=mbean, attribute='SerializedModules')
        expected_epl_identifiers = [self.test_name + '_global'
                                    , self.test_name + '_test'
                                    , self.test_name + '_default'
                                    , self.test_name, 'esa.types.enrichment'
                                    , self.test_name, 'esa.types.source'
                                    , self.test_name, 'esa.types.system']
        actual_epl_identifiers = []
        for i in data:
            actual_epl_identifiers.append(json.loads(i)['identifier'])
        LOGGER.debug('actual_epl_identifiers: %s', actual_epl_identifiers)
        LOGGER.info('Asserting total EPL modules deployed')
        self.assertEqual(9, len(actual_epl_identifiers))
        self.assertEqual(set(actual_epl_identifiers), set(expected_epl_identifiers))

        for _engineId in self.ENGINES_LIST:
            for attr in ['NumEnabled', 'NumDisabled', 'NumDeployed', 'NumModules']:
                #self.assertIn((self.test_name, _engineId), self.moduleIdentifier)

                if attr == 'NumDisabled':
                    expected_value = 1
                elif attr == 'NumModules':
                    expected_value = 5
                elif attr == 'NumDeployed' or attr == 'NumEnabled':
                    expected_value = 4

                LOGGER.info('Asserting \'%s\' stat value in \'%sModuleStats\' MBean'
                            , attr, _engineId)
                if _engineId == 'default':
                    engine = 'cep'
                mbean = ('com.rsa.netwitness.esa:type=CEP,subType=Module,id='
                         + engine + 'ModuleStats')
                actual_value = self.GetJolokiaRequest(mbean=mbean, attribute=attr)
                LOGGER.debug('Actual %s: %s', attr, actual_value)
                self.assertEquals(expected_value, actual_value)

                _attr = attr[0].lower() + attr[1:]
                LOGGER.info('Asserting \'%s\' stat value for \'%s\' engine in statsByEngine MBean'
                            , _attr, _engineId)
                mbean = 'com.rsa.netwitness.esa:type=CEP,subType=Module,id=statsByEngine'
                path = _engineId + '/' + _attr
                actual_value = self.GetJolokiaRequest(mbean=mbean, attribute='StatsByEngine'
                                                      , path=path)
                LOGGER.debug('Actual %s: %s', _attr, actual_value)
                self.assertEquals(expected_value, actual_value)

        for _engineId in self.ENGINES_LIST:
            mbean = 'com.rsa.netwitness.esa:type=CEP,subType=Module,id=statsByEngine'
            path = _engineId + '/' + 'stats'
            actual_value = self.GetJolokiaRequest(mbean=mbean, attribute='StatsByEngine'
                                                          , path=path)
            for i in actual_value:
                if i['id'] == self.test_name:
                    self.assertEqual(1, i['numEventsFired'])
                    self.assertEqual(1, i['numEventsIStream'])

    def GetEsaAttribute(self, mbean_path, attribute=None):
        """Returns ESA Mbean Attribute value, similar to esa-client 'get .'

        Args:
            mbean_path: mbean path as displayed in esaclient (str)
            attribute: any specific attribute from within the mbean tree (str)

        Returns:
            JSON output from mbean.
        """
        base_mbean = 'com.rsa.netwitness.esa'
        path_list = mbean_path.split('/')[1:]
        if len(path_list) != 3:
            raise TypeError('ESA MBean path "%s" is Wrong!' % mbean_path)
        mbean = ('%s:type=%s,subType=%s,id=%s'
                 % (base_mbean, path_list[0], path_list[1], path_list[2]))
        if attribute == '':
            attribute = None
        LOGGER.debug('==== mbean = %s', mbean)
        LOGGER.debug('==== attribute = %s', attribute)
        return self.GetJolokiaRequest(mbean=mbean, attribute=attribute)

    def CollectAnaStats(self):
        """ Collects Analytics engine specific stats"""

        ana_stat = '/Topology/statistics/topology'
        json_value = self.GetEsaAttribute(mbean_path=ana_stat, attribute='')
        with open(os.path.join('.', 'ana_stat.json'), 'wb') as _file:
            json_formatted_doc = json_util.dumps(json_value, sort_keys=False, indent=4
                                                 , default=json_util.default)
            LOGGER.debug('[CollectAnaStats] Writing JSON data into file:\n%s'
                         , json_formatted_doc)
            _file.write(bytes(json_formatted_doc, 'UTF-8'))


if __name__ == '__main__':
    # unittest.main()
    p = JolokiaMixins(host='10.101.59.231')
    # http://10.31.204.99:8778/jolokia/read/com.rsa.netwitness.esa:type=CEP,subType=Metrics,
    # id=statistics/EsperEngines/default/modules/epl_module_no_148/total
    # with open('epl_module_stats', 'a+', buffering=1) as f:
        # for i in xrange(100):
            # result = p.GetJolokiaRequest(mbean='com.rsa.netwitness.esa:type=CEP,subType=Metrics,id=statistics'
            #                              , attribute='EsperEngines'
            #                              , path='default/modules/epl_module_no_1/total')
            #         # return result['value']
            # if result is not None:
            #     f.write(result['value'] + '\n')
            # else:
            #     f.write(str(result) + '\n')
    # http://10.101.59.231:8778/jolokia/read/com.rsa.netwitness.esa:type=Workflow,subType=Source,id=nextgenAggregationSource/Stats
    # esper_feeder_stats = p.GetJolokiaRequest(mbean='com.rsa.netwitness.esa:type=Workflow'
    #                                                ',subType=Source,id=nextgenAggregationSource'
    #                                                , attribute='Stats')
    # # print (esper_feeder_stats)
    # sessions_behind_list = [i['sessionsBehind'] for i in esper_feeder_stats]
    # if sum(sessions_behind_list) == 0:
    #     print (sessions_behind_list)
    p.CollectAnaStats()
