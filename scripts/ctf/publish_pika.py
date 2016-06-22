#!/usr/bin/env python
# unify/framework/utils/rabbitmq.py

"""RabbitMQ utilities for ASOC automation."""

import msgpack
import decimal
import logging
import os
import pika
import requests
import simplejson as json
import time
import urllib.request
import urllib.parse
import urllib.error

from bson import json_util
from pathlib import Path
from pika.credentials import PlainCredentials
from pika.credentials import ExternalCredentials
from ssl import CERT_REQUIRED

from framework.common.harness import SshCommandClient
from framework.common.logger import LOGGER

LOGGER.setLevel('DEBUG')


class RabbitMQBase(object):
    """ Base Class which establishes RabbitMQ connection for Publisher and Consumer."""

    @property
    def connected(self):
        return self._connected

    @property
    def num_events_to_consume(self):
        return self._num_events_to_consume

    # setting pika specific debug level.
    logging.getLogger('pika').setLevel(logging.INFO)

    def __init__(self, host='localhost', port=5672
                 , exchange_header='esa.events', vhost='/rsa/sa'
                 , exchange_user='guest', exchange_pass='guest', exchange_durable=False
                 , _type='headers', use_ssl=False, cert_dir='/tmp/rabbitmq'
                 , create_new_exchange=True, create_null_binding=False, custom_binding=None
                 , msgpack=False, auto_delete=False, internal=False, nowait=False):
        """ Initializes RabbitMQ connection parameters.

        Args:
            host: RabbitMQ server host to connect to, default is 'localhost' (str)
            port: RabbitMQ server port to bind to, default is 5672 (int)
            exchange_header: exchange header to publish to, default is 'esa.events' (str)
            vhost: virtual host to bind client connection. (default is '/rsa/sa') (str)
            exchange_user: RabbitMQ user that has access to specified vhost and exchange_header
                           (str)
            exchange_pass: RabbitMQ user's password that has access to specified vhost
                           and exchange_header (str)
            exchange_durable: if the declared exchange is durable or not. (bool)
            _type: type of the event. (str)
            use_ssl: enabled SSL connection to RabbitMQ server (bool)
            cert_dir: dir to store CA & server certs (str)
            create_new_exchange: If True a new exchange is created by the client (bool)
            create_null_binding: Replaces the default binding with null. Useful when we want to read
                                 from rabbitmq Queue (bool)
            custom_binding: Enables the use of custom headers when publishing messages (dict)
        """

        self.host = host
        self.port = port
        self.exchange_header = exchange_header
        self.exchange_durable = exchange_durable
        self.vhost = vhost
        self.ssl = use_ssl
        self.certs_dir = cert_dir
        if not os.path.exists(self.certs_dir):
            os.makedirs(self.certs_dir)
        self.ssl_options = dict()
        self.credentials = PlainCredentials(username=exchange_user, password=exchange_pass)
        if self.ssl:
            self.copy_ssl_certs()
            self.get_ssl_options()
        self.connParameters = pika.ConnectionParameters(host=self.host
                                                        , port=self.port
                                                        , virtual_host=vhost
                                                        , credentials=self.credentials
                                                        , ssl=self.ssl
                                                        , ssl_options=self.ssl_options)
        self.msgProperties = None
        self.connection = None
        self.channel = None
        self._num_events_to_consume = 0
        self._connected = False
        self.queue_name = None
        self._type = _type
        self.create_new_exchange = create_new_exchange
        self.create_null_binding = create_null_binding
        self.custom_binding = custom_binding
        self.msgpack = msgpack
        self.auto_delete = auto_delete
        self.internal = internal
        self.nowait = nowait

    def connect(self, binding=None, passive=False, listen=False):
        """ Connects to RabbitMQ server.

        Args:
            binding: binding type (dict)
            passive: rabbitmq connection passive value (bool)
            listen: rabbitmq connection listen value (bool)
        """

        if binding is None:
            binding = {'esa.event.type': 'Event'}
        try:
            LOGGER.debug('[RabbitMQBase] Connecting to AMQP Broker %s:%d for %s'
                         , self.host, self.port, self.__class__.__name__)
            self.connection = pika.BlockingConnection(self.connParameters)
            LOGGER.debug('[RabbitMQBase] %s connected', self.host)
            if self.connection:
                self._connected = True
            if self.connected:
                self.on_connected(binding, passive=passive, listen=listen)
        except ProbableAuthenticationError:
            raise ProbableAuthenticationError('RabbitMQ Guest auth failed')
        except AMQPConnectionError:
            LOGGER.error("[RabbitMQBase] Cannot connect to RabbitMQ server on '%s:%s'. Trying "
                         "again...", self.host, self.port, exc_info=True)
            time.sleep(1)
            self.connect(binding=binding, passive=passive, listen=listen)

    def on_connected(self, binding, passive, listen):
        """ Declare the exchange, queue and do the binding.

        Args:
            binding: binding type (dict)
            passive: rabbitmq connection passive value (bool)
            listen: rabbitmq connection listen value (bool)
        """

        esa_binding = binding
        if 'carlos' in self.exchange_header:
            esa_binding = {'carlos.event.device.product': 'Event Stream Analysis'}
            self.exchange_durable = True
        if self.custom_binding is not None:
            esa_binding = self.custom_binding
        if self.create_null_binding:
            esa_binding = None
        self.msgProperties = pika.BasicProperties(headers=esa_binding, delivery_mode=1)
        try:
            # Open the channel
            LOGGER.debug('[RabbitMQBase] Opening a channel')
            self.channel = self.connection.channel()
            if self.channel:
                LOGGER.debug('[RabbitMQBase] Channel opened successfully.')
            if self.create_new_exchange:
                LOGGER.debug('[RabbitMQBase] Declaring the %s exchange.', self.exchange_header)
                self.channel.exchange_declare(exchange=self.exchange_header
                                              , exchange_type=self._type
                                              , passive=passive
                                              , durable=self.exchange_durable
                                              , auto_delete=self.auto_delete
                                              , internal=self.internal
                                              , nowait=self.nowait)
            if listen:
                # Declare our queue for this process
                result = self.channel.queue_declare(exclusive=True)
                self.queue_name = result.method.queue
                LOGGER.debug('[RabbitMQBase] Declaring the %s queue', self.queue_name)
                # Bind to the exchange
                self.channel.queue_bind(exchange=self.exchange_header
                                        , queue=self.queue_name
                                        , arguments=esa_binding)
            if self.msgpack:
                self.msgProperties = pika.BasicProperties(delivery_mode=1
                                                          , content_type='application/msgpack'
                                                          , reply_to=self.queue_name)
        except AMQPChannelError as e:
            LOGGER.error(e)

    def on_timeout(self):
        self.connection.close()

    def delete_exchange(self):
        self.channel.exchange_delete(self.exchange_header)

    def close(self):
        """ Close the channel and client connection"""

        LOGGER.debug('[RabbitMQBase] Closing RabbitMQ pika connections for %s.'
                     , self.__class__.__name__)
        self.channel.close()
        self.connection.close()

    def get_ssl_options(self):
        """ Constructs ssl_options dict"""

        self.ssl_options = {'ca_certs': os.path.abspath(os.path.join(self.certs_dir
                                                                     , 'ca_cert.pem')),
                            'keyfile': os.path.abspath(os.path.join(self.certs_dir
                                                                    , self.host + '_key.pem')),
                            'certfile': os.path.abspath(os.path.join(self.certs_dir
                                                                     , self.host + '_cert.pem')),
                            'cert_reqs': ssl.CERT_NONE,
                            'ssl_version': ssl.PROTOCOL_TLSv1,
                            }

    def copy_ssl_certs(self):
        """ Copies SSL certs for RabbitMQ remote host """

        key_file = os.path.join(self.certs_dir, self.host + '_key.pem')
        cert_file = os.path.join(self.certs_dir, self.host + '_cert.pem')
        ca_cert_file = os.path.join(self.certs_dir, 'ca_cert.pem')
        if os.path.exists(key_file) and os.path.exists(cert_file) and os.path.exists(ca_cert_file):
            return
        else:
            _ssh = SshCommandClient(host=self.host, user='root', password='netwitness')
            rabbitmq_path = '/etc/rabbitmq/ssl/server'
            LOGGER.debug('Copying host SSL Key from "%s" RabbitMQ server host', self.host)
            _ssh.Get(source_file=os.path.join(rabbitmq_path, 'key.pem'), destination_file=key_file)
            LOGGER.debug('Copying host SSL cert from "%s" RabbitMQ server host', self.host)
            _ssh.Get(source_file=os.path.join(rabbitmq_path, 'cert.pem')
                     , destination_file=cert_file)
            LOGGER.debug('Copying CA SSL cert from "%s" RabbitMQ server host', self.host)
            parent_rabbitmq_path = str(Path(rabbitmq_path).parent)
            _ssh.Get(source_file=os.path.join(parent_rabbitmq_path, 'truststore.pem')
                     , destination_file=ca_cert_file)


class PublishRabbitMQ(RabbitMQBase):
    """ Class for publishing on RabbitMQ using pika library. """

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)

    def publish(self, input_file, binding=None, publish_interval=None
                , routing_key='', passive=False, listen=False):
        """ Publishes events from input file on exchange header provided.

        Args:
            input_file: file to read events from and publish (JSON)
            binding: rabbitmq exchange binding (str)
            publish_interval: publish interval in seconds.
                              Default is publishing as fast as possible.
            routing_key: the routing key (str)
            passive: if True the exchange is created on connect if it des not exist (bool)
            listen: if False a queue is not declared (bool)

        Returns:
            True if Publishing successful, False Otherwise
        """

        LOGGER.debug('Passing binding %s', binding)
        if binding is None:
            binding = {'esa.event.type': 'Event'}
        LOGGER.debug('[PublishRabbitMQ] Binding is : %s', binding)
        self.connect(binding=binding, passive=passive, listen=listen)
        if self.connected:
            try:
                delivered = False
                self.channel.confirm_delivery()
                start_time = time.time()
                with open(input_file) as f:
                    for line in f:
                        if self.msgpack:
                            line = {'topology': 'HttpPacket', 'event': json.loads(line)}
                            line = msgpack.dumps(line)
                        if self.channel.basic_publish(exchange=self.exchange_header
                                                      , routing_key=routing_key
                                                      , properties=self.msgProperties
                                                      , body=line
                                                      , mandatory=True):
                            self._num_events_to_consume += 1
                            LOGGER.debug('[PublishRabbitMQ] Message #%s publish was confirmed'
                                         , self._num_events_to_consume)
                            delivered = True
                        else:
                            LOGGER.error('[PublishRabbitMQ] Message could not be confirmed')
                            delivered = False
                        if publish_interval is not None:
                            LOGGER.debug('[PublishRabbitMQ] Sleeping for %s seconds '
                                         'before next publish', publish_interval)
                            time.sleep(publish_interval)
                duration = time.time() - start_time
                LOGGER.info('[PublishRabbitMQ] Published %i messages in %.4f seconds'
                            ' (%.2f messages per second) on exchange \'%s\''
                            , self._num_events_to_consume, duration
                            , (self._num_events_to_consume / duration)
                            , self.exchange_header)
                self.close()
                return delivered
            except AMQPError as e:
                LOGGER.error(e)
                return False


class ConsumerRabbitMQ(RabbitMQBase):
    """ Class for consuming notification alerts/events from RabbitMQ using pika library."""

    def __init__(self, exchange_header='carlos.alerts', binding=None, *args, **kwargs):
        """ Initializes RabbitMQ connection properties.

        Args:
            exchange_header: exchange header to consume the events from.
            binding: Enables consumer to attach to an exchange with custom binding (dict).
        """

        super().__init__(exchange_header=exchange_header, *args, **kwargs)
        LOGGER.info('Connecting consumer to RabbitMQ')
        self.connect(listen=True, binding=binding)
        self.timestamp = 'carlos.event.timestamp'
        self.message_json_list = list()

    @staticmethod
    def _pretty_dump_json_to_file(data, outfile):
        """ Pretty print and writes JSON output to file name provided.

        Args:
            data: JSON data to print (json)
            outfile: output file to write JSON data into (str)
        """

        with open(outfile, 'wb') as _file:
            _file.write(bytes('[\n', 'UTF-8'))
            _file.write(bytes('[\n', 'UTF-8'))
            for i in data:
                json_formatted_doc = json_util.dumps(json.loads(i), sort_keys=False, indent=4
                                                     , default=json_util.default)
                LOGGER.debug('[RabbitMQ] Alert notification in JSON format:\n%s'
                             , json_formatted_doc)
                _file.write(bytes(json_formatted_doc, 'UTF-8'))
                if i is not data[-1]:
                    _file.write(bytes(',\n', 'UTF-8'))
            _file.write(bytes('\n]\n', 'UTF-8'))
            _file.write(bytes(']\n', 'UTF-8'))
        return

    def consume(self, timeout_secs=5, num_events_to_consume=None, output_file=None
                , msgpack=False):
        """ Consumes the alerts/events from exchange_header specified.

        Args:
            timeout_secs: timeout in seconds, before Consumer stops.
            num_events_to_consume: events/alerts to consume from exchange_header.
            output_file: file to dump the json output.
            msgpack: to consume alert from msgpack format (bool)

        Returns:
            True if successful, False otherwise.
        """

        self._num_events_to_consume = num_events_to_consume
        self.connection.add_timeout(timeout_secs, self.on_timeout)
        LOGGER.info("[RabbitMQ] Consuming %d events from '%s' exchange"
                    , self.num_events_to_consume, self.exchange_header)
        if self.connected:
            try:
                # Get expected number of messages and break out
                for method_frame, properties, body in self.channel.consume(queue=self.queue_name):
                    prop_dict = dict()
                    for k, v in list(properties.headers.items()):
                        if isinstance(k, str):
                            prop_dict[k] = v
                        elif isinstance(k, bytes):
                            prop_dict[k.decode()] = v
                    properties.headers = prop_dict
                    # Display the message parts
                    if self.timestamp in properties.headers:
                        properties.headers[self.timestamp] = str(properties.headers[self.timestamp])
                    # converting properties.headers to JSON
                    prop_json = json_util.dumps(properties.headers)
                    # creating dict from JSON objects
                    if self.msgpack:
                        body = msgpack.loads(body)
                    body_dict = json.loads(body.decode())
                    prop_dict = json.loads(prop_json)
                    # creating merged alert JSON object
                    alert_dict = dict(list(body_dict.items()) + list(prop_dict.items()))
                    alert_json = json.dumps(alert_dict)
                    self.message_json_list.append(alert_json)
                    # Acknowledge the message
                    self.channel.basic_ack(method_frame.delivery_tag)
                    if method_frame.delivery_tag == self._num_events_to_consume:
                        LOGGER.info('[RabbitMQ] Stopping Consumer because all expected number'
                                    'of messages consumed.')
                        break
                self._pretty_dump_json_to_file(self.message_json_list, output_file)
                # Cancel the consumer and return any pending messages
                requeued_messages = self.channel.cancel()
                LOGGER.debug('Re-queued %s messages', requeued_messages)
                self.close()
                return True
            except AMQPError as e:
                LOGGER.error('[RabbitMQ] Expected number of alerts not found. Consumer Timed Out!!')
                LOGGER.error(str(e))
                return False


if __name__ == '__main__':
    #log_dir = '/Users/bakhra/source/esa/python/ctf/esa/testdata/epl_test.py/EPLModulesTest/test_eventtype_double'
    log_dir = '.'
    # Publishing
    certs_dir = './ssl_dir'
    # sa_host = '10.40.13.191'
    sa_host = 'localhost'
    # 5672 is default non-ssl port
    # 5671 is default SSL port
    # openssl s_client -connect 10.40.13.191:5671 -cert ./ssl_dir/10.40.13.191_cert.pem -key ./ssl_dir/10.40.13.191_key.pem -CAfile ./ssl_dir/ca_cert.pem
    pub1 = PublishRabbitMQ(host=sa_host, port=5672
                           , exchange_header='esa-analytics-server'
                           , use_ssl=False
                           , cert_dir=certs_dir
                           , exchange_durable=False
                           , msgpack=True
                           , _type='topic'
                           , auto_delete=True)
    # San Francisco
    #pub2 = PublishRabbitMQ(host='10.101.216.223', port=5671
    #                       , exchange_header='esa.event.input', ssl=True
    #                       , ssl_options=get_ssl_options('10.101.216.223')
    #                       , exchange_durable=True)
    #pub3 = PublishRabbitMQ(host='10.101.216.227', exchange_header='esa.events')
    #pub2 = PublishRabbitMQ(exchange_header='esa.events1')
    #pub3 = PublishRabbitMQ(exchange_header='esa.events2')
    # New York
    #listen = ConsumerRabbitMQ(host='10.101.216.227', port=5671, exchange_header='carlos.alerts'
    #                          , ssl=True, ssl_options=get_ssl_options('10.101.216.227'))
    listen = ConsumerRabbitMQ(exchange_header='carlos.alerts')
    #pub.publish(file, publish_interval=1)
    pub1.publish(input_file=os.path.join(log_dir, 'json_input.txt')
                 , routing_key='esa-analytics-server.any./rsa/analytics/topology/temp-inject')
    #pub2.publish(input_file=os.path.join(log_dir, '1s.txt'))
    #pub2.publish(input_file=os.path.join(log_dir, 'json_input.txt'))
    #pub3.publish(input_file=os.path.join(log_dir, 'json_input.txt'))
    #pub1.publish(input_file=os.path.join(log_dir, 'default' + '_json_input.txt'))
    #time.sleep(1)
    #pub2.publish(input_file=os.path.join(log_dir, 'test' + '_json_input.txt'))
    #pub3.publish(input_file=os.path.join(log_dir, 'global' + '_json_input.txt'))
    print('======')
    # Consuming
    #listen.consume(num_events_to_consume=pub.num_events_to_consume)
    listen.consume(num_events_to_consume=4, output_file='consumed.json')
    #a = AssertJSON()
    #a.assertJSONFileAlmostEqualsKnownGood('consumed.json', 'consumed.json'
    #                                      , ignorefields=['esa_time', 'carlos.event.signature.id'
    #                                      , 'carlos.event.timestamp'])
