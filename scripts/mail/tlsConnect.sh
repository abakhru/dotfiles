#!/bin/sh
host=dianthos.sfbay.sun.com
user=kiwong2
port=993
cert_dir=/space/smime/newcerts/
openssl s_client -host $host -port $port -verify -msg -state -debug -cert $cert_dir/$user-cert.pem -CAfile $cert_dir/cacert.pem -key $cert_dir/../private/$user-key.pem
