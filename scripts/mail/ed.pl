#!/usr/bin/perl
#use threads;
#use threads::shared;
use Net::IMAP;
use LWP::UserAgent;
use Net::Cmd;
use Net::SMTP;
#use Net::SMTP_auth;
use Net::POP3;
#use Net::POP3_auth;
use Mail::IMAPClient;
#use Proc::ProcessTable;

$USERS=$ARGV[0];
print "Num users specified: $USERS\n";
if ( $USERS == "" ) {
   print "Usage:  mini_autostress.pl num-users-to-run-stress-with\n";
   exit(0);
}
$numiterations=$ARGV[1];
print "Num iterations specified: $numiterations\n";
if ( $numiterations == "" ) { $numiterations = 1 };
#system("./run.pl adduser neo $USERS");
#system("./clean_store.pl");
$GENV_MSHOST1="ednlina";
$GENV_DOMAIN="pacbell.net";
#$debug=1;
$debug=0;
my $useri = 0;

sub GetSid {
        my $raw= shift;
        unless ( $raw =~ /sid=/ ) {
                return 0;
        }
        $raw = $';
        $raw =~ /&/;
        return $`;
}

sub imap_autostress
{
#	my ($no_of_users) = @_;
	my @imap = "";
# need to calculate what user to login as
	my $range = 500;
	my $mmpORimap=2;
	$useri=int(rand($range))+1;
	if ($user1 == 0) { $user1 = 1; }
	if ($user1 == 501) { $user1 = 500; }
#	for(my $i=1;$i<=$no_of_users;$i++){
	$username="user$useri\@stresstest.com";
	#print "logging in as $useri\n";
	print "logging in as $username\n";
# randomly use imap or mmp/imap
		$usewhat=int(rand($mmpORimap));		
#		print "use imap: 0 use mmp: 1 : value $usewhat\n";
		if ( $usewhat == 0 ) { 
		  $useport=143;
		} else {
		  $useport=1143;
	 	}
		$imap[$i] = Mail::IMAPClient->new(Server => "$GENV_MSHOST1.$GENV_DOMAIN",Port => $useport, Debug => $debug, User => "$username", Password => "password");
		$imap[$i]->select("INBOX");
		#print $imap[$i]->Results();
		@a=$imap[$i]->Results();
		$a=check_imap_results( @a ); 
 		if ($a =~ /0/) {
		    print "problem with $username client session\n";
		}
		$imap[$i]->create("Drafts");
		@a=$imap[$i]->Results();
		$a=check_imap_results( @a ); 
 		if ($a =~ /0/) {
		    print "problem with $username client session\n";
		}
		$imap[$i]->create("Trash");
		@a=$imap[$i]->Results();
		$a=check_imap_results( @a ); 
 		if ($a =~ /0/) {
		    print "problem with $username client session\n";
		}
		$imap[$i]->create("Sents");
		@a=$imap[$i]->Results();
		$a=check_imap_results( @a ); 
 		if ($a =~ /0/) {
		    print "problem with $username client session\n";
		}
		$imap[$i]->create("folder1");
		@a=$imap[$i]->Results();
		$a=check_imap_results( @a ); 
 		if ($a =~ /0/) {
		    print "problem with $username client session\n";
		}
		$imap[$i]->create("folder1/folder11");
		@a=$imap[$i]->Results();
		$a=check_imap_results( @a ); 
 		if ($a =~ /0/) {
		    print "problem with $username client session\n";
		}
		$imap[$i]->create("folder1/folder11/folder111");
		@a=$imap[$i]->Results();
		$a=check_imap_results( @a ); 
 		if ($a =~ /0/) {
		    print "problem with $username client session\n";
		}
		#$imap[$i]->logout();
		#print $imap[$i]->Results();
#	}
}

sub check_imap_results
{
my (@resultstrings) = @_;
print "in check_imap_results\n";
for $resultstring (@resultstrings) {
  print "$resultstring\n";

  if ($resultstring =~ /[0-9].* OK/ ) {
    return 1;
  } elsif ($resultstring =~ /[0-9].* NO \[ALREADYEXISTS\]/ ) {
    return 1;
  } else {
    print "skipping $resultstring\n";
  }
}
}

sub smtp_autostress
{
	my ($no_of_users) = @_;
	my $msg = "f:text";
	my @smtp = "";
	for(my $i=1;$i<=$no_of_users;$i++)
	{
		$smtp[$i] = Net::SMTP->new("$GENV_MSHOST1.$GENV_DOMAIN", Port => $port, Debug => $debug);
  		$smtp[$i]->auth("neo$i","neo$i");
		for(my $j=2;$j<=100;$j++){
			$smtp[$i]->mail("neo$i");
			$smtp[$i]->to("neo$j");
			$smtp[$i]->data();
			$smtp[$i]->datasend("from: neo$i\n");
			$smtp[$i]->datasend("to: neo$j\n");
			$smtp[$i]->datasend("Subject: Test Mail $j \n");
			if ($msg =~ /^f:/i )
			{
				$file = substr($msg,2,100);
				chomp($file);
				open(File,"$file");
				while(defined($tmp = <File>)) {
					$smtp[$i]->datasend("$tmp");
				}
			} else {
				$smtp[$i]->datasend("$msg\n");
			}
			$smtp[$i]->dataend();
		}#j loop ends
		#$smtp[$i]->quit;
	}#i for loop ends
	return 1;
}

sub pop_autostress
{
	my ($no_of_users) = @_;
	my @pop = "";
	for(my $i=1;$i<=$no_of_users;$i++){
        	$pop[$i] = Net::POP3->new("$GENV_MSHOST1.$GENV_DOMAIN", Port => 110, Debug => "$debug");
                $pop[$i]->login("neo$i","neo$i");
        	$pop[$i]->list(); # hashref of msgnum => size
                $pop[$i]->get("1");
                $pop[$i]->delete("1");
                $pop[$i]->capa();
                $pop[$i]->rset();
                $pop[$i]->uidl();
                $pop[$i]->popstat();
                $pop[$i]->reset();
    		#$pop[$i]->quit();
	}
    return 1;
}

sub mshttp_autostress
{
	my($no_of_users) = @_;

   	for(my $i=1;$i<=$no_of_users;$i++)
	{
		$ua[$i] = LWP::UserAgent->new;
		$ua[$i]->agent("MyApp/0.1 ");
		$__uid= "neo" . "$i";
		
		for (my $j=1;$j<4;$j++) {
			print "SID = $__sid \n";
			if ( $j == 1 ) {
			    $url = HTTP::Request->new(POST => "http://$GENV_MSHOST1.$GENV_DOMAIN:8990/login.msc?user=$__uid&password=$__uid");
			    #proxyauth
			    #$url = HTTP::Request->new(POST => "http://$GENV_MSHOST1.$GENV_DOMAIN/login.msc?user=admin&proxyauth=$__uid&password=password");
			}
			elsif ( $j == 2 ) {
			    $url = HTTP::Request->new(GET => "http://$GENV_MSHOST1.$GENV_DOMAIN:8990/mbox.msc?sid=$__sid&mbox=INBOX&start=0&count=20&date=true&sortorder=R&sortby=recv&headerv=Content-type&lang=en&security=false");
			}
			elsif ( $j == 3 ) {
			    $url = HTTP::Request->new(GET => "http://$GENV_MSHOST1.$GENV_DOMAIN:8990/mbox.msc?sid=$__sid&mbox=Trash&start=0&count=20&date=true&sortorder=R&sortby=recv&headerv=Content-type&lang=en&security=false");
			}
			$url->content_type('application/x-www-form-urlencoded');
			$url->content('query=libwww-perl&mode=dist');
		
			my $res = $ua[$i]->request($url);
			my $uri = $res->base;
			print "HTTP REQUEST: $uri \n\n";
			my $response = $res->as_string;
			print "HTTP REPONSE: $response \n\n";
			if ($j == 1) {
				my $ct = $res->header('Location');
				$__sid = GetSid("$ct");
			}
			sleep 1;
		}#forloop j ends
    	}#forloop i ends
}

sub stats_capture()
{
	open(FH,">>./stress_test_stat.log") or die "can't open file\n";
sub proc_usage {
  my $t = new Proc::ProcessTable;
  foreach my $got ( @{$t->table} ) {
    next if not $got->pid eq $ARGV[0];
    print "--------------------------------\n";
#     foreach $f ($t->fields){
#       print $f, ":  ", $got->{$f}, "\n";
#     }
    print "memory:" . $got->size;
    print "   cpu:" . $got->pctcpu;
  }
}


print 'memory: '. proc_usage()/1024/1024 ."\n";

	
}

sub main() {
	print "=========== Starting main program ==============\n"; 
	my @childs; 
	  
        for (my $j=1;$j<=$numiterations;$j++) {
	  print "---- iteration $j ----\n";
          if ( 1 == 0 ) {
	  my $pid = fork();
	  if ($pid) { push(@childs, $pid); }
	  elsif ($pid == 0) { smtp_autostress($USERS); exit 0; }
	  }
	
	  my $pid; 
	  for(my $i=1;$i<=$USERS;$i++){
	    $pid = fork();
	    if ($pid) { push(@childs, $pid); }
	    elsif ($pid == 0) { print "user $i\n";imap_autostress($i); exit 0; }
          }
	
          if ( 1 == 0 ) {
	  my $pid = fork();
	  if ($pid) { push(@childs, $pid); }
	  elsif ($pid == 0) { pop_autostress($USERS); exit 0; }
	
	  my $pid = fork();
	  if ($pid) { push(@childs, $pid); }
	  elsif ($pid == 0) { mshttp_autostress($USERS); exit 0; }
	  }
	# between each iteration, sleep
	  sleep(3);
	  system("echo imap `netstat -a | grep imap | wc -l`");
	}
	  
        $count=0;
	foreach (@childs) { 
		my $tmp = waitpid($_, 0); 
		print "done with pid $tmp\n";  ### DONE WITH HTTP CHILD 
		$count++;
	} 
	
	print "there were $count children pids\n";
	print "--current imap connections--\n";
	system("netstat -a | grep imap");
	print "--current mmp connections--\n";
	system("netstat -a | grep 1143");
	print "============== End of main program ==================\n";
	return 1;
}

main();
#smtp_autostress(100);
#imap_autostress(100);
#pop_autostress(100);
#mshttp_autostress(1);
