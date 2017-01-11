#!/usr/bin/env python

import optparse

from framework.common.logger import LOGGER
# from framework.driver.amqp.rabbitmq import ConsumerRabbitMQ
# from framework.driver.amqp.rabbitmq import PublishRabbitMQ
from framework.utils.rabbitmq.rabbitmq import ConsumerRabbitMQ
from framework.utils.rabbitmq.rabbitmq import PublishRabbitMQ
# from framework.utils.ssh.ssh_util import SSHConnection
# from framework.utils.ssh.tunnel_util import SshTunnel

LOGGER.setLevel('DEBUG')
ANA_HOST = 'localhost'
VHOST = '/rsa/system'
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
    # LOGGER.debug('args: {}'.format(parser.parse_args))
    return parser.parse_args()


if __name__ == '__main__':
    options = loadArgs()[0]
    log_path = options.file
    ANA_HOST = options.server
    access_token = ('eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9'
                    '.eyJleHAiOjE0ODE5NDg2NjAzODUsImlzcyI6ImVzYS1hbmFseXRpY3Mtc2VydmVyLWY5M2ZiMjUxLTZjZmYtNDM4NS05MzY1LTk0NjA2MWFjZjhmMCIsImlhdCI6MTQ4MTkxMjY2MDM4NSwiYXV0aG9yaXRpZXMiOlsiZjkzZmIyNTEtNmNmZi00Mzg1LTkzNjUtOTQ2MDYxYWNmOGYwIl0sInVzZXJfbmFtZSI6ImxvY2FsIn0.UwcLy8LgBqNmTsYFc3oAyP8HMp3eSd-HLqUQ3bbyNFex-AY9p3cRBUMlyFsId5AvGl_QpbihnxKQ-1B0LG1HLTDTOk4dI432Y0EwA1toFqJFgyvYCs67tp_uAh5YlNKLEsFF9R2jmyeWpUEWQIE_WcZrPoZW5CVpLfaqMhOybocBDLahi4JnLMLAuFKPw_PT8gNjWuOgByl9bOAr90XEWRmkQ-eO8Ee-PIx-io4Cd0omRKwIBszz89LjJK5aJAYg8H_SvG0lfVLJW9Vm8YvOF5kUijGqxFvSpk0FTLkn__Ctw_QL9nt6Jatdm5jWNf6ABZXCh1alrTe2EZrIcnqoZw')
    # print(log_path)
    no_of_lines = 0
    with open(log_path) as f:
        lines = f.readlines()
        no_of_lines = len(lines)
    # s = SshTunnel('10.101.217.56', 'root', 'netwitness')
    # s.Open([5672, 7003])
    events_publisher = PublishRabbitMQ(exchange_header='esa-analytics-server'
                                       , exchange_durable=False
                                       , use_msgpack=True
                                       , use_ssl=False
                                       , port=5672
                                       , _type='topic'
                                       , auto_delete=True
                                       , vhost=VHOST
                                       , host=ANA_HOST
                                       , access_token=access_token)
    # alert_publisher = PublishRabbitMQ(exchange_header='carlos.alerts'
    #                                     , vhost=VHOST
    #                                     , exchange_durable=True
    #                                     , create_new_exchange=False
    #                                     , host=ANA_HOST
    #                                     , custom_binding=DEFAULT_AMQP_HEADER)
    consumer = ConsumerRabbitMQ(exchange_header='carlos.alerts'
                                , exchange_durable=True
                                , use_msgpack=False, host=ANA_HOST
                                , vhost=VHOST
                                , use_ssl=False, port=5672, retry=False)
    events_publisher.publish(input_file=log_path
                             , routing_key='esa-analytics-server.any./rsa/analytics'
                                           '/topology/temp-inject'
                             , topology_name='UbaCisco')
    consumer.consume(num_events_to_consume=30, output_file='consumed.json'
                     , timeout_secs=30, sort=False)
    # alert_publisher.publish(input_file=log_path)
    # s.Close()
