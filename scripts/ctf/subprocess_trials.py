#!/usr/bin/env python

import os
import subprocess

from ctf.framework.logger import LOGGER
LOGGER.setLevel('DEBUG')

def ControlJolokiaAgent(java_process_pid=0, command=None
                        , host='127.0.0.1', port=8778):
    """ Controls starting and stopping of attaching jolokia agent to any java pid.

    Args:
        java_process_pid: process id of the java process to attach jolokia agent to.
        command: stop/start jolokia JVM agent.
        host: if you want to enable remote access to jolokia provide IP address.
        port: port on which jolokia agent will be accessible. (default=8778)

    Attaching a jolokia agent gives HTTP access to all JMX objects of the java process.
    """
    if 'stop' in command:
        LOGGER.debug('Stopping jolokia JVM agent for esa-server PID %d', java_process_pid)
    else:
        LOGGER.debug('Starting jolokia JVM agent for esa-server PID %d', java_process_pid)

    # setting javaagent to Jolokia JVM agent for JMX details access.
    jolokia_agent_lib = os.path.join('..' , 'jolokia-jvm-1.2.2-agent.jar')
    cmd = '/usr/bin/java' + ' -jar ' + jolokia_agent_lib + ' '\
          + '--host ' + host + ' --port ' + str(port) + ' '\
          + command + ' ' + str(java_process_pid)
    LOGGER.debug('Launching command: \"%s\"', cmd)
    try:
        #p = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True)
        #output = subprocess.check_output(cmd, stderr=subprocess.PIPE, shell=True)
        subprocess.check_output(cmd, stderr=subprocess.PIPE, shell=True)
        #output = p.communicate()
        #LOGGER.debug(output[0])
        #LOGGER.debug(output)
    except subprocess.CalledProcessError as e:
        LOGGER.error(e)
        #LOGGER.error(output[1])
    return

def Status():
    dbdir = '/usr/local/var/postgres'
    """ Checks the postgres SQL server running status"""
    cmd = 'pg_ctl -D ' + dbdir + ' status | head -1'
    LOGGER.debug('Launching command: %s', cmd)
    p = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True)
    status = p.communicate()[0].strip()
    LOGGER.debug('posrgres status: %s', status)
    if 'PID' in status:
        LOGGER.debug('PostgreSQL server is already running')
        return True
    return False

print Status()
#ControlJolokiaAgent(java_process_pid=85478, command='start')
#ControlJolokiaAgent(java_process_pid=85478, command='stop')
