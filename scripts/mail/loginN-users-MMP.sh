#!/bin/bash -x
if [ $# -ne 4 ]
then
echo "Usage: $0 <mailserver> <username>  <no_of_users> <mmp_port_number>"
echo "Example: $0 dianthos neo 100 1993"
exit 0
fi
i=400
let no_of_users=$i+$3
while [ "$i" -le "$no_of_users" ] 
do
	perl connectMMPSSL.pl $1.sfbay.sun.com $2$i $4
	let i=i+1
	echo "VALUE OF I = $i"
done
