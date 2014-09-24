"""Utilities for testing multiple ESA components"""

import json
import os
import pexpect
import pika
import pymongo
import sys
import tempfile
import time
import unittest
import re

import logging

harness_log = logging.getLogger('Multi component Test')
harness_log.setLevel('DEBUG')
handler = logging.StreamHandler()
handler.setFormatter(logging.Formatter("%(asctime)s [%(levelname)s] %(name)s: %(message)s"))
harness_log.addHandler(handler)

class Ssh(object):
    """Ssh utility that allows executing commands on a specified host.
    Connection is established on init and maintained until close.
    For passwordless login skip password argument.
    """

    def __init__(self, host, user='root', password=None):
        self.host = host
        self.child = pexpect.spawn("ssh %s@%s"%(user, host))
        if password is not None:
            i = self.child.expect([r'[Pp]assword:', r'yes/no'], timeout=120)
            if i == 0:
                self.child.sendline(password)
            elif i == 1:
                self.child.sendline('yes')
                self.child.expect(r'[Pp]assword:', timeout=120)
                self.child.sendline(password)
        self.child.expect('#', timeout=120)

    def command(self, command, prompt='>'):
        """Send a command and return the response.
        Args:
            command - the command to be sent (str)
            prompt - the expected prompt after command execution (regex)

        Returns:
            response - the response after command execution
        """

        self.child.sendline(command )
        self.child.expect(prompt, timeout=60)
        response = self.child.before
        harness_log.debug (response)
        return response

    def close(self):
        """Close the ssh connection"""

        self.child.close()

class MongoDB(object):
    """MongoDB utilities that allow extracting alerts from mongo.
    TODO: implement more queries such as extract only specified fields.
    """

    def __init__(self, host):
        harness_log.info('Connectiong to MongoDb...')

        self.conn = pymongo.MongoClient(host)
        self.db = self.conn.esa
        if not self.db.authenticate('esa', 'esa', source='esa'):
            harness_log.error('Unable to connect to MongoDB')
            return

        harness_log.info('Connected OK')

    def get_alerts(self, sort_field='events.esa_time'):
        """Extract alerts from mongo"""

        harness_log.info('Extracting alerts...')
        try:
            alerts = list(self.db.alert.find().sort(sort_field, 1))
            harness_log.debug(alerts)
            return alerts
        except Exception as e:
            harness_log.error(e)
            harness_log.error('Unable to extract alerts')
            return None

    def wait_for_alerts(self, expected_alerts, num_retries=10, wait=None):
        """Pull mongo every second until expected alerts arrived

        Args:
            expected_alerts: the number of alerts we expect to appear (int)
            num_retries: the max number of retries (int)
            wait: initial wait time (s) before start pooling (int)
        """
        num_alerts = 0
        #initial wait is needed when expecting 0 alerts
        if wait is not None:
            time.sleep(wait)
        for i in range(num_retries):
            time.sleep(1)
            alerts = self.get_alerts()
            if alerts is not None:
                num_alerts = len(alerts)
            if num_alerts >= expected_alerts:
                return
        return

    def cleanup_mongo(self):
        """Removes all documents from the alert collection"""
        harness_log.info('Cleaning all alerts ....')
        try:
            self.db.alert.remove({})
        except Exception as e:
            harness_log.error(e)
            harness_log.error('Unable to cleanup mongo')

    def close(self):
        """Close connection if still opened"""

        try:
            self.conn.close()
        except:
            pass

class RabbitMQ(object):
    """RabbitMQ utilities that allow publishing events.
    TODO: add a listener, add publishing rate.
    """

    def __init__(self, host, exchange_in='esa.events', exchange_out='esa.csc'):
        """Initialize host, input and output exchanges and needed connections.
        host - the rabbitmqhost
        exchange_in - the exchange for incoming messages
        exchange_out - the exchange for outgoing messages
        """

        self.host = host
        self.exchange_in = exchange_in
        self.exchange_out = exchange_out

        harness_log.info ('Setting up connection to RabbitMQ on host ' + host + '...')
        try:
            credentials = pika.PlainCredentials('guest', 'guest')
            connection_parameters = pika.ConnectionParameters(self.host
                                                              , 5672
                                                              , '/rsa/sa'
                                                              , credentials = credentials
                                                              , socket_timeout = 120)
            self.connection = pika.BlockingConnection(connection_parameters)
            harness_log.info('Connection setup OK')
        except Exception as e:
            harness_log.error(e)
            harness_log.error('RabbitMQ connection failed')
            return

        try:
            self.channel_in = self.connection.channel()
            self.channel_out = self.connection.channel()
        except Exception as e:
            harness_log.error(e)
            harness_log.error( 'Cannot connect a RabbitMQ channels at ' + host)
            return

        try:
            self.channel_in.exchange_declare(self.exchange_in, type='headers')
            self.channel_out.exchange_declare(self.exchange_out, type='headers')
        except Exception as e:
            harness_log.error(e)
            harness_log.error( 'Cannot declare an exchange at ' + host)

    def close(self):
        """Closes RabbitMQ connection"""
        try:
            self.connection.close()
        except:
            pass

    def publish(self, filename, source='Event', sleep=0):
        """Publishes messages from file to a headers exchange
        The messages need to be in json format including event_source_id filed:
        {"event_source_id":"15", "ec_activity": "Logon", "ec_outcome": "Success"}
        """

        properties = pika.BasicProperties(headers={"esa.event.type" : source})

        for line in open(filename):
            line.strip()
            harness_log.debug(line)
            harness_log.debug('Sleeping...' + str(sleep))
            time.sleep(sleep)

            try:
                self.channel_in.basic_publish(exchange=self.exchange_in
                                              , routing_key = ''
                                              , properties= properties
                                              , body = line)
                harness_log.debug('Published OK')
            except Exception as e:
                harness_log.error( e)
                harness_log.error( 'Rabbitmq publish failed')

class EsaClient(object):
    """Esa client utilities that allow executing commands and inspecting the result.
    The host is the ESA client host. Esa client can connect to any other target host.
    """

    def __init__(self, host, user='root', password=None):
        self.host = host
        harness_log.info(password)
        self.ssh = Ssh( host, user, password)
        self.ssh.command('/opt/rsa/esa/client/bin/esa-client --profiles carlos')

    def get_modules(self, target_host=''):
        """Returns a list of existing epl modules

        target_host: the host where the module will be added (str)
        (target host can be different from client host)
        """

        module_ids = list()
        self.ssh.command('carlos-connect ' + target_host )
        modules = self.ssh.command('epl-module-get')

        modules = modules.replace("\r", "")
        # remove begin and end to make result a valid JSON
        modules =  '\n'.join(modules.split('\n')[4:-1])
        if '{' not in modules:
            return None
        # remove color coding before beginning of str
        modules = modules[modules.index('{') : ]

        modules_dict = json.loads(modules)

        for module in modules_dict['module']:
            module_ids.append(module['identifier'])

        return module_ids

    def add_module(self, module_id, module, mtype=None
                   , severity='4', enabled='true', target_host=''):
        """Add an epl module to ESA on a target host by saving the module def in a temp file.

        Args:
            module_id: the id of the module (str)
            module: the definition of the module (str)
            type: the type of the module (eg Forwarder) (str)
            severity: the severity of the alert (str)
            enabled: 'true' or 'false' (str)
            target_host: the host where the module will be added (str)
            (target host can be different from client host)

        Returns:
            The existing epl modules after the addition.
        """
        harness_log.debug('Creating temp file for ' + module + ' ...')
        epl_file = tempfile.NamedTemporaryFile(delete=False)
        epl_file.write(module)
        epl_file.close()

        harness_log.info('Connecting to client... ' + 'carlos-connect ' + target_host)
        self.ssh.command('carlos-connect ' + target_host )

        harness_log.info('Preparing command....')

        cli_command = ('epl-module-set %s --eplFile "%s" --severity %s --enabled %s'
                        % (module_id, epl_file.name, severity, enabled))
        if mtype is not None:
            cli_command = cli_command + ' --type %s' % mtype

        harness_log.info('Adding module ' + module_id)
        harness_log.info(cli_command)
        self.ssh.command(cli_command)

        os.unlink(epl_file.name)

        modules = self.get_modules(target_host)

        return (module_id in modules)

    def remove_module(self, module_id, target_host=''):
        """Remove a module to ESA on a target host

        Args:
            module_id: the id of the module (str)
            target_host: the host where the module will be removed (str)
            (target host can be different from client host)

        Returns:
            The existing epl modules after removal.
        """

        self.ssh.command('carlos-connect ' + target_host)

        cli_command = 'epl-module-rm %s' % (module_id)
        self.ssh.command(cli_command )

        harness_log.info('Removed ' + module_id)
        modules = self.ssh.command('epl-module-get')
        return modules

    def remove_all_modules(self, target_host=''):
        """Removes all modules"""

        modules = self.get_modules(target_host)

        if modules is None:
            return

        for module in modules:
            self.remove_module(module, target_host)
        return

    def forward_setup(self, exchange, source='Event'
                      , instance='forwardInstance', host=None, target_host=''):
        """Sets up distribution forwarding on Esa leaf node

        Args:
            exchange: the output exchange of the ESA node (str)
            source: the event type source (str)
            instance: the forward istance (str)
            target_host: the host where the forwarding will be set up (str)
            (target host can be different from client host)

        Returns:
            status of forwarding setup success (True or False)
        """

        harness_log.info('Connecting to client... ' + 'carlos-connect ' + target_host)
        self.ssh.command('carlos-connect ' + target_host)

        harness_log.info('Setting forwarding...')
        cmd = ('notification-provider-set-forward distribution '
               + ' --exchange %s ' % exchange
               + ' --durable false'
               + ' --defaultHeaders "esa.event.type=%s" --type HEADERS' % source)
        if host is not None:
            cmd = cmd + ' --host %s' % host
        self.ssh.command(cmd)

        harness_log.info('Setting forward instance')
        self.ssh.command('notification-instance-set-forward %s' % instance)

        notification_instances = self.ssh.command('notification-instance-get')
        return ('FORWARD' in notification_instances)

    def forward_remove(self, target_host=''):
        """Removes distribution forwarding from Esa leaf node

        Args:
            target_host: the host where the forwarding will be removed (str)
            (target host can be different from client host)

        Returns:
            status of forwarding removal success (True or False)
        """

        harness_log.info('Connecting to client... ' + 'carlos-connect ' + target_host)
        self.ssh.command('carlos-connect ' + target_host)
        cmd = 'notification-provider-rm distribution'
        harness_log.info('Removing notification provider for forwarding...')
        self.ssh.command(cmd)
        result = self.ssh.command('notification-provider-get')
        return ('FORWARD' not in result)

    def bind_module(self, moduleid, instance='forwardInstance', target_host=''):
        """Binds notification to a module.

        Args:
            moduleid: the id for the module that will be bound to a notification. (str)
            instance: the forwarding instance (str)
            target_host: the host where the module will be bound (str)
            (target host can be different from client host)

        Returns:
            status of bind success (True or False)
        """

        harness_log.info('Binding module...')
        harness_log.info('Connecting to client... ' + 'carlos-connect ' + target_host)
        self.ssh.command('carlos-connect ' + target_host)
        self.ssh.command('epl-module-bind-notification %s --binding p=distribution:i=%s'
                       % (moduleid, instance))
        modules = self.ssh.command('epl-module-get')
        #TODO define success
        return True

    def setup_mode(self, mode, lag=None):
        """Setting up esperFeeder mode. The target host can only be the client host.

        Args:
            mode - DIRECT or SLIDING (str)

        Returns:
            mode setup success (True or False)
        """

        harness_log.info('Setting up mode for ' + self.host)
        self.ssh.command('cd /Workflow/Worker/esperFeeder')

        self.ssh.command('set Mode --value %s --exact true' % mode)

        if ('Mode='+ mode) not in self.ssh.command('get Mode'):
            mode_setup = False
            harness_log.error('Mode setup failed for ' + self.host)
            return

        if mode == 'SLIDING' and lag is not None:
            self.ssh.command('set ClockLagInSeconds --value %s' % str(lag))
        return mode_setup

    def get_sources(self):
        """Returns a list of existing sources."""

        self.ssh.command('cd /Workflow/Source/messageBusSource')
        sources = self.ssh.command('get ConfiguredSources')

        sources = sources.replace("\r", "")
        sources = '\n'.join(sources.split('\n')[:-1])
        if '{' not in sources:
            return None
        # remove color coding before beginning of str
        sources = sources[sources.index('{') : ]

        sources_dict = json.loads(sources)

        return sources_dict['ConfiguredSources']

    def remove_sources(self):
        """Removes all message bus sources from workflows."""

        harness_log.info('Removing source for ' + self.host)
        self.ssh.command('cd /Workflow/Source/messageBusSource')
        sources = self.get_sources()
        for source in sources:
            self.ssh.command('invoke removeAmqpSource --param %s' % source)
        return

    def add_source(self, exchange, event_type='Event', id_field='event_source_id'
                   , time_field=None):
        """Adds a message bus source to workflows.
        TODO: Make it return success or failure. Make it enable the source.

        Args:
            exchange - the rabbitmq exchange for the source (str)
            event_type - the type of events (str)
            id_field - the name of the id field required by rabbitmq (str)
        """

        harness_log.info('Adding source for ' + self.host)

        self.ssh.command('cd /Workflow/Source/messageBusSource')
        if time_field is not None:
            self.ssh.command('invoke addAmqpSource --param '
                             + 'amqp://%s?EventType=%s&Source=Test&IdField=%s&TimeField=%s'
                             %(exchange, event_type, id_field, time_field))
        else:
            self.ssh.command('invoke addAmqpSource --param '
                             + 'amqp://%s?EventType=%s&Source=Test&IdField=%s'
                             %(exchange, event_type, id_field))
        return

    def enable_message_bus(self):

        self.ssh.command('cd /Workflow/Pipeline/messageBus')
        self.ssh.command('set Enabled --value "true"')
        return

    def shutdown(self):
        """Exit the client and close ssh connection"""

        self.ssh.command('exit', '#')
        self.ssh.close()

class Esa(object):
    """Esa component utilities"""

    def __init__(self, host,  user='root', password=None
                 , exchange_in='esa.events', exchange_out='esa.csc'):
        """Initializes ESA node with host, rabbitmq and mongo"""

        self.host = host
        self.exchange_in = exchange_in
        self.exchange_out = exchange_out
        self.mongo = MongoDB(self.host)
        self.rabbitmq = RabbitMQ(self.host, exchange_in, exchange_out)

class MultiEsa(unittest.TestCase):
    """Used for multi component ESA tests that publish through RabbitMQ and use Mongo."""

    def setUp(self):
        super(MultiEsa, self).setUp()

        #initialize test names and paths - consider reuse from CTF
        #TODO resue from CTF
        self.test_name = self.id().split('.').pop()
        self.test_case_name = self.__class__.__name__
        self.test_binary_name = os.path.basename(__file__)
        self.test_data_path = ''

        for argv in sys.argv:
            if 'test/' in argv:
                self.test_data_path = os.path.join(argv.split('/')[0]
                                                   , 'testdata'
                                                   , argv.split('/')[2]
                                                   , self.test_case_name
                                                   , self.test_name)

        # initialize test config
        self.config = json.loads(open('config.json').read())

        # initialize client for carlos-connect commands
        self.carlos_command_client = EsaClient(self.config['client'], 'root')

        self.esa_global = []
        for global_node in self.config['global']:
            esa_global = Esa(global_node['host']
                             , exchange_in=global_node['exchange-in']
                             , exchange_out=global_node['exchange-out'])
            self.esa_global.append(esa_global)

            self.carlos_command_client.remove_all_modules(target_host=global_node['host'])
            self.carlos_command_client.forward_remove(target_host=global_node['host'])
            esa_global.mongo.cleanup_mongo()

            if self.config['setup_aggregation'] == 'true':
                password = None
                if global_node.has_key('password'):
                    password = global_node['password']
                self._setup_aggregation(global_node['host'], user='root', password=password
                                       , exchange_in=global_node['exchange-in']
                                       , mode='SLIDING')

        self.esa_leafs = []
        for leaf in self.config['leaf']:
            esa_leaf = Esa(leaf['host']
                           , exchange_in=leaf['exchange-in']
                           , exchange_out=leaf['exchange-out'])
            self.esa_leafs.append(esa_leaf)

            self.carlos_command_client.remove_all_modules(target_host=leaf['host'])
            self.carlos_command_client.forward_remove(target_host=leaf['host'])

            esa_leaf.mongo.cleanup_mongo()

            if self.config['setup_aggregation'] == 'true':
                password = None
                if leaf.has_key('password'):
                    password = leaf['password']
                self._setup_aggregation(leaf['host'], user='root', password=password
                                       , exchange_in=leaf['exchange-in']
                                       , mode='DIRECT')

        self.esa_list = self.esa_global
        self.esa_list.extend(self.esa_leafs)

    def _setup_aggregation(self, host, user='root', password=None
                          , exchange_in='esa.csc', mode='SLIDING'
                          , time_field=None, lag=5):
        """Sets up message bus aggregation source, esper feeder mode
        and time sort field if applicable
        """

        client = EsaClient(host, user, password)
        client.enable_message_bus()
        client.remove_sources()
        client.add_source(exchange_in, time_field=time_field)
        client.setup_mode(mode, lag)
        client.shutdown()

    def tearDown(self):
        #cleanup epl modules and mongo only if configured
        if self.config['save_workspace'] == 'false':
            for esa in self.esa_list:
                esa.mongo.cleanup_mongo()
                self.carlos_command_client.remove_all_modules(target_host=esa.host)

        # in all cases try to close mongo, rabbitmq and ssh connections
        for esa in self.esa_list:
            esa.mongo.close()
            esa.rabbitmq.close()

        self.carlos_command_client.shutdown()

        super(MultiEsa, self).tearDown()

    def verify_alerts_count(self, esa, expected_alerts=0, wait=None):
        """Verifies the ESA component inserted the expected number of alerts in Mongo.

        Args:
            expected_alerts: the number of alerts expected (int)
            wait: initial wait time (int)
        """

        esa.mongo.wait_for_alerts(expected_alerts, wait=wait)
        alerts = esa.mongo.get_alerts()
        self.assertEqual(len(alerts), expected_alerts
                         , 'Expected %s leaf alerts got %s'
                         % (str(expected_alerts), str(len(alerts))))
