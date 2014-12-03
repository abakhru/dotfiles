#!/usr/bin/env python

#import logging
import os
import pika
import signal
import sys
import time
import simplejson as json

from bson import json_util
from collections import OrderedDict
from pprint import pprint
from ctf.framework.logger import LOGGER
from assertJSONAlmostEquals import AssertJSON

LOGGER.setLevel('DEBUG')


class RabbitMQBase(object):
    """ Base Class which establishes RabbitMQ connection for Publisher and Consumer."""

    @property
    def connected(self):
        return self._connected

    @property
    def  num_events_to_consume(self):
        return self._num_events_to_consume

    # setting pika specific debug level.
    #logging.getLogger('pika').setLevel(logging.INFO)

    def __init__(self, host='localhost', port=5672
                 , exchange_header='esa.events', vhost='/rsa/sa', logdir=None
                 , exchange_user='guest', exchange_pass='guest', exchange_durable=False
                 , _type='headers'):
        """ Initializes RabbitMQ connection parameters.

        Args:
            host: RabbitMQ server host to connect to, default is 'localhost'
            port: RabbitMQ server port to bind to, default is 5672
            exchange_header: exchange header to publish to, default is 'esa.events'
            vhost: virtual host to bind client connection. (default is '/rsa/sa')
            logdir: logdir to log pika.log
            exchange_user: RabbitMQ user that has access to specified vhost and exchange_header
            exchange_pass: RabbitMQ user's password that has access to specified vhost
                           and exchange_header
            exchange_durable: if the declared exchange is durable or not.
        """

        self.host = host
        self.port = port
        self.exchange_header = exchange_header
        self.exchange_durable = exchange_durable
        self.vhost = vhost
        self.credentials = pika.PlainCredentials(exchange_user, exchange_pass)
        self.connParameters = pika.ConnectionParameters(host=self.host
                                                        , port=self.port
                                                        , virtual_host=vhost
                                                        , credentials=self.credentials)
        self.msgProperties = None
        self.connection = None
        self.channel = None
        self._num_events_to_consume = 0
        self._connected = False
        self.queue_name = None
        self._type = _type

    def connect(self, exchange_type='Event', passive=False, listen=False):
        """ Connects to RabbitMQ server.

        Args:
            exchange_type: exchange header type (str)
        """
        try:
            LOGGER.debug('Connecting to AMQP Broker %s:%d for %s'
                         , self.host, self.port, self.__class__.__name__)
            self.connection = pika.BlockingConnection(self.connParameters)
            LOGGER.debug('%s connected', self.host)
            self.on_connected(exchange_type, passive=passive, listen=listen)
        except pika.exceptions.AMQPConnectionError:
            LOGGER.error('Cannot connect to RabbitMQ server on %s', self.host, exc_info=True)

    def on_connected(self, exchange_type, passive, listen):
        """ Declare the exchange, queue and do the binding."""

        esa_binding = {'esa.event.type' : exchange_type}
        if 'carlos' in self.exchange_header:
            esa_binding = {'carlos.event.device.product': 'Event Stream Analysis'}
            self.exchange_durable = True
        self.msgProperties = pika.BasicProperties(headers=esa_binding
                                                  , delivery_mode=1)

        try:
            # Open the channel
            LOGGER.debug("Opening a channel")
            self.channel = self.connection.channel()
            if self.channel:
                LOGGER.debug('Channel opened successfully.')
            # Declare our exchange
            LOGGER.debug('Declaring the %s exchange.', self.exchange_header)
            self.channel.exchange_declare(exchange=self.exchange_header
                                          , type=self._type
                                          , passive=passive
                                          , durable=self.exchange_durable)
            if listen:
                # Declare our queue for this process
                result = self.channel.queue_declare(exclusive=True)
                self.queue_name = result.method.queue
                LOGGER.debug('Declaring the %s queue', self.queue_name)
                # Bind to the exchange
                self.channel.queue_bind(exchange=self.exchange_header
                                        , queue=self.queue_name
                                        , arguments=esa_binding)
            self._connected = True
        except Exception as e:
            LOGGER.error(e)


    def on_timeout(self):
          self.connection.close()

    def delete_exchange(self):
        self.channel.exchange_delete(self.exchange_header)

    def close(self):
        """ Close the channel and client connection"""
        LOGGER.debug('Closing RabbitMQ pika connections for %s.', self.__class__.__name__)
        self.channel.close()
        self.connection.close()


class PublishRabbitMQ(RabbitMQBase):
    """ Class for publishing on RabbitMQ using pika library. """

    def __init__(self, *args, **kwargs):
        super(PublishRabbitMQ, self).__init__(*args, **kwargs)

    def publish(self, input_file, publish_interval=None
                , event_type='Event', routing_key='', passive=False, listen=False):
        """ Publishes events from input file on exchange header provided.

        Args:
            input_file: file to read events from and publish
            publish_interval: publish interval in seconds.
                              Default is publishing as fast as possible.
            event_type: the type of the published event (str)
            routing_key: the routing key (str)
            passive: if True the exchange is created on connect if it des not exist (bool)
            listen: if False a queue is not declared (bool)

        Returns:
            True if Publishing successful, False Otherwise
        """
        self.connect(exchange_type=event_type, passive=passive, listen=listen)
        if self.connected:
            try:
                delivered = False
                self.channel.confirm_delivery()
                start_time = time.time()
                with open(input_file) as f:
                    for line in f:
                        if self.channel.basic_publish(exchange=self.exchange_header
                                                      , routing_key=routing_key
                                                      , properties=self.msgProperties
                                                      , body=line
                                                      , mandatory=True):
                            self._num_events_to_consume += 1
                            LOGGER.debug('Message #%s publish was confirmed'
                                         , self._num_events_to_consume)
                            delivered = True
                        else:
                            LOGGER.error('Message could not be confirmed')
                            delivered = False
                        if publish_interval is not None:
                            LOGGER.debug('Sleeping for %s seconds before next publish'
                                         , publish_interval)
                            time.sleep(publish_interval)
                duration = time.time() - start_time
                LOGGER.info('Published %i messages in %.4f seconds (%.2f messages per second)'
                            , self._num_events_to_consume, duration
                            , (self._num_events_to_consume/duration))
                self.close()
                return delivered
            except Exception as e:
                LOGGER.error(e)
                return False

class ConsumerRabbitMQ(RabbitMQBase):
    """ Class for consuming notification alerts/events from RabbitMQ using pika library."""

    def __init__(self, exchange_header='carlos.alerts', *args, **kwargs):
        """ Initializes RabbitMQ connection properties.

        Args:
            exchange_header: exchange header to consume the events from.
        """
        super(ConsumerRabbitMQ, self).__init__(exchange_header=exchange_header, *args, **kwargs)
        LOGGER.info('Connecting consumer to RabbitMQ')
        self.connect(listen=True)
        self.timestamp = 'carlos.event.timestamp'
        self.message_json_list = []

    def _prettyDumpJsonToFile(self, data, outfile):
        """ Pretty print and writes JSON output to file name provided."""
        with open(outfile, 'w') as _file:
            _file.write('[\n')
            _file.write('[\n')
            for i in data:
                json_formatted_doc = json_util.dumps(json.loads(i), sort_keys=False, indent=4
                                                     , default=json_util.default)
                LOGGER.debug('[RabbitMQ] Alert notification in JSON format:\n%s', json_formatted_doc)
                _file.write(json_formatted_doc)
                if i is not data[-1]:
                    _file.write(',\n')
            _file.write('\n]')
            _file.write('\n]')
        return

    def consume(self, timeout_secs=5, num_events_to_consume=None, output_file=None):
        """ Consumes the alerts/events from exchange_header specified.

        Args:
            timeout_secs: timeout in seconds, before Consumer stops.
            num_events_to_consume: events/alerts to consume from exchange_header.
            output_file: file to dump the json output.
        Returns:
            True if successful, False otherwise.
        """
        self._num_events_to_consume = num_events_to_consume
        self.connection.add_timeout(timeout_secs, self.on_timeout)

        LOGGER.info('Consuming %d events from RabbitMQ', self.num_events_to_consume)
        if self.connected:
            try:
                # Get expected number of messages and break out
                for method_frame, properties, body in self.channel.consume(queue=self.queue_name):
                    # Display the message parts
                    if self.timestamp in properties.headers:
                        properties.headers[self.timestamp] = str(properties.headers[self.timestamp])
                    # converting properties.headers to JSON
                    prop_json = json_util.dumps(properties.headers)
                    # creating dict from JSON objects
                    body_dict = json.loads(body)
                    prop_dict = json.loads(prop_json)
                    # creating merged alert JSON object
                    alert_dict = dict(body_dict.items() + prop_dict.items())
                    alert_json = json.dumps(alert_dict)
                    self.message_json_list.append(alert_json)
                    # Acknowledge the message
                    self.channel.basic_ack(method_frame.delivery_tag)
                    if method_frame.delivery_tag == self._num_events_to_consume:
                        LOGGER.info('Stopping Consumer because all expected number of messages consumed.')
                        break

                self._prettyDumpJsonToFile(self.message_json_list, output_file)
                # Cancel the consumer and return any pending messages
                requeued_messages = self.channel.cancel()
                LOGGER.debug('Requeued %s messages' % requeued_messages)
                self.close()
                return True
            except Exception as e:
                LOGGER.error('[RabbitMQ] Expected number of alerts not found. Consumer Timed Out!!')
                return False


if __name__ == '__main__':
    #file = '/Users/bakhra/tmp/t/corelation/testdata/forward_notification_test.py'\
    #        + '/ForwardNotificationCarlosTest/test_global_five_failures_alert/json_input.txt'
    #file = '/Users/bakhra/source/server-ready/python/ctf/esa/testdata/basic_test.py/BasicESATest/test_up_and_down/json_input.txt'
    #file = '/Users/bakhra/source/server-ready/python/ctf/esa/testdata/basic_test.py/BasicESATest/test_5_failures_1_success_alert/json_input.txt'
    log_dir = '/Users/bakhra/source/esa/python/ctf/esa/testdata/multi_esper_engines_test.py/'\
              + 'MultiEsperEnginesTest/test_past_events_drop_between_default_global'
    # Publishing
    pub1 = PublishRabbitMQ(exchange_header='esa.events')
    #pub2 = PublishRabbitMQ(exchange_header='esa.events1')
    #pub3 = PublishRabbitMQ(exchange_header='esa.events2')
    listen = ConsumerRabbitMQ(exchange_header='carlos.alerts')
    #listen = ConsumerRabbitMQ(exchange_header='esa.events')
    #pub.publish(file, publish_interval=1)
    #pub1.publish(input_file=os.path.join(log_dir, 'json_input.txt'))
    pub1.publish(input_file=os.path.join(log_dir, 'default' + '_json_input.txt'))
    #pub2.publish(input_file=os.path.join(log_dir, 'test' + '_json_input.txt'))
    #pub3.publish(input_file=os.path.join(log_dir, 'global' + '_json_input.txt'))
    print '======'
    # Consuming
    #listen.consume(num_events_to_consume=pub.num_events_to_consume)
    listen.consume(num_events_to_consume=1, output_file='consumed.json')
    #a = AssertJSON()
    #a.assertJSONFileAlmostEqualsKnownGood('consumed.json', 'consumed.json'
    #                                      , ignorefields=['esa_time', 'carlos.event.signature.id', 'carlos.event.timestamp'])
