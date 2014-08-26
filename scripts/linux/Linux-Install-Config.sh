#!/bin/sh
/var/opt/sun/directory-server/slapd-$1/start-slapd
/var/opt/sun/directory-server/start-admin
/opt/sun/comms/dssetup/sbin/comm_dssetup.pl
/opt/sun/messaging/sbin/configure
/opt/sun/messaging/sbin/start-msg
/opt/sun/calender/sbin/csconfigurator.sh
/opt/sun/calender/sbin/start-cal
/opt/sun/webserver/https-$1.india.sun.com/start

/opt/sun/comms/commcli/sbin/config-commda
/opt/sun/uwc/sbin/config-uwc
/opt/sun/webserver/https-$1.india.sun.com/stop
/opt/sun/webserver/https-$1.india.sun.com/start
/opt/sun/im/configure
/opt/sun/webserver/https-admserv/start
/opt/sun/webserver/https-$1.india.sun.com/stop
/opt/sun/webserver/https-$1.India.Sun.COM/stop
/opt/sun/webserver/https-$1.India.Sun.COM/start
/opt/sun/webserver/https-$1.india.sun.com/start
/opt/sun/im/sbin/imadmin refresh
