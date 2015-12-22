#!/usr/bin/env python
import os

from framework.common.logger import LOGGER
from framework.common.harness import SshCommandClient

jenkins_slaves = []


class UpdateJenkins(object):

    jenkins_ssh_dict = dict()

    def __init__(self):
        for slave in jenkins_slaves:
            self.ssh_shell = SshCommandClient(host=slave, user='root', password='netwitness')
            self.jenkins_ssh_dict[slave] = self.ssh_shell

    def copy(self, repo_file):
        """Copies 10.6 repo file to all jenkins slave"""
        LOGGER.info('Copying RSA 10.5.1 repo file to all jenkins slaves')
        file_name = 'RSASoftware.repo'
        source_file = os.path.join(file_name)
        destination_file = os.path.join('/etc/yum.repos.d', file_name)
        for slave in self.jenkins_ssh_dict:
            LOGGER.info('Copying RSA 10.5.1 repo file to jenkins slave: %s', slave)
            self.jenkins_ssh_dict[slave].copy_file(source_file, destination_file
                                                   , operation='to_remote')

    def yum_update(self):
        for slave in self.jenkins_ssh_dict:
            LOGGER.info('Running \'yum update\' on jenkins slave: %s', slave)
            self.jenkins_ssh_dict[slave].Exec('yum update -y --nogpg')


if __name__ == '__main__':

    p = UpdateJenkins()
    p.copy(repo_file='')
    p.yum_update()
