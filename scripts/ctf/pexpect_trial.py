#!/usr/bin/python

import pexpect

ssh = pexpect.spawn('ssh mecha')

prompts = [">", "#", "\$", "}", '%', pexpect.TIMEOUT]
ssh.sendline('find /var/opt/silvertail/')
ssh.expect(prompts)
print ssh.before
