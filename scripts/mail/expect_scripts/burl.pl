use Expect;
use Net::SMTP_auth;
use Net::SMTP::TLS;
use Net::SMTP::SSL;
use MIME::Base64;
use Authen::SASL;
use Mail::IMAPClient;

$submitport="587";
$imapport="143";
$dir="/export/nightly/tmp/results/imap_urlauth";
$HOSTNAME=$ARGV[0];
$source=$ARGV[1];
$to_who=$ARGV[2];
$TestId=$ARGV[3];
$fetch_or_submit=$ARGV[4];
$MailBox="INBOX";
$debug="1";
$timeout="4";
($field1,$ID) = split('0',$TestId);
$userpass="burl"."$ID";
$starttls=$ARGV[6];

if ($ARGV[5] =~ /^[+-]?\d+$/ ) {
        $domain = "";
        $username = $source;
	$secuid=$source;
        $starttls = $ARGV[5];
} elsif ($ARGV[5] eq "" && $ARGV[5] eq ""){
        $domain = "";
	$username=$source;
	$secuid=$source;
        $starttls = 0;
} else {
        $domain = $ARGV[5];
	$username="$source\@$domain";
	$secuid="$source%40$domain";
        $starttls = $ARGV[6];
}

if (@ARGV < 5)
{
        print ("\nUsage: burl.pl <host> <mail_from> <mail_to> <testid> <urlfetch|submit> <sender_domain>(optional) starttls(0|1)\n\n");
}else {
	print "==== TESTID = $TestId ====\n";
	print "==== HOSTNAME = $HOSTNAME\n";
	print "==== FROM = $username\n";
	print "==== TO = $to_who\n";
	print "==== SENDER_DOMAIN = $domain\n";
	print "==== STARTTLS = $starttls\n";
	if("$ARGV[4]" =~ /urlfetch/i){ 
		unless(test_urlfetch()){
			print "==== BURL urlfetch execution failed ====\n";
			return 0;
		}
	}elsif("$ARGV[4]" =~ /submit/i){
		unless(test_submit()){
			print "==== BURL submit execution failed ====\n";
			return 0;
		}
	}
}

sub test_submit(){
	smtp();
	sleep(5);
	$urlauth = burl_genurlauth($source);
	unless($urlauth){ return 0; }
	unless(burl_submit($source,$to_who,$urlauth)){
		print "==== burl_submit FAILED ====\n";
		return 0;
	}
	return 1;
}
sub test_urlfetch(){
	smtp();
	sleep(5);
	$urlauth = burl_genurlauth($source);
	unless($urlauth){ return 0; }
	unless(burl_urlfetch($source,$urlauth)){
		print "==== burl_urlfetch FAILED ====\n";
		return 0;
	}
	return 1;
}

sub burl_genurlauth
{
	my ($source) = @_;
	my $log_file = "$dir/imaplog_genurlauth_$TestId";
	system("touch $log_file; echo > $log_file");
	unless($starttls){
		$cmd = "telnet $HOSTNAME $imapport";
	        $exp = new Expect();
	        $exp->raw_pty(1);
		$exp->log_file("$log_file");
		$exp->debug($debug);
	        $exp->spawn($cmd);
	        $exp->expect($timeout,'-re', '\)\s$');
	        $exp->send("1 login $username $userpass\n");
	        $exp->expect($timeout,'-re', 'in\s$');
	        $exp->send("2 genurlauth \"imap:\/\/$secuid\@$HOSTNAME\/$MailBox\/;uid=1;urlauth=submit+$secuid\" INTERNAL\n");
	        $exp->expect($timeout,'-re', 'Completed\s$');
	        $exp->send("3 logout\n");
	        $exp->expect($timeout,'-re', 'Completed\s$'); 
		$exp->hard_close();
		chomp($urlauthcode=`grep internal $log_file|cut -f4 -d\":\"`);
	}else{
		unless(burl_starttls_genurlauth($source)){
			return 0;
		}
		chomp($urlauthcode=`grep internal $log_file|cut -f5 -d\":\"`);
	}

	#extracting the required urlauthcode
	#removing the trailing " from the urlauthCode
	$urlauthcode =~ s/\"//;

	if(length($urlauthcode) == 0){
		print "==== genurlauth FAILED ====\n";
		return 0;
	} else {
		print "==== URLAUTHCODE = $urlauthcode\n";
	}
	return $urlauthcode;
}

sub smtp()
{
	print "==== Inside smtp() ====\n";
	if(0){
		$mboxutil_path="unset HOME; /opt/sun/comms/messaging64/bin/mboxutil";
	}else{
		$mboxutil_path="/opt/sun/comms/messaging64/bin/mboxutil";
	}
	system("$mboxutil_path -d user/$username/$MailBox");
	system("$mboxutil_path -d user/$to_who/$MailBox");
        $smtp = Net::SMTP_auth->new("$HOSTNAME:25", Debug => 1);
        $smtp->auth("PLAIN","admin","password");
        $smtp->mail("admin");
        $smtp->to("$username");
        $smtp->data();
        $smtp->datasend("to: $username\n");
        $smtp->datasend("from: admin\n");
        $smtp->datasend("Subject: Test Mail $TestId \n");
        $smtp->datasend("1\n");
        $smtp->datasend("2\n");
        $smtp->datasend("3\n");
        $smtp->dataend();
        $smtp->quit;
	return 1;
}
	
sub burl_submit
{
	print "==== Inside burl_submit ====\n";
	my ($source, $to_who, $urlauthcode) = @_;
	unless($starttls){
		my $log_file = "$dir/burl_submit_$TestId";
		if(length($domain) == 0){ 
	        	$sasl = encode_base64("$source\0$source\0$userpass");
		} else {
	        	$sasl = encode_base64("\000$source\@$domain\000$userpass");
		}
	
		$cmd = "telnet $HOSTNAME $submitport";
	        $exp = new Expect();
	        $exp->raw_pty(1);
		$exp->log_file("$log_file");
		$exp->debug($debug);
	        $exp->spawn($cmd);
	        $exp->expect($timeout,'-re', '\)\s$');
	        $exp->send("ehlo\n");
	        $exp->expect($timeout,'-re', '0\s$');
	        $exp->send("AUTH PLAIN $sasl\n");
	        $exp->expect($timeout,'-re', '.\s$');
	        $exp->send("mail from:$username\n");
	        $exp->expect($timeout,'-re', '.\s$'); 
	        $exp->send("rcpt to:$to_who\n");
	        $exp->expect($timeout,'-re', '.\s$'); 
		$exp->send("burl imap:\/\/$secuid\@$HOSTNAME\/$MailBox\/;uid=1;urlauth=submit+$secuid:internal:$urlauthcode last\n");
	        $exp->expect($timeout,'-re', 'com\s$'); 
		$exp->send("quit\n");
		$exp->hard_close();
	}else{
		smtp_tls($source, $to_who, $urlauthcode);
	}
	return 1;
}

sub smtp_tls
{
	print "==== Inside smtp_tls ====\n";
	my ($source, $to_who, $urlauthcode) = @_;
        my $smtp = new Net::SMTP::TLS("$HOSTNAME", Hello => "$HOSTNAME", Port => $submitport, User => "$source", Password=> "$userpass", Debug => 1);
        $smtp->mail("$username");
        $smtp->to("$to_who");
        $smtp->datasend("burl imap:\/\/$secuid\@$HOSTNAME\/$MailBox\/;uid=1;urlauth=submit+$secuid:internal:$urlauthcode LAST\n");
        $smtp->quit;
	return 1;
}

sub burl_urlfetch
{
	my ($source,$urlauth) = @_;
	unless($starttls){
		my $log_file = "$dir/imaplog_urlfetch_$TestId";
		system("touch $log_file; echo > $log_file");
		$cmd = "telnet $HOSTNAME $imapport";
	        $exp = new Expect();
	        $exp->raw_pty(1);
		$exp->log_file("$log_file");
		$exp->debug($debug);
	        $exp->spawn($cmd);
	        $exp->expect($timeout,'-re', '\)\s$');
	        $exp->send("1 login admin password\n");
	        $exp->expect($timeout,'-re', 'in\s$');
	        $exp->send("2 urlfetch imap:\/\/$secuid\@$HOSTNAME\/$MailBox\/;uid=1;urlauth=submit+$secuid:internal:$urlauth\n");
	        $exp->expect($timeout,'-re', 'Completed\s$');
	        $exp->send("3 logout\n");
	        $exp->expect($timeout,'-re', 'Completed\s$'); 
		$exp->hard_close();
	}else{
		unless(burl_starttls_urlfetch($source,$urlauth)){
			print "burl_starttls_urlfetch failed\n";
			return 0;
		}
	}
	return 1;
}

sub burl_starttls_urlfetch
{
	my ($source,$urlauth) = @_;
        print "==== Using burl_starttls_urlfetch method\n";
        $imap = Mail::IMAPClient->new(Server => "$HOSTNAME", Port => $imapport, User => "$source", Password => "$userpass", Starttls => 1, Authmechanism => "LOGIN", Debug => 1, Debug_fh => IO::File->new(">$dir/burl_starttls_urlfetch_$TestId.log"), Uid => 0) or die "Cannot connect to $HOSTNAME as $username : $@";
        my @arr2 = $imap->run("2 urlfetch \"imap:\/\/$secuid\@$HOSTNAME\/$MailBox\/;uid=1;urlauth=submit+$secuid:internal:$urlauth\"\n");
        $imap->logout or die "Logout error: ", $imap->LastError, "\n";
        return 1;
}

sub burl_starttls_genurlauth
{
        print "==== Using burl_starttls_genrulauth method\n";
        $imap = Mail::IMAPClient->new(Server => "$HOSTNAME", Port => $imapport, User => "$source", Password => "$userpass", Proxy => "$username", Starttls => 1, Authmechanism => "LOGIN", Debug => 1, Debug_fh => IO::File->new(">$dir/imaplog_genurlauth_$TestId"), Uid => 0) or die "Cannot connect to $HOSTNAME as $username: $@";
	my $arr2 = $imap->run("2 genurlauth \"imap:\/\/$secuid\@$HOSTNAME\/$MailBox\/;uid=1;urlauth=submit+$secuid\" INTERNAL\n");
        $imap->logout or die "Logout error: ", $imap->LastError, "\n";
	system("more $dir/imaplog_genurlauth_$TestId");
	return 1;
}
