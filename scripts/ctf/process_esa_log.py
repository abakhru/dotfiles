#!/usr/bin/env python

import os
import re

from framework.common.logger import LOGGER
LOGGER.setLevel('DEBUG')


class ProcessESALog(object):

    def process_esa_log(self, host):
        """ Processes esa.log file to get total events processes and avg processing rate.

        Args:
            host: host name suffix of esa.log file

        Returns:
            average_events_process_rate: Average processing rate.

        Note:
            This is log line from esa.log from which esa processing rate and number of
            events processed is harvested:
            "2015-09-24 22:46:06,145 [pipeline-sessions-0] INFO
            com.rsa.netwitness.core.workflow.worker.ESPERFeeder - 5,075,139 events in 60 seconds
            (84,585 EPS) at minute 9/24/15 10:45 PM forwarded for correlation"
        """
        LOGGER.info('Calculating ESA Avg Event processing Rate in EPS for \'%s\' host', host)
        esa_total_events_processed = list()
        esa_events_process_rates = list()
        esa_log_file = os.path.join('/Users/bakhra/src/esa/unify/performance/esa/o/nextgen_flow_test.py/PSRNextGenTestCase/test_match_recog_without_partition', 'esa.log_' + host)
        LOGGER.debug('esa.log full path: %s', esa_log_file)
        p = re.compile(r'pipeline-sessions.*- (.*)[^0-9,]events*.*\((.*) EPS')
        with open(esa_log_file) as f:
            for line in f.readlines():
                match = re.search(p, line)
                if match:
                    esa_total_events_processed.append(match.group(1))
                    esa_events_process_rates.append(match.group(2))
        # removing , from the events string and converting it to int
        esa_total_events_processed = [int(i.replace(',', ''))
                                      for i in esa_total_events_processed]
        LOGGER.debug('esa_total_events_processed: %s', esa_total_events_processed)
        esa_events_process_rates = [int(i.replace(',', '')) for i in
                                    esa_events_process_rates]
        LOGGER.debug('esa_events_process_rates: %s', esa_events_process_rates)
        self.esa_total_events_processed = sum(esa_total_events_processed)
        average_events_process_rate = (sum(esa_events_process_rates[1:])
                                       / len(esa_events_process_rates[1:]))
        LOGGER.debug('average_events_process_rate: %s', average_events_process_rate)

if __name__ == '__main__':

    p = ProcessESALog()
    p.process_esa_log(host='10.101.59.231')
