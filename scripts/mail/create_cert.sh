#!/usr/bin/bash
user=$1
domain=$2
host=$3
expect << EOF
set timeout 1800
spawn ./GenerateUserCert.sh $user $domain $host
expect "*]:"
send "\n"
expect "*]:"
send "\n"
expect "*]:"
send "\n"
expect "*]:"
send "\n"
expect "*]:"
send "\n"
expect "*]:"
send "$user@$domain\n"
expect "*]:"
send "$user@$domain\n"
expect "*]:"
send "password\n"
expect "*]:"
send "\n"
expect "*pem:"
send "password\n"
expect "*]:"
send "y\n"
expect "*]"
send "y\n"
expect "*word:"
send "password\n"
expect "*word:"
send "password\n"
expect "*p12"
exit
EOF
