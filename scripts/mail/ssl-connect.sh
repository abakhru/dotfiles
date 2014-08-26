if [ $# -ne 2 ]
then
echo "Usage: $0 <mailserver> <port_number_to_connect>"
exit 0
fi

perl connectMMPSSL.pl $1.sfbay.sun.com $2
