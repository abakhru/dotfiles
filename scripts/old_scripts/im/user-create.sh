let i=$2;
let k=$3;
domain="india.sun.com"
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
echo "userpassword:iplanet";
echo "";
let i=i+1;
done
