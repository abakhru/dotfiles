#!/usr/bin/env python

import os

from productlib.component.analytics.analytics_test_util import ActivityRestHandler
from productlib.component.analytics.analytics_test_util import AnalyticsMetrics
from productlib.component.analytics.analytics_test_util import AnalyticsRestHandler
from productlib.component.analytics.analytics_test_util import FlowRestHandler
from productlib.component.analytics.analytics_test_util import StreamRestHandler
from productlib.component.analytics.analytics_test_util import TopologyRestHandler
from productlib.component.analytics.analytics_test_util import WhoisRestHandler
from framework.common.logger import LOGGER
LOGGER.setLevel('DEBUG')


if __name__ == '__main__':
  p = WhoisRestHandler()
  # p.SetWhoisclient(whoisHttpsProxy='http://emc-proxy1.rsa.lab.emc.com:82'
  #                           , insecureConnection=False, whoisUserId='Bakhru')
  p.GetWhoisclient()
  p.SetWhoisclient(whois_config={'whoisHttpsProxy': 'http://emc-proxy1.rsa.lab.emc.com:82', 'insecureConnection':True, 'whoisUserId':'rsaWhoisESAUser'})
  p = StreamRestHandler()
  p.SetSource(id='Event')
  p.SetStream(id='Event')
  p.GetSource()
  p.GetStream()
  t = TopologyRestHandler()
  t.RestartTopology()
