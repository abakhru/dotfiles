let i=$2;
let k=$3;
domain="us.oracle.com"
osisuffix="o=usergroup"
host=$4
user=$1
status="active"
ldap_path=`find /opt/sun |grep "bin/ldapmodify"`

touch /tmp/.users.ldif
while test $i -lt $k
do
echo "dn:uid=$user$i,ou=People,o=$domain,$osisuffix" >> /tmp/.users.ldif;
echo "changetype:delete" >> /tmp/.users.ldif;
echo "" >> /tmp/.users.ldif;
let i=i+1;
done

$ldap_path -D"cn=directory manager" -w password -c -f /tmp/.users.ldif

rm /tmp/.users.ldif
