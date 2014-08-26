if [ $# -eq 4 ]
then
let i=$2;
let k=$3;
domain="pepsi1.com"
osisuffix="dc=india,dc=sun,dc=com"
host=$4
user=$1
status="active"

while test $i -lt $k
do
echo "dn:uid=$user$i,ou=People,o=$domain,$osisuffix";
echo "changetype:add";
echo "objectclass:top";
echo "objectclass:person";
echo "objectclass:organizationalPerson";
echo "objectclass:inetOrgPerson";
echo "objectclass:inetUser";
echo "objectclass:ipUser";
echo "objectclass:nsManagedPerson";
echo "objectclass:userPresenceProfile";
echo "objectclass:inetMailUser";
#echo "objectclass:sunIMuser";
#echo "objectclass:sunPresenceuser";
echo "objectClass: icsCalendaruser";
echo "objectclass:inetLocalMailRecipient";
echo "mail:$user$i@$domain";
echo "mailuserstatus:$status";
echo "datasource:Shell Script";
echo "mailquota:-1";
echo "mailhost:$host";
echo "initials: $user$i"
echo "givenname:$user$i";
echo "cn:$user$i $user$i";
echo "uid:$user$i";
echo "nsdacapability:mailListCreate";
echo "sn:$user$i";
echo "mailmsgquota:-1";
echo "maildeliveryoption:mailbox";
echo "preferredlanguage:en";
echo "nswmextendeduserprefs:meDraftFolder=Drafts";
echo "nswmextendeduserprefs:meSentFolder=Sent";
echo "nswmextendeduserprefs:meTrashFolder=Trash";
echo "nswmextendeduserprefs:meInitialized=true";
echo "inetuserstatus:$status";
echo "userpassword:$user$i";
echo "";
let i=i+1;
done

else
	if [ "$1" == "help" ]
	then
        echo "The number of required parameters is not provided, please run the command again with following usage#!"
        echo "# Here is the Usage of the script: "
        echo "#"
        echo "# ./ims-user.sh <user-name> 1 101 usg53.india.sun.com >/pepsiusers.ldif"
        echo "#"
        echo "# Above command will create 100 users from pepsi1 to pepsi100 in pepsiusers.ldif file"
	echo "# Add the above created ldif to the ldap using the below command:"
	echo "# ldapmodify -D\"cn=directory manager\" -w netscape -f /pepsiusers.ldif"

	else 
	echo "Your a fool"
        echo "The number of required parameters is not provided, please run the command again with following usage!!"
        echo "# Here is the Usage of the script: "
        echo "#"
        echo "# ./ims-user.sh <user-name> 1 101 usg53.india.sun.com >/pepsiusers.ldif"
        echo "#"
        echo "# Above command will create 100 users from pepsi1 to pepsi100 in pepsiusers.ldif file"
	echo "# Add the above created ldif to the ldap using the below command:"
	echo "# ldapmodify -D\"cn=directory manager\" -w netscape -f /pepsiusers.ldif"
	fi

exit
fi
