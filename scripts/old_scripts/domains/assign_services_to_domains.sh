# This script is to assign IM & Presence services to the any number of domains, also it requires ldapmodify in your PATH

if [ $# -eq 4 ]
then
let i=$2;
let k=$3;
domain=$1
osisuffix="dc=india,dc=sun,dc=com"
host=$4

while test $i -lt $k
do
	echo "dn: o=$domain$i.com,$osisuffix"
	echo "changetype: modify"
	echo "add: objectclass"
	echo "objectclass: sunIMuser";
	echo "objectclass: sunPresenceuser";
	echo "add: sunRegisteredServiceName"
	echo "sunRegisteredServiceName: SunIM";
	echo "sunRegisteredServiceName: SunPresence";
	echo ""
	let i=i+1;
done

else
	if [ "$1" == "help" ]
	then
        echo "The number of required parameters is not provided, please run the command again with following usage#!"
        echo "# Here is the Usage of the script: "
        echo "#"
        echo "# ./assign_services.sh <domain-name> 1 101 usg53.india.sun.com>/imservice.ldif"
        echo "#"
	echo "# ldapmodify -D\"cn=directory manager\" -w netscape -f /pepsiusers.ldif"

	else 
        echo "The number of required parameters is not provided, please run the command again with following usage!!"
        echo "# Here is the Usage of the script: "
        echo "#"
        echo "# ./assign_services.sh <domain-name> 1 101 usg53.india.sun.com >/pepsiusers.ldif"
        echo "#"
        echo "# Above command will create 100 users from pepsi1 to pepsi100 in pepsiusers.ldif file"
	echo "# Add the above created ldif to the ldap using the below command:"
	echo "# ldapmodify -D\"cn=directory manager\" -w netscape -f /pepsiusers.ldif"
	fi

exit
fi
