let i=$2;
let k=$3;
domain="us.oracle.com"
osisuffix="o=usergroup"
host=$4
user=$1
status="active"
ldap_path=`find /opt/|grep "bin/ldapmodify"|tail -1`

touch /tmp/users.ldif
./ims-user-schema1.sh $1 $2 $3 $4 > /tmp/.users.ldif

$ldap_path -D"cn=directory manager" -w password -c -f /tmp/.users.ldif

rm /tmp/.users.ldif
