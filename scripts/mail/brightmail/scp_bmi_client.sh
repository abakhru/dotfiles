#!/bin/bash
expect << EOF
set timeout 60
spawn scp dear.sfbay.sun.com:$1 .
expect "yes/no)?"
send "yes\n"
expect "*Password:"
send "iplanet\n"
expect "*#"
exit
EOF
