#!/bin/bash
if [ $# -lt 3 ]
then
echo "Usage: $0 <mailhost> <mailfrom> <imap_port> <from_user_domain>(optional)"
exit 0
fi
#userpass=$2
userpass=adminadmin
if [ -z $4 ]; then
       username=$2
       secuid=$2
else
	username="$2@$4"
	secuid="$2%40$4"
fi
FQDN=`nslookup $1|grep Name|awk '{print $2}'`
expect << EOF
set timeout 1800
spawn telnet $1 $3
expect "*))"
send "1 login $username $userpass\n"
expect "*logged in"
send "2 genurlauth \"imap://$secuid@$FQDN/INBOX/;uid=1;urlauth=submit+$secuid\" INTERNAL\n"
expect "*Completed"
send "3 logout\n"
exit
EOF
