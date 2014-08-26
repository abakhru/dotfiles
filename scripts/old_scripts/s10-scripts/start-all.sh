
echo "Starting LDAP Server"
/var/opt/mps/serverroot/slapd-`hostname`/start-slapd
/var/opt/mps/serverroot/start-admin
/opt/SUNWdsee/ds6/bin/dsadm start -i /var/opt/SUNWdsee/dsins1/

echo "starting smcwebconsole"
/usr/sbin/smcwebserver start

echo "Starting cacao agent"
/usr/sbin/cacaoadm start

echo "Starting mfwk agent"
/opt/SUNWmfwk/bin/mfwkadm start

echo "Starting Messaging Server"
/opt/SUNWmsgsr/sbin/start-msg
/opt/sun/comms/messaging/sbin/start-msg

echo "Starting Calendar Server"
/opt/SUNWics5/cal/sbin/start-cal
/opt/sun/comms/calendar/SUNWics5/cal/sbin/start-cal

echo "Starting WebServer" 
#/opt/SUNWwbsvr/https-`hostname`.sfbay.sun.com/start
/var/opt/SUNWwbsvr7/https-`hostname`.sfbay.sun.com/bin/startserv

echo "Starting Appserver" 
/opt/SUNWappserver/sbin/asadmin start-domain --user admin --password netscape domain1
/opt/SUNWappserver/bin/asadmin start-domain --user admin --password netscape domain1

echo "Starting  WebServer-Admin" 
#/opt/SUNWwbsvr/https-admserv/start
/var/opt/SUNWwbsvr7/admin-server/bin/startserv

echo "Starting IM Server"
/opt/SUNWiim/sbin/imadmin start
/opt/sun/comms/im/sbin/imadmin start
