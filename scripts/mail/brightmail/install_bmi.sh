#!/bin/bash
expect << EOF
set timeout 70
spawn ./install
expect "*install?"
send "1\n"
expect "*CONTINUE:"
send "\n"
expect "  : "
send "1\n"
expect "  : "
send "\n"
expect "*brightmail):"
send "\n"
expect "  : "
send "2\n"
expect "*none):"
send "10.5.195.174\n"
expect "  : "
send "3\n"
expect "*CONTINUE:"
send "\n"
expect "*1):"
send "10.5.195.174\n"
expect "*INSTALLER:"
send "\n"
expect "*#"
exit
EOF
