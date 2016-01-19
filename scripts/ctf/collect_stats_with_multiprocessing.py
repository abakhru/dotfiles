# unify/performance/framework/collect_stats.py

import os
import re
import requests
import time
import multiprocessing

from testconfig import config
from common.framework.logger import LOGGER
from common.framework.harness import SshCommandClient
from performance.framework.harness import EsaClientHarness


class TopStat(multiprocessing.Process):

    def __init__(self, esa_node, interval=5, count=2, timeout=180, esa_outfile='top_esa_result'
                 , trigger_rate=0, noise_rate=0, mongo_outfile='top_mongo_result'
                 , rabbit_outfile='top_rabbit_result', args=(), kwargs={}
                 , group=None, target=None, name=None):
        """ESA/Mongo/RabbitMQ Process top stats"""

        # threading.Thread.__init__(self, group, target, name, args, kwargs)
        # self.stop = threading.Event()
        self.host = esa_node
        self.esa_node = esa_node
        self.ssh = SshCommandClient(self.host, user='root', password=None)
        self.timeout = timeout
        self.interval = interval
        self.count = count
        self.noise_rate = noise_rate
        self.trigger_rate = trigger_rate
        self.esa_outfile = esa_outfile
        self.mongo_outfile = mongo_outfile
        self.rabbit_outfile = rabbit_outfile
        self.t1 = None
        header_text = 'PID USER      PR  NI  VIRT  RES  SHR S %CPU %MEM    TIME+  COMMAND'
        with open(self.mongo_outfile, 'a+', buffering=1) as f:
            f.write('timestamp, ' + ', '.join(header_text.split()) + '\n')
        with open(self.esa_outfile, 'a+', buffering=1) as f:
            f.write('timestamp, ' + ', '.join(header_text.split()) + '\n')
        with open(self.rabbit_outfile, 'a+', buffering=1) as f:
            f.write('timestamp, ' + ', '.join(header_text.split()) + '\n')
        # calculating rsa-esa server pid
        self.esa_pids = list()
        wrapper_pid = self.ssh.get_service_pid('rsa-esa')
        esa_pid = self.ssh.Exec('pgrep -P %s' % wrapper_pid, '#')
        self.esa_pids.append(esa_pid.split('\n')[-2].strip())
        LOGGER.debug('ESA Server pid: %s', self.esa_pids)
        # calculating rabbitmq pid
        output = self.ssh.Exec('service rabbitmq-server status|grep pid', '#')
        self.rabbitmq_pid = output.split(',')[1].split('}')[0].strip()
        LOGGER.debug('RabbitMQ pid: %s', self.rabbitmq_pid)
        # calculating tokumx pid
        output = self.ssh.Exec('service tokumx status', '#')
        self.mongodb_pid = output.split('\n')[1].split('pid ')[1].split(')')[0].strip()
        LOGGER.debug('TokuMX/MongoDB pid: %s', self.mongodb_pid)

    def finish(self):
        ssh1 = SshCommandClient(self.host, user='root', password=None)
        try:
            ssh1.Exec('killall -s 3 top', '#')
            ssh1.close()
        except OSError:
            pass
        self.ssh.close()
        self.stop.set()
        self.join()
        return

    def run(self):
        cmd = ("top -b -d 1 -n 1 | egrep '^%s|^%s|^%s'"
               % (self.esa_pids[0], self.mongodb_pid, self.rabbitmq_pid))
        for i in range(self.count):
            result = self.ssh.Exec(cmd, '#', timeout=self.timeout)
            [j_mem, m_mem, r_mem] = self.get_top(result)
            self.report(self.esa_outfile, j_mem)
            self.report(self.mongo_outfile, m_mem)
            self.report(self.rabbit_outfile, r_mem)
            time.sleep(self.interval)

    def get_top(self, result):
        top_result = result.split('\n')
        java_mem = list()
        mongo_mem = list()
        rabbit_mem = list()
        for line in top_result:
            line_list = line.split()
            if len(line_list) and line_list[0] == self.esa_pids[0]:
                java_mem = line_list
            if len(line_list) and line_list[1] == 'tokumx':
                mongo_mem = line_list
            if len(line_list) and line_list[1] == 'rabbitmq':
                rabbit_mem = line_list
        return [java_mem, mongo_mem, rabbit_mem]

    def report(self, outfile, mem):
        with open(outfile, 'a+', buffering=1) as f:
            f.write(str(time.strftime("%Y-%b-%d %H:%M:%S")) + ', ' + ', '.join(mem) + '\n')
            f.flush()


class MPStat(multiprocessing.Process):

    def __init__(self, esa_node, interval=5, count=None, timeout=120, noise_rate=0
                 , group=None, target=None, name=None, args=(), kwargs={}
                 , trigger_rate=0, outfile='cpu_stat_result'):
        """System CPU stats with memstat"""

        # threading.Thread.__init__(self, group, target, name, args, kwargs)
        # self.stop = threading.Event()
        self.host = esa_node
        self.esa_node = esa_node
        self.ssh = SshCommandClient(self.host, user='root', password=None)
        self.timeout = timeout
        self.interval = interval
        self.count = count
        self.t1 = None
        self.outfile = outfile
        self.noise_rate = noise_rate
        self.trigger_rate = trigger_rate
        header_text = self.ssh.Exec('mpstat 1 1', '#')
        with open(self.outfile, 'a+') as f:
            f.write('time, ' + ', '.join(header_text.split('\n')[3].split()[2:]) + '\n')

    def finish(self):
        ssh1 = SshCommandClient(self.host, user='root', password=None)
        try:
            ssh1.Exec('killall -s 3 mpstat', '#')
            ssh1.close()
        except OSError:
            pass
        self.ssh.close()
        self.stop.set()
        self.join()

    def run(self):
        cmd = 'mpstat 1 1'
        for i in range(self.count):
            result = self.ssh.Exec(cmd, '#')
            data = ', '.join(result.split('\n')[4].split()[2:])
            self.report(data)
            time.sleep(self.interval)

    def report(self, data):
        with open(self.outfile, 'a+') as f:
            f.write(str(time.strftime("%Y-%b-%d %H:%M:%S")) + ', ' + data + '\n')
            f.flush()


class DfStat(multiprocessing.Process):

    def __init__(self, esa_node, interval, timeout
                 , group=None, target=None, name=None
                 , args=(), kwargs={}, count=1, noise_rate=0
                 , trigger_rate=0, outfile='df_result'):
        # threading.Thread.__init__(self, group, target, name, args, kwargs)
        # self.stop = threading.Event()
        self.host = esa_node
        self.esa_node = esa_node
        self.ssh = SshCommandClient(self.host, user='root', password=None)
        self.interval = interval
        self.timeout = timeout
        self.stats = list()
        self.esa_node = esa_node
        self.outfile = outfile
        self.noise_rate = noise_rate
        self.trigger_rate = trigger_rate
        self.count = count
        with open(self.outfile, 'a+') as f:
            f.write('time' + ', ' + ', ' + 'total' + ', ' + 'write' + '\n')

    def run(self):
        for i in range(self.count):
            df = self.ssh.Exec('df -h', '#', timeout=2)
            data = list()
            for line in df.split('\r\n'):
                if 'database' in line:
                    line_list = [s.strip() for s in line.split(' ') if s.strip()]
                    if len(line_list) > 1:
                        data.append(('tokumx', line_list[1], line_list[3]))
                if 'rabbitmq' in line:
                    line_list = [s.strip() for s in line.split(' ') if s.strip()]
                    if len(line_list) > 1:
                        data.append(('rabbitmq', line_list[1], line_list[3]))
            self.report(data)
            time.sleep(self.interval)

    def finish(self):
        self.stop.set()
        self.join()

    def report(self, data):
        stats = data
        with open(self.outfile, 'a+') as f:
            for i in range(len(stats)):
                f.write(str(time.strftime("%Y-%b-%d %H:%M:%S")) + ', '
                        + str(stats[i][0]) + ', '
                        + str(stats[i][1]) + ', '
                        + str(stats[i][2]) + '\n')
            f.flush()


class ESANextgenStat(multiprocessing.Process):

    def __init__(self, esa_node, interval, timeout, fw_provider=None
                 , group=None, target=None, name=None
                 , args=(), kwargs={}, outfile='esa_stat_result'
                 , noise_rate=0, trigger_rate=0, count=0):

        # threading.Thread.__init__(self, group, target, name, args, kwargs)
        # self.stop = threading.Event()
        self.interval = interval
        self.timeout = timeout
        self.stats = list()
        self.esa_node = esa_node
        self.esa_client = EsaClientHarness(self.esa_node, user='root')
        self.fw_provider = fw_provider
        self.outfile = outfile
        self.noise_rate = noise_rate
        self.trigger_rate = trigger_rate
        self.count = count
        LOGGER.info('Collecting ESA stats for ' + str(self.esa_node))
        with open(self.outfile, 'a+') as f:
            if self.fw_provider is None:
                f.write('Time' + ', '
                        + 'NumEventsOffered' + ', '
                        + 'OfferedRate' + ', '
                        + 'MongoDBAlerts' + ', '
                        + 'FireRate' + ', '
                        + 'NumEventsFired' + ', '
                        + 'NextGenProcessRate' + ', '
                        + 'NextGenProcessCount' + ', '
                        + 'NextGenSessionsBehind' + ', '
                        + 'SecondsBetweenFeeds' + ', '
                        + 'ClockLagInSeconds' + ', '
                        + 'EsperWorkUnitProcessingRate' + ', '
                        + 'EsperWorkUnitsProcessed' + ', '
                        + 'EsperWindowDurationInSeconds' + ', '
                        + 'EsperWindowSize' + ', '
                        + 'RabbitMQAlerts' + '\n')
            else:
                f.write('Time' + ', '
                        + 'NumEventsOffered' + ', '
                        + 'OfferedRate' + ', '
                        + 'successfulNotifications' + ', '
                        + 'FireRate' + ', '
                        + 'NumEventsFired' + ', '
                        + 'NextGenProcessRate' + ', '
                        + 'NextGenProcessCount' + ', '
                        + 'NextGenSessionsBehind' + ', '
                        + 'RabbitMQAlerts' + ', '
                        + 'FW-successfulNotifications' + ', '
                        + 'FW-droppedNotifications' + '\n')

    def run(self):
        for i in range(self.count):
            data = list()
            esper_feeder_stats = self.esa_client.get_esperfeeder_stats()
            try:
                data.append((self.esa_client.get_num_events_offered()
                             , self.esa_client.get_offered_rate()['current']
                             , self.esa_client.get_notifications()['successfulNotifications']
                             , self.esa_client.get_fire_rate()['current']
                             , self.esa_client.get_num_events_fired()
                             , self.esa_client.get_nextgen_rate()
                             , self.esa_client.get_nextgen_count()
                             , self.esa_client.get_nextgen_sessions_behind()
                             , esper_feeder_stats['SecondsBetweenFeeds']
                             , esper_feeder_stats['ClockLagInSeconds']
                             , esper_feeder_stats['WorkUnitProcessingRate']
                             , esper_feeder_stats['WorkUnitsProcessed']
                             , esper_feeder_stats['WindowDurationInSeconds']
                             , esper_feeder_stats['WindowSize']
                             , self.esa_client.get_notifications(fw_provider='message_bus')[
                                 'successfulNotifications']))
                if self.fw_provider is not None:
                    data[0].append(
                        self.esa_client.get_notifications('distribution')['successfulNotifications']
                        , self.esa_client.get_notifications('distribution')[
                            'droppedNotifications']
                        , self.esa_client.get_global_num_events_offered()
                        , self.esa_client.get_global_offered_rate()['current'])
            except Exception as e:
                LOGGER.error(str(e))
            LOGGER.debug('data list values: %s', data)
            self.report(data)
            time.sleep(self.interval)

    def finish(self):
        self.stop.set()
        self.join()
        return

    def report(self, data):
        with open(self.outfile, 'a+') as f:
            f.write(str(time.strftime("%Y-%b-%d %H:%M:%S")) + ', '
                    + ', '.join(map(str, list(data[0]))) + '\n')
            f.flush()

    def report_global(self, data):
        stats = data
        with open(self.outfile, 'a+') as f:
            if len(f.readlines()) == 0:
                f.write('time' + ', '
                        + 'NumEventsOffered' + ', '
                        + 'OfferedRate' + ', '
                        + '\n')
            for i in range(len(stats)):
                f.write(str(i+1) + ', '
                        + str(stats[i][9]) + ', '
                        + str(stats[i][10]) + '\n')
            f.flush()


class LogDecoderConcentratorStat(multiprocessing.Process):

    def __init__(self, ld_node, c_node, interval, timeout, inj_node=None
                 , group=None, target=None, name=None
                 , args=(), kwargs={}, outfile='ld_stat_result'
                 , noise_rate=0, trigger_rate=0, count=0
                 , c_node_port=50105, ld_node_port=50102):
        # threading.Thread.__init__(self, group, target, name, args, kwargs)
        # self.stop = threading.Event()
        self.interval = interval
        self.timeout = timeout
        self.ld_node = ld_node
        self.ld_node_port = ld_node_port
        self.c_node = c_node
        self.c_node_port = c_node_port
        self.inj_node = inj_node
        self.noise_rate = noise_rate
        self.trigger_rate = trigger_rate
        self.count = count
        self.outfile = outfile
        with open(self.outfile, 'a+') as f:
            f.write('time' + ', '
                    + 'LogDecoderRate' + ', '
                    + 'LogDecoderCnt' + ', '
                    + 'ConcentratorRate' + ', '
                    + 'ConcentratorCnt' + ', '
                    + '\n')

    def get_session_rate(self, host, port):
        url = ('http://%s:%s/database/stats/session.rate' % (host, port))
        result = requests.get(url, auth=('admin', 'netwitness'))
        return re.findall(r'<string>(\d+)</string>', result.text)[0]

    def get_session_cnt(self, host, port):
        url = ('http://%s:%s/database/stats/session.total' % (host, port))
        result = requests.get(url, auth=('admin', 'netwitness'))
        return re.findall(r'<string>(\d+)</string>', result.text)[0]

    def run(self):
        for i in range(self.count):
            data = list()
            try:
                ld_rate = self.get_session_rate(self.ld_node, self.ld_node_port)
                ld_cnt = self.get_session_cnt(self.ld_node, self.ld_node_port)
                cn_rate = self.get_session_rate(self.c_node, self.c_node_port)
                cn_cnt = self.get_session_cnt(self.c_node, self.c_node_port)
                data.append((ld_rate, ld_cnt, cn_rate, cn_cnt))
            except requests.exceptions.ConnectionError:
                pass
            self.report(data)
            time.sleep(self.interval)

    def finish(self):
        self.stop.set()
        self.join()

    def report(self, data):
        stats = data
        with open(self.outfile, 'a+') as f:
            for i in range(len(stats)):
                f.write(str(time.strftime("%Y-%b-%d %H:%M:%S")) + ', '
                        + str(stats[i][0]) + ', '
                        + str(stats[i][1]) + ', '
                        + str(stats[i][2]) + ', '
                        + str(stats[i][3]) + '\n')


class ESAMongoStat(multiprocessing.Process):

    def __init__(self, esa_node, interval=5, count=2, timeout=120
                 , args=(), kwargs={}, group=None, target=None, name=None
                 , outfile='mongo_stat_result', trigger_rate=0, noise_rate=0):
        """Mongo stats with mongostat"""

        # threading.Thread.__init__(self, group, target, name, args, kwargs)
        # self.stop = threading.Event()
        self.host = esa_node
        self.esa_node = esa_node
        self.ssh = SshCommandClient(self.host, user='root', password=None)
        self.timeout = timeout
        self.interval = interval
        self.count = count
        self.t1 = None
        self.outfile = outfile
        self.trigger_rate = trigger_rate
        self.noise_rate = noise_rate
        header_text = self.ssh.Exec('mongostat -u datapuppy -p datapuppy -n 1 1', '#')
        with open(self.outfile, 'a+') as f:
            f.write('time, ' + ', '.join(header_text.split('\n')[2].split()) + '\n')

    def finish(self):
        ssh1 = SshCommandClient(self.host, user='root', password=None)
        try:
            ssh1.Exec('killall -s 3 mongostat', '#')
            ssh1.close()
        except OSError:
            pass
        self.ssh.close()
        self.t1.join()

    def run(self):
        cmd = 'mongostat -u datapuppy -p datapuppy --noheaders -n 1 1'
        for i in range(self.count):
            result = self.ssh.Exec(cmd, '#', timeout=self.timeout)
            result = ', '.join(result.split('\n')[2].split())
            self.report(result)
            time.sleep(self.interval)

    def report(self, data_list):
        with open(self.outfile, 'a+') as f:
            f.write(str(time.strftime("%Y-%b-%d %H:%M:%S")) + ', ' + data_list + '\n')
            f.flush()


class IOStat(multiprocessing.Process):

    def __init__(self, esa_node, interval=5, count=None, timeout=120
                 , group=None, target=None, name=None, args=(), kwargs={}
                 , outfile='io_stat_result', noise_rate=0, trigger_rate=0):
        """IO stats with iostat"""

        # threading.Thread.__init__(self, group, target, name, args, kwargs)
        # self.stop = threading.Event()
        self.host = esa_node
        self.esa_node = esa_node
        self.ssh = SshCommandClient(self.host, user='root', password=None)
        self.timeout = timeout
        self.interval = interval
        self.count = count
        self.t1 = None
        self.outfile = outfile
        self.noise_rate = noise_rate
        self.trigger_rate = trigger_rate
        with open(outfile, 'a+') as f:
            f.write('time, ' + 'Device, ' + 'rrqm/s, ' + 'wrqm/s, ' + 'r/s, '
                    + 'w/s, ' + 'rkB/s, ' + 'wkB/s, ' + 'avgrq-sz, ' + 'avgqu-sz'
                    + 'await, ' + 'svctm, ' + '%util' + '\n')

    def finish(self):
        ssh1 = SshCommandClient(self.host, user='root', password=None)
        try:
            ssh1.Exec('killall -s 3 iostat', '#')
            ssh1.close()
        except OSError:
            pass
        self.ssh.close()
        self.stop.set()
        self.join()

    def run(self):
        # Using VolGroup00-apps because it maps to /opt/rsa/databases
        cmd = 'iostat -x -k -N|grep apps'
        LOGGER.debug('Executing cmd: %s' % cmd)
        for i in range(self.count):
            result = self.ssh.Exec(cmd, '#')
            result = ', '.join(result.split('\n')[1].split())
            self.report(result)
            # change it to based on current time
            time.sleep(self.interval)

    def report(self, data):
        with open(self.outfile, 'a+') as f:
            f.write(str(time.strftime("%Y-%b-%d %H:%M:%S")) + ', ' + data + '\n')
            f.flush()


class FreeStat(multiprocessing.Process):

    def __init__(self, esa_node, interval=5, count=2, timeout=120
                 , group=None, target=None, name=None, args=(), kwargs={}
                 , outfile='free_mem_result', noise_rate=0, trigger_rate=0):
        """Memory usage stats with free"""

        # threading.Thread.__init__(self, group, target, name, args, kwargs)
        # self.stop = threading.Event()
        self.host = esa_node
        self.esa_node = esa_node
        self.ssh = SshCommandClient(self.host, user='root', password=None)
        self.timeout = timeout
        self.interval = interval
        self.count = count
        self.t1 = None
        self.outfile = outfile
        self.noise_rate = noise_rate
        self.trigger_rate = trigger_rate
        with open(self.outfile, 'a+') as f:
            f.write('time, ' + 'total, ' + 'used, ' + 'free' + '\n')

    def finish(self):
        ssh1 = SshCommandClient(self.host, user='root', password=None)
        try:
            ssh1.Exec('killall -s 3 free', '#')
            ssh1.close()
        except OSError:
            pass
        self.ssh.close()
        self.stop.set()
        self.join()

    def run(self):
        LOGGER.debug('Executing cmd: free')
        for i in range(self.count):
            result = self.ssh.Exec('free', '#')
            result = result.split('\n')[2].split()[1:4]
            a = [int(j) / 1024 for j in result]
            self.report(', '.join(map(str, a)))
            time.sleep(self.interval)

    def report(self, data):
        with open(self.outfile, 'a+') as f:
            f.write(str(time.strftime("%Y-%b-%d %H:%M:%S")) + ', ' + data + '\n')


class GCStat(multiprocessing.Process):
    """ Java Garbage Collection stats using jstat -gc."""

    def __init__(self, esa_node, interval=5, count=None, timeout=120, noise_rate=0
                 , group=None, target=None, name=None, args=(), kwargs={}
                 , trigger_rate=0, outfile='gc_stat_result'):

        # threading.Thread.__init__(self, group, target, name, args, kwargs)
        # self.stop = threading.Event()
        self.host = esa_node
        self.esa_node = esa_node
        self.ssh = SshCommandClient(self.host, user='root', password=None)
        self.timeout = timeout
        self.interval = interval
        self.count = count
        self.t1 = None
        self.outfile = outfile
        self.noise_rate = noise_rate
        self.trigger_rate = trigger_rate
        self.esa_pids = list()
        wrapper_pid = self.ssh.get_service_pid('rsa-esa')
        esa_pid = self.ssh.Exec('pgrep -P %s' % wrapper_pid, '#')
        esa_pid = esa_pid.replace("\r", "")
        esa_pid = esa_pid.split('\n')[1]
        self.esa_pids.append(esa_pid)
        result = self.ssh.Exec('jstat -gc -t %s 2>/dev/null' % self.esa_pids[0], '#')
        with open(self.outfile, 'a+') as f:
            f.write('time, ' + ', '.join(result.split('\n')[1].split()) + '\n')

    def finish(self):
        ssh1 = SshCommandClient(self.host, user='root', password=None)
        try:
            ssh1.Exec('killall -s 3 jstat', '#')
            ssh1.close()
        except OSError:
            pass
        self.ssh.close()
        self.stop.set()
        self.join()

    def run(self):
        cmd = ('jstat -gc -t %s 2>/dev/null' % self.esa_pids[0])
        LOGGER.debug('Executing cmd: %s' % cmd)
        for i in range(self.count):
            result = self.ssh.Exec(cmd, '#')
            result = ', '.join(result.split('\n')[2].split())
            self.report(result)
            time.sleep(self.interval)

    def report(self, data):
        with open(self.outfile, 'a+') as f:
            f.write(str(time.strftime("%Y-%b-%d %H:%M:%S")) + ', ' + data + '\n')
            f.flush()


class CollectStats(MPStat, IOStat, TopStat, ESAMongoStat, ESANextgenStat
                   , GCStat, FreeStat, DfStat, LogDecoderConcentratorStat):

    def __init__(self, **kwargs):
        for k, v in list(kwargs.items()):
            setattr(self, k, v)

        self.esa_nodes_stats_threads_dict = dict()
        for i in range(len(self.esa_nodes)):
            esa_stat = ESANextgenStat(self.esa_nodes[i].host, interval=self.interval
                                      , timeout=self.timeout, trigger_rate=self.trigger_rate
                                      , noise_rate=self.noise_rate, count=self.count
                                      , outfile=os.path.join(self.test_out_dir
                                                             , 'esa_stat_result%d' % i))
            mongo_stat = ESAMongoStat(self.esa_nodes[i].host, interval=self.interval,
                                      count=self.count
                                      , timeout=self.timeout
                                      , trigger_rate=self.trigger_rate, noise_rate=self.noise_rate
                                      , outfile=os.path.join(self.test_out_dir
                                                             , 'mongo_stat_result%d' % i))
            top_stat = TopStat(self.esa_nodes[i].host, interval=self.interval, count=self.count
                               , timeout=self.timeout
                               , trigger_rate=self.trigger_rate, noise_rate=self.noise_rate
                               , esa_outfile=os.path.join(self.test_out_dir
                                                          , 'top_esa_result%d' % i)
                               , mongo_outfile=os.path.join(self.test_out_dir
                                                            , 'top_mongo_result%d' % i)
                               , rabbit_outfile=os.path.join(self.test_out_dir
                                                             , 'top_rabbit_result%d' % i))
            mpstat = MPStat(self.esa_nodes[i].host, interval=self.interval, count=self.count
                            , timeout=self.timeout, trigger_rate=self.trigger_rate
                            , noise_rate=self.noise_rate, outfile=os.path.join(self.test_out_dir
                                                                               , 'cpu_stat_result%d'
                                                                               % i))
            df_stat = DfStat(self.esa_nodes[i].host, interval=self.interval, timeout=self.timeout
                             , trigger_rate=self.trigger_rate
                             , noise_rate=self.noise_rate, count=self.count
                             , outfile=os.path.join(self.test_out_dir, 'df_stat_result%d' % i))
            io_stat = IOStat(self.esa_nodes[i].host, interval=self.interval, count=self.count
                             , timeout=self.timeout, noise_rate=self.noise_rate
                             , trigger_rate=self.trigger_rate
                             , outfile=os.path.join(self.test_out_dir, 'io_stat_result%d' % i))
            free_stat = FreeStat(self.esa_nodes[i].host, interval=self.interval, count=self.count
                                 , timeout=self.timeout, noise_rate=self.noise_rate
                                 , trigger_rate=self.trigger_rate
                                 , outfile=os.path.join(self.test_out_dir, 'free_mem_result%d' % i))
            gc_stat = GCStat(self.esa_nodes[i].host, interval=self.interval, count=self.count
                             , timeout=self.timeout
                             , noise_rate=self.noise_rate, trigger_rate=self.trigger_rate
                             , outfile=os.path.join(self.test_out_dir, 'gc_result%d' % i))

            self.esa_nodes_stats_threads_dict[self.esa_nodes[i].host] = [mongo_stat, top_stat
                                                                         , mpstat, gc_stat, df_stat
                                                                         , io_stat, free_stat
                                                                         , esa_stat]

        self.ld_conc_stats_threads_list = list()
        for i in range(len(self.ld_nodes)):
            ld_c_stats = LogDecoderConcentratorStat(self.ld_nodes[i], self.cr_nodes[i]
                                                    , interval=self.interval, timeout=self.timeout
                                                    , outfile=os.path.join(self.test_out_dir
                                                                           , 'ld_c_result%d' % i)
                                                    , noise_rate=self.noise_rate
                                                    , trigger_rate=self.trigger_rate
                                                    , count=self.count)
            self.ld_conc_stats_threads_list.append(ld_c_stats)

    def get_threads(self):
        all_threads = list()
        for node, stat_threads in list(self.esa_nodes_stats_threads_dict.items()):
            for _thread in stat_threads:
                all_threads.append(_thread)
        all_threads += self.ld_conc_stats_threads_list
        return all_threads


# if __name__ == '__main__':
#
#     # from testconfig import config
#     from common.utils.utils import Utilities
#     import simplejson as json
#
#     file_obj = Utilities()
#     with open(file_obj.search_file('default.json')) as config_file:
#         config = json.load(config_file)
#     print(config)
#
#     timeout = 60 * config['psr_config']['timeout']
#     noise_rate = config['psr_config']['noise_rate']
#     trigger_rate = config['psr_config']['trigger_rate']
#     epl_count = config['psr_config']['epl_count']
#     interval = config['psr_config']['interval']
#     count = int(timeout / interval)
#     wait_after_publish = 60 * config['psr_config']['wait_after_publish']
#     start_consume = time.time()
#
#     esa_nodes = config['servers']['esa']
#     ld_nodes = config['servers']['log_decoder']
#     cr_nodes = config['servers']['concentrator']
#     noise_inj_nodes = config['servers']['injector']
#     trigger_inj_nodes = config['servers']['injector']
#
#     # Instantiate Stats Collection threads
#     stats = CollectStats(ld_nodes=ld_nodes
#                          , cr_nodes=cr_nodes
#                          , esa_nodes=esa_nodes
#                          , timeout=timeout, noise_rate=noise_rate
#                          , trigger_rate=trigger_rate, epl_count=epl_count
#                          , interval=interval, count=count
#                          , wait_after_publish=wait_after_publish
#                          , test_out_dir='.'
#                          , wake_up_time=start_consume + 30)
