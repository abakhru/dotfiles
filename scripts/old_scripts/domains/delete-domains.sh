# This shell script is to delete multiple domain, this requires DA to be installed on the system 
# so that it can use the commadmin CLI tool of the DA.
# If you want to delete the above created domains then use the below mentioned command
# /opt/SUNWcomm/bin/commadmin domain delete -D admin -w netscape -d domain4.com

if [ $# -eq 4 ]
then
	let i=$2
	let k=$3
	domain=$1
	host=$4

	while test $i -lt $k
	do
		/opt/SUNWcomm/bin/commadmin domain delete -D admin -w netscape -X $host -p 8080 -d $domain$i.com
		echo $domain$i Deleted
		let i=i+1;
	done
else
	echo "The number of required parameters is not provided, please run the command again with following usage!!"
	echo "# Here is the Usage of the script: "
	echo "#"
	echo "# ./delete-domains.sh pepsi 1 101 usg53.india.sun.com" 
	echo "#"
	echo "# Above command will delete 100 domains from pepsi1 to pepsi100"

exit
fi
