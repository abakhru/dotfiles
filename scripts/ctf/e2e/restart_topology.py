#!/usr/bin/env python

import os
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

    def __init__(self):
#        self.ana_server_host = 'localhost'
        self.ana_server_host = '10.101.217.56'
        self.rest_port = 7007
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


if __name__ == '__main__':
  p = RestHandlers()
  p.RestartTopology(topology_id='HttpPacket')
  #p.RestartTopology(topology_id='HttpLog')
