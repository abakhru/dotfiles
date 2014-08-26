#!/bin/sh

set -x

BACKUP_DIR=/rm_logs_backup

if [ "$#" -eq 0 ]; then
        echo "usage :"
	echo "-p : generate pkg list dynamically to remove"
	echo "     All Product pkgs, NO Common Components"
        echo "-s : generate pkg list dynamically to remove"
	echo "     All Product pkgs + Common Components"
        echo "-h : get the static pkg list to remove pkgs - fast"
        exit 0;
fi

# Get the PIDs of the running processes
AS_PID=`ps -eaf | grep appserv | awk '{print $2}'`
WS_PID=`ps -eaf | grep webs | awk '{print $2}'`
DS_PID=`ps -eaf | grep slapd | awk '{print $2}'`
ADMINSERV_PID=`ps -eaf | grep uxwdog | awk '{print $2}'`
ADMINSERV_PID=`ps -eaf | grep admin-serv | awk '{print $2}'`
IMQ_PID=`ps -eaf | grep imq | awk '{print $2}'`
PIDS="$AS_PID $WS_PID $DS_PID $ADMINSERV_PID $IMQ_PID"

# Kill all running processes
kill -9 $PIDS

removeShared=$1

packageCleaning() {
	if [ "${removeShared}" = "-h" ]; then
	    getHardCodedList
	else
	    getAutoGeneratedList
	fi

	exit 0
}

directoryCleaning() {

        mkdir ${BACKUP_DIR}

        #tar cf /tmp/opt.$$.tar /opt/SUNW*
        #tar cf /tmp/var.opt.$$.tar /var/opt/*
        #tar cf /tmp/etc.opt.$$.tar /etc/opt/*
        tar cf ${BACKUP_DIR}/var.sadm.prod.entsys.$$.tar /var/sadm/prod/entsys/*        tar cf ${BACKUP_DIR}/usr.sunone.$$.tar /usr/sunone/*
        tar cf ${BACKUP_DIR}/var.sadm.install.productregistry.$$.tar /var/sadm/install/productregistry
        tar cf ${BACKUP_DIR}/var.sadm.install.logs.$$.tar /var/sadm/install/logs/*

        rm -rf /var/opt/*
        rm -rf /opt/SUNW*
        rm -rf /etc/opt/*
        rm -rf /var/sadm/prod/entsys
        rm -rf /usr/sunone/*
	rm -rf /etc/ds/v5.2

        rm -f /var/sadm/install/productregistry
        rm -f /var/sadm/install/logs/Administration_Server*
        rm -f /var/sadm/install/logs/Directory_Server*
        rm -f /var/sadm/install/logs/Java_Enterprise_System*
        rm -f /var/sadm/install/logs/SUNW*
	
	for pkgName in SUNWics5 SUNWamsws SUNWscfab SUNWpscfab SUNWscref SUNWpscref SUNWschw SUNWpschw; do

            rm -rf /var/sadm/pkg/${pkgName}/\!R-Lock\! /var/sadm/pkg/${pkgName}/install/postremove /var/sadm/pkg/${pkgName}/install/preremove
 
	done

#	/usr/sbin/mpsadmserver unconfigure > ./temp
#        /usr/sbin/directoryserver unconfigure > ./temp

	rm -f ./temp
}

getAutoGeneratedList() {

	processor=`uname -p`
	suffix="sparc"

	if [ "${processor}" = "i386" ]; then
    	    suffix="x86"
	fi

	#PP="/net/installzone.eng/export/install/jes/orion3/pointproducts/Solaris_${suffix}/Product"

	 PP="/net/sunjump/o3/nightly/x86/Solaris_x86/Product"
	packages=`find ${PP} -name "SUNW*"|grep -v SUNWjhrt`
	for pkg in $packages; do
    	    location=`dirname $pkg`
    	    reloc_check=`echo ${location} | grep "reloc"`
	    name=`basename $pkg`

	    if [ "${removeShared}" = "-s" ]; then
		shared_check=`echo ${name} | egrep "SUNWpl5u|SUNWpl5v|SUNWpl5p|SUNWpl5m"`
	    else
	        shared_check=`echo ${location} | grep "shared_components"`
	    fi

    	    if [ ! -z "${reloc_check}" ] || [ ! -z "${shared_check}" ]; then
        	continue
	    else
            	/usr/sbin/pkgrm -n -a /net/installzone/export/install/jes/tools/admin.txt $name
            fi
	done
}

getHardCodedList() {
        
   	#for pack in `cat  $0| grep "\-\-" | cut -c3-23`
	for pack in `cat /smoketest/utils/pkgListSunOS.txt`
        do
            /usr/sbin/pkgrm -n -a /net/installzone.eng/export/install/jes/tools/admin.txt $pack
        done
}

directoryCleaning
packageCleaning


# Package List Data
--SUNWdsc
--SUNWdscshl
--SUNWdscssv
--SUNWdscvw
--SUNWawbsvr
--SUNWcwbsvr
