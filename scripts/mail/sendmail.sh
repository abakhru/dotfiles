if [ $# -ne 4 ]
then
echo "Usage: $0 <mailhost> <mail_from_user> <mail_to_user> <no.of mails>"
exit 0
echo "Please enter the mail server name (mailservername).sfbay.sun.com:"
read mailserver
echo "From:"
read mail_from_user
echo "To:"
read mail_to_user
echo "No. of mails:"
read no_of_times
for ((a=1; a <= $no_of_times ; a++))
do
	perl smail.pl f:text $mailserver.us.oracle.com $mail_from_user $mail_to_user $a
	echo "Sent email message to $rcpt for $a times"
done 
fi

for ((b=1; b<=$4 ; b++))
do
        perl smail.pl f:text $1.us.oracle.com $2 $3 $b
        echo "Sent email message to $3 for $b times"
done
