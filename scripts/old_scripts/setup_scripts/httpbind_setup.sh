#!/bin/bash
# To deploy a testhttpbind web-app in webserver this requires webserver to be pre-installed.
#/opt/SUNWiim/configure -silent -nodisplay -state IM_Configure_statefile

#cd /etc/opt/SUNWiim/

# Creating a seconf instance of IM-Server for Testing
cp -R ./default/ ./server2/
#cp -R /var/opt/SUNWiim/default/ /var/opt/SUNWiim/server2/
#rm -rf /var/opt/SUNWiim/server2/db/*
#rm -rf /var/opt/SUNWiim/server2/log/*
cd ./server2/config

# Editing the httpbind.conf file for configuring httpbind
sed "s/5222:5222/`hostname`.india.sun.com:5222/" httpbind.conf >httpbind.conf.bk
sed "s/componentjid=/componentjid=`hostname`./" httpbind.conf.bk >httpbind.conf
sed 's/changeit/netscape/' httpbind.conf >httpbind.conf.bk
sed '/log4j/ s/default/server2/' httpbind.conf.bk > httpbind.conf
#mv httpbind.conf.bk httpbind.conf
sed 's/default/server2/' ../imadmin > ../imadmin.bk; mv ../imadmin.bk ../imadmin

# Enabling the DEBUG logs for httpbind
sed 's/ERROR/DEBUG/' httpbind_log4j.conf > httpbind_log4j.conf.bk; mv httpbind_log4j.conf.bk httpbind_log4j.conf

# Editing the iim.conf to setup httpbind
sed '/httpbind.enable/ s/false/true/' iim.conf > iim.conf.bk
sed "/httpbind.jid/ s/=/=`hostname`.httpbind.india.sun.com/" iim.conf.bk > iim.conf
sed '/httpbind.password/ s/=/=netscape/' iim.conf > iim.conf.bk; mv iim.conf.bk iim.conf
sed '/instancedir/ s/default/server2/' iim.conf > iim.conf.bk
sed '/instancevardir/ s/default/server2/' iim.conf.bk > iim.conf
