#!`which bash`
cp /.ssh/known_hosts /.ssh/known_hosts.original
tar cvf bmi_install.tar bm_client_install.sh install_bmi.sh scp_bmi_client.sh
expect << EOF
set timeout 1800
spawn ssh root@$1
expect "yes/no)?"
send "yes\n"
expect "*Password:"
send "iplanet\n"
expect "*#"
send "scp algy.sfbay.sun.com:/space/amit/scripts/perl_installer/bmi_install.tar .\n"
expect "yes/no)?"
send "yes\n"
expect "*Password:"
send "iplanet\n"
expect "*#"
send "/usr/sbin/tar xvf ./bmi_install.tar\n"
expect "*#"
send "ln -s /usr/dist/exe/expect /usr/bin/expect\n"
expect "*#"
send "bash -x /opt/brightmail/bm_client_install.sh\n"
expect "*#"
send "cp /.ssh/known_hosts.original /.ssh/known_hosts\n"
expect "*#"
send "exit"
exit
EOF
rm bmi_install.tar
cp /.ssh/known_hosts.original /.ssh/known_hosts
