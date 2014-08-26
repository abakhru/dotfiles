#!/usr/bin/perl
use Net::IMAP;
use LWP::UserAgent;
use Net::Cmd;
use Net::SMTP;
use Net::SMTP_auth;
use Net::POP3;
use Net::POP3_auth;
use Mail::IMAPClient;
use Net::LDAP;
use Time::HiRes qw (time);
use Net::Domain qw(hostname hostfqdn hostdomain domainname);
use Expect;

$debug=0;
$first_user=$ARGV[0];
$last_user=$ARGV[1];
if (@ARGV < 2) {
	print "Usage:  $0 <first_user> <last_user> <num-of-iterations>\n";
	exit(0);
}
print "Users Range specified: $first_user - $last_user\n";
$numiterations=$ARGV[2];
print "Num iterations specified: $numiterations\n";
if ( $numiterations == "" ) { $numiterations = 1 };
$total_users = ($last_user-$first_user);
$iterations=($total_users*$numiterations);
$GENV_MSHOST1="sc11e0405";
$GENV_DSHOST1="sc11e0405";
$GENV_MSHOME1="/opt/sun/comms/messaging64";
$GENV_DOMAIN="us.oracle.com";
$GENV_DMPASSWORD="password";
$GENV_OSIROOT="o=usergroup";
$imap_report="./imapreport";
$pop_report="./popreport";
$smtp_report="./smtpreport";
$http_report="./httpreport";
$stats_file="./statsfile";
$FORMAT = "%-6s %-10s %-8s %-24s %s\n";
#$process = new Proc::ProcessTable;
my $i = 0;

sub AddUsers {
	my ($username, $no_of_users, $domain) = @_;
	if(length($domain) == 0){
		$domain = $GENV_DOMAIN;
	}
	DeleteUsers($username);
        print "===== Adding $username users on ldap_server:$GENV_DSHOST1.$GENV_DOMAIN & domain:$domain =====\n";
	$ldap = Net::LDAP->new("$GENV_DSHOST1.$GENV_DOMAIN", $debug => "1");
	$mesg = $ldap->bind("cn=Directory Manager", password => "$GENV_DMPASSWORD", version => 3);
	#@Dates = Vacation_getDate();

	for(my $i=1; $i<=$no_of_users; $i++)
	{
		my $uid = "$username" . "$i";
		my $entry = Net::LDAP::Entry->new;
		$entry->dn("uid=$uid, ou=People, o=$domain, $GENV_OSIROOT");
		$entry->changetype("add");
		$entry->add( 'objectclass' => ['top', 'person', 'userPresenceProfile', 'inetUser','ipUser','inetMailUser',
                                'inetLocalMailRecipient', 'icscalendaruser', 'icscalendardomain',
                                'iplanet-am-auth-configuration-service','organizationalPerson', 'inetOrgPerson'],
                         	'cn'   => "$uid $uid",
                         	'sn'   => "$uid",
                         	'mail' => "$uid\@$domain",
                		'mailuserstatus' => 'active',
				'mailquota' => '-1',
				'mailhost' => "$GENV_MSHOST1.$GENV_DOMAIN",
				'initials' => "$uid",
				'givenname' => "$uid",
				'uid' => "$uid",
				'mailmsgquota' => '-1',
				'maildeliveryoption' => 'mailbox',
				'preferredlanguage' => 'en',
				'nswmextendeduserprefs' => 'meDraftFolder=Drafts',
				'nswmextendeduserprefs' => 'meSentFolder=Sent',
				'nswmextendeduserprefs' => 'meTrashFolder=Trash',
				'nswmextendeduserprefs' => 'meInitialized=true',
				'mailAllowedServiceAccess' => '+imap,pop,http,smtp,imaps,smtps,pops,https:*',
				'inetuserstatus' => 'active',
				'userpassword' => "$uid",
				#calendar related entries
				'icsStatus' => 'active',
				'icsExtendedUserPrefs' => 'ceEnableInviteNotify=true',
				'icsExtendedUserPrefs' => 'ceNotifySMSAddress=sms://',
				'icsExtendedUserPrefs' => 'ceEnableNotifySMS=false',
				'icsExtendedUserPrefs' => 'ceDefaultAlarmStart=-PT5M',
				'icsExtendedUserPrefs' => "ceNotifyEmail=$uid\@$domain",
				'icsExtendedUserPrefs' => 'ceNotifyEnable=1',
				'icsExtendedUserPrefs' => "ceDefaultAlarmEmail=$uid\@$domain",
				'icsExtendedUserPrefs' => 'ceEnableNotifyPopup=false',
				#'vacationStartDate' => '20110621013000Z',
				#'vacationEndDate' => '20110623012900Z',
				#'vacationStartDate' => "$Dates[0]",
				#'vacationEndDate' => "$Dates[1]",
				#'mailDeliveryOption' => 'autoreply',
				'mailAutoReplySubject' => 'uuuuuuuuuuuuuuuuuuuu',
				'mailAutoReplyText' => 'jjjjjjjjjjjjjjjjjjjjjjjjjjjjjj',
				'mailAutoReplyTextInternal' => 'thnthnthn',
				'mailAutoReplyTimeout' => '1'
			);
                #$entry->dump()if($GENV_VERYVERYNOISY);
		$entry->update($ldap);
		my $dn = $entry->dn();
		print "Adding user $dn\n";
		#$result->code && warn "failed to add entry $uid: ", $result->error;
	}#for loop ends
        $ldap->unbind();
	return 1;
}

sub DeleteUsers {
        my ($uid) = @_;
        print "===== Deleting the existing $uid* users from ldap =====\n";
        my $ldap = Net::LDAP->new("$GENV_DSHOST1.$GENV_DOMAIN", debug => 0, version => 3 ) or die "$@";
        my $mesg = $ldap->bind("cn=Directory Manager", password => $GENV_DMPASSWORD, version => 3 ) or die "$@";
        my $mesg = $ldap->search(base => "$GENV_OSIROOT", filter => "uid=$uid*");
        foreach $entry ($mesg->entries) {
		$ldap->delete($entry);
		my $dn = $entry->dn();
		#print "Deleting user $dn\n";
	}
        $mesg = $ldap->unbind;
        return;
}

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
	my($i, $fetch_no) = @_;
	my @imap, @login_time, @folder_create_time = "";
        my $mmpORimap=2;
	LOOP: $useri=int(rand($last_user))+1;
	unless(($useri <= $last_user) && ($useri >= $first_user))
	{
		goto LOOP;
	}
        $username="neo$useri\@$GENV_DOMAIN";
	$password="neo$useri";
        print "IMAP login in as $username\n";

	# randomly use imap or mmp/imap
	$usewhat=int(rand($mmpORimap));

	#print "use imap: 0 use mmp: 1 : value $usewhat\n";
        if ( $usewhat == 0 ) {
  		$useport=143;
        } else {
		$useport=1143;
	}
	### Calculate the time it takes to bind ###
	$start = time();
	$imap[$i] = Mail::IMAPClient->new(Server => "$GENV_MSHOST1.$GENV_DOMAIN",Port => $useport, Debug => $debug, User => $username, Password => $password);
       	$login_time[$i] = time() - $start;
	$imap[$i]->select("INBOX");
	#print $imap[$i]->Results();
     	$a=check_imap_results($imap[$i]->Results());
 	if ($a =~ /0/) {
		print "problem with $username client session\n";
	}
	### Calculate the time it takes to create 4 folders ###
	$start = time();
	$imap[$i]->create("Drafts");
	$a=check_imap_results( $imap[$i]->Results());
 	if ($a =~ /0/) {
		print "problem with $username client session\n";
	}
	$imap[$i]->create("Trash");
	$a=check_imap_results( $imap[$i]->Results());
 	if ($a =~ /0/) {
		print "problem with $username client session\n";
	}
	$imap[$i]->create("Sents");
	$a=check_imap_results( $imap[$i]->Results());
 	if ($a =~ /0/) {
		print "problem with $username client session\n";
	}
	$imap[$i]->create("folder1");
	$a=check_imap_results( $imap[$i]->Results());
 	if ($a =~ /0/) {
		print "problem with $username client session\n";
	}
	$imap[$i]->create("folder1/folder11");
	$a=check_imap_results( $imap[$i]->Results());
 	if ($a =~ /0/) {
		print "problem with $username client session\n";
	}
	$imap[$i]->create("folder1/folder11/folder111");
	$a=check_imap_results( $imap[$i]->Results());
 	if ($a =~ /0/) {
		print "problem with $username client session\n";
	}
       	$folder_create_time[$i] = time() - $start;

	#imap fetch
        $start = time();
        @Lines = $imap[$i]->fetch($fetch_no,"RFC822.TEXT");
        $fetch_time[$i] = time() - $start;
        print "@Lines\n";
	###
	### Grab the local port number
	###
	#($localport) = sockaddr_in($imap[$i]->socket()->sockname());

	###
	### Calculate the time it takes to search
	###
        #$start = time();
	#$ldap->search( "base"   => $base, "filter" => "(objectclass=*)", "attrs"  => "cn", "scope"  => "base");
        #$search = time() - $start;

	###
	### Calculate the time it takes to unbind
	###
        #$start = time();
        #$ldap->unbind() or die("Unable to unbind from $server:$port");
        #$unbind = time() - $start;

	###
	### Check to see if the delay is greater than $excessive_delay
	###
        #if (($new > $excessive_delay) || ($bind > $excessive_delay) || 
        #    ($search > $excessive_delay) || ($unbind > $excessive_delay)) {
	#	my $dt = scalar localtime time;
        #	my $ds = $is_excessive ? "Excessive" : "Normal";
	#	printf("%s: new=%.3fs, = bind=%.3fs, search=%.3fs, unbind=%.3fs [local port=%d] [Excessive Delay]\n", $dt, $new, $bind, $search, $unbind, $localport);
        #} else {
        #       my $dt = scalar localtime time;
        #       my $ds = $is_excessive ? "Excessive" : "Normal";
        #       printf "%s: new=%.3fs, = bind=%.3fs, search=%.3fs, unbind=%.3fs [local port=%d] [Normal Delay]\n", $dt, $new, $bind, $search, $unbind, $localport;
        #}
	
        #sleep($delay);
	#}
	#$imap[$i]->logout();
	#print $imap[$i]->Results();
	#$count = getImapConn("$GENV_MSHOME1/log","imap");
	#my @process_details =`top -b -d 5 -u mailsrv -H |grep imapd`;
#	$imap_count = ("imap");
#	$mmp_imap_count = getConnCount("imap");
#	($imap_cpu_perc, $imap_mem_size, $imap_num_threads)=processStat("imapd");
       	printf IMAPFILE "%s\t %.3fs\t %.3fs\t %.3fs\t %d\t %d\t %.2f\%\t %.2f\t %.2f\n",$username,$login_time[$i],$folder_create_time[$i], $fetch_time[$i], $imap_count,$mmp_imap_count, $imap_cpu_perc, $imap_mem_size, $imap_num_threads;
}

sub check_imap_results
{
	my (@resultstrings) = @_;
	print "in check_imap_results\n";
	for $resultstring (@resultstrings) 
	{
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
	my $msg = "f:text";
	my @smtp = "";
        my $mmpORsmtp=2;
        $user1=int(rand($last_user))+1;
        if ($user1 < $first_user) { $user1 = $first_user; }
        if ($user1 > $last_user) { $user1 = $last_user; }

        $username="neo$user1\@$GENV_DOMAIN";
        $password="neo$user1";
        print "SMTP login in as $username\n";

        $receiver1=int(rand($last_user))+1;
        if ($receiver1 < $first_user) { $receiver1 = $first_user; }
        if ($receiver1 > $last_user) { $receiver1 = $last_user; }
        $receiver ="neo$receiver1\@$GENV_DOMAIN";

        # randomly use imap or mmp/smtp
        $usewhat=int(rand($mmpORsmtp));

        #print "use smtp: 0 use mmp: 1 : value $usewhat\n";
        if ( $usewhat == 0 ) {
                $useport=25;
        } else {
                $useport=125;
        }
        ### Calculate the time it takes to bind ###
        $start = time();
	$smtp[$i] = Net::SMTP->new("$GENV_MSHOST1.$GENV_DOMAIN", Port => $useport, Debug => $debug);
	$smtp_bind_time[$i] = time() - $start;

        ### Calculate the time it takes to login ###
        $start = time();
  	$smtp[$i]->auth($username,$password);
	$smtp_login_time[$i] = time() - $start;

        ### Calculate the time it takes to send a mail ###
        $start = time();
	$smtp[$i]->mail($username);
	$smtp[$i]->to("$receiver");
	$smtp[$i]->data();
	$smtp[$i]->datasend("from: $username\n");
	$smtp[$i]->datasend("to: $receiver\n");
	$smtp[$i]->datasend("Subject: Test Mail $i\n");
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
	$smtp_mailsend_time[$i] = time() - $start;
	#$smtp[$i]->quit;
#	$smtp_count = getConnCount("$GENV_MSHOME1/log","mail.log_current", "EEA", "Account Notice: close");
#	$mmp_smtp_count = getConnCount("$GENV_MSHOME1/log","mail.log_current", "EEPA", "Account Notice: close");
	#($smtp_cpu_perc, $smtp_mem_perc, $smtp_num_threads)=processStat("tcp_smtp_server");
       	printf SMTPFILE "%s\t %.3fs\t %.3fs\t %.3fs\t %d\t %d\t %.2f\%\t %.2f\%\t %.2f\n",$username, $smtp_bind_time[$i], $smtp_login_time[$i], $smtp_mailsend_time[$i], $smtp_count,$mmp_smtp_count,$smtp_cpu_perc, $smtp_mem_perc, $smtp_num_threads;
	return 1;
}

sub pop_autostress
{
        my $mmpORsmtp=2;
        $user1=int(rand($last_user))+1;
        if ($user1 < $first_user) { $user1 = $first_user; }
        if ($user1 > $last_user) { $user1 = $last_user; }

        $username="neo$user1\@$GENV_DOMAIN";
        $password="neo$user1";
        print "POP login in as $username\n";

        # randomly use imap or mmp/smtp
        $usewhat=int(rand($mmpORpop));

        #print "use pop: 0 use mmp: 1 : value $usewhat\n";
        if ( $usewhat == 0 ) {
                $useport=110;
        } else {
                $useport=1110;
        }
        ### Calculate the time it takes to bind ###
        $start = time();
        $pop[$i] = Net::POP3->new("$GENV_MSHOST1.$GENV_DOMAIN", Port => $useport, Debug => "$debug");
        $pop_bind_time[$i] = time() - $start;

        ### Calculate the time it takes to login ###
        $start = time();
        $pop[$i]->login($username,$password);
        $pop_login_time[$i] = time() - $start;

        $pop[$i]->list(); # hashref of msgnum => size
        $pop[$i]->get("1");
        $pop[$i]->delete("1");
        $pop[$i]->capa();
        $pop[$i]->uidl();
        $pop[$i]->popstat();
        $pop[$i]->reset();
    	#$pop[$i]->quit();
	$pop_count = getConnCount("pop");
#	$mmp_pop_count = getConnCount("$GENV_MSHOME1/log","popproxy", "USER", "session end");
	($pop_cpu_perc, $pop_mem_size, $pop_num_threads)=processStat("popd");
       	printf POPFILE "%s\t %.3fs\t %.3fs\t %d\t %d\t %.2f\%\t %.2f\t %d\n",$username,$pop_bind_time[$i],$pop_login_time[$i],$pop_count,$mmp_pop_count,$pop_cpu_perc, $pop_mem_size, $pop_num_threads;
    	return 1;
}

sub mshttp_autostress
{
        $user1=int(rand($last_user))+1;
        if ($user1 < $first_user) { $user1 = $first_user; }
        if ($user1 > $last_user) { $user1 = $last_user; }

        $username="neo$user1\@$GENV_DOMAIN";
        $password="neo$user1";
        print "HTTP login in as $username\n";

	$ua[$i] = LWP::UserAgent->new;
	$ua[$i]->agent("MyApp/0.1 ");
		
	for (my $j=1;$j<4;$j++) {
		print "SID = $sid[$i]\n" if($debug);
		if ( $j == 1 ) {
		    $url = HTTP::Request->new(POST => "http://$GENV_MSHOST1.$GENV_DOMAIN:8990/login.msc?user=$username&password=$password");
		    #proxyauth
		    #$url = HTTP::Request->new(POST => "http://$GENV_MSHOST1.$GENV_DOMAIN/login.msc?user=admin&proxyauth=$__uid&password=password");
		}
		elsif ( $j == 2 ) {
		    $url = HTTP::Request->new(GET => "http://$GENV_MSHOST1.$GENV_DOMAIN:8990/mbox.msc?sid=$sid[$i]&mbox=INBOX&start=0&count=20&date=true&sortorder=R&sortby=recv&headerv=Content-type&lang=en&security=false");
		}
		elsif ( $j == 3 ) {
		    $url = HTTP::Request->new(GET => "http://$GENV_MSHOST1.$GENV_DOMAIN:8990/mbox.msc?sid=$sid[$i]&mbox=Trash&start=0&count=20&date=true&sortorder=R&sortby=recv&headerv=Content-type&lang=en&security=false");
		}
		$url->content_type('application/x-www-form-urlencoded');
		$url->content('query=libwww-perl&mode=dist');
	
        ### Calculate the time it takes to bind ###
	$start = time();
		my $res = $ua[$i]->request($url);
		my $uri = $res->base;
		print "HTTP REQUEST: $uri \n\n" if($debug);
		my $response = $res->as_string;
		print "HTTP REPONSE: $response \n\n" if($debug);
	$http_login_time = time() - $start;
		if ($j == 1) {
			my $ct = $res->header('Location');
			$sid[$i] = GetSid("$ct");
		}
		sleep 1;
	}#forloop j ends
	$http_count = getConnCount("http");
	($http_cpu_perc, $http_mem_size, $http_num_threads)=processStat("mshttpd");
       	printf HTTPFILE "%s\t %.3fs\t %d\t %.2f\%\t %.2f\t %d\n",$username,$http_login_time, $http_count,$http_cpu_perc, $http_mem_size, $http_num_threads;
	return 1;
}

sub AutoStress_RunTest
{
	my ($first_user, $last_user) = @_;

        open( IMAPFILE, ">$imap_report") || die "ERROR: Couldn't open $imap_report in write mode: Perl error: $@";
        print IMAPFILE "username\t\t login\t create\t fetch\t conns\t mmp\t cpu\t memory\t threads\n";
        print IMAPFILE "================================================================================\n";

#        open( POPFILE, ">$pop_report") || die "ERROR: Couldn't open $pop_report in write mode: Perl error: $@";
#        print POPFILE "username\t\t bind\t login\t Conns\t mmp\t cpu\t memory\t threads\n";
#        print POPFILE "================================================================================\n";
#
#        open( SMTPFILE, ">$smtp_report") || die "ERROR: Couldn't open $smtp_report in write mode: Perl error: $@";
#        print SMTPFILE "username\t\t bind\t login\t send\t Conns\t mmp\t cpu\t memory\t threads\n";
#        print SMTPFILE "=======================================================================================\n";
#
#        open( HTTPFILE, ">$http_report") || die "ERROR: Couldn't open $http_report in write mode: Perl error: $@";
#        print HTTPFILE "username\t\t login\t Conns\t cpu\t memory\t threads\n";
#        print HTTPFILE "========================================================================\n";
#
#	system("prstat -u mailuser 5 20 > $stats_file");

	my @childs, $pid; 
        for (my $j=1;$j<=$numiterations;$j++) 
	{
#	          print "---- iteration $j ----\n";
#	          for(my $i=$first_user;$i<=$last_user;$i++){
#	            $pid = fork();
#	            if ($pid) { push(@childs, $pid); }
#	            elsif ($pid == 0) {
#			smtp_autostress($USERS);
#			exit 0; 
#		    }
#	          }
	
	          for(my $i=$first_user;$i<=$last_user;$i++){
	          	$pid = fork();
	          	if ($pid) {
				push(@childs, $pid);
			}
	          	elsif ($pid == 0) {
				print "user $i\n";
				imap_autostress($i,$j);
				exit 0;
			}
	          }
	
#	         for(my $i=$first_user;$i<=$last_user;$i++){
#	            $pid = fork();
#	            if ($pid) { push(@childs, $pid); }
#	            elsif ($pid == 0) {
#			pop_autostress($i);
#		 	exit 0;
#		    } 
#		 }
#	
#	          for(my $i=$first_user;$i<=$last_user;$i++){
#	             $pid = fork();
#	             if ($pid) { push(@childs, $pid); }
#	             elsif ($pid == 0) {
#			 mshttp_autostress($i);
#			 exit 0;
#		     }
#	          }
#
	       	  # between each iteration, sleep
	          sleep(2);
	          #@imapConnections = `netstat -a |grep ESTABLISHED| grep imap`;
		  #print IMAPFILE "@imapConnections\n";
        }

        $count=0;
        foreach (@childs) {
                my $tmp = waitpid($_, 0);
                $count++;
        }       

#        print SMTPFILE "===========================================================================\n";
#        print HTTPFILE "===========================================================================\n";
#        print POPFILE "===========================================================================\n";
        print IMAPFILE "===========================================================================\n";
#	close(SMTPFILE);
#	close(POPFILE);
#	close(HTTPFILE);
	close(IMAPFILE);
	return 1;
}

sub copy_report()
{
	my $host = hostname();
        if($client =~ /bakhru/){
                $host_user = "root";
        }else {
                $host_user = "uadmin";
        }
	chomp($a=`grep $GENV_MSHOST1.$GENV_DOMAIN /.ssh/known_hosts`);
        $cmd5="scp /tmp/imapreport $host_user\@$GENV_MSHOST1.$GENV_DOMAIN:/tmp/imapreport_$host\n";
        print "==== Copying the report file to remote host $GENV_MSHOST1.$GENV_DOMAIN ====\n";
        $exp2 = new Expect();
        $exp2->raw_pty(1);
        $exp2->debug(0);
        $exp2->spawn($cmd5);
	if($a eq ""){
        	$exp2->expect($timeout,'-re', '\?\s$');
        	$exp2->send ("yes\n");
	}
        $exp2->expect($timeout,'-re', ':\s$');
        $exp2->send ("iplanet\n");
        $exp2->expect($timeout,'-re', '#\s$');
        $exp2->hard_close();
}

AutoStress_RunTest($first_user, $last_user);
copy_report();
