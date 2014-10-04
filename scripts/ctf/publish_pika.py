#!/usr/bin/env python

#import logging
import os
import pika
import sys
import time
import simplejson as json

from bson import json_util
from collections import OrderedDict
from pprint import pprint
from ctf.framework.logger import LOGGER
from assertJSONAlmostEquals import AssertJSON

LOGGER.setLevel('DEBUG')

class RabbitMQPikaBase(object):

    @property
    def connected(self):
        return self._connected

    @property
    def  num_events_to_consume(self):
        return self._num_events_to_consume

    def __init__(self, host='localhost', port=5672, exchange_type='Event'
                 , exchange_header='esa.events', vhost='/rsa/sa', logdir=None
                 , exchange_user='guest', exchange_pass='guest', exchange_durable=False):

        self.host = host
        self.port = port
        self.exchange_header = exchange_header
        self.exchange_type = exchange_type
        self.exchange_durable = exchange_durable
        self.esa_binding = {'esa.event.type' : self.exchange_type}
        if 'carlos' in self.exchange_header:
            self.esa_binding = {'carlos.event.device.product': 'Event Stream Analysis'}
            self.exchange_durable = True
        self.vhost = vhost
        self.credentials = pika.PlainCredentials(exchange_user, exchange_pass)
        self.connParameters = pika.ConnectionParameters(host=self.host
                                                        , port=self.port
                                                        , virtual_host=vhost
                                                        , credentials=self.credentials)
        self.msgProperties = pika.BasicProperties(headers=self.esa_binding
                                                  , delivery_mode=1)
        self.connection = None
        self.channel = None
        self._num_events_to_consume = 0
        self._connected = False
        self.queue_name = None
        self.connect()

    def connect(self):
        try:
            LOGGER.debug('Connecting to AMQP Broker %s:%d for %s'
                         , self.host, self.port, self.__class__.__name__)
            self.connection = pika.BlockingConnection(self.connParameters)
            LOGGER.debug('%s connected', self.host)
            self.on_connected()
        except pika.exceptions.AMQPConnectionError:
            LOGGER.error('Cannot connect to RabbitMQ server on %s', self.host, exc_info=True)

    def on_connected(self):
        """ Declare exchange and queue and do the binding. """
        try:
            # Open the channel
            LOGGER.debug("Opening a channel")
            self.channel = self.connection.channel()
            if self.channel:
                LOGGER.debug('Channel opened successfully.')
            # Declare our exchange
            LOGGER.debug('Declaring the %s exchange.', self.exchange_header)
            self.channel.exchange_declare(exchange=self.exchange_header
                                          , type='headers'
                                          , durable=self.exchange_durable)
            # Declare our queue for this process
            result = self.channel.queue_declare(exclusive=True)
            self.queue_name = result.method.queue
            LOGGER.debug('Declaring the %s queue', self.queue_name)
            # Bind to the exchange
            self.channel.queue_bind(exchange=self.exchange_header
                                    , queue=self.queue_name
                                    , arguments=self.esa_binding)
            self._connected = True
        except Exception as e:
            LOGGER.error(e)

    def close(self):
        """ Close the channel and the connection"""
        LOGGER.debug('Closing RabbitMQ pika connections for %s.', self.__class__.__name__)
        self.channel.close()
        self.connection.close()


class PublishRabbitMQ(RabbitMQPikaBase):
    """ Class for publishing on RabbitMQ using pika library. """

    def __init__(self, *args, **kwargs):
        super(PublishRabbitMQ, self).__init__(*args, **kwargs)

    def publish(self, input_file=None, publish_interval=None):
        """ Publishes events from log file on exchange header provided.

        Args:
            input_file: file to read events and publish
            publish_interval: publish interval in seconds.

        Returns:
            True: if Publishing successful.
        """
        if self.connected:
            try:
                self.channel.confirm_delivery()
                start_time = time.time()
                with open(input_file) as f:
                    for line in f:
                        if self.channel.basic_publish(exchange=self.exchange_header
                                                      , routing_key=''
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

class ConsumerRabbitMQ(RabbitMQPikaBase):
    """ Class for consuming notification alerts/events from RabbitMQ using pika library.
    """

    def __init__(self, exchange_header='carlos.alerts', *args, **kwargs):
        """ Initializes RabbitMQ connection properties.

        Args:
            exchange_header: exchange header to consume the events from.
        """
        super(ConsumerRabbitMQ, self).__init__(exchange_header=exchange_header, *args, **kwargs)
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
                LOGGER.info('RabbitMQ Alert notification in JSON format:\n%s', json_formatted_doc)
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

        self.message_json_list = []
        self._num_events_to_consume = num_events_to_consume

        LOGGER.info('Consuming %d events from RabbitMQ', self.num_events_to_consume)
        if self.connected:
            try:
                start_time = time.time()
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
                    # Escape out of the loop after consuming expected number of messages
                    # or if timeout_secs happens
                    LOGGER.debug('num_events_to_consume: %d', self.num_events_to_consume)
                    duration = time.time() - start_time
                    if method_frame.delivery_tag is self._num_events_to_consume\
                       or duration > timeout_secs:
                        if method_frame.delivery_tag is self._num_events_to_consume:
                            LOGGER.info('Stopping Consumer because all expected number of messages consumed.')
                        if duration > timeout_secs:
                            LOGGER.info('Stopping Consumer because timeout happened.')
                        break

                self._prettyDumpJsonToFile(self.messages_ordered, 'consumed.json')
                # Cancel the consumer and return any pending messages
                requeued_messages = self.channel.cancel()
                LOGGER.debug('Requeued %s messages' % requeued_messages)
                self.close()
                return True
            except Exception as e:
                LOGGER.error(e)
                return False


if __name__ == '__main__':
    #file = '/Users/bakhra/tmp/t/corelation/testdata/forward_notification_test.py'\
    #        + '/ForwardNotificationCarlosTest/test_global_five_failures_alert/json_input.txt'
    #file = '/Users/bakhra/source/server-ready/python/ctf/esa/testdata/basic_test.py/BasicESATest/test_up_and_down/json_input.txt'
    #file = '/Users/bakhra/source/server-ready/python/ctf/esa/testdata/basic_test.py/BasicESATest/test_5_failures_1_success_alert/json_input.txt'
    file = '/Users/bakhra/source/server-ready/python/ctf/esa/testdata/esa_server_launch_test.py/'\
           + 'MultipleESAServerLaunchTest/test_multiple_esa_up_and_down/json_input.txt'
    # Publishing
    pub = PublishRabbitMQ()
    listen = ConsumerRabbitMQ(exchange_header='carlos.alerts')
    #listen = ConsumerRabbitMQ(exchange_header='esa.events')
    #pub.publish(file, publish_interval=1)
    pub.publish(file)
    print '======'
    # Consuming
    #listen.consume(num_events_to_consume=pub.num_events_to_consume)
    listen.consume(num_events_to_consume=2)
    #listen.PrettyDumpJson(messages, 'consumed.json')
    #a = AssertJSON()
    #a.assertJSONFileAlmostEqualsKnownGood('consumed.json', 'consumed.json'
    #                                      , ignorefields=['esa_time', 'carlos.event.signature.id', 'carlos.event.timestamp'])
