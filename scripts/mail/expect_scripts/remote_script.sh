#!/bin/bash
echo "" >/.ssh/known_hosts
expect << EOF
set timeout 180
spawn ssh root@$2
expect "yes/no)?"
send "yes\n"
expect "*assword:"
send "iplanet\n"
expect "*#"
send "$1\n"
expect "*#"
send "exit"
exit
EOF
