#!/bin/sh
if [ $# -ne 1 ]
then
echo "Usage: $0 <IM packages zip file location>"
echo "Eg: $0 /share/builds/products/IM/im8/ships/20081205_rr.2/monks_SunOS5.9/im-8.0-00.06-20081204-SunOS-sparc-packages.zip"
exit 0
fi

PWD=`pwd`

mkdir -p /tmp/t
cd /tmp/t
unzip $1 -d /tmp/t

ADMIN=/tmp/rm_pkgadmin
echo "action=nocheck" > $ADMIN
echo "idepend=nocheck" >> $ADMIN
echo "rdepend=nocheck" >> $ADMIN
echo "space=nocheck" >> $ADMIN
echo "mail=" >> $ADMIN
#LIST="SUNWiimdv SUNWiim SUNWiimc SUNWiimd SUNWiimid SUNWiimin SUNWiimm SUNWiimjd"
LIST=` pkginfo |grep SUNWiim|cut -f2 -d" "`

echo "Removing All Instant Messaging Packages ......."

echo "Stoping IM services"
/opt/SUNWiim/sbin/imadmin stop

for i in $LIST
do
pkgrm -A -n -a $ADMIN $i
done

echo "All Instant Messaging Packages removed"

echo "

Adding All Instant Messaging Packages ......."
cd $1 

for i in *
do
pkgadd -a $ADMIN -d . $i
done

cd $PWD

echo "
All Instant Messaging Packages added successfully


All Instant Messaging Packaglist with PSTAMP is printed below"

for i in $LIST
do
echo "$i :`pkginfo -l $i|grep PSTAMP`"
done

echo "

Starting IM services"
/opt/SUNWiim/sbin/imadmin start
