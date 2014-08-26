#if [ $# -ne 1 ]
#then
#        echo "Please enter the hostname:[`hostname`]"
#else
host=`hostname`

echo "Stop WebServer"
/opt/SUNWwbsvr/https-$host.sfbay.sun.com/stop
/var/opt/SUNWwbsvr7/https-$host.sfbay.sun.com/bin/stopserv

echo "Stopping APpserver"
/opt/SUNWappserver/sbin/asadmin stop-domain domain1
/opt/SUNWappserver/bin/asadmin stop-domain domain1

echo "Stopping APpserver"
/opt/SUNWappserver/sbin/asadmin stop-domain 
/opt/SUNWappserver/bin/asadmin stop-domain 

echo "Stop Messaging Server"
/opt/SUNWmsgsr/sbin/stop-msg
/opt/sun/comms/messaging/sbin/stop-msg

echo "Stop WebServer-admin"
/opt/SUNWwbsvr/https-admsevr/stop
/var/opt/SUNWwbsvr7/admin-server/bin/stopserv

echo "Stop Calendar Server"
/opt/SUNWics5/cal/sbin/stop-cal
/opt/sun/comms/calendar/SUNWics5/cal/sbin/stop-cal

echo "Stop LDAP Server Instance"
/var/opt/mps/serverroot/slapd-$host/stop-slapd
/opt/SUNWdsee/ds6/bin/dsadm stop /var/opt/SUNWdsee/dsins1/

echo "Stop LDAP Server Admin"
/var/opt/mps/serverroot/stop-admin

echo "Stopping IM Server"
/opt/SUNWiim/sbin/imadmin stop
/opt/sun/comms/im/sbin/imadmin stop

echo "Stopping mfwk agent"
/opt/SUNWmfwk/bin/mfwkadm stop

echo "Stoping cacao admin"
/usr/sbin/cacaoadm stop

echo "stoping smcwebconsole"
/usr/sbin/smcwebserver stop
