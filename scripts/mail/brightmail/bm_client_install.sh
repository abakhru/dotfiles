#!`which bash`
cd /opt/brightmail

#If Brightmail server installation directory exists
if [ -d /opt/brightmail/SBMF_610 ] ; then
	echo "Brightmail Scanner Client already installed...exiting!!"
	exit;
fi

#Copy the installer
if [ "`uname -p`" == "sparc" ] ; then
        bash -x ./scp_bmi_client.sh /export/brightmail/Symantec_Brightmail_Message_Filter_610_sparc_solaris.tar
fi
if [ "`uname`" == "Linux" ] ; then
        bash -x ./scp_bmi_client.sh /export/brightmail/Symantec_Brightmail_Message_Filter_610_x86_linux.tgz
fi
if [ "`uname -p`" == "i386" ] ; then
	echo "Solaris x86 platform not supported by Brightmail"
	exit;
fi

# Download the platform specific BMI installer file.
tar xvf Symantec*
mkdir -p /opt/symantec/sbas/Scanner/
groupadd bmi
groupadd mysql
useradd -c "MySQL user" -g mysql mysql
useradd -c "dummy user for Brightmail" -d /opt/symantec/sbas/Scanner -m -g bmi mailwall
passwd -d mailwall
cp ./install_bmi.sh /opt/brightmail/SBMF_610/
cd /opt/brightmail/SBMF_610/
./install_bmi.sh
#Chose BMI Scanner and then Install only the Bmi Client,Control Center and BMI server is available at this IP address 10.5.195.174
# Now add the /opt/symantec/sbas/Scanner/lib to the LD_LIBRARY_PATH
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/opt/symantec/sbas/Scanner/lib:.
/opt/symantec/sbas/Scanner/sbin/runner /opt/symantec/sbas/Scanner/etc/runner.cfg
