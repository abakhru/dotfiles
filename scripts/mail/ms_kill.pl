#!/usr/bin/perl
use Socket;     #defines PF_INET and SOCK_STREAM

$GENV_MSHOME1="/opt/sun/comms/messaging64";
sub MSG_Refresh()
{
	@msprocess = `ps -ef|grep messaging64|grep -v grep`;
	#$watcher_pid = `ps -ef|grep watcher|grep -v grep`;
#	push(@process, $watcher_pid);
	print "Process			 : PID\n";
	print "===============================\n";
	foreach $process (@msprocess) {
		my @a = split("\ ", $process);
		my @b = split("\/lib\/", $a[7]);
		if(("$b[1]" =~ /enpd/) || ("$b[1]" =~ /stored/) ||
		   ("$b[1]" =~ /im/) || ("$b[1]" =~ /popd/) ||
		   ("$b[1]" =~ /imapd/) || ("$b[1]" =~ /ms/) ||
		   ("$b[1]" =~ /watcher/) || ("$b[1]" =~ /impurge/)){
			print "$b[1]			 :$a[1]\n";
		}elsif("$b[1]" =~ /tcp_smtp/){
			print "$b[1]		 :$a[1]\n";
		}else{
			print "$b[1]		 :$a[1]\n";
		}
		#print ("kill -9 $a[1]\n");
		system("kill -9 $a[1]");
	}
	#system("ps -ef|grep messaging64");
}

MSG_Refresh();
