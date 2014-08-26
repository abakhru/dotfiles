#!/usr/bin/perl
use Net::LDAP;
use Net::LDAP::LDIF;

$GENV_MSHOME1="/opt/sun/comms/messaging64";
system("echo password > /tmp/.pwd.txt");

#system("/opt/sun/dsee7/bin/dsadm create -D\"cn=directory manager\" /var/opt/SUNWdsee/dsins1/");
$compat_mode = `/opt/sun/dsee7/bin/dsconf get-server-prop -c -w /tmp/.pwd.txt pwd-compat-mode`;
print "$compat_mode\n";
if("$compat_mode" =~ /DS5/){
	system("/opt/sun/dsee7/bin/dsconf pwd-compat -h bakhru.us.oracle.com -p 389 -w /tmp/.pwd.txt -a to-DS6-migration-mode");
	system("/opt/sun/dsee7/bin/dsconf pwd-compat -h bakhru.us.oracle.com -p 389 -w /tmp/.pwd.txt -a to-DS6-mode");
}

#metermaid configuration and setup
#system("$GENV_MSHOME1/sbin/configutil -o local.metermaid.enable -v 1");
#system("$GENV_MSHOME1/sbin/configutil -o logfile.metermaid.logdir -v $GENV_MSHOME1/log");
#system("$GENV_MSHOME1/sbin/configutil -o logfile.metermaid.loglevel -v Debug");
#system("$GENV_MSHOME1/sbin/configutil -o logfile.metermaid.syslogfacility -v none");
#system("$GENV_MSHOME1/sbin/configutil -o metermaid.config.port -v 63837");
#system("$GENV_MSHOME1/sbin/configutil -o metermaid.config.secret -v password");
#system("$GENV_MSHOME1/sbin/configutil -o metermaid.config.serverhost -v 127.0.0.1");
#system("$GENV_MSHOME1/sbin/configutil -o local.imap.pwexpirealert.viametermaid -v 1");
#system("$GENV_MSHOME1/sbin/configutil -o metermaid.table.pwexpirealert.data_type -v string");
#system("$GENV_MSHOME1/sbin/configutil -o metermaid.table.pwexpirealert.quota -v 1");
#system("$GENV_MSHOME1/sbin/configutil -o metermaid.table.pwexpirealert.quota_time -v 86400");
##logging enable
#system ("$GENV_MSHOME1/sbin/configutil -o local.debugkeys -v \"metermaid connect ldap lpool certmap\"");
#
#To get all the ds-server password related policies
#system("/opt/sun/dsee7/bin/dsconf get-server-prop -i -w /tmp/.pwd.txt |grep pwd");

#To set the ds-server password expiration policies
#system("/opt/sun/dsee7/bin/dsconf set-server-prop -v -e -w /tmp/.pwd.txt pwd-max-age:5w");
#system("/opt/sun/dsee7/bin/dsconf set-server-prop -v -e -w /tmp/.pwd.txt pwd-min-age:3w");
#system("/opt/sun/dsee7/bin/dsconf set-server-prop -v -e -w /tmp/.pwd.txt pwd-expire-warning-delay:5d");
#system("/opt/sun/dsee7/bin/dsconf set-server-prop -v -e -w /tmp/.pwd.txt pwd-expire-no-warning-enabled:off");
#system("/opt/sun/dsee7/bin/dsconf set-server-prop -v -e -w /tmp/.pwd.txt pwd-storage-scheme:CLEAR");
#system("/opt/sun/dsee7/bin/dsconf set-server-prop -v -e -w /tmp/.pwd.txt pwd-must-change-enabled:on");

#system("/opt/sun/dsee7/bin/dsconf get-server-prop -i -w /tmp/.pwd.txt |grep pwd");
#To check the any user's pwdChangedTime
#$user = $ARGV[0];
#system("/opt/sun/dsee7/dsrk/bin/ldapsearch -D\"cn=directory manager\" -w password -b \"uid=$user,ou=people,o=us.oracle.com,o=usergroup\" objectclass=* pwdChangedTime pwdreset");
#/opt/sun/dsee7/dsrk/bin/ldapsearch -D"cn=directory manager" -w password -b "uid=neo1,ou=people,o=us.oracle.com,o=usergroup" objectclass=* pwdChangedTime pwdreset
