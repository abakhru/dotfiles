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
$timeout=1;
$msg="f:text";
$user="neo1";
$GENV_MSHOST1=hostname();
$GENV_DSHOST1=hostname();
$GENV_MSHOME1="/opt/sun/comms/messaging64";
$GENV_DOMAIN="us.oracle.com";
$GENV_DMPASSWORD="password";
$GENV_OSIROOT="o=usergroup";
$num_messages=100;

sub AddUsers {
	my ($username, $no_of_users, $domain) = @_;
	if(length($domain) == 0){
		$domain = $GENV_DOMAIN;
	}
	DeleteUsers($username);
        print "===== Adding $username users on ldap_server:$GENV_DSHOST1.$GENV_DOMAIN & domain:$domain =====\n";
	$ldap = Net::LDAP->new("$GENV_DSHOST1.$GENV_DOMAIN", $debug => "1");
	$mesg = $ldap->bind("cn=Directory Manager", password => "$GENV_DMPASSWORD", version => 3);

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
				'icsStatus' => 'active',
			);
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
	}
        $mesg = $ldap->unbind;
        return;
}

sub multi_threads()
{
	my @childs, $pid; 
        for (my $j=1;$j<=1;$j++) 
	{
	       	$pid = fork();
	       	if ($pid) {
			push(@childs, $pid);
		}
	       	elsif ($pid == 0) {
			telnet_expect("lickitung.us.oracle.com", "/space/amit/scripts/mail/expect_scripts/imap.in", "143", "1", "./output1");
			rehostuser_expect();
			exit 0;
		}
        }

        $count=0;
        foreach (@childs) {
                my $tmp = waitpid($_, 0);
                $count++;
        }       
	return 1;
}

sub smtp
{
	my ($host, $from, $to, $subject) = @_;
	$smtp = Net::SMTP->new("$host", Port => "25", Debug => 0);
	$smtp->auth("$from","$from");
	$smtp->mail("$from");
	$smtp->to("$to");
	$smtp->data();
	$smtp->datasend("From: $from\n");
	$smtp->datasend("To: $to\n");
	$smtp->datasend("Subject: $subject\n");
	if ($msg =~ /^f:/i )
	{
		$file = substr($msg,2,100);
		chomp($file); 
		open(File,"$file");
	    	while(defined($tmp = <File>)) {
			$smtp->datasend("$tmp");
		}
	} else {
		$smtp->datasend("$msg\n");
	}
	$smtp->dataend();
	$smtp->quit;
}

sub telnet_expect
{
	#print ("\nUsage: ./telnet_expect.pl <filename> [143|25|110] <timeout> <output_file>\n\n");
	my ($host, $file, $port, $timeout, $output_file) = @_;

	chomp($file); 
	# start the smtp/telnet session
        $exp = new Expect();
        $exp->raw_pty(1);
        $exp->log_file("$output_file", "w");
        $exp->debug($debug);
        $exp->spawn("telnet $host $port");
	if("$port" =~ /110/){
        	$exp->expect($timeout,'-re', '\>\s$');
	}else{
        	$exp->expect($timeout,'-re', '\)\s$');
	}
	#open the input file
	open(File,"$file");
	while(defined($tmp = <File>)) {
		if("$tmp" =~ /EHLO/){
        		$exp->send("$tmp");
        		$exp->expect($timeout,'-re', '0\s$'); 
		}elsif(("$tmp" =~ /SENDSTART/) || ("$tmp" =~ /SENDEND/) || ("$tmp" =~ /#/)){
			next;
		}else{
        		$exp->send("$tmp");
        		$exp->expect($timeout,'-re', '\.$'); 
		}
	}
        $exp->send("quit\n");
        $exp->expect($timeout,'-re', '\.$'); 
        $exp->hard_close();
	return 1;
}

sub rehostuser_expect
{
	$cmd="/opt/sun/comms/messaging64/sbin/rehostuser -u neo1 -d sc11152026.us.oracle.com -x -e -s \"/usr/bin/ssh -l root\"";
        $exp = new Expect();
        $exp->raw_pty(1);
        $exp->log_file("$output_file", "w");
        $exp->debug($debug);
        $exp->spawn("$cmd");
        $exp->expect($timeout,'-re', 'word:$'); 
        $exp->send("iplanet\n");
        $exp->expect(10,'-re', 'word:$'); 
        $exp->send("iplanet\n");
        $exp->expect(5,'-re', '\.$'); 
        $exp->hard_close();
	return 1;
}

system("rm output*");
system("/opt/sun/comms/messaging64/sbin/mboxutil -d -P \'\\S*\'");
AddUsers("neo","3");
for($j=1;$j<=100;$j++){
	smtp("$GENV_MSHOST1.$GENV_DOMAIN", "neo2", "neo1", "TestMail$j");
	print "Sent message $j...\n";
}
sleep(5);
multi_threads();
telnet_expect("sc11152026.us.oracle.com", "/space/src/results/ims_BackupnRestore/Test062_a.in", "143", "1", "./output2");
