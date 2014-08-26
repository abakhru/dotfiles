#!/usr/bin/perl
$GENV_MSHOME1="/opt/sun/comms/messaging64";
chomp($check_ms_status = `netstat -na|grep 143|grep LISTEN`);
if ( $check_ms_status eq "" ) {
        print "MS Server is not running\n";
	system("$GENV_MSHOME1/sbin/start-msg");
}
system("$GENV_MSHOME1/sbin/mboxutil -d -P \'\\S*\'");
#LOL_SystemCall("$GENV_MSHOME1/sbin/mboxutil -d -P \'\\S*\'");
system("$GENV_MSHOME1/sbin/stop-msg");
system("rm -rf $GENV_MSHOME1/log/*");
@list = `ls /var/$GENV_MSHOME1/queue/`;
foreach $LIST (@list){
	chomp($LIST);
	system("rm -rf $LIST/*");
}
system("$GENV_MSHOME1/sbin/start-msg");
