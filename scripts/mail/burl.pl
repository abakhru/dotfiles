#!/usr/bin/perl.qa
use Expect;
use Net::SMTP_auth;
use MIME::Base64;
use Authen::SASL;

$submitport=587;
$imapport="143";
$dir="/space/src/results/imap_urlauth";
$HOSTNAME=$ARGV[0];
$source=$ARGV[1];
$to_who=$ARGV[2];
$TestId=$ARGV[3];
$MailBox="INBOX";
$debug="0";
$timeout="4";
($field1,$ID) = split('0',$TestId);
$userpass="burl"."$ID";
#$userpass="burl20";

if(length($ARGV[4]) == 0) {
	$username=$source;
	$secuid=$source;
} else {
	$domain = $ARGV[4];
	$username="$source\@$domain";
	$secuid="$source%40$domain";
}

if (@ARGV < 4)
{
        print ("\nUsage: burl.pl <host> <mail_from> <mail_to> <testid> <sender_domain>(optional)\n\n");
}else {
	print "========== TESTID = $TestId ===========\n";
	print "==== HOSTNAME = $HOSTNAME\n";
	print "==== FROM = $username\n";
	print "==== TO = $to_who\n";
	unless(length($ARGV[4]) == 0) {print "==== SENDER_DOMAIN = $domain\n";}
	#if($TestId =~ /11/ || $TestId =~ /12/){
	#test_submit();
	#}elsif($TestId =~ /13/ || $TestId =~ /14/ || $TestId =~ /15/ || $TestId =~ /16/){
		test_urlfetch();
	#}
}

sub test_submit(){
	smtp();
	$urlauth = burl_genurlauth($source);
	burl_submit($source,$to_who,$urlauth);
}
sub test_urlfetch(){
	smtp();
	sleep(5);
	$urlauth = burl_genurlauth($source);
	burl_urlfetch($source,$urlauth);
}

sub burl_genurlauth
{
	my ($source) = @_;
	my $log_file = "$dir/imaplog_genurlauth_$TestId";
	system("touch $log_file; echo > $log_file");
	$cmd = "telnet $HOSTNAME $imapport";
        $exp = new Expect();
        $exp->raw_pty(1);
	$exp->log_file("$log_file");
	$exp->debug(0);
        $exp->spawn($cmd);
        $exp->expect($timeout,'-re', '\)\s$');
        $exp->send("1 login $username $userpass\n");
        $exp->expect($timeout,'-re', 'in\s$');
        $exp->send("2 genurlauth \"imap:\/\/$secuid\@$HOSTNAME\/$MailBox\/;uid=1;urlauth=submit+$secuid\" INTERNAL\n");
        $exp->expect($timeout,'-re', 'Completed\s$');
        $exp->send("3 logout\n");
        $exp->expect($timeout,'-re', 'Completed\s$'); 
	$exp->hard_close();

	#extracting the required urlauthcode
	chomp($urlauthcode=`grep internal $log_file|cut -f4 -d\":\"`);

	#removing the trailing " from the urlauthCode
	$urlauthcode =~ s/\"//;

	if(length($urlauthcode) == 0){
		print "=== genurlauth FAILED\n";
		 return 0;
	} else {
		print "==== URLAUTHCODE = $urlauthcode\n";
	}
	return $urlauthcode;
}

sub smtp()
{
	chomp($mboxutil_path=`find /opt/sun |grep "bin/mboxutil"`);
	if($username =~ /408/){
		if ($username =~ /@/) {
			($uid, $domain) = split("@",$username);
			$username = "$userpass"."@"."$domain";	
		}else {
			$username=$userpass;
		}
	}
	print "==== MAIL FROM: admin , RCPT TO: $username\n";
	system("$mboxutil_path -d -P \'\\S*\'");
        $smtp = Net::SMTP_auth->new("$HOSTNAME:25", Debug => $debug);
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
	my ($source, $to_who, $urlauthcode) = @_;
	my $log_file = "$dir/burl_submit_$TestId";
	if(length($domain) == 0){ 
        	$sasl = encode_base64("$source\0$source\0$userpass");
	} else {
        	$sasl = encode_base64("\000$source\@$domain\000$userpass");
	}

	$cmd = "telnet $HOSTNAME $submitport";
        $exp = new Expect();
        $exp->raw_pty(0);
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
	return 1;
}

sub burl_urlfetch
{
	my ($source,$urlauth) = @_;
	my $log_file = "$dir/imaplog_urlfetch_$TestId";
	system("touch $log_file; echo > $log_file");
	$cmd = "telnet $HOSTNAME $imapport";
        $exp = new Expect();
        $exp->raw_pty(0);
	$exp->log_file("$log_file");
	$exp->debug(0);
        $exp->spawn($cmd);
        $exp->expect($timeout,'-re', '\)\s$');
        $exp->send("1 login admin password\n");
        $exp->expect($timeout,'-re', 'in\s$');
        $exp->send("2 urlfetch imap:\/\/$secuid\@$HOSTNAME\/$MailBox\/;uid=1;urlauth=submit+$secuid:internal:$urlauth\n");
        $exp->expect($timeout,'-re', 'Completed\s$');
        $exp->send("3 logout\n");
        $exp->expect($timeout,'-re', 'Completed\s$'); 
	$exp->hard_close();
	return 1;
}

#sub ldapsearch
#{
#        my ($user) = @_;
#	my $ldap = Net::LDAP->new( "$GENV_DSHOST1.$GENV_DOMAIN", debug => $debug) or die "$@";
#	my $mesg = $ldap->bind ( "GENV_DM", password => "GENV_DMPASSWORD", version => 3);
#        $mesg = $ldap->search ( base  => "GENV_OSIROOT", scope => "subtree", filter  => "(mobile=$user)" );
#        foreach $entry ($mesg->entries) {
#	        if($0) { $entry->dump(); }
#                #get_value will return array reference
#                $uidref = $entry->get_value ("uid", asref => 1 );
#        }
#	$ldap->unbind();
#        return $uidref;
#}
