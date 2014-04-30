#!/usr/bin/env python

import os
import sys
import time
import subprocess
import datetime
import collections


class GetVarz(object):

    def setup(self, delay='250', total_txns=0, get_varz_time_seconds='300'):

        self.cql_interesting_varz_list = [ 'cql-execs'
                                         , 'cql-execs-failed'
                                         , 'cql-exec-timeouts'
                                         , 'cql-prepare-timeouts'
                                         , 'cql-exec-time-micros'
                                         , 'cql-completed-exec-time-micros-percentile-99'
                                         , 'cql-completed-exec-time-micros-percentile-99.9'
                                         , 'cql-completed-exec-time-micros-percentile-99.99' ]

        self.cprofile_interesting_varz_list = self.cql_interesting_varz_list + [ 
                                               'cprofileupdater-ip_profile_profile_sessions-inserted'
                                             , 'cprofileupdater-ip_profile_scorelets-inserted'
                                             , 'cprofileupdater-ip_profile_txn_time_blocks-inserted'
                                             , 'cprofileupdater-user_profile_profile_sessions-inserted'
                                             , 'cprofileupdater-user_profile_scorelets-inserted'
                                             , 'cprofileupdater-user_profile_txn_time_blocks-inserted'
                                             , 'cprofileupdater-txns-failed'
                                             , 'cprofileupdater-txns-received'
                                             , 'cprofileupdater-txns-processed'
                                             , 'cprofileupdater-ooo-txns' ]

        self.gPeriodNanos = int(delay) # delay between txns in microseconds
        self.get_varz_time_seconds = int(get_varz_time_seconds) # get the varz every <time> seconds
        self.total_txns = int(total_txns)
        self.publish_rate = 1000 * 1000 / self.gPeriodNanos

        self.total_time_to_publish = self.total_txns / self.publish_rate # in seconds

        self.run_for_seconds = self.total_time_to_publish + 120 # additional 2 mins for queue cleanup
        self.run_range = ( self.run_for_seconds / self.get_varz_time_seconds )

        print ("==== Setting Publishing period to %s microseconds (%d msgs/s)."
               % (self.gPeriodNanos, self.publish_rate))
        print ('==== Running get_varz.py for \'%d\' seconds' % self.run_for_seconds )
        print ('==== Getting varz every \'%d\' seconds' % self.get_varz_time_seconds)

        self.sts_ver = self.ExecuteShell('/var/opt/silvertail/bin/cprofileupdater -h 2>&1 | grep \'Silver Tail\'| awk \'{print $5}\'', 'lab5')
        self.orig_proc_id = self.ExecuteShell('ps -eaf | grep [c]profileupdater | awk \'{print $2}\'', 'lab5')
        time.sleep(2)

        print (self.ExecuteShell('cat /proc/%s/statm' % self.orig_proc_id, 'lab5'))

        self.current_time = datetime.datetime.now().strftime("%Y%m%d%H%M")
        self.reports_dir = './reports'
        if not os.path.exists(self.reports_dir):
            os.makedirs(self.reports_dir)

        self.perf_result_file =  os.path.join(self.reports_dir, str(self.publish_rate) + 'txnsPerSec_' 
                                 + str(self.total_txns) + '_' + self.orig_proc_id + '_'
                                 + self.current_time + '_perf.csv')
        self.cprofile_varz_file = os.path.join(self.reports_dir, str(self.publish_rate) 
                                  + 'txnsPerSec_' + str(self.total_txns) + '_cprofile_all_varz_'
                                  + self.orig_proc_id + '_'  + self.current_time + '.txt')
        self.cql_varz_file = os.path.join(self.reports_dir, str(self.publish_rate) + 'txnsPerSec_'
                             + str(self.total_txns) + '_cassandra_all_varz_' + self.orig_proc_id 
                             + '_' + self.current_time + '.txt')

    def ExecuteShell(self, cmd, host='localhost'):
        """ Execute a bash command on localhost or remote machine using ssh."""

        if host != 'localhost':
            COMMAND = ['ssh', '-t', '-Ap 2772', '-oStrictHostKeyChecking=no'
                        , host, 'sudo' , cmd]
        else:
            COMMAND = [cmd]

        print '==== Running:' + " ".join(COMMAND)
        popen = subprocess.Popen(COMMAND
                                 , stdout=subprocess.PIPE
                                 , stderr=subprocess.STDOUT
                                 , close_fds=True)
        lines = popen.stdout.readlines()
        for line in lines:
            print line.rstrip()
        popen.wait()

        return lines[0].rstrip()

    def _CreateDict(self, varz):
        """ Create and return sorted dict object from varz.

        Returns sorted dict.
        """
        d = dict((k.strip(), v.strip()) for k,v in
                                      (item.split(':') for item in varz.splitlines()))
        return collections.OrderedDict(sorted(d.items()))

    def dict_subset(self, orig_dict, keys_that_matter, def_value=None):
        """ Extract a subset of key/val from a dictionary

        Args:
            orig_dict: a dictionary
            keys_that_matter: a list of keys to extract key/var pair of
            def_value: this, includes both key AND the value of the key is what the "get" returns

        Returns:
            a dictionary object that is a subset of original dictionary
        """
        r_dict = dict([ (k, orig_dict.get(k, def_value)) for k in keys_that_matter ])
        return collections.OrderedDict(sorted(r_dict.items()))

    def _findKey(self, list, varz_dict):
        """ Match interesting_varz_list elements in varz_dict, appends to result_dict.

        Returns sorted dict.
        """
        r_dict = {}
        for i in xrange(len(list)):
            for key, value in varz_dict.iteritems():
                if key == list[i]:
                    values = value.split(' ')[-1]
                    r_dict[key] = values
        return collections.OrderedDict(sorted(r_dict.items()))

    def _DictToCSV(self, varz_dict, timestamp, flag=False):
        """ Write varz_dict in cvs format file."""
        f = open(self.perf_result_file, 'a+')
        if flag:
            f.write('time: %s ' % timestamp + "\n=========================\n")
        for varz_name, value in varz_dict.iteritems():
            f.write(varz_name + ', ' + value + '\n')
        f.close()

    def run(self):
    
        f = open(self.cprofile_varz_file, 'a+')
        f1 = open(self.cql_varz_file, 'a+')
    
        for i in xrange(1,self.run_range):

            cprofileupdater_varz = ExecuteShell('curl -u admin:silvertail -s -k https://lab6.silvertailsystems.com'
                                      + '/mon/varz/CProfileUpdater/lab5')
            cassandra_varz= ExecuteShell('curl -u admin:silvertail -s -k https://lab6.silvertailsystems.com'
                                     + '/mon/varz/Cassandra/lab9')

            print (ExecuteShell('cat /proc/%s/statm' % orig_proc_id, 'lab5'))

            cprofileupdater_varz_dict = _CreateDict(cprofileupdater_varz)
            cassandra_varz_dict = _CreateDict(cassandra_varz)
            #after_val = cprofileupdater_varz_dict['cprofileupdater-messages']

            proc_stat = ExecuteShell('top -b -n 1 -p %s|grep cprofileupdater' % self.orig_proc_id, 'lab5')

            current_time = ExecuteShell('date +\'%F %T.%6N\'')
            f.write('\n' + current_time + '\n=========================\n')
            for key in cprofileupdater_varz_dict.iterkeys():
                f.write('%s: %s\n' % (key, cprofileupdater_varz_dict[key]))
            f.write(proc_stat)

            f1.write('\n' + current_time + '\n=========================\n')
            for key in cassandra_varz_dict.iterkeys():
                f1.write('%s: %s\n' % (key, cassandra_varz_dict[key]))

            print ('==== Creating interesting dict')
            r_cprofileupdater_varz_dict = _findKey(self.cprofile_interesting_varz_list, cprofileupdater_varz_dict)
            r_cassandra_varz_dict = _findKey(self.cql_interesting_varz_list, cassandra_varz_dict)
            # dictionary of keys that matter
            #r_cprofileupdater_varz_dict = dict_subset(cprofileupdater_varz_dict, self.cprofile_interesting_varz_list)
            #r_cassandra_varz_dict = dict_subset(cassandra_varz_dict, self.cql_interesting_varz_list)

            print ('==== Writing to CSV file')
            _DictToCSV(r_cprofileupdater_varz_dict, self.current_time, flag=True)
            _DictToCSV(r_cassandra_varz_dict, self.current_time)

            print ('==== Sleeping for %d seconds...' % self.get_varz_time_seconds)
            time.sleep(self.get_varz_time_seconds)

        f.close()
        f1.close()
