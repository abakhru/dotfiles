#ldapsearch -D"cn=directory manager" -w password -b dc=sfbay,dc=sun,dc=com "uid=msg*"
msg_pkg=`pkginfo |grep SUNWmessaging |cut -f2 -d" "`
msg_dir=`pkginfo -l $msg_pkg|grep BASEDIR |cut -f2 -d":"`
cd $msg_dir/config
cp /space/amit/scripts/mail/config/*ce.cfg .
for i in `\ls *yAService.cfg |cut -f1 -d"."`;
do
sed -e 's/default:BindDN/#default:BindDN/' $i.cfg > t
grep "default:BindDN" $i-def.cfg >> t
mv t $i.cfg
done
chown mailuser:mailgrp *
