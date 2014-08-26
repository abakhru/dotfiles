#!/bin/sh

REMOVE='/bin/rpm -e --nodeps --noscripts'
PKG=`rpm -qa | egrep "SUN|sun-|imq|jdk"`
for pkg in $PKG; do
$REMOVE $pkg
echo $pkg removed.
done
echo "Killing the processes -- imq,appservd,httpd,slapd,webservd"

echo "SUNWam, entsys, jdk, SUNWps, Multiplexor, SUNWcs"

for i in `ps -eaf |grep -i imq |awk '{ print $2 }'`; do kill -9 $i; done

for i in `ps -eaf |grep -i appservd |awk '{ print $2 }'`; do kill -9 $i; done

for i in `ps -eaf |grep -i webservd |awk '{ print $2 }'`; do kill -9 $i; done

for i in `ps -eaf |grep -i entsys |awk '{ print $2 }'`; do kill -9 $i; done

for i in `ps -eaf |grep -i jdk |awk '{ print $2 }'`; do kill -9 $i; done

for i in `ps -eaf |grep -i slapd |awk '{ print $2 }'`; do kill -9 $i; done

for i in `ps -eaf |grep -i httpd |awk '{ print $2 }'`; do kill -9 $i; done

#for i in `ps -eaf |grep -i portal |awk '{ print $2 }'`; do kill -9 $i; done

#for i in `ps -eaf |grep -i identity |awk '{ print $2 }'`; do kill -9 $i; done

echo "Removing Installation Directories"
rm -rf /var/opt/sun/install/product*
rm -fr /opt/sun/*
rm -fr /var/opt/sun/*
rm -fr /etc/opt/sun/*
rm -rf /var/sun/*
rm -rf /var/sadm/prod/entsys
rm -rf /var/sadm/prod/orion
rm -rf /var/sadm/install/productregistry
rm -rf /var/sadm/install/.lockfile
rm -rf /var/sadm/install/.pkg.lock
rm -rf /usr/share/bdb/db.jar
