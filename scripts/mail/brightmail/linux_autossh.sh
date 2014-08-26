#!/bin/bash
cp /.ssh/known_hosts /.ssh/known_hosts.original
tar cvf bmi_install.tar bm_client_install.sh install_bmi.sh scp_bmi_client.sh
expect << EOF
set timeout 1800
spawn ssh root@$1
expect "yes/no)?"
send "yes\n"
expect "*password:"
send "iplanet\n"
expect "*#"
send "mkdir /opt/brightmail/\n"
expect "*#"
send "cd /opt/brightmail/\n"
expect "*#"
send "/bin/cp /root/.ssh/known_hosts /root/.ssh/known_hosts.original\n"
expect "*#"
send "scp algy:/space/amit/scripts/mail/brightmail/bmi_install.tar .\n"
expect "yes/no)?"
send "yes\n"
expect "*Password:"
send "iplanet\n"
expect "*#"
send "tar xvf ./bmi_install.tar\n"
expect "*#"
send "/bin/bash -x /opt/brightmail/bm_client_install.sh\n"
expect "*#"
send "/bin/cp /root/.ssh/known_hosts.original /root/.ssh/known_hosts\n"
expect "*#"
send "exit"
exit
EOF
rm bmi_install.tar
cp /.ssh/known_hosts.original /.ssh/known_hosts
