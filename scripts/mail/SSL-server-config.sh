cd /opt/sun/comms/messaging64/sbin
echo "password" > /tmp/.pwd.txt
./msgcert generate-certDB
./msgcert list-certs -W /tmp/.pwd.txt
./msgcert remove-cert -W /tmp/.pwd.txt Server-Cert
./msgcert request-cert -W /tmp/.pwd.txt --name `hostname`.red.iplanet.com --org "Sun Microsystems, Inc." --org-unit Comms --city SCA --state CA --country US -F ascii -o /tmp/`hostname`-cert-req.txt

#Generate the CA-cert db
#Import cacert.pem  to cert-db
#Get the cert-req.txt signed from CA
openssl ca -config openssl.cnf.SSL-Server -out /tmp/`hostname`-cert.pem -infiles /tmp/`hostname`-cert-req.txt
# Import the signed server-cert to the certdb

./msgcert add-cert -W /tmp/.pwd.txt -C CA-Cert /opt/sun/comms/messaging64/sbin/cacert.pem
./msgcert add-cert -W /tmp/.pwd.txt Server-Cert /opt/sun/comms/messaging64/sbin/`hostname`-cert.pem


# Create user cert-request
openssl req -new -nodes -out ./certs/neo32-req.pem -keyout private/neo32-key.pem -config openssl.cnf
openssl req -new -nodes -out ./certs/neo35-req.pem -keyout private/neo35-key.pem -config openssl.cnf

# Approve user cert-request
openssl ca -config openssl.cnf -out ./newcerts/neo32-cert.pem -infiles ./certs/neo32-req.pem
openssl ca -config openssl.cnf -out ./newcerts/neo35-cert.pem -infiles ./certs/neo35-req.pem

# To Export user-signed certificated into pkcs12 format:
openssl pkcs12 -export -in neo32-cert.pem -inkey private/neo32-key.pem -certfile neo32-cert.pem -name neo32@red.iplanet.com -out neo32-cert.p12
openssl pkcs12 -export -in neo35-cert.pem -inkey private/neo35-key.pem -certfile neo35-cert.pem -name neo35@red.iplanet.com -out neo35-cert.p12

#Ftp the neo*-cert.pk12 files to the desktop & import it into Thunderbird
# Add the certificate into the 
