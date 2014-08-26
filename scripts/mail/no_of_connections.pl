#!/usr/bin/perl
use Net::Domain qw(hostname hostfqdn hostdomain);

$debug=0;
$no_of_users=$ARGV[0];
$GENV_MSHOST1=hostname();
$GENV_MSHOME1="/opt/sun/comms/messaging64";
#$GENV_HOTFIXLOC="/net/comms-nfs.us.oracle.com/export/megan/wspace/ab155742/common_files";
$GENV_HOTFIXLOC="/tmp";

chomp($GENV_IP=`nslookup $GENV_MSHOST1|grep Address|tail -1|awk '{print \$2}'`);
print "==== GENV_IP = $GENV_IP ====\n";

if( -e "$GENV_MSHOME1/config/imta.cnf"){
	$filename="$GENV_MSHOME1/config/imta.cnf";
}
elsif( -e "$GENV_MSHOME1/config/config.xml"){
	$filename="$GENV_MSHOME1/config/config.xml";
}
my $uid=(stat $filename) [4];
my $GENV_MAILADMINUSER=(getpwuid $uid) [0];
print "==== GENV_MAILADMINUSER = $GENV_MAILADMINUSER\n" if($debug);

my $iterations=($no_of_users/3);
system("pkill -9 prstat");
system("echo > $GENV_HOTFIXLOC/imap_conn_count");
system("echo > $GENV_HOTFIXLOC/statsfile");

for (my $i=0;$i<$iterations;$i++){
	print "netstat -na | grep $GENV_IP.143 | grep ESTAB | awk \'{print \$NF}\' | sort | uniq -c >> $GENV_HOTFIXLOC/imap_conn_count\n" if($debug);
	system("netstat -na | grep $GENV_IP.143 | grep ESTAB | awk \'{print \$NF}\' | sort | uniq -c >> $GENV_HOTFIXLOC/imap_conn_count");
	print "prstat -u $GENV_MAILADMINUSER 1 1 | grep imap >> $GENV_HOTFIXLOC/statsfile\n" if($debug);
	system("prstat -u $GENV_MAILADMINUSER 1 1 | grep imap >> $GENV_HOTFIXLOC/statsfile");
	sleep(1);
}
