#!/bin/bash
FQDN=`nslookup $1|grep Name|awk '{print $2}'`
expect << EOF
set timeout 1800
spawn telnet localhost 25
expect "*))"
send "ehlo\n"
expect "*0"
send "mail from:$1\n"
expect "*."
send "rcpt to:$2 NOTIFY=SUCCESS\n"
expect "*."
send "rcpt to:$2 NOTIFY=SUCCESS\n"
expect "*."
send "rcpt to:$2 NOTIFY=SUCCESS\n"
expect "*."
send "RSET\n"
expect "*."
send "quit\n"
exit
EOF
