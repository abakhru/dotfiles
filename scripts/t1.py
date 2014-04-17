#!/usr/bin/env python

import paramiko

client = paramiko.SSHClient()
client.load_system_host_keys()
client.connect('mecha')
stdin, stdout, stderr = client.exec_command('ls -l')

