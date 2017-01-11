#!/usr/bin/env python

import os
import optparse
import timeit
import logging
import pika
import json
import itertools

from multiprocessing.pool import ThreadPool

from framework.common.logger import LOGGER
from framework.utils.rabbitmq.rabbitmq import PublishRabbitMQ

# LOGGER.setLevel('DEBUG')
VHOST = '/'
DEFAULT_AMQP_HEADER = {'carlos.event.version': '1',
                       'carlos.event.timestamp': '2016-10-27T10:03:27.482Z',
                       'carlos.event.signature_id': '003b7c31-22fa-'
                                                    '43c6-8c0b-0eb18e7e33aa',
                       'carlos.event.device.vendor': 'RSA',
                       'carlos.event.device.product': 'Event Stream Analysis',
                       'carlos.event.device.version': '11.0.0000',
                       'carlos.event.severity': 5,
                       'carlos.event.name': 'P2P software as detected by'
                                            ' an Intrusion detection device'}
template_file = 'c2_alert_template.json'
with open(template_file) as f:
    alert = f.readlines()

ALERT_TEMPLATE = alert[0].rstrip()
FILE_LIST = list()

if not FILE_LIST:
    FILE_LIST = [os.path.join(r, f) for r, d, fs in os.walk('.')
                 for f in fs if f.startswith('final_999')]
print('=== FILE_LIST: {}'.format(FILE_LIST))

LOG_FORMAT = ('%(levelname) -10s %(asctime)s %(name) -30s %(funcName) '
              '-35s %(lineno) -5d: %(message)s')
LOGGER = logging.getLogger(__name__)


class AsyncPublisher(object):
    """This is an example publisher that will handle unexpected interactions
    with RabbitMQ such as channel and connection closures.

    If RabbitMQ closes the connection, it will reopen it. You should
    look at the output, as there are limited reasons why the connection may
    be closed, which usually are tied to permission related issues or
    socket timeouts.

    It uses delivery confirmations and illustrates one way to keep track of
    messages that have been sent and if they've been confirmed by RabbitMQ.

    """
    EXCHANGE = 'carlos.alerts'
    EXCHANGE_TYPE = 'headers'
    PUBLISH_INTERVAL = 1
    QUEUE = 'im.alert_queue'
    ROUTING_KEY = ''

    def __init__(self, amqp_url, input_file):
        """Setup the example publisher object, passing in the URL we will use
        to connect to RabbitMQ.

        :param str amqp_url: The URL for connecting to RabbitMQ
        """

        self._connection = None
        self._channel = None
        self._deliveries = []
        self._acked = 0
        self._nacked = 0
        self._message_number = 0
        self._stopping = False
        self._url = amqp_url
        self._closing = False
        self.input_file = None

    def connect(self):
        """This method connects to RabbitMQ, returning the connection handle.
        When the connection is established, the on_connection_open method
        will be invoked by pika. If you want the reconnection to work, make
        sure you set stop_ioloop_on_close to False, which is not the default
        behavior of this adapter.

        :rtype: pika.SelectConnection

        """
        LOGGER.info('Connecting to %s', self._url)
        return pika.SelectConnection(pika.URLParameters(self._url)
                                     , self.on_connection_open
                                     , stop_ioloop_on_close=False)

    def on_connection_open(self, unused_connection):
        """This method is called by pika once the connection to RabbitMQ has
        been established. It passes the handle to the connection object in
        case we need it, but in this case, we'll just mark it unused.

        :type unused_connection: pika.SelectConnection

        """
        LOGGER.info('Connection opened')
        self.add_on_connection_close_callback()
        self.open_channel()

    def add_on_connection_close_callback(self):
        """This method adds an on close callback that will be invoked by pika
        when RabbitMQ closes the connection to the publisher unexpectedly."""

        LOGGER.info('Adding connection close callback')
        self._connection.add_on_close_callback(self.on_connection_closed)

    def on_connection_closed(self, connection, reply_code, reply_text):
        """This method is invoked by pika when the connection to RabbitMQ is
        closed unexpectedly. Since it is unexpected, we will reconnect to
        RabbitMQ if it disconnects.

        :param pika.connection.Connection connection: The closed connection obj
        :param int reply_code: The server provided reply_code if given
        :param str reply_text: The server provided reply_text if given

        """
        self._channel = None
        if self._closing:
            self._connection.ioloop.stop()
        else:
            LOGGER.warning('Connection closed, reopening in 5 seconds: (%s) %s'
                           , reply_code, reply_text)
            self._connection.add_timeout(5, self.reconnect)

    def reconnect(self):
        """Will be invoked by the IOLoop timer if the connection is
        closed. See the on_connection_closed method."""
        self._deliveries = []
        self._acked = 0
        self._nacked = 0
        self._message_number = 0

        # This is the old connection IOLoop instance, stop its ioloop
        self._connection.ioloop.stop()

        # Create a new connection
        self._connection = self.connect()

        # There is now a new connection, needs a new ioloop to run
        self._connection.ioloop.start()

    def open_channel(self):
        """This method will open a new channel with RabbitMQ by issuing the
        Channel.Open RPC command. When RabbitMQ confirms the channel is open
        by sending the Channel.OpenOK RPC reply, the on_channel_open method
        will be invoked.

        """
        LOGGER.info('Creating a new channel')
        self._connection.channel(on_open_callback=self.on_channel_open)

    def on_channel_open(self, channel):
        """This method is invoked by pika when the channel has been opened.
        The channel object is passed in so we can make use of it.

        Since the channel is now open, we'll declare the exchange to use.

        :param pika.channel.Channel channel: The channel object

        """
        LOGGER.info('Channel opened')
        self._channel = channel
        self.add_on_channel_close_callback()
        self.setup_exchange(self.EXCHANGE)

    def add_on_channel_close_callback(self):
        """This method tells pika to call the on_channel_closed method if
        RabbitMQ unexpectedly closes the channel.

        """
        LOGGER.info('Adding channel close callback')
        self._channel.add_on_close_callback(self.on_channel_closed)

    def on_channel_closed(self, channel, reply_code, reply_text):
        """Invoked by pika when RabbitMQ unexpectedly closes the channel.
        Channels are usually closed if you attempt to do something that
        violates the protocol, such as re-declare an exchange or queue with
        different parameters. In this case, we'll close the connection
        to shutdown the object.

        :param pika.channel.Channel: The closed channel
        :param int reply_code: The numeric reason the channel was closed
        :param str reply_text: The text reason the channel was closed

        """
        LOGGER.warning('Channel was closed: (%s) %s', reply_code, reply_text)
        if not self._closing:
            self._connection.close()

    def setup_exchange(self, exchange_name):
        """Setup the exchange on RabbitMQ by invoking the Exchange.Declare RPC
        command. When it is complete, the on_exchange_declareok method will
        be invoked by pika.

        :param str|unicode exchange_name: The name of the exchange to declare

        """
        LOGGER.info('Declaring exchange %s', exchange_name)
        self._channel.exchange_declare(self.on_exchange_declareok
                                       , exchange=exchange_name
                                       , type=self.EXCHANGE_TYPE
                                       , durable=True)

    def on_exchange_declareok(self, unused_frame):
        """Invoked by pika when RabbitMQ has finished the Exchange.Declare RPC
        command.

        :param pika.Frame.Method unused_frame: Exchange.DeclareOk response frame

        """
        LOGGER.info('Exchange declared')
        self.setup_queue(self.QUEUE)

    def setup_queue(self, queue_name):
        """Setup the queue on RabbitMQ by invoking the Queue.Declare RPC
        command. When it is complete, the on_queue_declareok method will
        be invoked by pika.

        :param str|unicode queue_name: The name of the queue to declare.

        """
        LOGGER.info('Declaring queue %s', queue_name)
        self._channel.queue_declare(self.on_queue_declareok
                                    , queue_name
                                    , durable=True)

    def on_queue_declareok(self, method_frame):
        """Method invoked by pika when the Queue.Declare RPC call made in
        setup_queue has completed. In this method we will bind the queue
        and exchange together with the routing key by issuing the Queue.Bind
        RPC command. When this command is complete, the on_bindok method will
        be invoked by pika.

        :param pika.frame.Method method_frame: The Queue.DeclareOk frame

        """
        LOGGER.info('Binding %s to %s with %s'
                    , self.EXCHANGE, self.QUEUE, self.ROUTING_KEY)
        self._channel.queue_bind(self.on_bindok, self.QUEUE
                                 , self.EXCHANGE, self.ROUTING_KEY)

    def on_bindok(self, unused_frame):
        """This method is invoked by pika when it receives the Queue.BindOk
        response from RabbitMQ. Since we know we're now setup and bound, it's
        time to start publishing."""
        LOGGER.info('Queue bound')
        self.start_publishing()

    def start_publishing(self):
        """This method will enable delivery confirmations and schedule the
        first message to be sent to RabbitMQ

        """
        LOGGER.info('Issuing consumer related RPC commands')
        self.enable_delivery_confirmations()
        self.schedule_next_message()

    def enable_delivery_confirmations(self):
        """Send the Confirm.Select RPC method to RabbitMQ to enable delivery
        confirmations on the channel. The only way to turn this off is to close
        the channel and create a new one.

        When the message is confirmed from RabbitMQ, the
        on_delivery_confirmation method will be invoked passing in a Basic.Ack
        or Basic.Nack method from RabbitMQ that will indicate which messages it
        is confirming or rejecting.

        """
        LOGGER.info('Issuing Confirm.Select RPC command')
        self._channel.confirm_delivery(self.on_delivery_confirmation)

    def on_delivery_confirmation(self, method_frame):
        """Invoked by pika when RabbitMQ responds to a Basic.Publish RPC
        command, passing in either a Basic.Ack or Basic.Nack frame with
        the delivery tag of the message that was published. The delivery tag
        is an integer counter indicating the message number that was sent
        on the channel via Basic.Publish. Here we're just doing house keeping
        to keep track of stats and remove message numbers that we expect
        a delivery confirmation of from the list used to keep track of messages
        that are pending confirmation.

        :param pika.frame.Method method_frame: Basic.Ack or Basic.Nack frame

        """
        confirmation_type = method_frame.method.NAME.split('.')[1].lower()
        LOGGER.info('Received %s for delivery tag: %i'
                    , confirmation_type
                    , method_frame.method.delivery_tag)
        if confirmation_type == 'ack':
            self._acked += 1
        elif confirmation_type == 'nack':
            self._nacked += 1
        self._deliveries.remove(method_frame.method.delivery_tag)
        LOGGER.info('Published %i messages, %i have yet to be confirmed, '
                    '%i were acked and %i were nacked'
                    , self._message_number, len(self._deliveries)
                    , self._acked, self._nacked)

    def schedule_next_message(self):
        """If we are not closing our connection to RabbitMQ, schedule another
        message to be delivered in PUBLISH_INTERVAL seconds.

        """
        if self._stopping:
            return
        LOGGER.info('Scheduling next message for %0.1f seconds'
                    , self.PUBLISH_INTERVAL)
        self._connection.add_timeout(self.PUBLISH_INTERVAL
                                     , self.publish(input_file='final_c2_alert_template.json'))

    def publish(self):
        """If the class is not stopping, publish a message to RabbitMQ,
        appending a list of deliveries with the message number that was sent.
        This list will be used to check for delivery confirmations in the
        on_delivery_confirmations method.

        Once the message has been sent, schedule another message to be sent.
        The main reason I put scheduling in was just so you can get a good idea
        of how the process is flowing by slowing down and speeding up the
        delivery intervals by changing the PUBLISH_INTERVAL constant in the
        class.

        """
        if self._stopping:
            return

        with open(self.input_file) as f:
            for i in itertools.zip_longest(*[f]*batch_size):
                message = [json.loads(j) for j in list(i)]
                properties = pika.BasicProperties(delivery_mode=1
                                                  , content_type='application/json'
                                                  , reply_to=self.QUEUE)

                self._channel.basic_publish(self.EXCHANGE, self.ROUTING_KEY
                                            , json.dumps(message, ensure_ascii=False)
                                            , properties)
                self._message_number += 1
                self._deliveries.append(self._message_number)
                LOGGER.info('Published message # %i', self._message_number)
                self.schedule_next_message()

    def close_channel(self):
        """Invoke this command to close the channel with RabbitMQ by sending
        the Channel.Close RPC command."""
        LOGGER.info('Closing the channel')
        if self._channel:
            self._channel.close()

    def run(self):
        """Run the example code by connecting and then starting the IOLoop."""
        self._connection = self.connect()
        self._connection.ioloop.start()

    def stop(self):
        """Stop the example by closing the channel and connection. We
        set a flag here so that we stop scheduling new messages to be
        published. The IOLoop is started because this method is
        invoked by the Try/Catch below when KeyboardInterrupt is caught.
        Starting the IOLoop again will allow the publisher to cleanly
        disconnect from RabbitMQ.

        """
        LOGGER.info('Stopping')
        self._stopping = True
        self.close_channel()
        self.close_connection()
        self._connection.ioloop.start()
        LOGGER.info('Stopped')

    def close_connection(self):
        """This method closes the connection to RabbitMQ."""
        LOGGER.info('Closing connection')
        self._closing = True
        self._connection.close()


class AlertsGenerator(object):

    def __init__(self, o_dir, prefix, template=None, no_alerts=10000):
        file_list = list()
        final_alert_list = list()
        if template is None:
            template = ALERT_TEMPLATE
        for i in range(no_alerts):
            a = template.replace('AAAA', '{}{}'.format(prefix, str(i)))
            final_alert_list.append(a)
        file_name = os.path.join(o_dir, 'final_{}{}'.format(prefix, template_file))
        file_list.append(file_name)
        with open(file_name, 'wb') as _file:
            _file.write(bytes('\n'.join(final_alert_list), 'UTF-8'))
        LOGGER.info('{} file created with {} alerts'.format(file_name, no_alerts))


class ResponseBatchPublishing(object):

    def __init__(self, file):
        self.file = file
        self.publisher = PublishRabbitMQ(exchange_header='carlos.alerts'
                                         , vhost=VHOST
                                         , exchange_durable=True
                                         , create_new_exchange=False
                                         , host=ANA_HOST
                                         , custom_binding=DEFAULT_AMQP_HEADER)
        LOGGER.info('Starting publishing alerts using {} publisher'.format(self.publisher))
        self.publisher.publish(input_file=self.file)

        # logging.basicConfig(level=logging.INFO, format=LOG_FORMAT)
        # # Connect to localhost:5672 as guest with the password guest and virtual host "/" (%2F)
        # example = AsyncPublisher('amqp://guest:guest@{}:5672/'
        #                          '%2F?connection_attempts=3&heartbeat_interval=3600'.format(ANA_HOST)
        #                          , input_file=self.file)
        # try:
        #     example.run()
        # except KeyboardInterrupt:
        #     example.stop()


def loadArgs():
    """ get command line arguments """

    defaults = {'file': 'json_input.txt',
                'server': 'localhost'}

    usage = ('%prog [options] \n\n{}'.format(__doc__))
    parser = optparse.OptionParser(usage=usage)
    parser.add_option('-f', '--file',
                      type='str', action='store', dest='file',
                      default=defaults['file'],
                      help='event in json file to publish')
    parser.add_option('-s', '--server',
                      type='str', action='store', dest='server',
                      default=defaults['server'],
                      help='hostname to publish')
    return parser.parse_args()

def generate_testdata():
    # Generating separate files with 1million alerts with unique event_source_id
    number_of_threads = 10
    alert_tuple = list()
    [alert_tuple.append(('.'
                        , '999{}'.format(i)
                        , ALERT_TEMPLATE
                        , 100000)) for i in range(number_of_threads)]
    pool = ThreadPool(number_of_threads)
    pool.starmap(AlertsGenerator, alert_tuple)
    pool.close()
    pool.join()


if __name__ == '__main__':

    options = loadArgs()[0]
    log_path = options.file
    ANA_HOST = options.server
    number_of_thread = 10

    # os.system('rm -rf final*.json')
    generate_testdata()

    # # creating publisher threads that publishes unique files generated above
    # start_time = timeit.default_timer()
    # pool = ThreadPool(number_of_thread)
    # pool.map(ResponseBatchPublishing, FILE_LIST)
    # pool.close()
    # pool.join()
    # print(timeit.default_timer() - start_time)

    # cleaning up used files
    # os.system('rm -rf final*.json')
