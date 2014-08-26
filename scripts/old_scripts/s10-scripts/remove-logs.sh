echo "Removing WebServer Log Files" 
rm -rf /var/opt/SUNWwbsvr7/https-`hostname`.red.iplanet.com/logs/*
rm -rf /opt/SUNWwbsvr/https-`hostname`.india.sun.com/logs/*
rm -rf /opt/SUNWappserver/appserver/domains/domain1/logs/*

echo "Removing IS Server Log Files"
rm -rf /var/opt/SUNWam/logs/*
rm -rf /var/opt/SUNWam/debug/*

echo "Removing Messaging Server Log Files"
rm -rf /var/opt/SUNWmsgsr/log/*
rm -rf /var/opt/sun/comms/messaging/log/*

echo "Removing Calendar Server Log Files"
rm -rf /var/opt/SUNWics5/logs/*
rm -rf /var/opt/sun/comms/calendar/SUNWics5/logs/*

echo "Removing LDAP Log Files"
#rm -rf /var/opt/mps/serverroot/slapd-`hostname`/logs/*
rm -rf /var/opt/SUNWdsee/dsins1/logs/*

echo "Removing IM Log Files"
rm -rf /var/opt/SUNWiim/default/log/*.log
rm -rf /var/opt/sun/comms/im/default/log/*.log

echo "Removing IWC Log Files"
rm -rf /var/opt/SUNWiwc/logs/*
rm -rf /var/opt/sun/comms/iwc/logs/*

echo "Removing MFWK Log Files"
rm -rf /var/opt/SUNWmfwk/logs/*

echo "Removing CE Log Files"
rm -rf /var/opt/SUNWuwc/logs/*
rm -rf /var/opt/sun/comms/ce/logs/*
