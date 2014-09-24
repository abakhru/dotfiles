#!/usr/bin/env python

#import logging
import os
import pika
import sys
import time
import simplejson as json

from bson import json_util
from pprint import pprint
from ctf.framework.logger import LOGGER

LOGGER.setLevel('DEBUG')

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

    def consume(self, timeout_secs=5, num_events_to_consume=None):
        """ Consumes the alerts/events from exchange_header specified.

        Args:
            output_file: file to dump the json output.
            timeout_secs: timeout in seconds, before Consumer stops.
            num_events_to_consume: events/alerts to consume from exchange_header.
        Returns:
            alerts/events list in JSON format.
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

                    LOGGER.debug('method_frame: %s' % method_frame)
                    LOGGER.debug('properties: %s' % properties.headers)
                    LOGGER.debug('body: %s' % body)

                    # Acknowledge the message
                    self.channel.basic_ack(method_frame.delivery_tag)
                    alert_json = json.dumps({"amqp_headers": properties.headers
                                             , "body": json.loads(body
                                             , object_hook=json_util.object_hook)})
                                             #, indent=2)
                    LOGGER.debug('RabbitMQ Alert notification in JSON format:\n%s', alert_json)
                    self.message_json_list.append(alert_json)
                    # Escape out of the loop after consuming expected number of messages
                    # or if timeout_secs happens
                    LOGGER.debug('num_events_to_consume: %d', self.num_events_to_consume)
                    duration = time.time() - start_time
                    if method_frame.delivery_tag is self._num_events_to_consume\
                       or duration > timeout_secs:
                        LOGGER.info('Stopping Consumer because either all messages consumed or'
                                     + ' timeout happened.')
                        break

                # Cancel the consumer and return any pending messages
                requeued_messages = self.channel.cancel()
                LOGGER.debug('Requeued %s messages' % requeued_messages)
                self.close()
                return self.message_json_list
            except Exception as e:
                LOGGER.error(e)


if __name__ == '__main__':
    file = '/Users/bakhra/tmp/t/corelation/testdata/forward_notification_test.py'\
            + '/ForwardNotificationCarlosTest/test_global_five_failures_alert/json_input.txt'
    file = '/Users/bakhra/source/server-ready/python/ctf/esa/testdata/basic_test.py/BasicESATest/test_up_and_down/json_input.txt'
    # Publishing
    pub = PublishRabbitMQ()
    #listen = ConsumeRabbitMQ(exchange_header='carlos.alerts')
    listen = ConsumerRabbitMQ(exchange_header='esa.events')
    #pub.publish(file, publish_interval=1)
    pub.publish(file)
    print '======'
    # Consuming
    messages = listen.consume(num_events_to_consume=pub.num_events_to_consume)
    if messages:
        for i in messages:
            print i
