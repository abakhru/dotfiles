user=$1;
cat /opt/certs/private/$user-key.pem > /opt/certs/newcerts/$user-KeyCert.pem
cat /opt/certs/newcerts/$user-cert.pem >> /opt/certs/newcerts/$user-KeyCert.pem
/opt/csw/bin/curl -v --sslv3 --cert /opt/certs/newcerts/$user-KeyCert.pem --cacert /opt/certs/newcerts/cacert.pem -c /tmp/cookies.txt https://dianthos.sfbay.sun.com:81/iwc/svc/iwcp/login.iwc
/opt/csw/bin/curl -v --sslv3 --cert /opt/certs/newcerts/$user-KeyCert.pem --cacert /opt/certs/newcerts/cacert.pem -c /tmp/cookies.txt  https://dianthos.sfbay.sun.com:81/iwc/svc/wcap/get_calprops.wcap?
#/opt/csw/bin/curl --sslv3 --cert /opt/certs/newcerts/$user-KeyCert.pem --cacert /opt/certs/newcerts/cacert.pem -c /tmp/cookies.txt https://dianthos.sfbay.sun.com/login.wcap
