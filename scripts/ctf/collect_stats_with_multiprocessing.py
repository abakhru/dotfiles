# unify/performance/framework/collect_stats.py

import os
import re
import requests
import time
import timeit

from bson import json_util
from multiprocessing.dummy import Pool as ThreadPool
from multiprocessing import Process
from pymongo.errors import OperationFailure

from framework.common.harness import SshCommandClient
from framework.common.logger import LOGGER
from framework.common.nw_common import NwConsoleHarness
from framework.esa.harness import ESAClientRpmHarness
from framework.utils.generic_utils import GenericUtilities

HOST_USERNAME = 'root'
HOST_PASSWORD = 'netwitness'
REST_USERNAME = 'admin'
REST_PASSWORD = 'netwitness'

LOGGER.setLevel('DEBUG')

ESA_CLIENT = None
ESA_SSH = None


class BaseObjectClass(object):

    def __init__(self, esa_node):
        LOGGER.info('Launching ESA Client and SSH connection to ESA host: %s', esa_node)
        global ESA_CLIENT
        global ESA_SSH
        ESA_CLIENT = ESAClientRpmHarness(testcase=None, host=esa_node
                                              , user=HOST_USERNAME
                                              , password=HOST_PASSWORD)
        ESA_SSH = ESA_CLIENT.ssh

    def finish(self):
        ESA_CLIENT.close()
        ESA_SSH.close()

class TopStat(BaseObjectClass):
    """ESA/Mongo/RabbitMQ Process top stats"""

    def __init__(self, esa_node, dict_of_pid=None, test_out_dir=None):
        """ Creates a thread for top process related metrics collection for esa, rabbitmq & mongodb.

        Args:
            esa_node: ESA server host name (str)
            interval: metrics collection interval (int)
            count: number of collection count duration/interval (int)
            timeout: timeout value in seconds (int)
            dict_of_pid: list of pids to collect metrics of (list)
            trigger_rate: Trigger log publishing rate (int)
            noise_rate: Noise log publishing rate (int)
        """

        global ESA_CLIENT
        global ESA_SSH
        self.dict_of_pid = dict_of_pid
        self.pid_out_file_dict = dict()
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

    def run(self):
        cmd = ('top -b -d 1 -n 1 -p%s -p%s'
               % (self.dict_of_pid['rabbit'], self.dict_of_pid['mongo']))
        e_mem = list()
        result = ESA_SSH.Exec(cmd, timeout=self.timeout)
        [m_mem, r_mem] = self.get_top(result)
        result = ESA_CLIENT.jolokia.GetJolokiaRequest(mbean='java.lang:type=Memory'
                                                           , attribute='HeapMemoryUsage')
        LOGGER.debug('[JVM] MemoryUsage: %s', result)
        e_mem.append(str(result['used']))
        e_mem.append(str(result['committed']))
        e_mem.append(str(result['init']))
        e_mem.append(str(result['max']))
        result = ESA_CLIENT.jolokia.GetJolokiaRequest(mbean='java.lang:type='
                                                                 'OperatingSystem')
        LOGGER.debug('[JVM] CpuUsage: %s', result)
        e_mem.append(str(result['ProcessCpuLoad']))
        e_mem.append(str(result['SystemCpuLoad']))
        self.report(self.pid_out_file_dict['mongo'], m_mem)
        self.report(self.pid_out_file_dict['rabbit'], r_mem)
        self.report(self.pid_out_file_dict['esa'], e_mem)

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


class MPStat(BaseObjectClass):
    """System CPU stats using mpstat"""

    def __init__(self, esa_node, outfile='cpu_stat_result'):

        global ESA_CLIENT
        global ESA_SSH
        self.outfile = outfile
        header_text = ESA_SSH.Exec('mpstat 1 1', '#')
        with open(self.outfile, 'a+') as f:
            f.write('time, ' + ', '.join(header_text.split('\n')[3].split()[2:]) + '\n')

    def run(self):
        cmd = 'mpstat 1 1'
        result = ESA_SSH.Exec(cmd, '#')
        data = ', '.join(result.split('\n')[4].split()[2:])
        self.report(data)

    def report(self, data):
        with open(self.outfile, 'a+') as f:
            f.write(str(time.strftime("%Y-%b-%d %H:%M:%S")) + ', ' + data + '\n')
            f.flush()


class DfStat(BaseObjectClass):
    """Disk Usage using df"""

    def __init__(self, esa_node, outfile='df_result'):

        global ESA_CLIENT
        global ESA_SSH
        self.stats = list()
        self.outfile = outfile
        with open(self.outfile, 'a+') as f:
            f.write('time' + ', ' + ', ' + 'total' + ', ' + 'write' + '\n')

    def run(self):
        df = ESA_SSH.Exec('df -hP', timeout=2)
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

    def report(self, data):
        stats = data
        with open(self.outfile, 'a+') as f:
            for i in range(len(stats)):
                f.write(str(time.strftime("%Y-%b-%d %H:%M:%S")) + ', '
                        + str(stats[i][0]) + ', '
                        + str(stats[i][1]) + ', '
                        + str(stats[i][2]) + '\n')
            f.flush()


class ESANextgenStat(BaseObjectClass):
    """ESA Server next-gen stats from JVM using Jolokia"""

    def __init__(self, esa_node, outfile='esa_stat_result'):

        self.stats = list()
        self.outfile = outfile
        session_behind_header_text = ''
        global ESA_CLIENT
        global ESA_SSH
        LOGGER.debug('esa-client: %s', ESA_CLIENT)
        LOGGER.debug('esa-ssh: %s', ESA_SSH)
        for i in range(len(ESA_CLIENT.get_nextgen_sessions_behind())):
            session_behind_header_text += ('NextGenSessionsBehind' + str(i) + ', ')
        LOGGER.info('Collecting ESA stats for %s', esa_node)
        with open(self.outfile, 'a+') as f:
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

    def run(self):
        data = list()
        esper_feeder_stats = ESA_CLIENT.get_esperfeeder_stats()
        mbean = 'com.rsa.netwitness.esa:type=CEP,subType=Module,id=cepModuleStats'
        cep_module_stats = ESA_CLIENT.jolokia.GetJolokiaRequest(mbean=mbean)
        mbean = ('com.rsa.netwitness.esa:type=Workflow'
                 ',subType=Source,id=nextgenAggregationSource')
        next_gen_stats = ESA_CLIENT.jolokia.GetJolokiaRequest(mbean=mbean)
        try:
            data.append((ESA_CLIENT.get_num_events_offered()
                         , ESA_CLIENT.get_offered_rate()['current']
                         , ESA_CLIENT.get_notifications()['successfulNotifications']
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
                         , ESA_CLIENT.get_notifications(fw_provider='message_bus')[
                             'successfulNotifications']))
        except Exception as e:
            LOGGER.error(str(e))
        LOGGER.debug('data list values: %s', data)
        self.report(data)

    def report(self, data):
        with open(self.outfile, 'a+') as f:
            f.write(str(time.strftime("%Y-%b-%d %H:%M:%S")) + ', '
                    + ', '.join(map(str, list(data[0]))) + '\n')
            f.flush()


class ESAMongoStat(BaseObjectClass):
    """MongoDB stats using mongostat"""

    def __init__(self, esa_node, outfile='mongo_stat_result'):

        self.outfile = outfile
        global ESA_CLIENT
        global ESA_SSH
        try:
            header_text = ESA_SSH.Exec('mongostat -u datapuppy -p datapuppy -n 1 1', '#')
        except OperationFailure as e:
            LOGGER.error(e)
            raise OperationFailure('%s auth failed, please add the datapuppy user!!')
        with open(self.outfile, 'a+') as f:
            f.write('time, ' + ', '.join(header_text.split('\n')[2].split()) + '\n')

    def run(self):
        cmd = 'mongostat -u datapuppy -p datapuppy --noheaders -n 1 1'
        result = ESA_SSH.Exec(cmd, '#', timeout=self.timeout)
        result = ', '.join(result.split('\n')[2].split())
        self.report(result)

    def report(self, data_list):
        with open(self.outfile, 'a+') as f:
            f.write(str(time.strftime("%Y-%b-%d %H:%M:%S")) + ', ' + data_list + '\n')
            f.flush()


class IOStat(BaseObjectClass):
    """System I/O stats using iostat"""

    def __init__(self, esa_node, outfile='io_stat_result'):

        global ESA_CLIENT
        global ESA_SSH
        self.outfile = outfile
        with open(outfile, 'a+') as f:
            f.write('time, ' + 'Device, ' + 'rrqm/s, ' + 'wrqm/s, ' + 'r/s, '
                    + 'w/s, ' + 'rkB/s, ' + 'wkB/s, ' + 'avgrq-sz, ' + 'avgqu-sz'
                    + 'await, ' + 'svctm, ' + '%util' + '\n')

    def run(self):
        # Using VolGroup00-apps because it maps to /opt/rsa/databases
        cmd = 'iostat -x -k -N|grep apps'
        result = ESA_SSH.Exec(cmd, '#')
        result = ', '.join(result.split('\n')[1].split())
        self.report(result)

    def report(self, data):
        with open(self.outfile, 'a+') as f:
            f.write(str(time.strftime("%Y-%b-%d %H:%M:%S")) + ', ' + data + '\n')
            f.flush()


class FreeStat(BaseObjectClass):
    """Memory usage stats using free"""

    def __init__(self, esa_node, outfile='free_mem_result'):

        global ESA_CLIENT
        global ESA_SSH
        self.outfile = outfile
        with open(self.outfile, 'a+') as f:
            f.write('time, ' + 'total, ' + 'used, ' + 'free' + '\n')

    def run(self):
        result = ESA_SSH.Exec('free', '#')
        result = result.split('\n')[2].split()[1:4]
        a = [int(j) / 1024 for j in result]
        self.report(', '.join(map(str, a)))

    def report(self, data):
        with open(self.outfile, 'a+') as f:
            f.write(str(time.strftime("%Y-%b-%d %H:%M:%S")) + ', ' + data + '\n')


class GCStat(BaseObjectClass):
    """ Java Garbage Collection stats using jstat -gc."""

    def __init__(self, esa_node, outfile='gc_stat_result'):

        global ESA_CLIENT
        global ESA_SSH
        self.outfile = outfile
        self.esa_pids = list()
        wrapper_pid = ESA_SSH.get_service_pid('rsa-esa')
        esa_pid = ESA_SSH.Exec('pgrep -P %s' % wrapper_pid, '#')
        esa_pid = esa_pid.replace("\r", "")
        esa_pid = esa_pid.split('\n')[1]
        self.esa_pids.append(esa_pid)
        result = ESA_SSH.Exec('jstat -gc -t %s 2>/dev/null' % self.esa_pids[0], '#')
        with open(self.outfile, 'a+') as f:
            f.write('time, ' + ', '.join(result.split('\n')[1].split()) + '\n')

    def run(self):
        cmd = ('jstat -gc -t %s 2>/dev/null' % self.esa_pids[0])
        result = ESA_SSH.Exec(cmd, '#')
        result = ', '.join(result.split('\n')[2].split())
        self.report(result)

    def report(self, data):
        with open(self.outfile, 'a+') as f:
            f.write(str(time.strftime("%Y-%b-%d %H:%M:%S")) + ', ' + data + '\n')
            f.flush()


class AnalyticsEngineStats(BaseObjectClass):
    """ESA Server Analytics engine stats from JVM using Jolokia"""

    def __init__(self, esa_node, test_out_dir, outfile='ana_stat_result'):

        global ESA_CLIENT
        global ESA_SSH
        self.stats = list()
        self.outfile = outfile
        self.output_dir = os.path.join(test_out_dir, 'ana')
        if not os.path.exists(self.output_dir):
            os.makedirs(self.output_dir)
        self.ana_stat_mbean = config['performance']['analytics']['mbean']
        self.ana_stat_attribute = config['performance']['analytics']['attribute']
        LOGGER.info('Collecting Analytics stats for %s', esa_node)

    def collect_ana_stats(self, _outfile):
        """ Collects Analytics engine specific stats

        Args:
            _outfile: output file path (str)
        """

        json_value = (ESA_CLIENT.GetEsaAttribute(mbean_path=self.ana_stat_mbean[0]
                                                      , attribute=self.ana_stat_attribute))
        with open(_outfile, 'wb') as _file:
            json_formatted_doc = json_util.dumps(json_value, sort_keys=False, indent=4
                                                 , default=json_util.default)
            _file.write(bytes(json_formatted_doc, 'UTF-8'))

    def run(self):
        _outfile = os.path.join(self.output_dir
                                , '{0}_{1}.json'.format(self.outfile
                                                        , str(int(time.time()))))
        try:
            self.collect_ana_stats(_outfile)
        except Exception as e:
            LOGGER.error(str(e))


class LogDecoderConcentratorStat(object):
    """LogDecoder and Concentrator stats using REST API calls"""

    def __init__(self, ld_node, c_node, outfile='ld_stat_result'):
        self.conc = NwConsoleHarness(host=c_node, program='NwConcentrator', password=HOST_PASSWORD
                                     , rest_password=REST_PASSWORD, sdk_node='concentrator', port=50005)
        self.ld = NwConsoleHarness(host=ld_node, program='NwLogDecoder',             password=HOST_PASSWORD, sdk_node='decoder', rest_password=REST_PASSWORD, port=50002)
        self.outfile = outfile
        with open(self.outfile, 'a+') as f:
            f.write('time' + ', '
                    + 'LogDecoderRate' + ', '
                    + 'LogDecoderCnt' + ', '
                    + 'ConcentratorRate' + ', '
                    + 'ConcentratorCnt' + ', '
                    + '\n')

    def run(self):
        data = list()
        return self.nwconsole.GetValue(attribute_path='/%s/%s' % (url_path, attribute))
        ld_rate = self.ld.GetValue(attribute_path='/database/stats/session.rate')
        ld_cnt = self.ld.GetValue(attribute_path='/database/stats/session.last.id')
        cn_rate = self.conc.GetValue(attribute_path='/database/stats/session.rate')
        cn_cnt = self.conc.GetValue(attribute_path='/database/stats/session.last.id')
        data.append((ld_rate, ld_cnt, cn_rate, cn_cnt))
        self.report(data)

    def finish(self):
        self.ld.Close()
        self.conc.Close()

    def report(self, data):
        stats = data
        with open(self.outfile, 'a+') as f:
            for i in range(len(stats)):
                f.write(str(time.strftime("%Y-%b-%d %H:%M:%S")) + ', '
                        + str(stats[i][0]) + ', '
                        + str(stats[i][1]) + ', '
                        + str(stats[i][2]) + ', '
                        + str(stats[i][3]) + '\n')


class CollectStats(object):
    """ Main Class that consolidates all stats collection threads"""

    def __init__(self, **kwargs):
        for k, v in kwargs.items():
            setattr(self, k, v)
        self.esa_hosts = [node for node in self.esa_nodes]
        BaseObjectClass(self.esa_hosts[0])
        self.esa_nodes_stats_threads_dict = dict()
        self.all_objs_list = list()

        # init all class objects
        i = 0
        esa_stat = ESANextgenStat(esa_node=self.esa_hosts[0]
                                  , outfile=os.path.join(self.test_out_dir
                                                         , 'esa_stat_result%d' % i))
        mongo_stat = ESAMongoStat(esa_node=self.esa_hosts[0]
                                  , outfile=os.path.join(self.test_out_dir
                                                         , 'mongo_stat_result%d' % i))
        top_stat = TopStat(esa_node=self.esa_hosts[0]
                           , dict_of_pid=self.dict_of_pid, test_out_dir=self.test_out_dir)
        mp_stat = MPStat(esa_node=self.esa_hosts[0]
                        , outfile=os.path.join(self.test_out_dir, 'cpu_stat_result%d' % i))
        df_stat = DfStat(esa_node=self.esa_hosts[0]
                         , outfile=os.path.join(self.test_out_dir, 'df_stat_result%d' % i))
        io_stat = IOStat(esa_node=self.esa_hosts[0]
                         , outfile=os.path.join(self.test_out_dir, 'io_stat_result%d' % i))
        free_stat = FreeStat(esa_node=self.esa_hosts[0]
                             , outfile=os.path.join(self.test_out_dir, 'free_mem_result%d' % i))
        gc_stat = GCStat(esa_node=self.esa_hosts[0]
                         , outfile=os.path.join(self.test_out_dir, 'gc_result%d' % i))
        ana_stat = AnalyticsEngineStats(esa_node=self.esa_hosts[0], outfile='ana_stat_result'
                                        , test_out_dir = self.test_out_dir)

        # ld_c_stats = list()
        # for i in range(len(self.ld_nodes)):
        #     ld_c_stats.append(LogDecoderConcentratorStat(ld_node=self.ld_nodes[i]
        #                                             , c_node=self.cr_nodes[i]
        #                                             , outfile=os.path.join(self.test_out_dir
        #                                                                    , 'ld_c_result%d' % i)))
        self.all_objs_list = [esa_stat, mongo_stat, top_stat, mp_stat, df_stat, io_stat, free_stat, gc_stat, ana_stat] #+ ld_c_stats

    def finish():
        BaseObjectClass.finish()
        # for i in ld_c_stats:
        #     i.finish()


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
    # noise_rate = config['performance']['noise_rate']
    # trigger_rate = config['performance']['trigger_rate']
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
                         , wait_after_publish=wait_after_publish
                         , test_out_dir='./t/'
                         , dict_of_pid=get_pid(ssh_obj))

    start_time = timeit.default_timer()
    pool = list()
    while (timeit.default_timer() - start_time) < timeout:
        current_time = timeit.default_timer()
        # Make the Pool of workers
        pool = ThreadPool(8)
        # Open the urls in their own threads and return the results
        # for obj in stats.all_objs_list:
        #     pool.append(Process(target=obj.run, args=('')))
        for obj in stats.all_objs_list:
            pool.starmap(obj.run, '')
        # close the pool and wait for the work to finish
        pool.close()
        pool.join()
        # print(pool)
        time.sleep(interval - (timeit.default_timer() - current_time))

    print(timeit.default_timer() - start_time)
    stats.finish()
