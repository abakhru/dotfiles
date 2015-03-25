#!/usr/bin/python

import os

temp_dir = '/tmp/temp_epl_dir'

if os.path.exists(temp_dir):
    os.system('rm -rf %s' % temp_dir)

os.system('mkdir %s' % temp_dir)
setup_script = os.path.join(temp_dir, 'setup.cmds')

epl_count = 20

for i in range(1, epl_count + 1):
    module_def = ("@RSAAlert @Name('EPL-user%s') Select * from Event (user_dst='user%s')"
                   % (str(i), str(i)))
    epl_file = os.path.join(temp_dir, 'epl' + str(i) + '.epl')
    cli_command = ('epl-module-set %s --eplFile "%s" --severity %s --enabled %s --engineId %s'
                   % ('epl' + str(i), epl_file, '4', 'True', 'default'))
    os.system('echo "%s" > %s' % (module_def, epl_file))
    os.system('echo "%s" >> %s' % (cli_command, setup_script))
