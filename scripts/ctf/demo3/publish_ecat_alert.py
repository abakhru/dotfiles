#!/usr/bin/env python

import optparse

from framework.common.logger import LOGGER
from framework.driver.amqp.rabbitmq import PublishRabbitMQ
from productlib.component.analytics.handler.rest_activity import ActivityRestHandler

LOGGER.setLevel('DEBUG')
VHOST = '/rsa/system'
DEFAULT_AMQP_HEADER = {'carlos.event.version': '1',
                       'carlos.event.timestamp': '2017-01-05T10:03:27.482Z',
                       'carlos.event.signature_id': 'ModuleIOC',
                       'carlos.event.device.vendor': 'RSA',
                       'carlos.event.device.product': 'ECAT',
                       'carlos.event.device.version': '11.0.0000',
                       'carlos.event.severity': 9,
                       'carlos.event.name': 'ModuleIOC'}

"""
python3 python/update-config.py --xdfile=./xd-services.json
--servicefile=/Users/bakhra/src/automation/unite/config/services.json
--databasefile=/Users/bakhra/src/automation/unite/config/database.json
--mapperfile=./config/xd-to-unite-mapper.config
--dbmapperfile=./config/xd-to-database-mapper.config
--testconfigfile=/Users/bakhra/src/automation/unite/config/test_config.json --updatetestconfig logging=DEBUG
"""

def loadArgs():
    """ get command line arguments """

    defaults = {'file': 'json_input.txt',
                'server': '10.101.216.131'}

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
    a = ActivityRestHandler(server='https://{}:7003'.format(ANA_HOST))
    alert_publisher = PublishRabbitMQ(exchange_header='carlos.alerts'
                                      , vhost=VHOST
                                      , exchange_durable=True
                                      , create_new_exchange=False
                                      , host=ANA_HOST
                                      , custom_binding=DEFAULT_AMQP_HEADER
                                      , access_token=a.access_token
                                      , port=5672)
    alert_publisher.publish(input_file=log_path, topology_name='uba')
