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
LOGGER.setLevel('DEBUG')

class RestHandlers(ActivityRestHandler, MetricsRestHandler, AnalyticsRestHandler
                   , FlowRestHandler, StreamRestHandler, TopologyRestHandler, WhoisRestHandler):

    def __init__(self):
        self.ana_server_host = '127.0.0.1'
        self.rest_port = 8080
        self.ana_server_url = 'https://{}:{}'.format(self.ana_server_host
                                                     , self.rest_port)
        self.topologyname = 'HttpPacket'
        self.InitRestHandlers()

    def InitRestHandlers(self):
        """ Init all Rest API Handlers"""

        ActivityRestHandler.__init__(self, server=self.ana_server_url)
        MetricsRestHandler.__init__(self, host=self.ana_server_host, port=self.rest_port)
        AnalyticsRestHandler.__init__(self, server=self.ana_server_url)
        FlowRestHandler.__init__(self, server=self.ana_server_url)
        StreamRestHandler.__init__(self, server=self.ana_server_url)
        TopologyRestHandler.__init__(self, server=self.ana_server_url)
        WhoisRestHandler.__init__(self, server=self.ana_server_url)

    def DefaultConfig(self):
        # define activities
        self.SetActivity(activity='normalized')
        self.SetActivity(activity='alert')
        self.SetFlow(activities=['normalized', 'whois', 'alert'])

        # set source and stream
        # self.SetSource(id='nw', host='localhost')
        self.SetSource(id='Event', host='localhost', port=50005, password='netwitness')
        self.SetStream(id='Event', linkedSources='{[id:"nw"]}')
        self.SetWhoisclient(insecureConnection=False, waitForHttpRequest=True
                             , whoisUserId='rsaWhoisESAUser'
                             , refreshIntervalSeconds=1000000
                             , whoisHttpsProxy='http://emc-proxy1.rsa.lab.emc.com:82'
                             , whoisPassword='netwitness!!!whois')

        # set topology
        self.SetTopology(name=self.topologyname)
        self.RestartTopology(topology_id=self.topologyname)


if __name__ == '__main__':
  p = RestHandlers()
  p.DefaultConfig()
  p.RestartTopology(p.topologyname)
  # p.assertProcessedCounterWait(expected=6)
  # p.GetRootTree(path='/rsa/analytics')
  # a = m.GetCount()
  # print(a)
