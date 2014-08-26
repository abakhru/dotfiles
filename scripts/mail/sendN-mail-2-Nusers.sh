#!/bin/bash
if [ $# -ne 4 ]
then
echo "Usage: $0 <mailserver> <mail_from_user> <mail_to_user> <no.of mails>"
echo "Example: $0 <mailserver>.sfbay.sun.com <mail_from_user> <no_of_users> <no.of mails>"
exit 0
fi

for ((b=1; b<=$3 ; b++))
do
  inner=$4
  for ((a=1; a<=$inner ; a++))
  do
	perl smail.pl f:text $1.sfbay.sun.com $2 smime$b $a
        echo "Sent email message to $3 for $b times"
  done
done               
