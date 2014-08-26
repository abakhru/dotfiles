#!/usr/bin/perl

$GENV_MSHOME1="/opt/sun/comms/messaging64";

sub LOL_SystemCall {
	my @options = @_;
	print "@options\n";
	system("@options");	
	return 1;
}

sub meter_main(){
	LOL_SystemCall("$GENV_MSHOME1/sbin/configutil -o local.metermaid.enable -v 1");
	LOL_SystemCall("$GENV_MSHOME1/sbin/configutil -o logfile.metermaid.logdir -v \"$GENV_MSHOME1/log\"");
	LOL_SystemCall("$GENV_MSHOME1/sbin/configutil -o logfile.metermaid.loglevel -v Debug");
	LOL_SystemCall("$GENV_MSHOME1/sbin/configutil -o logfile.metermaid.syslogfacility -v none");
	LOL_SystemCall("$GENV_MSHOME1/sbin/configutil -o metermaid.config.port -v 63837");
	LOL_SystemCall("$GENV_MSHOME1/sbin/configutil -o metermaid.config.secret -v password");
	LOL_SystemCall("$GENV_MSHOME1/sbin/configutil -o metermaid.config.serverhost -v 127.0.0.1");
	return;
}

sub meter_default() {
	LOL_SystemCall("$GENV_MSHOME1/sbin/configutil -o metermaid.table.default.data_type -v ipv4");
	LOL_SystemCall("$GENV_MSHOME1/sbin/configutil -o metermaid.table.default.max_entries -v 1000");
	LOL_SystemCall("$GENV_MSHOME1/sbin/configutil -o metermaid.table.default.quota -v 10");
	LOL_SystemCall("$GENV_MSHOME1/sbin/configutil -o metermaid.table.default.quota_time -v 600");
	LOL_SystemCall("$GENV_MSHOME1/sbin/configutil -o metermaid.table.default.type -v throttle");
	LOL_SystemCall("$GENV_MSHOME1/sbin/configutil -o local.service.http.showunreadcounts -v yes");
	return 1;
}

sub MSG_Refresh() {
	LOL_SystemCall("$GENV_MSHOME1/sbin/stop-msg; rm $GENV_MSHOME1/log/*; $GENV_MSHOME1/sbin/imsimta cnbuild; $GENV_MSHOME1/sbin/start-msg");
	print "\n\n==== Current Metermaid Configuration Details ====\n\n";
	LOL_SystemCall("$GENV_MSHOME1/sbin/configutil |grep metermaid");
	return 1;
}

########################
#
# Add the following line mappings file to enable metermaid:
#
# PORT_ACCESS
#
#  *|*|*|*|* $C$:A$[/opt/sun/comms/messaging/lib/check_metermaid.so,throttle,default,$3]$N421$ Connection$ declined$ at$ this$ time$E
#  *|*|*|*|*  $C$|INTERNAL_IP;$3|$Y$E
#  *  $YEXTERNAL
#
########################
sub meter_disable(){
        LOL_SystemCall("$GENV_MSHOME1/sbin/configutil -o local.metermaid.enable -d");
	@list = `$GENV_MSHOME1/sbin/configutil |grep metermaid|grep -v local`;
	foreach $config (@list){
		chomp($config);
		($field1,$field2) = split("=",$config);
		print "$GENV_MSHOME1/sbin/configutil -o $field1 -d\n";
		LOL_SystemCall("$GENV_MSHOME1/sbin/configutil -o $field1 -d");
		sleep(1);
	}
	return 1;
}

sub meter_bad_password_attempts(){
        LOL_SystemCall("$GENV_MSHOME1/sbin/configutil -o metermaid.table.bad_password_attempts.data_type -v string");
        LOL_SystemCall("$GENV_MSHOME1/sbin/configutil -o metermaid.table.bad_password_attempts.max_entries -v 1000");
        LOL_SystemCall("$GENV_MSHOME1/sbin/configutil -o metermaid.table.bad_password_attempts.options -v \"nocase,penalize\"");
        LOL_SystemCall("$GENV_MSHOME1/sbin/configutil -o metermaid.table.bad_password_attempts.type -v throttle");
        LOL_SystemCall("$GENV_MSHOME1/sbin/configutil -o metermaid.table.bad_password_attempts.quota -v 2");
        LOL_SystemCall("$GENV_MSHOME1/sbin/configutil -o metermaid.table.bad_password_attempts.quota_time -v 86400");
	return 1;
}

sub meter_slow_deliver(){
        LOL_SystemCall("$GENV_MSHOME1/sbin/configutil -o metermaid.table.slow_delivery.data_type -v string");
        LOL_SystemCall("$GENV_MSHOME1/sbin/configutil -o metermaid.table.slow_delivery.max_entries -v 2000");
        LOL_SystemCall("$GENV_MSHOME1/sbin/configutil -o metermaid.table.slow_delivery.options -v nocase");
        LOL_SystemCall("$GENV_MSHOME1/sbin/configutil -o metermaid.table.slow_delivery.type -v throttle ");
        LOL_SystemCall("$GENV_MSHOME1/sbin/configutil -o metermaid.table.slow_delivery.quota -v 2");
        LOL_SystemCall("$GENV_MSHOME1/sbin/configutil -o metermaid.table.slow_delivery.quota_time -v 3600");
	return 1;
}

sub meter_bad_user_attempts(){
        LOL_SystemCall("$GENV_MSHOME1/sbin/configutil -o metermaid.table.bad_user_attempts.data_type -v ipv4");
        LOL_SystemCall("$GENV_MSHOME1/sbin/configutil -o metermaid.table.bad_user_attempts.max_entries -v 1000");
        LOL_SystemCall("$GENV_MSHOME1/sbin/configutil -o metermaid.table.bad_user_attempts.options -v penalize");
        LOL_SystemCall("$GENV_MSHOME1/sbin/configutil -o metermaid.table.bad_user_attempts.type -v throttle ");
        LOL_SystemCall("$GENV_MSHOME1/sbin/configutil -o metermaid.table.bad_user_attempts.quota -v 2");
        LOL_SystemCall("$GENV_MSHOME1/sbin/configutil -o metermaid.table.bad_user_attempts.quota_time -v 86400");
	return 1;
}

sub meter_sends_to_bogus_recipients(){
        LOL_SystemCall("$GENV_MSHOME1/sbin/configutil -o metermaid.table.sends_to_bogus_recipients.data_type -v string"); 
        LOL_SystemCall("$GENV_MSHOME1/sbin/configutil -o metermaid.table.sends_to_bogus_recipients.max_entries -v 5000"); 
        LOL_SystemCall("$GENV_MSHOME1/sbin/configutil -o metermaid.table.sends_to_bogus_recipients.options -v \"nocase,penalize\"");
        LOL_SystemCall("$GENV_MSHOME1/sbin/configutil -o metermaid.table.sends_to_bogus_recipients.type -v throttle");
        LOL_SystemCall("$GENV_MSHOME1/sbin/configutil -o metermaid.table.sends_to_bogus_recipients.quota -v 5");
        LOL_SystemCall("$GENV_MSHOME1/sbin/configutil -o metermaid.table.sends_to_bogus_recipients.quota_time -v 86400");
	return 1;
}

sub meter_greylisting(){
        LOL_SystemCall("$GENV_MSHOME1/sbin/configutil -o metermaid.table.greylisting.type -v greylisting");
        LOL_SystemCall("$GENV_MSHOME1/sbin/configutil -o metermaid.table.greylisting.data_type -v string");
        LOL_SystemCall("$GENV_MSHOME1/sbin/configutil -o metermaid.table.greylisting.block_time -v pt5s");
        LOL_SystemCall("$GENV_MSHOME1/sbin/configutil -o metermaid.table.greylisting.resubmit_time -v pt30s");
        LOL_SystemCall("$GENV_MSHOME1/sbin/configutil -o metermaid.table.greylisting.inactivity_time -v pt1m");
	return 1;
}

sub execute(){

	if($ARGV[0] eq "enable"){
		meter_main();
#		meter_default();
#		meter_bad_password_attempts();
#		meter_slow_deliver();
#		meter_bad_user_attempts();
#		meter_sends_to_bogus_recipients();
		meter_greylisting();
	}
	elsif("$ARGV[0]" eq "disable"){
		meter_disable();
	}
	MSG_Refresh();
}

execute();
