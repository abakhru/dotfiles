#!/usr/bin/env python

import time

from driver.ssh.tunnel_util import SshTunnel
from framework.common.logger import LOGGER
# from framework.utils.ssh.ssh_util import SSHConnection
# from framework.utils.ssh.tunnel_util import SshTunnel
# from productlib.microservice.response_service import ResponseService
from driver.ssh.ssh_driver import SshDriver

LOGGER.setLevel('DEBUG')


if __name__ == '__main__':
    s = SshTunnel('10.40.13.185', 'root', 'netwitness')
    s.Open([5672, 15671, 15672, 7003])
    # s1 = SshTunnel('10.101.217.56', 'root', 'netwitness')
    # s1.Open([5672, 15671, 15672, 7007])
    #time.sleep(30000)
    # r = ResponseService(host='10.101.217.122'
    #                    , amqp_username='guest'
    #                    , amqp_password='guest'
    #                    , amqp_port=5672
    #                    , secure=False
    #                    , amqp_routing_key_prefix='response'
    #                    , appl_username='root'
    #                    , appl_password='netwitness')
    # r.Restart()
    # r.WaitForReady()
    # s = SshDriver('10.40.13.185', 'root', 'netwitness')
    # s.put_file(from_file_path='/Users/bakhra/src/automation/unite/tests/performance/analytics/testdata/qba_test.py/QueryBasedAggregationTestCase/test_uba_with_qba/esa-analytics-server.yml', to_file_path='/tmp/esa-analytics-server.yml')
    time.sleep(600)
    s.Close()
