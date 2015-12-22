#!/usr/bin/env python

import os
import sys

from subprocess import Popen, CalledProcessError, PIPE
from ctf.framework.logger import LOGGER
from mctf.framework import harness as mctf_harness

LOGGER.setLevel('DEBUG')
# For Mac
# ROOT_DIR = '/Users/bakhra/src/esa'
# JDK7_HOME = '/Library/Java/JavaVirtualMachines/jdk1.7.0_71.jdk/Contents/Home'
# JDK8_HOME = '/Library/Java/JavaVirtualMachines/jdk1.8.0_40.jdk/Contents/Home'
# For Linux
ROOT_DIR = '/home/bakhra/source/esa/'
JDK7_HOME = '/usr/lib/jvm/java-1.7.0-openjdk.x86_64'
JDK8_HOME = '/usr/lib/jvm/java-1.8.0-openjdk'

PYTHONPATH = ('%s/python:../../../python' % ROOT_DIR)

class BaseJenkinsJob(object):
    def __init__(self, host='localhost', **kwargs):
        for k, v in kwargs.items():
            setattr(self, k, v)
        self.rpms_list = list()
        self.dest_host = host
        if self.dest_host != 'localhost':
            self.ssh_shell = mctf_harness.SshCommandClient(self.dest_host)

    def set_env_variables(self, **kwargs):
        cur_env = os.environ.copy()
        new_env = cur_env
        if 'JDK_HOME' in kwargs:
            new_env['JDK_HOME'] = kwargs.get('JDK_HOME', JDK8_HOME)
        if 'JAVA_HOME' in kwargs:
            new_env['JAVA_HOME'] = kwargs.get('JAVA_HOME', JDK8_HOME)
        return new_env

    def ExecShell(self, cmd, env=None):
        """Executes a shell subprocess."""
        LOGGER.debug('ExecShell: %s', cmd)
        if env is None:
            env = os.environ.copy()
        try:
            p = Popen(cmd, stdout=PIPE, bufsize=1, shell=True, env=env)
            for line in iter(p.stdout.readline, b''):
                print(line.decode(), end='')
            p.stdout.close()
            p.wait()
        except CalledProcessError as e:
            LOGGER.error(e)

    def build_rpm(self):
        if sys.platform.lower() == 'darwin':
            cmd = ('cd %s; mvn package -DskipTests' % ROOT_DIR)
        else:
            cmd = ('cd %s; mvn -U clean package -Prpm -DskipTests' % ROOT_DIR)
        new_env = self.set_env_variables(JAVA_HOME=JDK7_HOME)
        self.ExecShell(cmd, new_env)

    def find_rpms(self):
        cmd = ('find %s -type f -name \'*.rpm\'' % ROOT_DIR)
        p = Popen(cmd, stdout=PIPE, shell=True)
        output = p.communicate()[0].strip().decode()
        LOGGER.debug('Output: %s', output)
        for rpm in output.split('\n'):
            self.rpms_list.append(os.path.join(ROOT_DIR, rpm))
        LOGGER.info('RPMS: %s', self.rpms_list)

    def scp_rpm(self):
        for rpm in self.rpms_list:
            if self.dest_host != 'localhost':
                cmd = ('scp %s root@%s:~' % (rpm, self.dest_host))
            else:
                cmd = ('cp %s ~' % rpm)
            LOGGER.debug('Launching command: \"%s\"', cmd)
            self.ExecShell(cmd)

    def remove_existing_rpm(self, rpm_name='rsa-esa-server rsa-esa-client'):
        cmd = ('sudo yum -y remove %s' % rpm_name)
        LOGGER.debug('Launching command: \"%s\"', cmd)
        if self.dest_host != 'localhost':
            self.ssh_shell.command(cmd, '#')
        else:
            self.ExecShell(cmd)

    def install_new_rpm(self, rpm_full_path='~/rsa-esa-*.rpm'):
        cmd = ('sudo yum -y install %s' % rpm_full_path)
        LOGGER.debug('Launching command: \"%s\"', cmd)
        if self.dest_host != 'localhost':
            self.ssh_shell.command(cmd, '#')
        else:
            self.ExecShell(cmd)

    def python3_env_vars(self, python_enable_file='/opt/rh/python34/enable'):
        py_env_dict = {}
        with open(python_enable_file) as f:
            for line in f.readlines():
                if '#' in line:
                    continue
            a = line.split(' ')[1].split('=')
            py_env_dict[a[0]] = a[1].strip()
        return py_env_dict

    def run_ctf(self, CTF_DEBUG=0):

        cmd = ('cd %s/python/ctf/esa; ' % ROOT_DIR)
        cmd += 'nosetests --version; '
        cmd += 'nosetests --version; '
        cmd += 'nosetests -e \"^Setup\" -svm \'single\' test/basic_test.py'
        all_env_vars = dict()
        all_env_vars['PYTHONPATH'] = PYTHONPATH
        all_env_vars['JAVA_HOME'] = JDK7_HOME
        all_env_vars['CTF_DEBUG'] = CTF_DEBUG
        for k, v in self.python3_env_vars().items():
            all_env_vars[k] = v
        new_env = self.set_env_variables(**all_env_vars)
        self.ExecShell(cmd, new_env)

# class BuildAndInstallESA(BaseJenkinsJob):

if __name__ == '__main__':
    # Publishing
    p = BaseJenkinsJob()
    # p.build_rpm()
    # p.find_rpms()
    # p.scp_rpm()
    # p.remove_existing_rpm()
    # p.install_new_rpm()
    p.run_ctf(CTF_DEBUG=1)
