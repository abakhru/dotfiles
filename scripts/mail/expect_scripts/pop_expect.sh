#!/bin/bash
expect << EOF
set timeout 1800
spawn telnet $1 $3
expect "*))"
send "user $2\n"
expect "OK*"
send "pass $2\n"
expect "OK*"
send "list\n"
expect "OK*"
send "retr 1\n"
expect "."
send "quit\n"
exit
EOF
