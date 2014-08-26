#!/bin/bash
expect << EOF
set timeout 20
spawn ssh root@$1
expect "*Password:"
send "iplanet\n"
expect "*#"
send "cd /tmp\n"
expect "*#"
send "cp ../mail/t.sh /tmp/\n"
expect "*#"
send "ls -lrt /tmp\n"
expect "*#"
send "exit"
exit
EOF
