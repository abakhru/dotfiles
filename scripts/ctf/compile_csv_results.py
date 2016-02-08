#!/usr/bin/env python

import os
import re
import subprocess
import timeit

from framework.common.logger import LOGGER
LOGGER.setLevel('DEBUG')


class SummarizePSRResults(object):

    RESULT_DIR = '/Users/bakhra/src/esa/unify/performance/esa/o/persist_missrate_vs_domains_test.py/PersistMissRateVsDomainsTestCase/test_persist_missrate_5'
    trigger_rate = 30000
    trigger_event_count = 1000000
    start_consume = timeit.default_timer()

    def ProcessEsaLog(self, host):
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
        esa_log_file = os.path.join(self.RESULT_DIR, 'esa.log_%s.txt' % host)
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
        # LOGGER.debug('esa_total_events_processed: %s', esa_total_events_processed)
        esa_events_process_rates = [int(i.replace(',', '')) for i in
                                    esa_events_process_rates]
        # LOGGER.debug('esa_events_process_rates: %s', esa_events_process_rates)
        self.esa_total_events_processed = sum(esa_total_events_processed)
        average_events_process_rate = (sum(esa_events_process_rates[1:])
                                       / len(esa_events_process_rates[1:]))
        LOGGER.debug('average_events_process_rate: %s', average_events_process_rate)
        return average_events_process_rate

    @staticmethod
    def _get_elements(_file, column_no):
        a_list = list()
        with open(_file) as f:
            for line in f.readlines():
                a = line.split(', ')
                a_list.append(a[column_no])
        # first line is headers, so ignoring it
        if a_list[2].endswith('g'):
            a_list = [float(a.split('g')[0]) * 1024 for a in a_list[1:]]
        else:
            a_list = list(map(float, [a.strip() for a in a_list][1:]))
        return a_list

    def GetAverage(self, _file, column_no):
        """ Calculates the average of column number.

        Args:
            _file: csv file path (str)
            column_no: column number from the csv file to calculate average on. (int)

        Returns:
            average of the all the values in column number. (float)
        """
        a_list = self._get_elements(_file, column_no)
        return sum(a_list) / len(a_list)

    def GetMax(self, _file, column_no):
        a_list = self._get_elements(_file, column_no)
        return max(a_list)

    def GetTotalSessionsIngested(self, nodes=None, attribute='session.last.id'):
        """ Gets Total Sessions/Meta Ingested by All LD/Concentrator.

        Args:
            nodes: dict of LogDecoder/Concentrator harnesses. (dict)
            attribute: attribute for nwconsole GetValue call (str)

        Returns:
            Total sessions/meta ingested. (int)
        """
        if nodes is None:
            nodes = self.log_decoders
        total_session_ingested = 0
        LOGGER.debug('LD/Conc nodes: %s', nodes)
        for k in nodes:
            session_ingested = k.GetValue(url_path='database/stats', attribute=attribute)
            total_session_ingested += int(session_ingested)
        return total_session_ingested

    def CompileCSVResults(self):
        """ Compiling test run results"""

        summary_file = os.path.join('.', 'summary_result.txt')
        if os.path.exists(summary_file):
            os.system('rm %s' % summary_file)
        # self.StopPublishing()
        consume_duration = 12 * 60 * 60 #int(time.time()) - self.start_consume

        total_session_ingested = 1 #self.GetTotalSessionsIngested(self.log_decoders)
        total_meta_ingested = 1 #self.GetTotalSessionsIngested(self.log_decoders
        #                                                     , attribute='meta.total')

        # avg_ld_rates = list()
        # for j in range(len(self.log_decoders_ip)):
        #     avg_ld_rates.append(self.GetAverage(os.path.join(self.RESULT_DIR
        #                                                      , 'ld_c_result' + str(j)), 3))

        # avg_ld_rate = sum(avg_ld_rates) / len(avg_ld_rates)
        avg_ld_rate = 30000
        LOGGER.info('Average LD Ingest rate: %s', avg_ld_rate)
        LOGGER.info('Total Sessions Ingested: %s', total_session_ingested)
        LOGGER.info('Total Meta Ingested: %s', total_meta_ingested)
        LOGGER.info('Meta Ratio = Total Meta / Event Count : %.2f'
                    , float(total_meta_ingested / total_session_ingested))
        # result = self.multi_esa[self.esa_host_ips[0]].ssh_shell.Exec("mongo esa -u esa -p esa "
        #                                                              "--eval 'db.alert.count()'")
        # self.total_mongo_alerts = int(result.split('\n')[3].strip())
        result_file = os.path.join(self.RESULT_DIR, 'esa_stat_result0.txt')
        self.esa_total_events_processed = self._get_elements(result_file, 1)[-1]
        LOGGER.debug('Total ESA Events Processed (JVM): %s', self.esa_total_events_processed)
        self.total_esa_notifications = self._get_elements(result_file, 3)[-1]
        average_process_rate = self.ProcessEsaLog('10.101.59.231')
        LOGGER.debug('==== Avg ESA Events Processing rate (esa.log): %s', average_process_rate)
        # Average EPS calculated from esa_stat_result0.txt file
        a_list = self._get_elements(_file=result_file, column_no=2)
        # ignoring first 3 and last 4 lines for average calculations
        average_process_rate = sum(a_list[2:]) / len(a_list[2:])
        LOGGER.debug('==== Avg ESA Events Processing rate (esa_stat_result0.txt): %s'
                     , average_process_rate)
        with open(os.path.join(self.RESULT_DIR, 'summary_result'), 'w+') as f:
            f.write('Trigger Log Ingest rate, %s\n' % '90000')
            f.write('Average LD Ingest rate, %s\n' % avg_ld_rate)
            f.write('Total Concentrator sessions ingested, %s\n' % total_session_ingested)
            f.write('Total meta ingested, %s\n' % total_meta_ingested)
            f.write('Meta Ratio = Total Meta / Event Count, %.2f\n'
                    % float(total_meta_ingested / total_session_ingested))
            f.write('Total ESA events processed, %s\n' % self.esa_total_events_processed)
            f.write('ESA Average Events Process Rate, %.2f\n' % average_process_rate)
            f.write('Published trigger events, %s\n' % self.trigger_event_count)
            # f.write('Fired events, %s\n' % str(self.total_esa_notifications))
            # f.write('Mongo events, %s\n' % str(self.total_mongo_alerts))
            f.write('CPU (System) - AVG, %s\n'
                    % str(self.GetAverage(os.path.join(self.RESULT_DIR
                                                       , 'cpu_stat_result0.txt'), 2)))
            f.write('CPU (System) - MAX, %s\n'
                    % str(self.GetMax(os.path.join(self.RESULT_DIR, 'cpu_stat_result0.txt'), 2)))
            f.write('MEM (System GB) - AVG, %.2f\n'
                    % (self.GetAverage(os.path.join(self.RESULT_DIR, 'free_mem_result0.txt')
                                      , 2) / 1024))
            f.write('MEM (System GB) - MAX, %.2f\n'
                    % (self.GetMax(os.path.join(self.RESULT_DIR, 'free_mem_result0.txt')
                                  , 2) / 1024))
            f.write('CPU (Process) - AVG, %.2f\n'
                    % (self.GetAverage(os.path.join(self.RESULT_DIR, 'top_esa_result0.txt')
                                       , 5) * 100))
            f.write('CPU (Process) - MAX, %.2f\n'
                    % (self.GetMax(os.path.join(self.RESULT_DIR, 'top_esa_result0.txt')
                                   , 5) * 100))
            f.write('MEM (Process GB) - AVG, %.2f\n'
                    % (self.GetAverage(os.path.join(self.RESULT_DIR
                                                    , 'top_esa_result0.txt'), 1) / (1024 * 1024
                                                                                * 1024)))
            f.write('MEM (Process GB) - MAX, %.2f\n'
                    % (self.GetMax(os.path.join(self.RESULT_DIR
                                                , 'top_esa_result0.txt'), 1) / (1024 * 1024 * 1024)))
            # f.write('I/O - AVG, ' + str(self.GetAverage('ld_c_result0.txt', 3)) + '\n')
            # f.write('I/O - MAX, ' + str(mongo_events) + '\n')
            f.write('Total Run Duration, %s' % str(timeit.default_timer() - self.start_consume))
        # subprocess.call('sudo mv %s %s' % (summary_file, self.RESULT_DIR), shell=True)

if __name__ == '__main__':

    p = SummarizePSRResults()
    p.CompileCSVResults()
