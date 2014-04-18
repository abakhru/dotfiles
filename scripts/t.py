#!/usr/bin/env python

COMMAND="sudo find /var/lib/cassandra/data/ -type d -empty -mtime +1"

import paramiko
import os

hostname = 'mecha.silvertailsystems.com'
port = 2772

env = dict(os.environ)
user = env['USER']
private_key = env['HOME'] + '/.ssh/id_rsa'

ssh = paramiko.SSHClient()
host_keys = ssh.load_system_host_keys()

if host_keys.has_key(hostname):
    hostkeytype = host_keys[hostname].keys()[0]
    hostkey = host_keys[hostname][hostkeytype]
    print 'Using host key of type %s' % hostkeytype

#ssh.connect('mecha', username = user, key_filename = private_key)
ssh.connect(hostname, port=2772, username=user, allow_agent=True, look_for_keys=True)
#ssh.connect("10.4.21.236", username=user, allow_agent=True)
#stdin, stdout, stderr = ssh.exec_command("sudo dmesg")
stdin, stdout, stderr = ssh.exec_command(COMMAND)
#stdin.write('lol\n')
stdin.flush()
data = stdout.read.splitlines()
for line in data:
    #if line.split(':')[0] == 'AirPort':
    print line
