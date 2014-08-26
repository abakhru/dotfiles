if [ $# -ne 1 ]
then
echo "Usage: ./$0 <user>"
exit 0
fi

user=$1
dir=`pwd`
rm *.msg

#To send a singed message
openssl smime -sign -in /space/amit/scripts/mail/file -out $dir/signed.msg -signer /space/smime/newcerts/$user-cert.pem -inkey /space/smime/private/$user-key.pem -text

#To send an encrypted message
openssl smime -encrypt -in $dir/signed.msg -out $dir/encrypted-signed.msg /space/smime/newcerts/$user-cert.pem

# To decrypt the encrypted message
openssl smime -decrypt -in $dir/encrypted-signed.msg -out $dir/received.msg -recip /space/smime/newcerts/$user-cert.pem -inkey /space/smime/private/$user-key.pem

#Signature validation
openssl smime -verify -text -CAfile /space/smime/newcerts/cacert.pem -in $dir/received.msg

#print the content of the message and verify the valitidy of the certificate chain. Finally, the recipient checks whether the signer is indeed the appropriate sender
openssl smime -pk7out -in $dir/received.msg | openssl pkcs7 -print_certs -noout
