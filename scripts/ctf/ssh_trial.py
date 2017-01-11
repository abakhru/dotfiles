#!/usr/bin/env python

import os
import pexpect
from framework.common.logger import LOGGER

LOGGER.setLevel('DEBUG')
from productlib.component.esa.harness import ESAClientRpmHarness


if __name__ == '__main__':
    # p = ESAClientRpmHarness(testcase=None, host='10.40.13.106', user='root', password='netwitness')
    # p.deploy_modules(epl_count=1, epl_text='@RSAAlert select * from Event;')
    # p.Close()
    p = Concentrator(host=cls.concentrator_host, username=HOST_USERNAME
                     , password=HOST_PASSWORD, nw_port=cls.concentrator_port)
