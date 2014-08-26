#!/bin/bash -x
if [ $# -lt 3 ]
then
echo "Usage: $0 <mailhost> <mail-from> <mail-to> <from_user_domain>"
exit 0
fi

mailhost=$1
mailfrom=$2
rcptto=$3
domain=$4
#userpass=$2
adminpass=adminadmin
FQDN=`nslookup $mailhost|grep Name|awk '{print $2}'`

if [ -z $domain ]; then
	sub=1;
else
	sub=2;
fi

#Generating and extracting urlauthCode for burl urlfetch
Code=`./burl_imap.sh $mailhost $mailfrom 143 $domain|grep internal|cut -f4 -d":"`
echo "code = $Code"

#removing the trailing " from the urlauthCode
strlen=${#Code}
a=`expr $strlen - $sub`
urlauthCode=${Code:0:$a}
echo "UrlAuthCode = $urlauthCode"

#encoding uid@domainadminnetscape in base64encoded format
sasl=`./encode.pl $mailfrom $adminpass $domain`

#initiating the tcp_smtp connection on port 587 for burl access
./burl_smtp.sh $mailhost $mailfrom 587 "$sasl" $urlauthCode $rcptto $domain
#./burl_sasl.pl $mailhost $mailfrom $rcptto $urlauthCode
