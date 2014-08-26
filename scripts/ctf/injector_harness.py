#!/usr/bin/env python

import time
import threading
import pexpect
import re

from ctf.framework import harness as ctf_harness
from ctf.framework.logger import LOGGER
from mctf.framework import harness as mctf_harness

LOGGER.setLevel('DEBUG')


class RpmHarness(ctf_harness.Harness):
    """Harness for a service installed through an rpm."""

    def Launch(self):
        pass

    def Terminate(self):
        pass

class InjectorRpmHarness(RpmHarness):
    """Harness for publishing data to the Nextgen pipeline through NwLogPlayer."""

    def __init__(self, host, user='root', password=None):
        """Initializes Injector with host and ssh"""

        self.host = host
        self.user = user
        self.password = password
        self.ssh = mctf_harness.SshCommandClient(host, user, password)

    def publish(self, dst_host, data_path, rate=1000, timeout=120, publish_all=True):
        """Publishes through NwLogPlayer in a loop until timeout is reached.
        Returns the count of published events.
        """
        start_time = time.time()
        end_time = start_time + timeout
        LOGGER.debug('Expected publish duration(timeout): %s', str(timeout))
        LOGGER.debug('Start time: %s', str(start_time))
        LOGGER.debug('End time: %s', str(end_time))
        publish_loops = 0
        published_events = 0
        for i in xrange(10000):
            if time.time() <= end_time:
                LOGGER.info('Starting \"%s\" publishing loop ... #%d', (data_path, publish_loops))
                command = '/usr/bin/NwLogPlayer -s %s -f "%s" --rate %d' \
                          % (dst_host, data_path, rate)
                LOGGER.info('Publish using cmd: \"%s\"', command)
                result = self.ssh.command(command, prompt='#', timeout=1000)
                LOGGER.debug('Result......: %s', result)
                try:
                    published_events = re.findall(r'sending (\d+) records', result)[0]
                    published_events = int(published_events)
                except Exception as e:
                    LOGGER.error(str(e))
                    published_events = 1269718
                publish_loops += 1
                LOGGER.info('Published events in loop #%d: %d' % (publish_loops, published_events))
            else:
                self.stop_publish()
                LOGGER.info('Stopped after ... %d loops', publish_loops)
                break
        duration = time.time() - start_time
        LOGGER.debug('Publishing duration = %s', str(duration))
        return publish_loops * published_events

    def check_kill_process(pstring):
        for line in os.popen("ps ax | grep " + pstring + " | grep -v grep"):
            fields = line.split()
            pid = fields[0]
            os.kill(int(pid), signal.SIGKILL)

    def stop_publish(self):
        try:
            self.check_kill_process('NwLogPlayer')
        except:
            pass
        return

    def cleanup(self):
        """Brings the Injector to a clean state."""
        self.stop_publish()

class NextGenFlow(InjectorRpmHarness):

    trigger_event_count = 0

    def publish_target(self, injector, dst_host, data_path, rate=1000, timeout=120):
        LOGGER.info('Start publishing trigger log %s' % data_path)
        trigger_events = self.publish(dst_host=dst_host, data_path=data_path, rate=rate, timeout=timeout)
        self.trigger_event_count += int(trigger_events)

    def publish_clearnoise(self, injector, dst_host, data_path='/root/clearNoise.dev', rate=1000, timeout=120):
        LOGGER.info('Start publishing noise %s' % data_path)
        self.publish(dst_host=dst_host, data_path=data_path, rate=rate,
                                    timeout=timeout, publish_all=False)

    def async_publish_clearnoise(self, injector, dst_host, data_path='/root/clearNoise.dev', rate=1000, timeout=120):
        t = threading.Thread(target=self.publish_clearnoise,
                             args=(injector, dst_host, data_path, rate, timeout))
        t.start()
        return t

    def async_publish_target(self, injector, dst_host, triggerlog_path=None, rate=1000, timeout=120):
        # if triggerlog_path is None:
            # triggerlog_path =  self.test_name + '.log'
        # test_log = os.path.join(self.test_data_dir, triggerlog_path)
        # test_log = triggerlog_path
        # os.system('scp %s %s@%s:' % (test_log, injector.user, injector.host))
        data_path = triggerlog_path
        t = threading.Thread(target=self.publish_target,
                             args=(injector, dst_host, data_path, rate, timeout))
        t.start()
        return t


if __name__ == '__main__':

    inj_node1 = '10.31.204.103'
    ld_node1 = inj_node1
    inj_trigger_node1 = inj_node1
    inj_node2 = '10.31.204.104'
    ld_node2 = inj_node2
    inj_trigger_node2 = inj_node2
    inj_node3 = '10.31.204.107'
    ld_node3 = inj_node3
    inj_trigger_node3 = inj_node3

    timeout = 60 * 60
    noise_rate = 60000
    trigger_rate = 3000

    abc = NextGenFlow(inj_node1, user='root')
    t = abc.async_publish_clearnoise(injector=inj_node1, dst_host=ld_node1
                                     , rate=noise_rate, timeout=timeout-60)
    time.sleep(1)
    t1 = abc.async_publish_target(injector=inj_trigger_node1, dst_host=ld_node1
                                  , rate=trigger_rate, timeout=timeout-60
                                  , triggerlog_path='/root/test_trigger_200.log')
    time.sleep(1)
    t2 = abc.async_publish_clearnoise(injector=inj_node2, dst_host=ld_node2
                                     , rate=noise_rate, timeout=timeout-60)
    time.sleep(1)
    t3 = abc.async_publish_target(injector=inj_trigger_node2, dst_host=ld_node2
                                  , rate=trigger_rate, timeout=timeout-60
                                  , triggerlog_path='/root/test_trigger_200.log')
    time.sleep(1)
    t4 = abc.async_publish_clearnoise(injector=inj_node3, dst_host=ld_node3
                                     , rate=noise_rate, timeout=timeout-60)
    time.sleep(1)
    t5 = abc.async_publish_target(injector=inj_trigger_node3, dst_host=ld_node3
                                  , rate=trigger_rate, timeout=timeout-60
                                  , triggerlog_path='/root/test_trigger_200.log')
    time.sleep(1)
    t.join()
    t1.join()
    t2.join()
    t3.join()
    t4.join()
    t5.join()
