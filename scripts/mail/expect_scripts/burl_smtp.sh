#!/bin/bash
if [ $# -lt 6 ]
then
echo "Usage: $0 <mailhost> <mailfrom> <smtpport> <BASE64encodedpassword> <urlauthcode> <mailto> <domain>(optional)"
exit 0
fi
mailhost=$1
mailfrom=$2
smtpport=$3
sasl=$4
urlauthcode=$5
rcptto=$6
domain=$7

if [ "$domain" == "" ]; then
       username=$mailfrom
       secuid=$mailfrom
else
        username="$mailfrom@$domain"
        secuid="$mailfrom%40$domain"
fi
FQDN=`nslookup $mailhost|grep Name|awk '{print $2}'`
expect << EOF
set timeout 1800
spawn telnet $mailhost $smtpport
expect "*))"
send "ehlo\n"
expect "*0"
send "AUTH PLAIN $sasl\n"
expect "*."
send "mail from:$username\n"
expect "*."
send "rcpt to:$rcptto\n"
expect "*."
send "burl imap://$secuid@$FQDN/INBOX/;uid=1;urlauth=submit+$secuid:internal:$urlauthcode last\n"
expect "*com"
send "quit\n"
exit
EOF
