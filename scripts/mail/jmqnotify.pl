#!/usr/bin/perl

if (@ARGV < 1)
{
	print ("\nUsage: jmqnotify.pl [enable|disable]\n\n");
	exit;
}
my $option=$ARGV[0];
my $msgdir="/opt/sun/comms/messaging64/";

if ($option eq "disable") {
	print "Disabling jmqnotify configuration\n";
          system("$msgdir/sbin/configutil -o local.store.notifyplugin -d");
          system("$msgdir/sbin/configutil -o local.store.notifyplugin.jmqnotify.annotatemsg.enable -d");
          system("$msgdir/sbin/configutil -o local.store.notifyplugin.jmqnotify.changeflag.enable -d");
          system("$msgdir/sbin/configutil -o local.store.notifyplugin.jmqnotify.copymsg.enable -d");
          system("$msgdir/sbin/configutil -o local.store.notifyplugin.jmqnotify.debuglevel -d");
          system("$msgdir/sbin/configutil -o local.store.notifyplugin.jmqnotify.deletemsg.enable -d");
          system("$msgdir/sbin/configutil -o local.store.notifyplugin.jmqnotify.destinationtype -d");
          system("$msgdir/sbin/configutil -o local.store.notifyplugin.jmqnotify.enable -d");
          system("$msgdir/sbin/configutil -o local.store.notifyplugin.jmqnotify.expungemsg.enable -d");
          system("$msgdir/sbin/configutil -o local.store.notifyplugin.jmqnotify.jmqhost -d");
          system("$msgdir/sbin/configutil -o local.store.notifyplugin.jmqnotify.jmqport -d");
          system("$msgdir/sbin/configutil -o local.store.notifyplugin.jmqnotify.jmqpwd -d");
          system("$msgdir/sbin/configutil -o local.store.notifyplugin.jmqnotify.jmqqueue -d");
          system("$msgdir/sbin/configutil -o local.store.notifyplugin.jmqnotify.jmqtopic -d");
          system("$msgdir/sbin/configutil -o local.store.notifyplugin.jmqnotify.jmquser -d");
          system("$msgdir/sbin/configutil -o local.store.notifyplugin.jmqnotify.loguser.enable -d");
          system("$msgdir/sbin/configutil -o local.store.notifyplugin.jmqnotify.maxheadersize -d");
          system("$msgdir/sbin/configutil -o local.store.notifyplugin.jmqnotify.msgflags.enable -d");
          system("$msgdir/sbin/configutil -o local.store.notifyplugin.jmqnotify.msgtypes.enable -d");
          system("$msgdir/sbin/configutil -o local.store.notifyplugin.jmqnotify.newmsg.enable -d");
          system("$msgdir/sbin/configutil -o local.store.notifyplugin.jmqnotify.noneinbox.enable -d");
          system("$msgdir/sbin/configutil -o local.store.notifyplugin.jmqnotify.persistent -d");
          system("$msgdir/sbin/configutil -o local.store.notifyplugin.jmqnotify.priority -d");
          system("$msgdir/sbin/configutil -o local.store.notifyplugin.jmqnotify.purgemsg.enable -d");
          system("$msgdir/sbin/configutil -o local.store.notifyplugin.jmqnotify.readmsg.enable -d");
          system("$msgdir/sbin/configutil -o local.store.notifyplugin.jmqnotify.ttl -d");
          system("$msgdir/sbin/configutil -o local.store.notifyplugin.jmqnotify.updatemsg.enable -d");
          system("$msgdir/sbin/configutil -o local.store.notifyplugin.msgflags -d");
}

if($option eq "enable") {
          system("$msgdir/sbin/configutil -o store.maxcachefilesize -v 1048576");
          system("$msgdir/sbin/configutil -o local.store.notifyplugin -v \"lib/libjmqnotify\\\$jmqnotify\"");
          system("$msgdir/sbin/configutil -o local.store.notifyplugin.msgflags -v 1");
          system("$msgdir/sbin/configutil -o local.store.notifyplugin.index.maxheadersize -v 16384");
          system("$msgdir/sbin/configutil -o local.store.notifyplugin.jmqnotify.annotatemsg.enable -v 1");
          system("$msgdir/sbin/configutil -o local.store.notifyplugin.jmqnotify.changeflag.enable -v 1");
          system("$msgdir/sbin/configutil -o local.store.notifyplugin.jmqnotify.debuglevel -v 1");
          system("$msgdir/sbin/configutil -o local.store.notifyplugin.jmqnotify.deletemsg.enable -v 1");
          system("$msgdir/sbin/configutil -o local.store.notifyplugin.jmqnotify.destinationtype -v topic");
          system("$msgdir/sbin/configutil -o local.store.notifyplugin.jmqnotify.enable -v 1");
          system("$msgdir/sbin/configutil -o local.store.notifyplugin.jmqnotify.expungemsg.enable -v 1");
          system("$msgdir/sbin/configutil -o local.store.notifyplugin.jmqnotify.jmqhost -v 127.0.0.1");
          system("$msgdir/sbin/configutil -o local.store.notifyplugin.jmqnotify.jmqport -v 7676");
          system("$msgdir/sbin/configutil -o local.store.notifyplugin.jmqnotify.jmqpwd -v guest");
          system("$msgdir/sbin/configutil -o local.store.notifyplugin.jmqnotify.jmqqueue -v jesms");
          system("$msgdir/sbin/configutil -o local.store.notifyplugin.jmqnotify.jmqtopic -v JES-MS");
          system("$msgdir/sbin/configutil -o local.store.notifyplugin.jmqnotify.jmquser -v guest");
          system("$msgdir/sbin/configutil -o local.store.notifyplugin.jmqnotify.loguser.enable -v 1");
          system("$msgdir/sbin/configutil -o local.store.notifyplugin.jmqnotify.maxheadersize -v 1024");
          system("$msgdir/sbin/configutil -o local.store.notifyplugin.jmqnotify.msgflags.enable -v 1");
          system("$msgdir/sbin/configutil -o local.store.notifyplugin.jmqnotify.msgtypes.enable -v 1");
          system("$msgdir/sbin/configutil -o local.store.notifyplugin.jmqnotify.newmsg.enable -v 1");
          system("$msgdir/sbin/configutil -o local.store.notifyplugin.jmqnotify.noneinbox.enable -v 1");
          system("$msgdir/sbin/configutil -o local.store.notifyplugin.jmqnotify.copymsg.enable -v 0");
          system("$msgdir/sbin/configutil -o local.store.notifyplugin.jmqnotify.persistent -v 1");
          system("$msgdir/sbin/configutil -o local.store.notifyplugin.jmqnotify.priority -v 3");
          system("$msgdir/sbin/configutil -o local.store.notifyplugin.jmqnotify.purgemsg.enable -v 1");
          system("$msgdir/sbin/configutil -o local.store.notifyplugin.jmqnotify.readmsg.enable -v 1");
          system("$msgdir/sbin/configutil -o local.store.notifyplugin.jmqnotify.ttl -v 1000");
          system("$msgdir/sbin/configutil -o local.store.notifyplugin.jmqnotify.updatemsg.enable -v 1");
}

################### README ###################
###################Configuring JMQ notifications in mail-server #########################

#Configure JMQ:

#Install all the packages required for JMQ to work properly, namely:
#SUNWiqr, SUNWiquc, SUNWiqu, SUNWiqlpl, SUNWiqdoc, SUNWiqum, SUNWiqjx, SUNWiqfs, SUNWiqcrt, SUNWiqcdv, SUNWiqlen
#Edit JMQ configuration files to enable autostart (/etc/imq/imqbrokerd.conf in solaris and /etc/opt/sun/mq/imqbrokerd.conf)
#Edit the line "AUTOSTART=NO" to "AUTOSTART=YES"
#stop/start the JMQ Broker Daemon?
#"/etc/init.d/imq start" to start "/etc/init.d/imq stop" to stop the JMQ broker daemon
#Add/delete JMQ Client user:
#Run "/usr/bin/imqusermgr add -u guest -p guest" to add the user "guest" and run "/usr/bin/imqusermgr delete -u guest -f" to remove the user
#To receive the notification:
#/opt/SUNWmsgsr/sbin/jmqclient -t ako1 -u guest -w guest
#Configure the user for which to recieve JMQ notifications
#
#add the following to a user( say algy60) using ldapsh or ldapmodify
#maileventnotificationdestination: ako1
#Configure the messaging server
#
#Add the following to the options.dat file:
#!
#! Configurations for JMQ notification testing
#!
#LDAP_SPARE_1=mailEventNotificationDestination
#SPARE_1_SEPARATOR=259
#Now when you receive new message/read/trash/move/send message a JMQ notification will be generated, which will be used by MISO server for indexing services.
#Here is an example:
#/opt/sun/comms/messaging64/examples/jmqsdk/jmqclient -t ako1
#message is not persistent
#Event type=NewMsg
#       timestamp=Mon Mar  2 15:38:49 2009
#        hostname=algy.red.iplanet.com
#        process=ims_master
#        pid=9151
#        ctx=0
#        mailboxName=algy60
#        uidValidity=1235687026
#        imapUID=22
#        internaldate=Mon Mar  2 15:38:49 2009
#        size=1455
#        hdrLen=607
#        numMsgs=2954784
#        modseq_sec=73697929
#        modseq_usec=890347
#message is not persistent
#Event type=ReadMsg
#        timestamp=Mon Mar  2 15:39:27 2009
#        hostname=algy.red.iplanet.com
#        process=imapd
#        pid=9070
#        mailboxName=algy60
#        userid=algy60
#                owner
#        uidValidity=1235687026
#        numMsgs=21
#        numSeen=7
#        numDeleted=0
#        numSeenDeleted=2
#message is not persistent
#Event type=TrashMsg
#        timestamp=Mon Mar  2 15:39:37 2009
#        hostname=algy.red.iplanet.com
#        process=imapd
#        pid=9070
#        mailboxName=algy60
#        userid=algy60
#                owner
#        uidValidity=1235687026
#        numMsgs=21
#        numSeen=7
#        numDeleted=0
#        numSeenDeleted=3
