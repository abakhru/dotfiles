#!/usr/bin/env python
import os
import timeit

from multiprocessing.dummy import Pool as ThreadPool

from framework.common.logger import LOGGER
from framework.common.harness import SshCommandClient

JENKIN_SLAVES = ['10.101.59.103']
LOGGER.setLevel('DEBUG')


class UpdateJenkins(object):

    jenkins_ssh_dict = dict()

    def __init__(self, slave):
        self.ssh_shell = SshCommandClient(host=slave, user='root', password='netwitness')
        self.jenkins_ssh_dict[slave] = self.ssh_shell

    def copy(self, repo_file):
        """Copies 10.6 repo file to all jenkins slave"""

        LOGGER.info('Copying RSA 10.6 repo file to all jenkins slaves')
        file_name = repo_file
        source_file = os.path.join('.', file_name)
        destination_file = os.path.join('/etc/yum.repos.d', file_name)
        for slave in self.jenkins_ssh_dict:
            LOGGER.info('Copying RSA 10.6 repo file \"%s\" to jenkins slave: %s', file_name, slave)
            self.jenkins_ssh_dict[slave].remove_file(destination_file)
            self.jenkins_ssh_dict[slave].copy_file(source_file, destination_file
                                                   , operation='to_remote')

    def yum_update(self):
        for slave in self.jenkins_ssh_dict:
            LOGGER.info('Running \'yum update\' on jenkins slave: %s', slave)
            self.jenkins_ssh_dict[slave].Exec('yum update -y --nogpg --skip-broken'
                                              , prompt=r']#'
                                              , timeout=6000)


def Run(slave, filename):
    p = UpdateJenkins(slave)
    p.copy(repo_file=filename)
    p.yum_update()


if __name__ == '__main__':

    repo_file = 'RSA-SA-10-Dev.repo'
    jen_tuple = list()
    for i in JENKIN_SLAVES:
        jen_tuple.append((i, repo_file))
    LOGGER.debug('=== JENKINS TUPLE: %s', jen_tuple)

    start_time = timeit.default_timer()
    # Make the Pool of workers
    pool = ThreadPool(4)
    # Open the urls in their own threads and return the results
    pool.starmap(Run, jen_tuple)
    #close the pool and wait for the work to finish
    pool.close()
    pool.join()
    print(timeit.default_timer() - start_time)
