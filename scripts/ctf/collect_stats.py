#!/usr/bin/env python

import os
import re
import time
import threading

import requests
from ctf.framework.logger import LOGGER
from mctf.framework import harness as mctf_harness


LOGGER.setLevel('DEBUG')


class ThreadWithReturnValue(threading.Thread):
    def __init__(self, group=None, target=None, name=None,
                 args=(), kwargs={}, verbose=None):
        threading.Thread.__init__(self, group, target, name, args, kwargs, verbose)
        self._return = None

    def run(self):
        if self._Thread__target is not None:
            self._return = self._Thread__target(*self._Thread__args
                                                , **self._Thread__kwargs)

    def join(self):
        threading.Thread.join(self)
        return self._return

    def result(self):
        return self._return


class TopStat(object):

    def __init__(self, esa_node, interval=5, count=2, timeout=180, esa_outfile='top_esa_result'
                 , trigger_rate=0, noise_rate=0, mongo_outfile='top_mongo_result'
                 , rabbit_outfile='top_rabbit_result'):
        """ESA/Mongo/RabbitMQ Process top stats"""

        self.host = esa_node
        self.esa_node = esa_node
        self.ssh = mctf_harness.SshCommandClient(self.host, user='root', password=None)
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
        esa_pid = self.ssh.command('pgrep -P %s' % wrapper_pid, '#')
        self.esa_pids.append(esa_pid.split('\n')[-2])
        LOGGER.debug('ESA Server pid: %s', self.esa_pids)
        # calculating rabbitmq pid
        output = self.ssh.command('service rabbitmq-server status|grep pid', '#')
        self.rabbitmq_pid = output.split(',')[1].split('}')[0]
        LOGGER.debug('RabbitMQ pid: %s', self.rabbitmq_pid)
        # calculating tokumx pid
        output = self.ssh.command('service tokumx status', '#')
        self.mongodb_pid = output.split('\n')[1].split('pid ')[1].split(')')[0].strip()
        LOGGER.debug('TokuMX/MongoDB pid: %s', self.mongodb_pid)

    def start(self):
        self.t1 = ThreadWithReturnValue(target=self.topstat)
        self.t1.start()

    def finish(self):
        ssh1 = mctf_harness.SshCommandClient(self.host, user='root', password=None)
        try:
            ssh1.command('killall -s 3 top', '#')
            ssh1.close()
        except OSError:
            pass
        self.ssh.close()
        self.t1.join()

    def topstat(self):
        cmd = ('top -b -d 1 -n 1 | egrep \'^%s|^%s|^%s\''
               % (self.esa_pids[0], self.mongodb_pid, self.rabbitmq_pid))
        for i in xrange(self.count):
            result = self.ssh.command(cmd, '#', timeout=self.timeout)
            [j_mem, m_mem, r_mem] = self.get_top(result)
            self.report(self.esa_outfile, j_mem)
            self.report(self.mongo_outfile, m_mem)
            self.report(self.rabbit_outfile, r_mem)
            time.sleep(self.interval)

    def get_top(self, result):
        top_result = result.split('\n')[8:]
        java_mem = list()
        mongo_mem = list()
        rabbit_mem = list()
        for line in top_result:
            line_list = line.split()
            if len(line_list) and line_list[-1] == 'java':
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


class MPStat(object):

    def __init__(self, esa_node, interval=5, count=None, timeout=120, noise_rate=0
                 , trigger_rate=0, outfile='cpu_stat_result'):
        """System CPU stats with memstat"""

        self.host = esa_node
        self.esa_node = esa_node
        self.ssh = mctf_harness.SshCommandClient(self.host, user='root', password=None)
        self.timeout = timeout
        self.interval = interval
        self.count = count
        self.t1 = None
        self.outfile = outfile
        self.noise_rate = noise_rate
        self.trigger_rate = trigger_rate
        header_text = self.ssh.command('mpstat 1 1', '#')
        with open(self.outfile, 'a+') as f:
            f.write('time, ' + ', '.join(header_text.split('\n')[3].split()[2:]) + '\n')

    def start(self):
        self.t1 = ThreadWithReturnValue(target=self.mp_stat)
        self.t1.start()

    def finish(self):
        ssh1 = mctf_harness.SshCommandClient(self.host, user='root', password=None)
        try:
            ssh1.command('killall -s 3 mpstat', '#')
            ssh1.close()
        except OSError:
            pass
        self.ssh.close()
        self.t1.join()

    def mp_stat(self):
        cmd = 'mpstat 1 1'
        for i in xrange(self.count):
            result = self.ssh.command(cmd, '#')
            data = ', '.join(result.split('\n')[4].split()[2:])
            self.report(data)
            time.sleep(self.interval)

    def report(self, data):
        with open(self.outfile, 'a+') as f:
            f.write(str(time.strftime("%Y-%b-%d %H:%M:%S")) + ', ' + data + '\n')
            f.flush()


class DfStat(threading.Thread):

    def __init__(self, esa_node, interval, timeout,
                 group=None, target=None, name=None,
                 args=(), kwargs={}, Verbose=None, count=1, noise_rate=0
                 , trigger_rate=0, outfile='df_result'):
        threading.Thread.__init__(self, group, target, name, args, kwargs, Verbose)
        self.host = esa_node
        self.esa_node = esa_node
        self.stop = threading.Event()
        self.ssh = mctf_harness.SshCommandClient(self.host, user='root', password=None)
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
        for i in xrange(self.count):
            df = self.ssh.command('df -h', '#', timeout=2)
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
            for i in xrange(len(stats)):
                f.write(str(time.strftime("%Y-%b-%d %H:%M:%S")) + ', '
                        + str(stats[i][0]) + ', '
                        + str(stats[i][1]) + ', '
                        + str(stats[i][2]) + '\n')
            f.flush()


class ESANextgenStat(threading.Thread):

    def __init__(self, esa_node, interval, timeout, fw_provider=None
                 , group=None, target=None, name=None
                 , args=(), kwargs={}, Verbose=None, outfile='esa_stat_result'
                 , noise_rate=0, trigger_rate=0, count=0):

        threading.Thread.__init__(self, group, target, name, args, kwargs, Verbose)

        self.stop = threading.Event()
        self.interval = interval
        self.timeout = timeout
        self.stats = list()
        self.esa_node = esa_node
        self.esa_client = mctf_harness.EsaClient(self.esa_node, user='root')
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
        for i in xrange(self.count):
            data = list()
            try:
                data.append((self.esa_client.get_NumEventsOffered()
                             , self.esa_client.get_OfferedRate()['current']
                             , self.esa_client.get_Notifications()['successfulNotifications']
                             , self.esa_client.get_FireRate()['current']
                             , self.esa_client.get_NumEventsFired()
                             , self.esa_client.get_nextgen_rate()
                             , self.esa_client.get_nextgen_count()
                             , self.esa_client.get_nextgen_sessionsBehind()
                             , self.esa_client.get_Notifications(fw_provider='message_bus')[
                                 'successfulNotifications']))
                if self.fw_provider is not None:
                    data[0].append(
                        self.esa_client.get_Notifications('distribution')['successfulNotifications']
                        , self.esa_client.get_Notifications('distribution')[
                            'droppedNotifications']
                        , self.esa_client.get_global_NumEventsOffered()
                        , self.esa_client.get_global_OfferedRate()['current'])
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
        stats = data
        with open(self.outfile, 'a+') as f:
            for i in xrange(len(stats)):
                f.write(str(time.strftime("%Y-%b-%d %H:%M:%S")) + ', '
                        + str(stats[i][0]) + ', '
                        + str(stats[i][1]) + ', '
                        + str(stats[i][2]) + ', '
                        + str(stats[i][3]) + ', '
                        + str(stats[i][4]) + ', '
                        + str(stats[i][5]) + ', '
                        + str(stats[i][6]) + ', '
                        + str(stats[i][7]) + ', '
                        + str(stats[i][8]) + '\n')
            f.flush()

    def report_global(self, data):
        stats = data
        with open(self.outfile, 'a+') as f:
            if len(f.readlines()) == 0:
                f.write('time' + ', '
                        + 'NumEventsOffered' + ', '
                        + 'OfferedRate' + ', '
                        + '\n')
            for i in xrange(len(stats)):
                f.write(str(i+1) + ', '
                        + str(stats[i][9]) + ', '
                        + str(stats[i][10]) + '\n')
            f.flush()


class LogDecoderConcentratorStat(threading.Thread):

    def __init__(self, ld_node, c_node, interval, timeout, inj_node=None
                 , group=None, target=None, name=None
                 , args=(), kwargs={}, Verbose=None, outfile='ld_stat_result'
                 , noise_rate=0, trigger_rate=0, count=0
                 , c_node_port=50105, ld_node_port=50102):
        threading.Thread.__init__(self, group, target, name, args, kwargs, Verbose)

        self.stop = threading.Event()
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
        for i in xrange(self.count):
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
            for i in xrange(len(stats)):
                f.write(str(time.strftime("%Y-%b-%d %H:%M:%S")) + ', '
                        + str(stats[i][0]) + ', '
                        + str(stats[i][1]) + ', '
                        + str(stats[i][2]) + ', '
                        + str(stats[i][3]) + '\n')


class ESAMongoStat(object):

    def __init__(self, esa_node, interval=5, count=2, timeout=120
                 , outfile='mongo_stat_result', trigger_rate=0, noise_rate=0):
        """Mongo stats with mongostat"""

        self.host = esa_node
        self.esa_node = esa_node
        self.ssh = mctf_harness.SshCommandClient(self.host, user='root', password=None)
        self.timeout = timeout
        self.interval = interval
        self.count = count
        self.t1 = None
        self.outfile = outfile
        self.trigger_rate = trigger_rate
        self.noise_rate = noise_rate
        header_text = self.ssh.command('mongostat -u datapuppy -p datapuppy -n 1 1', '#')
        with open(self.outfile, 'a+') as f:
            f.write('time, ' + ', '.join(header_text.split('\n')[2].split()) + '\n')

    def start(self):
        self.t1 = ThreadWithReturnValue(target=self.mongostat)
        self.t1.start()

    def finish(self):
        ssh1 = mctf_harness.SshCommandClient(self.host, user='root', password=None)
        try:
            ssh1.command('killall -s 3 mongostat', '#')
            ssh1.close()
        except OSError:
            pass
        self.ssh.close()
        self.t1.join()

    def mongostat(self):
        cmd = 'mongostat -u datapuppy -p datapuppy --noheaders -n 1 1'
        for i in xrange(self.count):
            result = self.ssh.command(cmd, '#', timeout=self.timeout)
            result = ', '.join(result.split('\n')[2].split())
            self.report(result)
            time.sleep(self.interval)

    def report(self, data_list):
        with open(self.outfile, 'a+') as f:
            f.write(str(time.strftime("%Y-%b-%d %H:%M:%S")) + ', ' + data_list + '\n')
            f.flush()


class IOStat(object):

    def __init__(self, esa_node, interval=5, count=None, timeout=120
                 , outfile='io_stat_result', noise_rate=0, trigger_rate=0):
        """IO stats with iostat"""

        self.host = esa_node
        self.esa_node = esa_node
        self.ssh = mctf_harness.SshCommandClient(self.host, user='root', password=None)
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

    def start(self):
        self.t1 = ThreadWithReturnValue(target=self.iostat)
        self.t1.start()

    def finish(self):
        ssh1 = mctf_harness.SshCommandClient(self.host, user='root', password=None)
        try:
            ssh1.command('killall -s 3 iostat', '#')
            ssh1.close()
        except OSError:
            pass
        self.ssh.close()
        self.t1.join()

    def iostat(self):
        # Using VolGroup00-apps because it maps to /opt/rsa/databases
        cmd = 'iostat -x -k -N|grep apps'
        LOGGER.debug('Executing cmd: %s' % cmd)
        for i in xrange(self.count):
            result = self.ssh.command(cmd, '#')
            result = ', '.join(result.split('\n')[1].split())
            self.report(result)
            # change it to based on current time
            time.sleep(self.interval)

    def report(self, data):
        with open(self.outfile, 'a+') as f:
            f.write(str(time.strftime("%Y-%b-%d %H:%M:%S")) + ', ' + data + '\n')
            f.flush()


class FreeStat(object):

    def __init__(self, esa_node, interval=5, count=2, timeout=120
                 , outfile='free_mem_result', noise_rate=0, trigger_rate=0):
        """Memory usage stats with free"""

        self.host = esa_node
        self.esa_node = esa_node
        self.ssh = mctf_harness.SshCommandClient(self.host, user='root', password=None)
        self.timeout = timeout
        self.interval = interval
        self.count = count
        self.t1 = None
        self.outfile = outfile
        self.noise_rate = noise_rate
        self.trigger_rate = trigger_rate
        with open(self.outfile, 'a+') as f:
            f.write('time, ' + 'total, ' + 'used, ' + 'free' + '\n')

    def start(self):
        self.t1 = ThreadWithReturnValue(target=self.freestat)
        self.t1.start()

    def finish(self):
        ssh1 = mctf_harness.SshCommandClient(self.host, user='root', password=None)
        try:
            ssh1.command('killall -s 3 free', '#')
            ssh1.close()
        except OSError:
            pass
        self.ssh.close()
        self.t1.join()

    def freestat(self):
        LOGGER.debug('Executing cmd: free')
        for i in xrange(self.count):
            result = self.ssh.command('free', '#')
            result = result.split('\n')[2].split()[1:4]
            a = [int(j) / 1024 for j in result]
            self.report(', '.join(map(str, a)))
            time.sleep(self.interval)

    def report(self, data):
        with open(self.outfile, 'a+') as f:
            f.write(str(time.strftime("%Y-%b-%d %H:%M:%S")) + ', ' + data + '\n')


class GCStat(object):
    """ Java Garbage Collection stats using jstat -gc."""

    def __init__(self, esa_node, interval=5, count=None, timeout=120, noise_rate=0
                 , trigger_rate=0, outfile='gc_stat_result'):
        self.host = esa_node
        self.esa_node = esa_node
        self.ssh = mctf_harness.SshCommandClient(self.host, user='root', password=None)
        self.timeout = timeout
        self.interval = interval
        self.count = count
        self.t1 = None
        self.outfile = outfile
        self.noise_rate = noise_rate
        self.trigger_rate = trigger_rate
        self.esa_pids = list()
        wrapper_pid = self.ssh.get_service_pid('rsa-esa')
        esa_pid = self.ssh.command('pgrep -P %s' % wrapper_pid, '#')
        esa_pid = esa_pid.replace("\r", "")
        esa_pid = esa_pid.split('\n')[1]
        self.esa_pids.append(esa_pid)
        result = self.ssh.command('jstat -gc -t %s 2>/dev/null' % self.esa_pids[0], '#')
        with open(self.outfile, 'a+') as f:
            f.write('time, ' + ', '.join(result.split('\n')[1].split()) + '\n')

    def start(self):
        self.t1 = ThreadWithReturnValue(target=self.jstat)
        self.t1.start()

    def finish(self):
        ssh1 = mctf_harness.SshCommandClient(self.host, user='root', password=None)
        try:
            ssh1.command('killall -s 3 jstat', '#')
            ssh1.close()
        except OSError:
            pass
        self.ssh.close()
        self.t1.join()

    def jstat(self):
        cmd = ('jstat -gc -t %s 2>/dev/null' % self.esa_pids[0])
        LOGGER.debug('Executing cmd: %s' % cmd)
        for i in xrange(self.count):
            result = self.ssh.command(cmd, '#')
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
        for k, v in kwargs.items():
            setattr(self, k, v)

        i = 0
        top_stat = TopStat(self.esa_nodes[i], interval=self.interval, count=self.count
                           , timeout=self.timeout
                           , trigger_rate=self.trigger_rate, noise_rate=self.noise_rate
                           , esa_outfile=os.path.join(self.test_out_dir
                                                      , 'top_esa_result%d' % i)
                           , mongo_outfile=os.path.join(self.test_out_dir
                                                        , 'top_mongo_result%d' % i)
                           , rabbit_outfile=os.path.join(self.test_out_dir
                                                         , 'top_rabbit_result%d' % i))

        gc_stat = GCStat(self.esa_nodes[i], interval=self.interval, count=self.count
                         , timeout=self.timeout
                         , noise_rate=self.noise_rate, trigger_rate=self.trigger_rate
                         , outfile=os.path.join(self.test_out_dir, 'gc_result%d' % i))

    def run(self):
        import multiprocessing as mp
        pool = mp.Pool(processes=2)
        results.append(pool.apply_async(gc_stat.jstat()))
        results.append(pool.apply_async(top_stat.topstat()))

if __name__ == '__main__':
    esa_node = '10.101.59.231'
    timeout = 60 * 2
    noise_rate = 60000
    trigger_rate = 3000
    epl_count = 20
    count = int(timeout/2)
    interval = 2
    wait_after_publish = 10
    p = CollectStats(ld_nodes=['10.101.59.238']
                   , cr_nodes=['10.101.59.240']
                   , esa_nodes=[esa_node]
                   , timeout=timeout, noise_rate=noise_rate
                   , trigger_rate=trigger_rate, epl_count=epl_count
                   , interval=interval, count=count
                   , wait_after_publish=wait_after_publish
                   , test_out_dir='.')
    p.run()

#
#         self.esa_nodes_stats_threads_dict = dict()
#         for i in xrange(len(self.esa_nodes)):
#             esa_stat = ESANextgenStat(self.esa_nodes[i], interval=self.interval
#                                       , timeout=self.timeout, trigger_rate=self.trigger_rate
#                                       , noise_rate=self.noise_rate, count=self.count
#                                       , outfile=os.path.join(self.test_out_dir
#                                                              , 'esa_stat_result%d' % i))
#             mongo_stat = ESAMongoStat(self.esa_nodes[i], interval=self.interval, count=self.count
#                                       , timeout=self.timeout
#                                       , trigger_rate=self.trigger_rate, noise_rate=self.noise_rate
#                                       , outfile=os.path.join(self.test_out_dir
#                                                              , 'mongo_stat_result%d' % i))
#             top_stat = TopStat(self.esa_nodes[i], interval=self.interval, count=self.count
#                                , timeout=self.timeout
#                                , trigger_rate=self.trigger_rate, noise_rate=self.noise_rate
#                                , esa_outfile=os.path.join(self.test_out_dir
#                                                           , 'top_esa_result%d' % i)
#                                , mongo_outfile=os.path.join(self.test_out_dir
#                                                             , 'top_mongo_result%d' % i)
#                                , rabbit_outfile=os.path.join(self.test_out_dir
#                                                              , 'top_rabbit_result%d' % i))
#             mpstat = MPStat(self.esa_nodes[i], interval=self.interval, count=self.count
#                             , timeout=self.timeout, trigger_rate=self.trigger_rate
#                             , noise_rate=self.noise_rate, outfile=os.path.join(self.test_out_dir
#                                                                                , 'cpu_stat_result%d'
#                                                                                % i))
#             df_stat = DfStat(self.esa_nodes[i], interval=self.interval, timeout=self.timeout
#                              , trigger_rate=self.trigger_rate
#                              , noise_rate=self.noise_rate, count=self.count
#                              , outfile=os.path.join(self.test_out_dir, 'df_stat_result%d' % i))
#             io_stat = IOStat(self.esa_nodes[i], interval=self.interval, count=self.count
#                              , timeout=self.timeout, noise_rate=self.noise_rate
#                              , trigger_rate=self.trigger_rate
#                              , outfile=os.path.join(self.test_out_dir, 'io_stat_result%d' % i))
#             free_stat = FreeStat(self.esa_nodes[i], interval=self.interval, count=self.count
#                                  , timeout=self.timeout, noise_rate=self.noise_rate
#                                  , trigger_rate=self.trigger_rate
#                                  , outfile=os.path.join(self.test_out_dir, 'free_mem_result%d' % i))
#             gc_stat = GCStat(self.esa_nodes[i], interval=self.interval, count=self.count
#                              , timeout=self.timeout
#                              , noise_rate=self.noise_rate, trigger_rate=self.trigger_rate
#                              , outfile=os.path.join(self.test_out_dir, 'gc_result%d' % i))
#
#             self.esa_nodes_stats_threads_dict[self.esa_nodes[i]] = [mongo_stat, top_stat, mpstat
#                                                                     , gc_stat, df_stat, io_stat
#                                                                     , free_stat, esa_stat]
#
#         self.ld_conc_stats_threads_list = list()
#         for i in xrange(len(self.ld_nodes)):
#             ld_c_stats = LogDecoderConcentratorStat(self.ld_nodes[i], self.cr_nodes[i]
#                                                     , interval=self.interval, timeout=self.timeout
#                                                     , outfile=os.path.join(self.test_out_dir
#                                                                            , 'ld_c_result%d' % i)
#                                                     , noise_rate=self.noise_rate
#                                                     , trigger_rate=self.trigger_rate
#                                                     , count=self.count)
#             self.ld_conc_stats_threads_list.append(ld_c_stats)
#
#     def get_threads(self):
#         all_threads = list()
#         for node, stat_threads in self.esa_nodes_stats_threads_dict.iteritems():
#             for _thread in stat_threads:
#                 all_threads.append(_thread)
#         all_threads += self.ld_conc_stats_threads_list
#         return all_threads
