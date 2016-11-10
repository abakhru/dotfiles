#!/usr/bin/env python

import os
from pprint import pprint
import optparse

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
#        self.ana_server_host = 'localhost'
        # self.ana_server_host = '10.101.217.56'
        # self.ana_server_host = '10.101.217.122'
        self.ana_server_host = 'localhost'
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

    def SetupConf_test_all_ueba_scores(self, averaging_window=5184000000
                                       , analysis_window=86400000
                                       , time_gap=3600000
                                       , condition='#event[result] == \'Failure Audit\''
                                       , max_lifetime_window=5184000000):
        """ To configure test case level activities and flow. """

        # self.flow_name = self.test_case_name
        # cleanup cached files and old analytic configs
        # self.AnalyticsConfigCleanUp()
        # self.ConfigCleanUps()

        # set topology, activity, source and stream
        self.SetTopology(name=self.topologyname, rootFlow=self.flow_name)
        self.SetActivity(activity='normalized', **{'flowName': self.flow_name})
        self.SetActivity(activity='alert', **{'flowName': self.flow_name})

        self.SetActivity(activity='failedaccess',
                         **{'precondition': condition,
                            'primary-key': 'server',
                            'averaging-window': averaging_window,
                            'analysis-window': analysis_window,
                            'flowName': self.flow_name})

        self.SetActivity(activity='slidingwindowcardinality'
                         , **{'precondition': '#event[enrichment]['
                                              '\'rsa.analytics.http-packet.{}'
                                              '.failedaccess\'][cardinality] > 2'
                                              .format(self.flow_name),
                              'primary-key': 'server',
                              'averaging-window': averaging_window,
                              'analysis-window': analysis_window,
                              'flowName': self.flow_name})

        self.SetActivity(activity='newdevice'
                         , **{'precondition': '#event[enrichment]['
                                              '\'rsa.analytics.http-packet.{}'
                                              '.failedaccess\'][cardinality] > 2'
                                              .format(self.flow_name),
                              'primary-key': 'device',
                              'averaging-window': averaging_window,
                              'analysis-window': analysis_window,
                              'max-life-time-window': max_lifetime_window,
                              'flowName': self.flow_name})

        self.SetActivity(activity='newserver'
                         , **{'precondition': '#event[enrichment]['
                                              '\'rsa.analytics.http-packet.{}'
                                              '.failedaccess\'][cardinality] > 2'
                                              .format(self.flow_name),
                              'primary-key': 'server',
                              'averaging-window': averaging_window,
                              'analysis-window': analysis_window,
                              'max-life-time-window': max_lifetime_window,
                              'flowName': self.flow_name})

        self.SetActivity(activity='new_device_service'
                         , **{'precondition': '#event[enrichment]['
                                              '\'rsa.analytics.http-packet.{}'
                                              '.failedaccess\'][cardinality] > 2'
                                              .format(self.flow_name),
                              'primary-key': 'device',
                              'is-device-key': 'isdevice',
                              'averaging-window': averaging_window,
                              'analysis-window': analysis_window,
                              'time-gap': time_gap,
                              'flowName': self.flow_name})

        self.SetWhoisclient(insecureConnection=False, waitForHttpRequest=True
                             , whoisUserId='rsaWhoisESAUser'
                             , refreshIntervalSeconds=1000000
                             , whoisHttpsProxy='http://emc-proxy1.rsa.lab.emc.com:82'
                             , whoisPassword='netwitness!!!whois')

        self.SetSource(id='nw', host=self.conc_ip)
        self.SetStream(id='Event', linkedSources='{[id:"nw"]}')

        # set flow and start topology
        flow_time_source = ('enrichment/rsa.analytics.http-packet.{}.normalized/timestamp'
                            .format(self.flow_name))
        self.SetFlow(activities=['normalized'
                                 , 'failedaccess'
                                 , 'slidingwindowcardinality'
                                 , 'newdevice'
                                 , 'newserver'
                                 , 'new_device_service'
                                 , 'whois'
                                 , 'alert']
                     , name=self.flow_name, timeSource=flow_time_source)
        self.StartTopology(topology_id=self.topologyname)

    def DeleteAllConfigs(self):
        self.RemoveAllActivities()
        self.RemoveAllFlows()
        self.RemoveStream()
        self.RemoveSource()
        self.RemoveAllTopologies()
        self.ConfigCleanUps()

    def DefaultConfig(self):
        # define activities
        self.SetWhoisclient(insecureConnection=True
                            , waitForHttpRequest=True
                           , whoisUserId='rsaWhoisESAUser'
                           , refreshIntervalSeconds=1000000
                           , whoisHttpsProxy='http://emc-proxy1.rsa.lab.emc.com:82'
                           , whoisPassword='netwitness!!!whois')
        self.SetFlow(activities=['normalized',
                                 'newdomain',
                                 'rare',
                                 'ua',
                                 'beaconing',
                                 'whois',
                                 'alert']
                     , name=self.flow_name)

        self.SetSource(id='nw', host='10.101.216.247', port=50005, password='netwitness')
        self.SetStream(id='Event', linkedSources='{[id:"nw"]}')
        self.SetWhoisclient(insecureConnection=False, waitForHttpRequest=True
                             , whoisUserId='rsaWhoisESAUser'
                             , refreshIntervalSeconds=1000000
                             , whoisHttpsProxy='http://emc-proxy1.rsa.lab.emc.com:82'
                             , whoisPassword='netwitness!!!whois')
        self.SetTopology(name=self.topologyname, rootFlow=self.flow_name)
        # set topology
        self.RestartTopology(topology_id=self.topologyname)

    def SetUeba(self):
        # self.SetActivity(activity='aggregation'
        #              , **{'type': 'com.rsa.asoc.esa.analytics.topology.framework.activity.enrichment.AggregationEnrichment',
        #                   'shardKey':'username',
        #                   'enabled': True,
        #                   'format': False,
        #                   'properties': {'optional-fields': {
        #                                        'enrichment/rsa.analytics.uba.sinbad.highserverscore/score': 0.2,
        #                                        'enrichment/rsa.analytics.uba.sinbad.failedserversscore/score': 0.2,
        #                                        'enrichment/rsa.analytics.uba.sinbad.newserverscore/score': 0.2,
        #                                        'enrichment/rsa.analytics.uba.sinbad.newdevicescore/score': 0.2,
        #                                     }
        #                                  },
        #                   'flowName': 'sinbad'})
        self.SetActivity(activity='aggregation'
                     , **{'type': 'com.rsa.asoc.esa.analytics.topology.framework.activity.enrichment.AggregationEnrichment',
                          'shardKey':'user_dst',
                          'enabled': True,
                          'format': False,
                          'properties': {'optional-fields': {
                                               'enrichment/rsa.analytics.uba.winauth.highserverscore/score': 0.2,
                                               'enrichment/rsa.analytics.uba.winauth.failedserversscore/score': 0.2,
                                               'enrichment/rsa.analytics.uba.winauth.newserverscore/score': 0.1,
                                               'enrichment/rsa.analytics.uba.winauth.newdevicescore/score': 0.2,
                                               'enrichment/rsa.analytics.uba.winauth.pthscore/score': 0.3
                                            }
                                         },
                          'flowName': 'winauth'})
        self.StopTopology(topology_id='uba')
        self.StartTopology(topology_id='uba')

def loadArgs():
    """ get command line arguments """

    defaults = {'topology': 'HttpPacket'}

    usage = ('%prog [options] \n\n{}'.format(__doc__))
    parser = optparse.OptionParser(usage=usage)
    parser.add_option('-t', '--topology',
                      type='str', action='store', dest='topology',
                      default=defaults['topology'],
                      help='Name of the Topology to Restart')
    return parser.parse_args()


if __name__ == '__main__':
  options = loadArgs()[0]
  topology_name = options.topology

  p = RestHandlers()
  # p.SetStream(stream_config=qba_stream_config)
  p.RestartTopology(topology_id=topology_name)
  # p.RestartTopology(topology_id='HttpLog')
  # p = MetricsRestHandler(server)
  # p.RemoveSource(['nw', 'temp'])
  # p.SetSource(id='nw', host='10.101.59.233', port=50004)
  # p.RestartTopology(topology_id='HttpPacket')
  # p.GetSource()
 # p.SetUeba()
  # p.GetFlow()
  #p.GetActivity(name='aggregation')
  # p.DefaultConfig()

  # p.SetupConf_test_all_ueba_scores()
  # p.DeleteAllConfigs()
  # p.GetActivity()
  # p.RestartTopology(p.topologyname)
  # p.assertProcessedCounterWait(expected=6)
  # p.GetRootTree(path='/rsa/analytics')

  # print('httppacket-eventcount: {}'.format(p.GetCount(path='rsa.analytics.http-packet.event-count')))
  # print('normalized-event-seen-count: {}'.format(p.GetCount(path='rsa.analytics.http-packet.c2.normalized.event-seen-count')))
  # print('normalized-acted-event-count: {}'.format(p.GetCount(path='rsa.analytics.http-packet.c2.normalized.event-acted-count')))
  # print('c2-1: {}'.format(p.GetCount(path='rsa.analytics.http-packet.c2.c2-1.processed-count')))
  # print('c2-2: {}'.format(p.GetCount(path='rsa.analytics.http-packet.c2.c2-2.processed-count')))
  # print('c2-3: {}'.format(p.GetCount(path='rsa.analytics.http-packet.c2.c2-3.processed-count')))
  # print('whois-seen-eventcount: {}'.format(p.GetCount(path='rsa.analytics.http-packet.c2.whois.event-seen-count')))
  # print('whois-acted-eventcount: {}'.format(p.GetCount(path='rsa.analytics.http-packet.c2.whois.event-acted-count')))
  # print('command_control-seen-eventcount: {}'.format(p.GetCount(path='rsa.analytics.http-packet.c2.command_control.event-seen-count')))
  # print('command_control-acted-eventcount: {}'.format(p.GetCount(path='rsa.analytics.http-packet.c2.command_control.event-acted-count')))
  # print('alert-seen-eventcount: {}'.format(p.GetCount(path='rsa.analytics.http-packet.c2.alert.event-seen-count')))
  # print('alert-acted-eventcount: {}'.format(p.GetCount(path='rsa.analytics.http-packet.c2.alert.event-acted-count')))
