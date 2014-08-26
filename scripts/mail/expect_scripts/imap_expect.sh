#!/bin/bash
expect << EOF
set timeout 1800
spawn telnet localhost 143
expect "*))"
send "a login $2 $2\n"
expect "*logged in"
#send "b LIST \"\" \"\*\"\n"
#expect "*"
send "c select INBOX\n"
expect "*Completed"
send "d fetch 1 rfc822\n"
#send "d fetch 1 all\n"
#send "d fetch 1 fast\n"
expect "*Completed"
#send "e EXAMINE INBOX\n"
#expect "*Completed"
send "e status INBOX (SIZE)\n"
expect "*Completed"
send "f capability\n"
expect "*Completed"
send "g logout\n"
exit
EOF
