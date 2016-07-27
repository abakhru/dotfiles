#!/usr/bin/env python

import optparse

from framework.common.logger import LOGGER
from framework.utils.rabbitmq.rabbitmq import ConsumerRabbitMQ
from framework.utils.rabbitmq.rabbitmq import PublishRabbitMQ
from framework.utils.rabbitmq.rabbitmq import RabbitMQClient

LOGGER.setLevel('DEBUG')

def loadArgs():
    """ get command line arguments """

    defaults = {'file': 'json_input.txt'}

    usage = ('%prog [options] \n\n{}'.format(__doc__))
    parser = optparse.OptionParser(usage=usage)
    parser.add_option('-f', '--file',
                      type='str', action='store', dest='file',
                      default=defaults['file'],
                      help='event in json file to publish')
    # LOGGER.debug('args: {}'.format(parser.parse_args))
    return parser.parse_args()


if __name__ == '__main__':
    options = loadArgs()[0]
    log_path = options.file
    print(log_path)
    publisher = PublishRabbitMQ(exchange_header='esa-analytics-server'
                                 , exchange_durable=False
                                 , use_msgpack=True
                                 , use_ssl=False
                                 , port=5672
                                 , _type='topic'
                                 , auto_delete=True
                                 , vhost='/rsa/sa'
                                 , host='localhost')
    consumer = ConsumerRabbitMQ(exchange_header='carlos.alerts'
                                 , exchange_durable=True
                                 , use_msgpack=False, host='localhost'
                                 , use_ssl=False, port=5672, retry=False)
    publisher.publish(input_file=log_path
                       , routing_key='esa-analytics-server.any./rsa/analytics/topology/temp-inject'
                       , topology_name='HttpPacket')
    consumer.consume(num_events_to_consume=1, output_file='consumed.json', timeout_secs=60, sort=True)
