if [ $# -lt 4 ]
then
echo "Usage: $0 <mail_host> <mail_from_user> <mail_to_user> <no.of mails> <sender_domain>"
exit
fi

FQDN=`nslookup $1|grep Name|awk '{print $2}'`
perl SASL.pl f:text $FQDN $2 $3 $4 $5
