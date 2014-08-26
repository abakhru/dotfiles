echo "Executing on usg53"
/opt/SUNWiim/sbin/imadmin $1

echo "Executing on usg61"
rsh usg61.india.sun.com nohup /opt/SUNWiim/sbin/imadmin $1

echo "Executing on usg60"
rsh usg60.india.sun.com nohup /opt/SUNWiim/sbin/imadmin $1

#echo "Executing on nicp103"
#rsh nicp103.india.sun.com nohup /opt/SUNWiim/sbin/imadmin $1

a=$1;
b="stop";
if [ $a = $b ];then
rsh usg61.india.sun.com rm /var/opt/SUNWiim/default/log/*
rsh usg60.india.sun.com rm /var/opt/SUNWiim/default/log/*
rsh usg53.india.sun.com rm /var/opt/SUNWiim/default/log/*
#rsh nicp103.india.sun.com rm /var/opt/SUNWiim/default/log/*
echo "Log files deleted"
else
exit 0
fi
