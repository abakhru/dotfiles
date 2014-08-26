# Usage: /opt/SUNWcomm/bin/commadmin domain create -D admin 
# -w netscape -X usg53.india.sun.com -p 8080 -S cal -S mail -H usg53.india.sun.com -d domain5.com
# This shell script is to add multiple domain, this requires DA to be installed on the system 
# so that it can use the commadmin CLI tool of the DA.
# If you want to delete the above created domains then use the below mentioned command
# ldapdelete -v -D"cn=directory manager" -w netscape -h usg53.india.sun.com -p 389 dn: o=domain*.com,dc=india,dc=sun,dc=com
# /opt/SUNWcomm/bin/commadmin domain delete -D admin -w netscape -d domain4.com
os=`uname`
if [ $# -eq 4 ]
then
	let i=$2
	let k=$3
	domain=$1
	host=$4

	while test $i -lt $k
	do
		if [ $os == "SunOS" ] ; then
			echo " This is Solaris Installation";
			/opt/SUNWcomm/bin/commadmin -v domain create -D admin -w netscape -X $host -p 8080 -S cal -S mail -H $host -d $domain$i.com
			if  [ $? -eq 0 ] ; then
				echo $domain$i.com added
			fi
		else
			if [ $os == "Linux" ] ; then
				echo " This is Linux Installation";
				/opt/sun/comms/commcli/bin/commadmin -v domain create -D admin -w netscape -X $host -p 8080 -S cal -S mail -H $host -d $domain$i.com
				if  [ $? -eq 0 ] ; then
					echo $domain$i.com added
				fi
			fi
		fi

		let i=i+1;
	done
else
	echo "The number of required parameters is not provided, please run the command again with following usage!!"
	echo "# Here is the Usage of the script: "
	echo "#"
	echo "# ./create-domains.sh pepsi 1 101 usg53.india.sun.com" 
	echo "#"
	echo "# Above command will create 100 domains from pepsi1.com to pepsi100.com"

exit
fi
