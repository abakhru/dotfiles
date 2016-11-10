#!/usr/bin/env python

import os
import optparse
import timeit
from multiprocessing.pool import ThreadPool

from framework.common.logger import LOGGER
from framework.utils.rabbitmq.rabbitmq import PublishRabbitMQ

LOGGER.setLevel('DEBUG')
VHOST = '/rsa/sa'
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


class AlertsGenerator(object):

    def __init__(self, prefix):
        final_alert_list = list()
        for i in range(10000):
            a = ALERT_TEMPLATE.replace('AAAA', '{}{}'.format(prefix, str(i)))
            final_alert_list.append(a)

        file_name = os.path.join('final_{}{}'.format(prefix, template_file))
        FILE_LIST.append(file_name)
        with open(file_name, 'wb') as _file:
            _file.write(bytes('\n'.join(final_alert_list), 'UTF-8'))


class ResponseBatchPublishing(object):

    def __init__(self, file):
        self.file = file
        self.publisher = PublishRabbitMQ(exchange_header='carlos.alerts'
                                          , vhost=VHOST
                                          , exchange_durable=True
                                          , create_new_exchange=False
                                          , host=ANA_HOST
                                          , custom_binding=DEFAULT_AMQP_HEADER)
        self.publisher.publish(input_file=self.file)


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


if __name__ == '__main__':
    options = loadArgs()[0]
    log_path = options.file
    ANA_HOST = options.server
    no_of_lines = 0
    number_of_thread = 3

    pool = ThreadPool(number_of_thread)
    pool.map(AlertsGenerator
             , ['999{}'.format(i) for i in range(number_of_thread)])
    pool.close()
    pool.join()

    start_time = timeit.default_timer()
    pool = ThreadPool(number_of_thread)
    pool.map(ResponseBatchPublishing, FILE_LIST)
    pool.close()
    pool.join()
    print(timeit.default_timer() - start_time)
