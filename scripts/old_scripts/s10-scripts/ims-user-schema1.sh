let i=$2;
let k=$3;
domain="us.oracle.com"
osisuffix="o=usergroup"
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
echo "objectclass:inetMailUser";
echo "objectclass:inetLocalMailRecipient";
echo "objectClass:icscalendaruser";
echo "objectClass:icscalendardomain";
echo "objectclass:iplanet-am-auth-configuration-service";
echo "mail:$user$i@$domain";
echo "mailuserstatus:$status"
echo "mailquota:-1";
echo "mailhost:$host";
echo "initials: $user$i"
echo "givenname:$user$i";
echo "cn:$user$i $user$i";
echo "uid:$user$i";
echo "sn:$user$i";
echo "mailmsgquota:-1";
echo "maildeliveryoption:mailbox";
echo "preferredlanguage:en";
echo "nswmextendeduserprefs:meDraftFolder=Drafts";
echo "nswmextendeduserprefs:meSentFolder=Sent";
echo "nswmextendeduserprefs:meTrashFolder=Trash";
echo "nswmextendeduserprefs:meInitialized=true";
echo "mailAllowedServiceAccess: +imap,pop,http,smtp,imaps,smtps,pops,https:*";
echo "inetuserstatus:$status";
echo "userpassword:$user$i";
#calendar related entries
#echo "icsStatus: active";
#echo "icsExtendedUserPrefs: ceEnableInviteNotify=true";
#echo "icsExtendedUserPrefs: ceNotifySMSAddress=sms://";
#echo "icsExtendedUserPrefs: ceEnableNotifySMS=false";
#echo "icsExtendedUserPrefs: ceDefaultAlarmStart=-PT5M";
#echo "icsExtendedUserPrefs: ceNotifyEmail=$user$i@$domain";
#echo "icsExtendedUserPrefs: ceNotifyEnable=1";
#echo "icsExtendedUserPrefs: ceDefaultAlarmEmail=$user$i@$domain";
#echo "icsExtendedUserPrefs: ceEnableNotifyPopup=false";
echo "";
let i=i+1;
done
