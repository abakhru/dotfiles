#!/usr/bin/env python

import os
import optparse
from pprint import pprint

from productlib.component.analytics.handler.rest_activity import ActivityRestHandler
from productlib.component.analytics.handler.rest_metrics import MetricsRestHandler
from productlib.component.analytics.handler.rest_analytics import AnalyticsRestHandler
from productlib.component.analytics.handler.rest_flow import FlowRestHandler
from productlib.component.analytics.handler.rest_stream import StreamRestHandler
from productlib.component.analytics.handler.rest_topology import TopologyRestHandler
from productlib.component.analytics.handler.rest_whois import WhoisRestHandler
from framework.common.logger import LOGGER
# LOGGER.setLevel('DEBUG')

class RestHandlers(ActivityRestHandler, MetricsRestHandler, AnalyticsRestHandler
                   , FlowRestHandler, StreamRestHandler, TopologyRestHandler, WhoisRestHandler):

    def __init__(self, host='localhost', port=7007):
        self.ana_server_host = host
        self.rest_port = port
        self.ana_server_url = 'https://{}:{}'.format(self.ana_server_host
                                                     , self.rest_port)
        self.topologyname = 'HttpPacket'
        self.InitRestHandlers()
        self.flow_name = 'c2'
        self.conc_ip = '10.101.217.47'

    def InitRestHandlers(self):
        """ Init all Rest API Handlers"""

        ActivityRestHandler.__init__(self, server=self.ana_server_url)
        MetricsRestHandler.__init__(self, server=self.ana_server_url)
        AnalyticsRestHandler.__init__(self, server=self.ana_server_url)
        FlowRestHandler.__init__(self, server=self.ana_server_url)
        StreamRestHandler.__init__(self, server=self.ana_server_url)
        TopologyRestHandler.__init__(self, server=self.ana_server_url)
        WhoisRestHandler.__init__(self, server=self.ana_server_url)


def loadArgs():
    """ get command line arguments """

    defaults = {'server': 'localhost',
                'port': 7007}

    usage = ('%prog [options] \n\n{}'.format(__doc__))
    parser = optparse.OptionParser(usage=usage)
    parser.add_option('-s', '--server',
                      type='str', action='store', dest='server',
                      default=defaults['server'],
                      help='hostname to get activity counts from')
    parser.add_option('-p', '--port',
                      type='int', action='store', dest='port',
                      default=defaults['port'],
                      help='launch service HTTP port')
    # LOGGER.debug('args: {}'.format(parser.parse_args))
    return parser.parse_args()


if __name__ == '__main__':
  options = loadArgs()[0]
  host = options.server
  port = options.port
  p = RestHandlers(host=host, port=port)
  #pprint(p.GetAllMeters())
  pprint(p.GetAllCounts())
  #pprint(p.GetAllTimers())
