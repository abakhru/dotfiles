#!/usr/bin/env python

import optparse

from framework.common.logger import LOGGER
from framework.driver.amqp.rabbitmq import PublishRabbitMQ, ConsumerRabbitMQ
from productlib.component.analytics.handler.rest_activity import ActivityRestHandler

LOGGER.setLevel('DEBUG')
ANA_HOST = '10.101.216.131'
VHOST = '/rsa/system'


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
                      help='hostname to get activity counts from')
    return parser.parse_args()


if __name__ == '__main__':
    options = loadArgs()[0]
    log_path = options.file
    ANA_HOST = options.server
    print(log_path)
    no_of_lines = 0
    with open(log_path) as f:
        lines = f.readlines()
        no_of_lines = len(lines)
    a = ActivityRestHandler(server='https://{}:7007'.format(ANA_HOST))
    events_publisher = PublishRabbitMQ(exchange_header='esa-analytics-server'
                                       , exchange_durable=False
                                       , use_msgpack=True
                                       , use_ssl=False
                                       , port=5672
                                       , _type='topic'
                                       , auto_delete=True
                                       , vhost=VHOST
                                       , access_token=a.access_token
                                       , host=ANA_HOST)
    consumer = ConsumerRabbitMQ(exchange_header='carlos.alerts'
                                , exchange_durable=True
                                , use_msgpack=False, host=ANA_HOST
                                , vhost=VHOST
                                , use_ssl=False, port=5672, retry=False)
    events_publisher.publish(input_file=log_path
                             , routing_key='esa-analytics-server.any./rsa/analytics'
                                           '/topology/temp-inject'
                             , topology_name='uba')
    consumer.consume(num_events_to_consume=no_of_lines, output_file='consumed.json'
                     , timeout_secs=90, sort=False)