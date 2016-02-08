#!/usr/bin/env python

import os
import timeit

from multiprocessing.dummy import Pool as ThreadPool

from framework.common.logger import LOGGER
from framework.common.harness import SshCommandClient

REPO_FILE = 'RSA-SA-10-Dev.repo'
FIX_JAVA = 'fix_java_alternatives_old.sh'
JENKIN_SLAVES = ['10.101.59.103',
                 '10.101.59.127',
                 '10.101.216.127',
                 '10.101.59.131',
                 '10.101.59.174',
                 '10.101.59.123',
                 '10.101.59.132',
                 '10.101.59.178',
                 '10.101.59.125',
                 '10.101.59.133',
                 '10.101.59.179',
                 '10.101.59.126',
                 '10.101.59.134',
                 '10.101.59.149',
                 '10.101.59.23',
                 '10.101.59.26',
                 '10.101.59.63',
                 '10.101.59.68',
                 '10.101.59.66',
                 '10.101.59.65',
                 '10.101.59.81',
                 '10.101.59.82',
                 '10.101.59.69',
                 '10.101.59.64',
                 '10.101.59.105',
                 '10.101.59.62',
                 '10.101.59.96',
                 '10.101.59.36',
                 '10.101.59.19',
                 '10.101.59.53',
                 '10.101.59.109',
                 '10.101.59.124',
                 '10.101.59.34'
                 ]
REF_SLAVES = ['10.101.216.148'
              , '10.101.216.150'
              , '10.101.216.223'
              , '10.101.216.227'
              , '10.101.216.238'
              , '10.101.216.231'
              ]
PSR_SLAVES = ['10.101.59.231'
              , '10.101.59.232'
              , '10.101.59.232'
              , '10.101.59.233'
              , '10.101.59.234'
              , '10.101.59.235'                                                                                      , '10.101.59.236'
              , '10.101.59.237'
              , '10.101.59.238'
              , '10.101.59.239'
              , '10.101.59.240'
              , '10.101.59.241'
              , '10.101.59.242'
            #   , '10.101.59.243'
              , '10.101.59.244'
              , '10.101.59.245'
              , '10.101.59.204'
              , '10.101.59.206'
              , '10.101.59.208'
              , '10.101.59.227'
              , '10.101.59.229'
              , '10.101.59.246'
              , '10.101.59.210'
              , '10.101.59.248'
              , '10.101.59.202'
              ]

LOGGER.setLevel('DEBUG')


class UpdateJenkins(object):

    def __init__(self, slave):
        self.ssh_shell = SshCommandClient(host=slave, user='root', password='netwitness')
        # self.CopyRepo()
        # self.YumUpdate()
        # self.Put(src_file='Python-3.5.1.tgz', dest_file='/Python-3.5.1.tgz')
        # stop all puppets and firewall
        self.RunCommand('for i in puppetmaster puppet iptables ip6tables ; do service $i stop; chkconfig $i off; done')
        # self.RunCommand('service ntpd stop; service ntpdate start; service ntpd start')
        # self.RunCommand("source /opt/rh/python35/enable; python -V; pip list|grep psycopg2")
        self.Close()

    def Put(self, src_file, dest_file):
        """Copies src_file to all jenkins slave"""

        src_file = os.path.join('.', src_file)
        LOGGER.info('[%s] Copying %s file to jenkins slave', self.ssh_shell.host, src_file)
        self.ssh_shell.remove_file(dest_file)
        if not self.ssh_shell.assert_remote_file_exists(dest_file):
            self.ssh_shell.copy_file(src_file, dest_file, operation='to_remote')
        self.ssh_shell.Exec('ls -larth /%s' % os.path.basename(src_file))
        self.ssh_shell.Exec('cd /; tar xvzf %s' % dest_file)
        self.ssh_shell.Exec('ls -l /opt/rh')

    def CopyRepo(self, repo_file=None):
        """Copies 10.6 repo file to all jenkins slave"""

        LOGGER.info('Copying RSA 10.6 repo file to all jenkins slaves')
        file_name = repo_file
        if file_name is None:
            file_name = REPO_FILE
        source_file = os.path.join('.', file_name)
        destination_file = os.path.join('/etc/yum.repos.d', file_name)
        LOGGER.info('Copying RSA 10.6 repo file \"%s\" to jenkins slave: %s'
                    , file_name, self.ssh_shell.host)
        self.ssh_shell.remove_file(destination_file)
        self.ssh_shell.Exec('cd /etc/yum.repos.d; mkdir t; mv *.repo ./t/')
        self.ssh_shell.copy_file(source_file, destination_file, operation='to_remote')

    def YumUpdate(self):
        cmd = 'yum clean all; yum update -y --nogpg --skip-broken'
        LOGGER.info('Running \'%s\' on jenkins slave: %s', cmd, self.ssh_shell.host)
        self.ssh_shell.Exec(cmd, prompt=r']#', timeout=6000)

    def RunCommand(self, cmd):
        LOGGER.info('[%s] Running \'%s\'', self.ssh_shell.host, cmd)
        self.ssh_shell.Exec(cmd)

    def Close(self):
        self.ssh_shell.close()

class FixJava(object):

    def __init__(self, slave):
        self.ssh_shell = SshCommandClient(host=slave, user='root', password='netwitness')
        self.fix_java_file = ''
        self.copy()
        self.execute()
        self.ssh_shell.close()

    def copy(self, repo_file=None):
        """Copies 10.6 repo file to all jenkins slave"""

        LOGGER.info('Copying RSA 10.6 repo file to all jenkins slaves')
        file_name = repo_file
        if file_name is None:
            file_name = FIX_JAVA
        source_file = os.path.join('.', file_name)
        if os.path.exists(source_file):
            raise FileNotFoundError('%s not found' % source_file)
        self.fix_java_file = os.path.join('/tmp', file_name)
        LOGGER.info('Copying RSA 10.6 repo file \"%s\" to jenkins slave: %s'
                    , file_name, self.ssh_shell.host)
        self.ssh_shell.remove_file(self.fix_java_file)
        self.ssh_shell.copy_file(source_file, self.fix_java_file, operation='to_remote')

    def execute(self):
        LOGGER.info('Running on jenkins slave: %s', self.ssh_shell.host)
        self.ssh_shell.Exec('sh -x %s; sh -x /tmp/fix_java_alternatives.sh' % self.fix_java_file
                            , prompt=r']#', timeout=6000)
        self.ssh_shell.Exec('java -version')


if __name__ == '__main__':

    start_time = timeit.default_timer()
    # Make the Pool of workers
    pool = ThreadPool(8)
    # Open the urls in their own threads and return the results
    pool.map(UpdateJenkins, PSR_SLAVES)
    # pool.map(UpdateJenkins, REF_SLAVES)
    # pool.map(UpdateJenkins, JENKIN_SLAVES)
    # pool.map(FixJavaRun, REF_SLAVES)
    # close the pool and wait for the work to finish
    pool.close()
    pool.join()
    print(timeit.default_timer() - start_time)
