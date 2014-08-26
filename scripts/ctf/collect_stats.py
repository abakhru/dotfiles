#!/usr/bin/env python

import pexpect
import threading
import re
from ctf.framework.logger import LOGGER
from mctf.framework import harness as mctf_harness
import time

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


class Top(object):

    def __init__(self, esa_node, interval=5, count=2, timeout=180, esa_outfile='top_esa_result'
                 , trigger_rate=0, noise_rate=0, mongo_outfile='top_mongo_result'):
        """Process mem stats with top"""

        # self.host = esa_node.host
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
        self.t1 = None
        with open(self.mongo_outfile, 'a+', buffering=1) as f:
            f.write('time' + ', ' + 'noise rate' + ', ' + 'target rate' + ', '
                    + 'VIRT' + ', ' + 'RES' + ', ' + '%CPU' + '\n')
        with open(self.esa_outfile, 'a+', buffering=1) as f:
            f.write('time' + ', ' + 'noise rate' + ', ' + 'target rate' + ', '
                    + 'VIRT' + ', ' + 'RES' + ', ' + '%CPU' + '\n')

    def start(self):
        self.t1 = ThreadWithReturnValue(target=self.topstat)
        # self.t1.daemon = True
        self.t1.start()

    def finish(self):
        ssh1 = mctf_harness.SshCommandClient(self.host, user='root', password=None)
        try:
            ssh1.command('killall -s 3 top', '#')
            ssh1.close()
        except:
            pass
        self.t1.join()
        self.ssh.close()

    def topstat(self):
        cmd = 'top -b -d 1 -n 1'
        for i in xrange(self.count):
            result = self.ssh.command(cmd, '#', timeout=self.timeout)
            [j_mem, m_mem] = self.get_top(result)
            self.report_java_mem(j_mem, i+1)
            self.report_mongo_mem(m_mem, i+1)
            time.sleep(self.interval)

    def get_top(self, result):
        top_result = result
        a = top_result.split('\r\n')
        java_mem = list()
        mongo_mem = list()
        esa_pids = list()
        wrapper_pid = self.ssh.get_service_pid('rsa-esa')
        esa_pid = self.ssh.command('pgrep -P %s' % wrapper_pid, '#')
        esa_pid = esa_pid.replace("\r", "")
        esa_pid = esa_pid.split('\n')[-2]
        esa_pids.append(esa_pid)

        #   PID     USER     PR  NI    VIRT      RES     SHR    S   %CPU    %MEM  TIME+  COMMAND
        # ['17736', 'root', '20', '0', '80.3g', '3.0g', '18m', 'S', '0.0', '3.1', '2:39.70', 'java']
        res = 0
        for line in a:
            line_list = [s.strip() for s in line.split(' ') if s.strip()]
            # ESA java process has very long classpath so length will be more
            if len(line_list) > 10:
                if esa_pids[0] in line_list[0]:
                    if line_list[4][-1] == 'g':
                        vir = float(line_list[4][:-1]) * 1024
                    elif line_list[4][-1] == 'm':
                        vir = float(line_list[4][:-1])
                    if line_list[5][-1] == 'g':
                        res = float(line_list[5][:-1])  * 1024
                    elif line_list[5][-1] == 'm':
                        res = float(line_list[5][:-1])
                    java_mem.append((vir, res, line_list[8]))
            if 'toku' in line:
                if line_list[4][-1] == 'g':
                    vir = float(line_list[4][:-1]) * 1024
                elif line_list[4][-1] == 'm':
                    vir = float(line_list[4][:-1])
                if line_list[5][-1] == 'g':
                    res = float(line_list[5][:-1])  * 1024
                elif line_list[5][-1] == 'm':
                    res = float(line_list[5][:-1])
                mongo_mem.append((vir, res, line_list[8]))
        return [java_mem, mongo_mem]

    def report_java_mem(self, result, loop_count):
        mem = result
        with open(self.esa_outfile, 'a+', buffering=1) as f:
            for i in xrange(len(mem)):
                f.write(str(loop_count) + ', ' + str(self.noise_rate) + ', ' + str(self.trigger_rate) + ', '
                        + str(mem[i][0]) + ', ' + str(mem[i][1]) + ', ' + str(mem[i][2]) + '\n')
            f.flush()

    def report_mongo_mem(self, result, loop_count):
        mem = result
        with open(self.mongo_outfile, 'a+', buffering=1) as f:
            for i in xrange(len(mem)):
                f.write(str(loop_count) + ', ' + str(self.noise_rate) + ', ' + str(self.trigger_rate) + ', '
                        + str(mem[i][0]) + ', ' + str(mem[i][1]) + ', ' + str(mem[i][2]) + '\n')
            f.flush()


class MPStat(object):

    def __init__(self, esa_node, interval=5, count=None, timeout=120, noise_rate=0
                 , trigger_rate=0, outfile='cpu_stat_result'):
        """CPU stats with memstat"""

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
            f.write('time' + ', ' + 'noise rate' + ', ' + 'target rate' + ', '
                    + '%usr' + ', ' +  '%sys'+ '\n')

    def start(self):
        self.t1 = ThreadWithReturnValue(target=self.mpstat)
        # self.t1.daemon = True
        self.t1.start()

    def finish(self):
        ssh1 = mctf_harness.SshCommandClient(self.host, user='root', password=None)
        try:
            ssh1.command('killall -s 3 mpstat', '#')
            ssh1.close()
        except:
            pass
        self.t1.join()

    def mpstat(self):
        cmd = 'mpstat 1 1'
        for i in xrange(self.count):
            result = self.ssh.command(cmd, '#')
            data = self.get_cpu(result)
            self.report(data, i+1)
            time.sleep(self.interval)

    def get_cpu(self, data):
        memstat_result = data
        a = memstat_result.split('\r\n')[4]
        # print 'a list:', a
        cpu_pct=list()
        line_list = a.split('    ')
        if len(line_list) > 3:
            cpu_pct.append((line_list[0], line_list[1], line_list[3]))
        return cpu_pct

    def report(self, data, loop_count):
        cpu = data
        with open(self.outfile, 'a+') as f:
            for i in xrange(len(cpu)):
                f.write(str(loop_count) + ', ' + str(self.noise_rate) + ', '
                        +  str(self.trigger_rate) + ', '
                        +  str(cpu[i][1]) + ', ' +  str(cpu[i][2]) + '\n')
            f.flush()


class Df(threading.Thread):

    def __init__(self, esa_node, interval, timeout,
                 group=None, target=None, name=None,
                 args=(), kwargs={}, Verbose=None, count=1, noise_rate=0
                 , trigger_rate=0, outfile='df_result'):
        threading.Thread.__init__(self, group, target, name, args, kwargs, Verbose)
        self.host = esa_node#.host
        self.esa_node = esa_node
        self.stop  = threading.Event()
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
            f.write('time' + ', ' + 'noise rate'+ ', '
                    + 'target rate' + ', ' + 'total' + ', ' + 'write'+ '\n')

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
            self.report(data, i+1)
            time.sleep(self.interval)

    def finish(self):
        self.stop.set()
        self.join()

    def report(self, data, loop_count):
        stats = data
        with open(self.outfile, 'a+') as f:
            for i in xrange(len(stats)):
                f.write(str(loop_count) + ', ' + str(self.noise_rate) + ', '
                        + str(self.trigger_rate) + ', '
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

        self.stop  = threading.Event()
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
        with open(self.outfile, 'a+') as f:
            if len(f.readlines()) == 0:
                f.write('time' + ', '
                        + 'noise rate'+ ', '
                        + 'target rate'+ ', '
                        + 'NumEventsOffered'+ ', '
                        + 'OfferedRate' + ', '
                        + 'successfulNotifications' + ', '
                        + 'FireRate' + ', '
                        + 'NumEventsFired' + ', '
                        + 'FW-successfulNotifications' + ', '
                        + 'FW-droppedNotifications' + ', '
                        + '\n')

    def run(self):
        end_time = time.time() + self.timeout
        for i in xrange(self.count):
            data = list()
            try:
                if self.fw_provider is None:
                    LOGGER.info('Collecting stats for ' + str(self.esa_node))
                    data.append((self.esa_client.get_NumEventsOffered()
                               , self.esa_client.get_OfferedRate()['current']
                               , self.esa_client.get_Notifications()['successfulNotifications']
                               , self.esa_client.get_FireRate()['current']
                               , self.esa_client.get_NumEventsFired()
                               , '', '', ''))
                    self.report(data, i+1)
                else:
                    LOGGER.info('Collecting stats for ' + str(self.esa_node))
                    data.append((self.esa_client.get_NumEventsOffered()
                               , self.esa_client.get_OfferedRate()['current']
                               , self.esa_client.get_Notifications()['successfulNotifications']
                               , self.esa_client.get_FireRate()['current']
                               , self.esa_client.get_NumEventsFired()
                               , self.esa_client.get_Notifications('distribution')['successfulNotifications']
                               , self.esa_client.get_Notifications('distribution')['droppedNotifications']
                               , self.esa_client.get_global_NumEventsOffered()
                               , self.esa_client.get_global_OfferedRate()['current']))
                    self.report(data, i+1)
            except Exception as e:
                LOGGER.error('******************** %s', str(e))
                LOGGER.error('Failed to collect ESA stats')
            time.sleep(self.interval)

    def finish(self):
        self.stop.set()
        self.join()
        return

    def report(self, data, loop_count):
        stats = data
        with open(self.outfile, 'a+') as f:
            for i in xrange(len(stats)):
                f.write(str(loop_count) + ', '
                        + str(self.noise_rate) + ', '
                        + str(self.trigger_rate) + ', '
                        + str(stats[i][0]) + ', '
                        + str(stats[i][1]) + ', '
                        + str(stats[i][2]) + ', '
                        + str(stats[i][3]) + ', '
                        + str(stats[i][4]) + ', '
                        + str(stats[i][5]) + ', '
                        + str(stats[i][6]) + '\n')
            f.flush()

    def report_global(self, data, loop_count):
        stats = data
        with open(self.outfile, 'a+') as f:
            if len(f.readlines()) == 0:
                f.write('time' + ', '
                        + 'noise rate'+ ', '
                        + 'target rate'+ ', '
                        + 'NumEventsOffered'+ ', '
                        + 'OfferedRate' + ', '
                        + '\n')
            for i in xrange(len(stats)):
                f.write(str(i+1) + ', '
                        + str(noise_rate) + ', '
                        + str(trigger_rate) + ', '
                        + str(stats[i][7]) + ', '
                        + str(stats[i][8]) + '\n')
            f.flush()


class LogDecoderConcentratorStat(threading.Thread):

    def __init__(self, ld_node, c_node, interval, timeout, inj_node
                 , group=None, target=None, name=None
                 , args=(), kwargs={}, Verbose=None, outfile='ld_stat_result'
                 , noise_rate=0, trigger_rate=0, count=0
                 , c_node_port=50105, ld_node_port=50102):
        threading.Thread.__init__(self, group, target, name, args, kwargs, Verbose)

        self.stop  = threading.Event()
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
        with open(self.outfile, 'a+') as f:
            f.write('time' + ', '
                    + 'noise rate'+ ', '
                    + 'target rate'+ ', '
                    + 'LogDecoderRate' + ', '
                    + 'LogDecoderCnt'+ ', '
                    + 'ConcentratorRate'+ ', '
                    + 'ConcentratorCnt'+ ', '
                    + '\n')

    def get_session_rate(self, host, port):
        cmd = ('curl -u admin:netwitness "http://%s:%s/database/stats/session.rate"' % (host, port))
        rate = self.inj_node.ssh.command(cmd, '#')
        return re.findall(r'<string>(\d+)</string>', rate)[0]

    def get_session_cnt(self, host, port):
        cmd = ('curl -u admin:netwitness "http://%s:%s/database/stats/session.total"' % (host, port))
        cnt = self.inj_node.ssh.command(cmd, '#')
        try:
            cnt_result = re.findall(r'<string>(\d+)</string>', cnt)
            if len(cnt_result) > 0:
                return cnt_result[0]
            return 0
        except:
            return 0

    def run(self):
        for i in xrange(self.count):
            data = list()
            try:
                ld_rate = self.get_session_rate(self.ld_node, self.ld_node_port)
                ld_cnt = self.get_session_cnt(self.ld_node, self.ld_node_port)
                cn_rate = self.get_session_rate(self.c_node, self.c_node_port)
                cn_cnt = self.get_session_cnt(self.c_node, self.c_node_port)
                data.append((ld_rate, ld_cnt, cn_rate, cn_cnt))
            except:
                pass
            self.report(data, i+1)
            time.sleep(self.interval)

    def finish(self):
        self.stop.set()
        self.join()

    def report(self, data, loop_count):
        stats = data
        with open(self.outfile, 'a+') as f:
            for i in xrange(len(stats)):
                f.write(str(loop_count) + ', '
                        + str(self.noise_rate) + ', '
                        + str(self.trigger_rate) + ', '
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
        with open(self.outfile, 'a+') as f:
            f.write('time' + ', ' + 'noise rate'
                    + ', ' + 'target rate' + ', ' + 'inserts' + ', ' + 'queue'+ '\n')

    def start(self):
        self.t1 = ThreadWithReturnValue(target=self.mongostat)
        # self.t1.daemon = True
        self.t1.start()

    def finish(self):
        ssh1 = mctf_harness.SshCommandClient(self.host, user='root', password=None)
        try:
            ssh1.command('killall -s 3 mongostat', '#')
            ssh1.close()
        except:
            pass
        self.t1.join()

    def mongostat(self):
        cmd = 'mongostat -u datapuppy -p datapuppy --noheaders -n 1 1'
        for i in xrange(self.count):
            result = self.ssh.command(cmd, '#', timeout=self.timeout)
            data_list = self.get_mongostat(result)
            self.report(data_list, i+1)
            time.sleep(self.interval)

    def get_mongostat(self, data):
        line = data.split('\r\n')[2]
        mongo=list()
        line_list = [s.strip() for s in line.split('  ') if s.strip()]
        # print 'current line list: ', line_list
        if len(line_list) > 1:
            mongo.append((line_list[0], line_list[8]))
        return mongo

    def report(self, data_list, loop_count):
        mongostat = data_list
        with open(self.outfile, 'a+') as f:
            for i in xrange(len(mongostat)):
                f.write(str(loop_count) + ', ' + str(self.noise_rate)
                        + ', ' + str(self.trigger_rate)
                        + ', ' +  str(mongostat[i][0])
                        + ', ' +  str(mongostat[i][1])  + '\n')
            f.flush()

#
# class ESAMongoTop(object):
#
#     def __init__(self, esa_node, interval=5, count=2, timeout=120):
#         """Mongo stats with mongotop"""
#
#         self.host = esa_node
#         self.esa_node = esa_node
#         self.ssh = mctf_harness.SshCommandClient(self.host, user='root', password=None)
#         self.timeout = timeout
#         self.interval = interval
#         self.count = count
#         self.t1 = None
#         self.mongo_top_stats = list()
#
#     def start(self):
#         self.t1 = ThreadWithReturnValue(target=self.mongotop)
#         # self.t1.daemon = True
#         self.t1.start()
#
#     def finish(self):
#         ssh1 = mctf_harness.SshCommandClient(self.host, user='root', password=None)
#         try:
#             ssh1.command('killall -s 3 mongotop', '#')
#             ssh1.close()
#         except:
#             pass
#         self.t1.join()
#
#     def mongotop(self):
#         # LOGGER.debug('mongotop -u datapuppy -p datapuppy %s' % self.interval)
#         cmd = 'mongotop -u datapuppy -p datapuppy'
#         for i in xrange(self.count):
#             try:
#                 result = self.ssh.command(cmd, '#', timeout=2)
#                 LOGGER.debug('Result: %s', result)
#             except Exception as e:
#                 # LOGGER.error(str(e))
#                 pass
#             time.sleep(self.interval)
#             self.mongo_top_stats.append(result)
#         # return self.ssh.command('mongotop -u datapuppy -p datapuppy  %s'
#                                 # % self.interval, '#', timeout=self.timeout)
#
#     def get_mongotop(self):
#         # mongo_result = self.t1.result()
#         mongo_result = self.mongo_top_stats
#         print 'mongo_top_result:\n', mongo_result
#         a = mongo_result.split('\r\n')
#         mongo=list()
#         for line in a:
#             print 'current line:', line
#             if 'alert' in  line:
#                 line_list = [s.strip() for s in line.split('  ') if s.strip()]
#                 print 'current line list:', line_list
#                 if len(line_list) > 1:
#                     mongo.append((line_list[1], line_list[3]))
#         return mongo
#
#     def report(self, outfile, noise_rate, trigger_rate):
#         mongotop = self.get_mongotop()
#         with open(outfile, 'a+', buffering=1) as f:
#             if len(f.readlines()) == 0:
#                 f.write('time' + ', ' + 'noise rate'
#                         + ', ' + 'target rate'
#                         + ', ' + 'total alertdb time'+ ', ' + 'write alertdb time'+ '\n')
#             for i in xrange(len(mongotop)):
#                 f.write(str(i+1) + ', ' + str(noise_rate)
#                         + ', ' + str(trigger_rate)
#                         + ', ' +  str(mongotop[i][0]) + ', ' +  str(mongotop[i][1]) + '\n')
#             f.flush()
#         self.ssh.close()


if __name__ == '__main__':

    esa_node = '10.31.204.99'
    # esa_node = '10.31.205.69'
    timeout = 60 * 30
    noise_rate = 60000
    trigger_rate = 3000
    epl_count = 200
    interval = 5
    count = int(timeout/interval)

    # initialize objects
    esa_stat = ESANextgenStat(esa_node, interval=interval, timeout=timeout+1
                              , trigger_rate=trigger_rate, noise_rate=noise_rate, count=count)
    mongo_stat = ESAMongoStat(esa_node, interval=interval, count=count, timeout=timeout+1
                              , trigger_rate=trigger_rate, noise_rate=noise_rate)
    top = Top(esa_node, interval=interval, count=count, timeout=timeout+1
              , trigger_rate=trigger_rate, noise_rate=noise_rate)
    mpstat = MPStat(esa_node, interval=interval, count=count, timeout=timeout+1
                    , trigger_rate=trigger_rate, noise_rate=noise_rate)
    df = Df(esa_node, interval=interval, timeout=timeout+1, trigger_rate=trigger_rate
            , noise_rate=noise_rate, count=count)
    # mongo_top = ESAMongoTop(esa_node, interval=interval, count=count, timeout=timeout+1)

    # start threads
    esa_stat.start()
    top.start()
    mpstat.start()
    df.start()
    mongo_stat.start()
    # mongo_top.start()

    time.sleep(timeout+1)

    # stop the thread
    esa_stat.finish()
    top.finish()
    mpstat.finish()
    df.finish()
    mongo_stat.finish()
    # mongo_top.finish()
