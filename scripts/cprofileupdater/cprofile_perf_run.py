#!/usr/bin/env python

import os
import shutil
import time

from c8_utils import CassandraUtils
from get_varz import GetVarz
from optparse import OptionParser

OPTS = OptionParser(usage='%%prog [options]\n\n%s' % __doc__)

OPTS.add_option('-k', dest='keyspace'
                , default=None
                , help='Cassandra keyspace name to store data.')
OPTS.add_option('-c', dest='pubtr_conf_file'
                , default='./Pubtransaction.conf'
                , help='Pubtransaction configuration file.')
OPTS.add_option('-n', dest='txnsPerLog'
                , default=None
                , help='Txns Per shard log file.')
OPTS.add_option('-d', dest='base_date'
                , default='2011-01-01'
                , help='base date for pubtransaction.')
OPTS.add_option('-p', dest='delay'
                , default=250
                , help='Period for publishing messages in microseconds.')
OPTS.add_option('-v', dest='get_varz_time_seconds'
                , default=300
                , help='Collect CProfileUpdater and Cassandra varz time duration in seconds.')

(options, args) = OPTS.parse_args()

SERVICES_LIST = ['SilverPlex-back', 'SilverPlex-front', 'SilverSurfer-0'
                 , 'VarzCache-0', 'VarzFetcher-0', 'VarzGrapher-0', 'SysStats-lab6']
SEARS_DATA_DIR = '/var/opt/sears/sears_unified'

#class CProfileUpdaterPerformanceTest(c8_utils.CassandraUtils, get_varz.GetVarz):
class CProfileUpdaterPerformanceTest():

    def __init__(self):

        self.gPeriodNanos = int(options.delay) # delay between txns in microseconds
        self.txnsPerLog = options.txnsPerLog # txns to process from each log file
        self.get_varz_time_seconds = int(options.get_varz_time_seconds) # get the varz every <time> seconds
        self.base_date = options.base_date

        self.publish_rate = 1000 * 1000 / self.gPeriodNanos
        
        # we have 6 days * 24 hours worth of sears data
        if self.txnsPerLog == None:
            self.total_txns = 432000000 # 432 million (each log has around 3 million txns * 24 * 6)
            print ('==== Publishing ALL txns. No Limits.!')
        else:
            self.total_txns = self.txnsPerLog * 24 * 6
            print ('==== Publishing %d txns.' % self.total_txns)

        print ('==== Publishing at %d msgs/s rate.' % self.publish_rate)

    def DeployUniversalConf(self, file_path=None):
        """ Imports and push the universal_conf.py file provided.

        Full universal_conf.py file path is required.
        """

        if not os.exists(file_path):
            print ('%s does not exists. Please provide proper file.!', file_path)
            return False
        else:
            GetVarz.ExecuteShell('curl -s -k --user admin:silvertail --form file=%s --form overlay="" https://lab6:80/silvercat/import.do', file_path)
            GetVarz.ExecuteShell('curl -s -k --user admin:silvertail --form comment="Import from %s" https://lab6:80/silvercat/push', file_path)
            return True

    def UpdateUniversalConf(self, new_keyspace=None):
        """ Updates the exisiting universal_conf.py with keyspace name provided."""

        #original_uni_conf = '/var/opt/silvertail/etc/universal_conf.py'
        original_uni_conf = 'confs/universal_conf.py'
        modified_uni_conf = original_uni_conf + '_' + new_keyspace

        print ('==== Updating %s conf file with \'%s\' keyspace name' % (original_uni_conf, new_keyspace))
        # Keep a backup if not already exists
        if not os.path.exists(original_uni_conf + '.ORIG'):
            shutil.copy(original_uni_conf, original_uni_conf + '.ORIG')

        f = open(original_uni_conf, 'r')
        f1 = open(original_uni_conf + '_' + new_keyspace , 'w')
        for line in f.readlines():
            if ', keyspace' in line:
                print 'before:', line
                a = line.split('=')
                a[1] = '\'' + new_keyspace + '\'\n'
                line = '='.join(a)
                print 'after:', line
            f1.write(line)
        f.close()
        f1.close()
        shutil.copy(modified_uni_conf, original_uni_conf)
        os.remove(modified_uni_conf)
        return original_uni_conf

    def stopServices(self):
        for service in SERVICES_LIST:
            print ('==== %sing %s service on localhost/lab6', service)
            GetVarz.ExecuteShell('sudo /etc/init.d/st-' + service + ' stop')

        print '==== Stopping CProfileUpdater Sercive on lab5'
        GetVarz.ExecuteShell('sudo /etc/init.d/st-CProfileUpdater-0 stop', 'lab5')

    def cleanupCassandraDirectory(self, keyspace=None):
        print '==== Stopping cassandra server'
        GetVarz.ExecuteShell('/etc/init.d/cassandra stop', 'lab9')
        print 'Removing the directory'
        GetVarz.ExecuteShell('rm -rf /var/lib/cassandra/data/silvertail*')
        time.sleep(10)
        print '==== Starting cassandra server'
        GetVarz.ExecuteShell('/etc/init.d/cassandra start', 'lab9')

    def LaunchPubtransaction(self, pubtr_conf_file='confs/pubtransaction.conf'):
        for day in range(6,11):
            day = '%02d' % (day,)
            for hour in range(0,23):
                hour = '%02d' % (hour,)
                shard_files = os.listdir(os.path.join(SEARS_DATA_DIR, str(day) + '/' + str(hour) + ':00'))
                for shard_file in shard_files:
                    if self.txnsPerLog == None:
                        GetVarz.ExecuteShell('/var/opt/silvertail/bin/pubtransaction -P -p %d -d %s -f %s %s',
                                             (self.gPeriodNanos, base_date, self.pubtr_conf_file
                                             , shard_file))
                    else:
                        GetVarz.ExecuteShell('/var/opt/silvertail/bin/pubtransaction -P -n %d -p %d -d %s -f %s %s',
                                             (self.txnsPerLog, self.gPeriodNanos, self.base_date, self.pubtr_conf_file
                                             , shard_file))

if __name__ == '__main__':

        # create class object
        c = CProfileUpdaterPerformanceTest()
        g = GetVarz()
        g.setup(c.gPeriodNanos, c.total_txns, c.get_varz_time_seconds)
        # stop all st-* services
        #c.stopServices()
        c8 = CassandraUtils()
        #CassandraUtils.setup()
        # drop the existing silvertail-* related keyspaces
        c8.DropKeyspaceIfExists()
        # cleanup the dropped keyspace cached cassandra directories
        g.ExecuteShell('cleanup', 'lab9')
        # create a new unique keyspace
        new_keyspace = c8.CreateKeyspace()
        # update the universal_conf.py with new keyspace name
        new_uni_conf = c.UpdateUniversalConf(new_keyspace)
        # deploy the new universal_conf.py and do the push
        #assertTrue(c.DeployUniversalConf(new_uni_conf))
        # wait for services to be ready
        #time.sleep(30)
        # launch pubtransaction
        c.LaunchPubtransaction()
        # wait for publishing to begin
        time.sleep(10)
        # start collecting varz every 5 mins
        GetVarz.run()
