# unify/performance/framework/collect_stats.py

import os
import re
import requests
import time
import threading

from bson import json_util
from pymongo.errors import OperationFailure

from framework.common.harness import SshCommandClient
from framework.common.logger import LOGGER
from framework.esa.harness import ESAClientRpmHarness
from framework.utils.generic_utils import GenericUtilities

HOST_USERNAME = 'root'
HOST_PASSWORD = 'netwitness'
REST_USERNAME = 'admin'
REST_PASSWORD = 'netwitness'

LOGGER.setLevel('DEBUG')


class TopStat(threading.Thread):
    """ESA/Mongo/RabbitMQ Process top stats"""

    def __init__(self, esa_node, interval=5, count=2, timeout=180, dict_of_pid=None
                 , group=None, test_out_dir=None, target=None, name=None, *args, **kwargs):
        """ Creates a thread for top process related metrics collection for esa, rabbitmq & mongodb.

        Args:
            esa_node: ESA server host name (str)
            interval: metrics collection interval (int)
            count: number of collection count duration/interval (int)
            timeout: timeout value in seconds (int)
            dict_of_pid: list of pids to collect metrics of (list)
            trigger_rate: Trigger log publishing rate (int)
            noise_rate: Noise log publishing rate (int)
            group: thread vars
            target: thread vars
            name: thread vars
            args: thread vars
            kwargs: thread vars
        """

        threading.Thread.__init__(self, group, target, name, *args, **kwargs)
        self.stop = threading.Event()
        self.host = esa_node
        self.esa_node = esa_node
        self.esa_client = ESAClientRpmHarness(testcase=None, host=self.esa_node
                                              , user=HOST_USERNAME
                                              , password=HOST_PASSWORD)
        self.ssh = self.esa_client.ssh
        self.timeout = timeout
        self.interval = interval
        self.count = count
        self.dict_of_pid = dict_of_pid
        self.pid_out_file_dict = dict()

        self.t1 = None
        self.output_file_list = list()
        self.test_out_dir = test_out_dir
        LOGGER.debug('dict of pid: %s', self.dict_of_pid)
        header_text = 'PID USER      PR  NI  VIRT  RES  SHR S %CPU %MEM    TIME+  COMMAND'
        esa_header_text = ('used(Bytes) committed(Bytes)   init(Bytes) '
                           'max(Bytes) ProcessCpuLoad(%) SystemCpuLoad(%)')
        for p_name in list(self.dict_of_pid.keys()):
            f_name = os.path.join(self.test_out_dir, 'top_' + p_name + '_result0')
            with open(f_name, 'a+', buffering=1) as f:
                if p_name == 'esa':
                    f.write('timestamp, ' + ', '.join(esa_header_text.split()) + '\n')
                else:
                    f.write('timestamp, ' + ', '.join(header_text.split()) + '\n')
            self.pid_out_file_dict[p_name] = f_name
        LOGGER.debug('pid output file dict: %s', self.pid_out_file_dict)

    def finish(self):
        self.ssh.Close()
        self.stop.set()
        self.join()
        return

    def run(self):
        cmd = ('top -b -d 1 -n 1 -p%s -p%s'
               % (self.dict_of_pid['rabbit'], self.dict_of_pid['mongo']))
        for _ in range(self.count):
            e_mem = list()
            result = self.esa_client.ssh.Exec(cmd, timeout=self.timeout)
            [m_mem, r_mem] = self.get_top(result)
            result = self.esa_client.jolokia.GetJolokiaRequest(mbean='java.lang:type=Memory'
                                                               , attribute='HeapMemoryUsage')
            LOGGER.debug('[JVM] MemoryUsage: %s', result)
            e_mem.append(str(result['used']))
            e_mem.append(str(result['committed']))
            e_mem.append(str(result['init']))
            e_mem.append(str(result['max']))
            result = self.esa_client.jolokia.GetJolokiaRequest(mbean='java.lang:type='
                                                                     'OperatingSystem')
            LOGGER.debug('[JVM] CpuUsage: %s', result)
            e_mem.append(str(result['ProcessCpuLoad']))
            e_mem.append(str(result['SystemCpuLoad']))
            self.report(self.pid_out_file_dict['mongo'], m_mem)
            self.report(self.pid_out_file_dict['rabbit'], r_mem)
            self.report(self.pid_out_file_dict['esa'], e_mem)
            time.sleep(self.interval)

    def get_top(self, result):
        top_result = result.split('\n')
        mongo_mem = list()
        rabbit_mem = list()
        for line in top_result:
            line_list = line.split()
            if len(line_list) and line_list[1] == 'rabbitmq':
                rabbit_mem = line_list
            if len(line_list) and line_list[1] == 'tokumx':
                mongo_mem = line_list
        return [mongo_mem, rabbit_mem]

    @staticmethod
    def report(outfile, mem):
        with open(outfile, 'a+', buffering=1) as f:
            f.write(str(time.strftime('%Y-%b-%d %H:%M:%S')) + ', ' + ', '.join(mem) + '\n')
            f.flush()


class MPStat(threading.Thread):
    """System CPU stats using mpstat"""

    def __init__(self, esa_node, interval=5, count=None, timeout=120, group=None, target=None
                 , name=None, outfile='cpu_stat_result', *args, **kwargs):

        threading.Thread.__init__(self, group, target, name, *args, **kwargs)
        self.stop = threading.Event()
        self.host = esa_node
        self.esa_node = esa_node
        self.ssh = SshCommandClient(self.host, user=HOST_USERNAME, password=HOST_PASSWORD)
        self.timeout = timeout
        self.interval = interval
        self.count = count
        self.t1 = None
        self.outfile = outfile
        header_text = self.ssh.Exec('mpstat 1 1', '#')
        with open(self.outfile, 'a+') as f:
            f.write('time, ' + ', '.join(header_text.split('\n')[3].split()[2:]) + '\n')

    def finish(self):
        ssh1 = SshCommandClient(self.host, user=HOST_USERNAME, password=HOST_PASSWORD)
        try:
            GenericUtilities.kill_process(ssh_obj=ssh1, process_string='mpstat')
            ssh1.close()
        except OSError:
            pass
        self.ssh.close()
        self.stop.set()
        self.join()
        return

    def run(self):
        cmd = 'mpstat 1 1'
        for _ in range(self.count):
            result = self.ssh.Exec(cmd, '#')
            data = ', '.join(result.split('\n')[4].split()[2:])
            self.report(data)
            time.sleep(self.interval)

    def report(self, data):
        with open(self.outfile, 'a+') as f:
            f.write(str(time.strftime("%Y-%b-%d %H:%M:%S")) + ', ' + data + '\n')
            f.flush()


class DfStat(threading.Thread):
    """Disk Usage using df"""

    def __init__(self, esa_node, interval, timeout, group=None, target=None, name=None
                 , count=1, outfile='df_result', *args, **kwargs):

        threading.Thread.__init__(self, group, target, name, *args, **kwargs)
        self.host = esa_node
        self.esa_node = esa_node
        self.stop = threading.Event()
        self.ssh = SshCommandClient(self.host, user=HOST_USERNAME, password=HOST_PASSWORD)
        self.interval = interval
        self.timeout = timeout
        self.stats = list()
        self.esa_node = esa_node
        self.outfile = outfile
        self.count = count
        with open(self.outfile, 'a+') as f:
            f.write('time' + ', ' + ', ' + 'total' + ', ' + 'write' + '\n')

    def run(self):
        for _ in range(self.count):
            df = self.ssh.Exec('df -hP', timeout=2)
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


class ESANextgenStat(threading.Thread):
    """ESA Server next-gen stats from JVM using Jolokia"""

    def __init__(self, testcase, esa_node, interval, timeout, fw_provider=None, group=None
                 , target=None, name=None, outfile='esa_stat_result'
                 , noise_rate=0, trigger_rate=0, count=0, *args, **kwargs):

        threading.Thread.__init__(self, group, target, name, *args, **kwargs)
        self.stop = threading.Event()
        self.interval = interval
        self.timeout = timeout
        self.stats = list()
        self.esa_node = esa_node
        self.esa_client = ESAClientRpmHarness(testcase=testcase, host=self.esa_node
                                              , user=HOST_USERNAME
                                              , password=HOST_PASSWORD)
        self.fw_provider = fw_provider
        self.outfile = outfile
        self.noise_rate = noise_rate
        self.trigger_rate = trigger_rate
        self.count = count
        session_behind_header_text = ''
        for i in range(len(self.esa_client.get_nextgen_sessions_behind())):
            session_behind_header_text += ('NextGenSessionsBehind' + str(i) + ', ')
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
                        + session_behind_header_text
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
        LOGGER.debug('TOTAL ESA getStat COUNT: %s', self.count)

    def run(self):
        for _ in range(self.count):
            data = list()
            esper_feeder_stats = self.esa_client.get_esperfeeder_stats()
            mbean = 'com.rsa.netwitness.esa:type=CEP,subType=Module,id=cepModuleStats'
            cep_module_stats = self.esa_client.jolokia.GetJolokiaRequest(mbean=mbean)
            mbean = ('com.rsa.netwitness.esa:type=Workflow'
                     ',subType=Source,id=nextgenAggregationSource')
            next_gen_stats = self.esa_client.jolokia.GetJolokiaRequest(mbean=mbean)
            try:
                data.append((self.esa_client.get_num_events_offered()
                             , self.esa_client.get_offered_rate()['current']
                             , self.esa_client.get_notifications()['successfulNotifications']
                             , cep_module_stats['FireRate']['current']
                             , cep_module_stats['NumEventsFired']
                             , next_gen_stats['WorkUnitProcessingRate']
                             , next_gen_stats['WorkUnitsProcessed']
                             , [i['sessionsBehind'] for i in next_gen_stats['Stats']]
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
                f.write(str(i + 1) + ', '
                        + str(stats[i][9]) + ', '
                        + str(stats[i][10]) + '\n')
            f.flush()


class LogDecoderConcentratorStat(threading.Thread):
    """LogDecoder and Concentrator stats using REST API calls"""

    def __init__(self, ld_node, c_node, interval, timeout, inj_node=None, group=None
                 , target=None, name=None, outfile='ld_stat_result', noise_rate=0, trigger_rate=0
                 , count=0, c_node_port=50105, ld_node_port=50102, *args, **kwargs):

        threading.Thread.__init__(self, group, target, name, *args, **kwargs)
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
        self.rest_user = REST_USERNAME
        self.rest_pass = REST_PASSWORD
        with open(self.outfile, 'a+') as f:
            f.write('time' + ', '
                    + 'LogDecoderRate' + ', '
                    + 'LogDecoderCnt' + ', '
                    + 'ConcentratorRate' + ', '
                    + 'ConcentratorCnt' + ', '
                    + '\n')

    def get_session_rate(self, host, port):
        url = ('http://%s:%s/database/stats/session.rate' % (host, port))
        result = requests.get(url, auth=(self.rest_user, self.rest_pass))
        return re.findall(r'<string>(\d+)</string>', result.text)[0]

    def get_session_cnt(self, host, port):
        url = ('http://%s:%s/database/stats/session.total' % (host, port))
        result = requests.get(url, auth=(self.rest_user, self.rest_pass))
        return re.findall(r'<string>(\d+)</string>', result.text)[0]

    def run(self):
        for _ in range(self.count):
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


class ESAMongoStat(threading.Thread):
    """MongoDB stats using mongostat"""

    def __init__(self, esa_node, interval=5, count=2, timeout=120, outfile='mongo_stat_result'
                 , group=None, target=None, name=None, *args, **kwargs):

        threading.Thread.__init__(self, group, target, name, *args, **kwargs)
        self.stop = threading.Event()
        self.host = esa_node
        self.esa_node = esa_node
        self.ssh = SshCommandClient(self.host, user=HOST_USERNAME, password=HOST_PASSWORD)
        self.timeout = timeout
        self.interval = interval
        self.count = count
        self.t1 = None
        self.outfile = outfile

        try:
            header_text = self.ssh.Exec('mongostat -u datapuppy -p datapuppy -n 1 1', '#')
        except OperationFailure as e:
            LOGGER.error(e)
            raise OperationFailure('%s auth failed, please add the datapuppy user!!')

        with open(self.outfile, 'a+') as f:
            f.write('time, ' + ', '.join(header_text.split('\n')[2].split()) + '\n')

    def finish(self):
        ssh1 = SshCommandClient(self.host, user=HOST_USERNAME, password=HOST_PASSWORD)
        try:
            GenericUtilities.kill_process(ssh_obj=ssh1, process_string='mongostat')
            ssh1.close()
        except OSError:
            pass
        self.ssh.close()
        self.stop.set()
        self.join()
        return

    def run(self):
        cmd = 'mongostat -u datapuppy -p datapuppy --noheaders -n 1 1'
        for _ in range(self.count):
            result = self.ssh.Exec(cmd, '#', timeout=self.timeout)
            result = ', '.join(result.split('\n')[2].split())
            self.report(result)
            time.sleep(self.interval)

    def report(self, data_list):
        with open(self.outfile, 'a+') as f:
            f.write(str(time.strftime("%Y-%b-%d %H:%M:%S")) + ', ' + data_list + '\n')
            f.flush()


class IOStat(threading.Thread):
    """System I/O stats using iostat"""

    def __init__(self, esa_node, interval=5, count=None, timeout=120, group=None
                 , target=None, name=None, outfile='io_stat_result', *args, **kwargs):

        threading.Thread.__init__(self, group, target, name, *args, **kwargs)
        self.stop = threading.Event()
        self.host = esa_node
        self.esa_node = esa_node
        self.ssh = SshCommandClient(self.host, user=HOST_USERNAME, password=HOST_PASSWORD)
        self.timeout = timeout
        self.interval = interval
        self.count = count
        self.t1 = None
        self.outfile = outfile
        with open(outfile, 'a+') as f:
            f.write('time, ' + 'Device, ' + 'rrqm/s, ' + 'wrqm/s, ' + 'r/s, '
                    + 'w/s, ' + 'rkB/s, ' + 'wkB/s, ' + 'avgrq-sz, ' + 'avgqu-sz'
                    + 'await, ' + 'svctm, ' + '%util' + '\n')

    def finish(self):
        ssh1 = SshCommandClient(self.host, user=HOST_USERNAME, password=HOST_PASSWORD)
        try:
            GenericUtilities.kill_process(ssh_obj=ssh1, process_string='iostat')
            ssh1.close()
        except OSError:
            pass
        self.ssh.close()
        self.stop.set()
        self.join()
        return

    def run(self):
        # Using VolGroup00-apps because it maps to /opt/rsa/databases
        cmd = 'iostat -x -k -N|grep apps'
        LOGGER.debug('Executing cmd: %s', cmd)
        for _ in range(self.count):
            result = self.ssh.Exec(cmd, '#')
            result = ', '.join(result.split('\n')[1].split())
            self.report(result)
            # change it to based on current time
            time.sleep(self.interval)

    def report(self, data):
        with open(self.outfile, 'a+') as f:
            f.write(str(time.strftime("%Y-%b-%d %H:%M:%S")) + ', ' + data + '\n')
            f.flush()


class FreeStat(threading.Thread):
    """Memory usage stats using free"""

    def __init__(self, esa_node, interval=5, count=2, timeout=120, group=None, target=None
                 , name=None, outfile='free_mem_result', *args, **kwargs):

        threading.Thread.__init__(self, group, target, name, *args, **kwargs)
        self.stop = threading.Event()
        self.host = esa_node
        self.esa_node = esa_node
        self.ssh = SshCommandClient(self.host, user=HOST_USERNAME, password=HOST_PASSWORD)
        self.timeout = timeout
        self.interval = interval
        self.count = count
        self.t1 = None
        self.outfile = outfile
        with open(self.outfile, 'a+') as f:
            f.write('time, ' + 'total, ' + 'used, ' + 'free' + '\n')

    def finish(self):
        ssh1 = SshCommandClient(self.host, user=HOST_USERNAME, password=HOST_PASSWORD)
        try:
            GenericUtilities.kill_process(ssh_obj=ssh1, process_string='free')
            ssh1.close()
        except OSError:
            pass
        self.ssh.close()
        self.stop.set()
        self.join()
        return

    def run(self):
        LOGGER.debug('Executing cmd: free')
        for _ in range(self.count):
            result = self.ssh.Exec('free', '#')
            result = result.split('\n')[2].split()[1:4]
            a = [int(j) / 1024 for j in result]
            self.report(', '.join(map(str, a)))
            time.sleep(self.interval)

    def report(self, data):
        with open(self.outfile, 'a+') as f:
            f.write(str(time.strftime("%Y-%b-%d %H:%M:%S")) + ', ' + data + '\n')


class GCStat(threading.Thread):
    """ Java Garbage Collection stats using jstat -gc."""

    def __init__(self, esa_node, interval=5, count=None, timeout=120, group=None, target=None
                 , name=None, outfile='gc_stat_result', *args, **kwargs):

        threading.Thread.__init__(self, group, target, name, *args, **kwargs)
        self.stop = threading.Event()
        self.host = esa_node
        self.esa_node = esa_node
        self.ssh = SshCommandClient(self.host, user=HOST_USERNAME, password=HOST_PASSWORD)
        self.timeout = timeout
        self.interval = interval
        self.count = count
        self.t1 = None
        self.outfile = outfile
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
        ssh1 = SshCommandClient(self.host, user=HOST_USERNAME, password=HOST_PASSWORD)
        try:
            GenericUtilities.kill_process(ssh_obj=ssh1, process_string='jstat')
            ssh1.close()
        except OSError:
            pass
        self.ssh.close()
        self.stop.set()
        self.join()
        return

    def run(self):
        cmd = ('jstat -gc -t %s 2>/dev/null' % self.esa_pids[0])
        LOGGER.debug('Executing cmd: %s', cmd)
        for _ in range(self.count):
            result = self.ssh.Exec(cmd, '#')
            result = ', '.join(result.split('\n')[2].split())
            self.report(result)
            time.sleep(self.interval)

    def report(self, data):
        with open(self.outfile, 'a+') as f:
            f.write(str(time.strftime("%Y-%b-%d %H:%M:%S")) + ', ' + data + '\n')
            f.flush()


class AnalyticsEngineStats(threading.Thread):
    """ESA Server Analytics engine stats from JVM using Jolokia"""

    def __init__(self, testcase, esa_node, interval, timeout, test_out_dir, group=None, target=None
                 , name=None, outfile='ana_stat_result', trigger_rate=0, count=0, *args, **kwargs):

        threading.Thread.__init__(self, group, target, name, *args, **kwargs)
        self.stop = threading.Event()
        self.interval = interval
        self.timeout = timeout
        self.stats = list()
        self.esa_node = esa_node
        self.esa_client = ESAClientRpmHarness(testcase=testcase, host=self.esa_node
                                              , user=HOST_USERNAME
                                              , password=HOST_PASSWORD)
        self.outfile = outfile
        self.output_dir = os.path.join(test_out_dir, 'ana')
        if not os.path.exists(self.output_dir):
            os.makedirs(self.output_dir)
        self.trigger_rate = trigger_rate
        self.count = count
        self.ana_stat_mbean = config['performance']['analytics']['mbean']
        self.ana_stat_attribute = config['performance']['analytics']['attribute']
        LOGGER.info('Collecting Analytics stats for ' + str(self.esa_node))

    def collect_ana_stats(self, _outfile):
        """ Collects Analytics engine specific stats

        Args:
            _outfile: output file path (str)
        """

        json_value = (self.esa_client.GetEsaAttribute(mbean_path=self.ana_stat_mbean[0]
                                                      , attribute=self.ana_stat_attribute))
        with open(_outfile, 'wb') as _file:
            json_formatted_doc = json_util.dumps(json_value, sort_keys=False, indent=4
                                                 , default=json_util.default)
            _file.write(bytes(json_formatted_doc, 'UTF-8'))

    def run(self):
        for _ in range(self.count):
            _outfile = os.path.join(self.output_dir
                                    , '{0}_{1}.json'.format(self.outfile
                                                            , str(int(time.time()))))
            try:
                self.collect_ana_stats(_outfile)
            except Exception as e:
                LOGGER.error(str(e))
            time.sleep(self.interval)

    def finish(self):
        self.stop.set()
        self.join()
        return


class CollectStats(MPStat, IOStat, TopStat, ESAMongoStat, ESANextgenStat
                   , GCStat, FreeStat, DfStat, LogDecoderConcentratorStat):
    """ Main Class that consolidates all stats collection threads"""

    def __init__(self, **kwargs):
        for k, v in kwargs.items():
            setattr(self, k, v)
        self.esa_hosts = [node for node in self.esa_nodes]

        self.esa_nodes_stats_threads_dict = dict()
        for i in range(len(self.esa_hosts)):
            # esa_stat = ESANextgenStat(testcase=self.testcase, esa_node=self.esa_hosts[i]
            #                           , interval=self.interval
            #                           , timeout=self.timeout, trigger_rate=self.trigger_rate
            #                           , noise_rate=self.noise_rate, count=self.count
            #                           , outfile=os.path.join(self.test_out_dir
            #                                                  , 'esa_stat_result%d' % i))
            # mongo_stat = ESAMongoStat(esa_node=self.esa_hosts[i], interval=self.interval
            #                           , count=self.count, timeout=self.timeout
            #                           , outfile=os.path.join(self.test_out_dir
            #                                                  , 'mongo_stat_result%d' % i))
            top_stat = TopStat(esa_node=self.esa_hosts[i], interval=self.interval
                               , count=self.count, timeout=self.timeout
                               , dict_of_pid=self.dict_of_pid, test_out_dir=self.test_out_dir)
            # mpstat = MPStat(esa_node=self.esa_hosts[i], interval=self.interval
            #                 , count=self.count, timeout=self.timeout
            #                 , outfile=os.path.join(self.test_out_dir, 'cpu_stat_result%d' % i))
            # df_stat = DfStat(esa_node=self.esa_hosts[i], interval=self.interval
            #                  , timeout=self.timeout, count=self.count
            #                  , outfile=os.path.join(self.test_out_dir, 'df_stat_result%d' % i))
            # io_stat = IOStat(esa_node=self.esa_hosts[i], interval=self.interval
            #                  , count=self.count, timeout=self.timeout
            #                  , outfile=os.path.join(self.test_out_dir, 'io_stat_result%d' % i))
            # free_stat = FreeStat(esa_node=self.esa_hosts[i], interval=self.interval
            #                      , count=self.count, timeout=self.timeout
            #                      , outfile=os.path.join(self.test_out_dir, 'free_mem_result%d' % i))
            # gc_stat = GCStat(esa_node=self.esa_hosts[i], interval=self.interval
            #                  , count=self.count, timeout=self.timeout
            #                  , outfile=os.path.join(self.test_out_dir, 'gc_result%d' % i))
            # ana_stat = AnalyticsEngineStats(testcase=self.testcase, esa_node=self.esa_hosts[i]
            #                                 , interval=self.interval, timeout=self.timeout
            #                                 , count = self.count, outfile='ana_stat_result'
            #                                 , test_out_dir = self.test_out_dir)

            # self.esa_nodes_stats_threads_dict[self.esa_hosts[i]] = [mongo_stat, top_stat, mpstat
            #                                                         , gc_stat, df_stat, io_stat
            #                                                         , free_stat, esa_stat]
            self.esa_nodes_stats_threads_dict[self.esa_hosts[i]] = [top_stat]

            if config['performance']['collect_ana_stats']:
                # self.esa_nodes_stats_threads_dict[self.esa_hosts[i]].append(ana_stat)
                LOGGER.debug('==== FINAL ESA threads: %s'
                             , self.esa_nodes_stats_threads_dict[self.esa_hosts[i]])

        self.ld_conc_stats_threads_list = list()
        for i in range(len(self.ld_nodes)):
            ld_c_stats = LogDecoderConcentratorStat(ld_node=self.ld_nodes[i]
                                                    , c_node=self.cr_nodes[i]
                                                    , interval=self.interval, timeout=self.timeout
                                                    , outfile=os.path.join(self.test_out_dir
                                                                           , 'ld_c_result%d' % i)
                                                    , noise_rate=self.noise_rate
                                                    , trigger_rate=self.trigger_rate
                                                    , count=self.count)
            # self.ld_conc_stats_threads_list.append(ld_c_stats)

    def get_threads(self):
        all_threads = list()
        for node, stat_threads in self.esa_nodes_stats_threads_dict.items():
            for _thread in stat_threads:
                all_threads.append(_thread)
        all_threads += self.ld_conc_stats_threads_list
        return all_threads


def get_pid(ssh_obj):
    """ Gets the PIDs of ESA, RabbitMQ and MongoDB Server processes"""

    # calculating ESA pid
    dict_of_pid = dict()
    wrapper_pid = ssh_obj.get_service_pid('rsa-esa')
    _pid = ssh_obj.Exec('pgrep -P %s' % wrapper_pid)
    esa_pid = _pid.split('\n')[-2].strip()
    LOGGER.debug('ESA Service pid: %s', esa_pid)
    dict_of_pid['esa'] = esa_pid
    # calculating rabbitmq pid
    output = (ssh_obj.Exec('service rabbitmq-server status|grep pid'))
    rabbitmq_pid = output.split(',')[1].split('}')[0].strip()
    LOGGER.debug('RabbitMQ pid: %s', rabbitmq_pid)
    dict_of_pid['rabbit'] = rabbitmq_pid
    # calculating tokumx pid
    output = ssh_obj.get_service_pid('tokumx')
    mongodb_pid = output
    LOGGER.debug('TokuMX/MongoDB pid: %s', mongodb_pid)
    dict_of_pid['mongo'] = mongodb_pid
    LOGGER.info('dict of PIDs: %s', dict_of_pid)
    return dict_of_pid


if __name__ == '__main__':

    import simplejson as json
    with open('/Users/bakhra/default.json') as config_file:
        config = json.load(config_file)
        # print(config)

    timeout = 60 * config['performance']['duration']
    noise_rate = config['performance']['noise_rate']
    trigger_rate = config['performance']['trigger_rate']
    epl_count = config['performance']['epl_count']
    interval = config['performance']['interval']
    count = int(timeout / interval)
    wait_after_publish = 60 * config['performance']['wait_after_publish']
    start_consume = time.time()

    esa_nodes = config['servers']['esa']['ip']
    ld_nodes = config['servers']['logdecoder']['ip']
    cr_nodes = config['servers']['concentrator']['ip']
    noise_inj_nodes = config['servers']['injector']['ip']
    trigger_inj_nodes = config['servers']['injector']['ip']
    ssh_obj = SshCommandClient(esa_nodes[0], HOST_USERNAME, HOST_PASSWORD)

    os.system('rm -rf ./t/*')
    # Instantiate Stats Collection threads
    stats = CollectStats(testcase=None
                         , ld_nodes=ld_nodes
                         , cr_nodes=cr_nodes
                         , esa_nodes=esa_nodes
                         , timeout=timeout, noise_rate=noise_rate
                         , trigger_rate=trigger_rate, epl_count=epl_count
                         , interval=interval, count=5
                         , wait_after_publish=wait_after_publish
                         , test_out_dir='./t/'
                         , wake_up_time=start_consume + 30
                         , dict_of_pid=get_pid(ssh_obj))
    all_threads = stats.get_threads()
    for _thread in all_threads:
        _thread.start()
        time.sleep(1)

    for _thread in all_threads:
        # if isinstance(_thread, threading.Thread):
        _thread.join()

    for _thread in all_threads:
        try:
            if isinstance(_thread, threading.Thread):
                _thread.finish()
        except AttributeError as e:
            LOGGER.error('%s %s', _thread._name, str(e))
