#!/usr/bin/env python

from framework.common.logger import LOGGER
from productlib.component.analytics.handler.rest_activity import ActivityRestHandler
from productlib.component.analytics.handler.rest_metrics import MetricsRestHandler
from productlib.component.analytics.handler.rest_analytics import AnalyticsRestHandler
from productlib.component.analytics.handler.rest_flow import FlowRestHandler
from productlib.component.analytics.handler.rest_stream import StreamRestHandler
from productlib.component.analytics.handler.rest_topology import TopologyRestHandler
from productlib.component.analytics.handler.rest_whois import WhoisRestHandler
from productlib.component.analytics.harness import AnalyticsServerHarness, AnalyticsServerRpmHarness

LOGGER.setLevel('DEBUG')

if __name__ == '__main__':

    # p1 = AnalyticsServerRpmHarness(None, host='10.101.217.122'
    #                                 , rest_port=8080
    #                                 , user='root'
    #                                 , password='netwitness')
    # p2 = AnalyticsServerRpmHarness(None, host='10.101.217.122'
    #                                 , rest_port=8181
    #                                 , user='root'
    #                                 , password='netwitness')
    # p1 = AnalyticsServerHarness(None, own_dir='/Users/bakhra/tmp/ana1'
    #                              , stdout_append=False
    #                              , rest_port=8080
    #                              , host='localhost')
    p2 = AnalyticsServerHarness(None, own_dir='/Users/bakhra/tmp/ana2'
                                 , stdout_append=False
                                 , rest_port=8181
                                 , host='localhost')
    # LOGGER.debug('p1: {}'.format(p1))
    LOGGER.debug('p2: {}'.format(p2))
    # p1.PreLaunch()
    # p1.Launch()
    p2.PreLaunch()
    p2.Launch()
    # p1.WaitForReady()
    p2.WaitForReady()

    p1.InitRestHandlers()
    s1 = StreamRestHandler(server=p.url)
    s1.SetSource(id='Event', host='10.101.59.240', port=50005, password='netwitness')
    s1.SetStream(id='Event')
    s1.GetSource()
    s1.GetStream()
    t1 = TopologyRestHandler(server=p.url)
    t1.RestartTopology()
    s1.GetStream()
    # p.WaitForReady()
    p2.StartAna()
