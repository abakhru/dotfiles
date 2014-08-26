#!/usr/bin/bash
if [ $# -lt 2 ]
then
echo "Usage: ./GenerateUserCert.sh <user> <us.oracle.com> <ldaphost>"
exit 0
fi

user=$1
domain=$2
ldaphost=$3

CERTLOC="GENV_CERTIFICATELOC"
OPENSSL_PATH="/usr/local/ssl/bin"

#creating the cert-request
echo "Issuing command: $OPENSSL_PATH/openssl req -new -nodes -out $CERTLOC/certs/$user-req.pem -keyout $CERTLOC/private/$user-key.pem -config $CERTLOC/openssl.cnf
"
$OPENSSL_PATH/openssl req -new -nodes -out $CERTLOC/certs/$user-req.pem -keyout $CERTLOC/private/$user-key.pem -config $CERTLOC/openssl.cnf

# CA signing the cert-request
echo "Issuing command: $OPENSSL_PATH/openssl ca -config $CERTLOC/openssl.cnf -out $CERTLOC/newcerts/$user-cert.pem -infiles $CERTLOC/certs/$user-req.pem
"
$OPENSSL_PATH/openssl ca -config $CERTLOC/openssl.cnf -out $CERTLOC/newcerts/$user-cert.pem -infiles $CERTLOC/certs/$user-req.pem

# exporting the user cert in p12 format
echo "Issuing command: $OPENSSL_PATH/openssl pkcs12 -export -in $CERTLOC/newcerts/$user-cert.pem -inkey $CERTLOC/private/$user-key.pem -certfile $CERTLOC/newcerts/$user-cert.pem -name $user@$domain -out $CERTLOC/newcerts/$user-cert.p12 -password \"pass:GENV_MSADMINPSWD\" -passin \"pass:GENV_MSADMINPSWD\"
"
$OPENSSL_PATH/openssl pkcs12 -export -in $CERTLOC/newcerts/$user-cert.pem -inkey $CERTLOC/private/$user-key.pem -certfile $CERTLOC/newcerts/$user-cert.pem -name $user@$domain -out $CERTLOC/newcerts/$user-cert.p12 -password "pass:GENV_MSADMINPSWD" -passin "pass:GENV_MSADMINPSWD"

#extracting the cert binary from cert-pem file
first=`grep -n BEGIN $CERTLOC/newcerts/$user-cert.pem | cut -f1 -d":"`
last=`grep -n END $CERTLOC/newcerts/$user-cert.pem | cut -f1 -d":"`
sed "1,$first d" $CERTLOC/newcerts/$user-cert.pem > $CERTLOC/ldifs/$user.ldif
sed '/CERTIFICATE/d' $CERTLOC/ldifs/$user.ldif > $CERTLOC/ldifs/a
CERT=`cat $CERTLOC/ldifs/a |tr -d '\n'`

# creating the user.ldif file to be imported into ldap
echo "dn:uid=$user,ou=People,o=$domain,GENV_OSIROOT
changetype:modify
add: userCertificate;binary
usercertificate;binary:: $CERT" >$CERTLOC/ldifs/$user.ldif

rm $CERTLOC/ldifs/a

echo "==== Importing $CERTLOC/ldifs/$user.ldif into GENV_DSHOST1.us.oracle.com";
echo "Issuing command: LDAPMODIFY_PATH -D"GENV_DM" -w GENV_DMPASSWORD -v -h "GENV_DSHOST1.GENV_DOMAIN" -c -f $CERTLOC/ldifs/$user.ldif
"

LDAPMODIFY_PATH -D"GENV_DM" -w GENV_DMPASSWORD -v -h GENV_DSHOST1.GENV_DOMAIN -p 389 -c -f $CERTLOC/ldifs/$user.ldif

if [ $? -eq 0 ]
then
    echo "==== Modified the user entry in ldap with usercertificate Successfully"
else
    echo "==== User's ldap entry modification FAILED"
fi

cd $CERTLOC
