#!/usr/bin/perl
use Net::SMTP::TLS;
#use Net::LMTP_tls;
use Net::SMTP::SSL_auth;
use Net::SMTP_auth;
use MIME::Base64;
use Authen::SASL;
 
if (@ARGV < 4)
 {
  print ("\nUsage: $0 mailhost sender rcpt1 authtype port domain(optional) starttls[1|0](optional)\n");
  print ("Supported auth mechanisms : PLAIN, LOGIN, CRAM-MD5\n\n");
  exit;
}

$debug="1";
$host = $ARGV[0];
$UserName = $ARGV[1];
$to_who = $ARGV[2];
$authtype = $ARGV[3];
$port = $ARGV[4];
$UserPass = "USERPASSWORD";

if ($ARGV[5] =~ /^[+-]?\d+$/ ) {
	$domain = "";
	$from = $UserName;
	$starttls = $ARGV[5];
} elsif ($ARGV[5] eq "" && $ARGV[6] eq ""){
	$domain = "";
	$from = $UserName;
	$starttls = 0;
} else {
	$domain = $ARGV[5];
	$from = "$UserName\@$domain";
	$starttls = $ARGV[6];
}

if("$UserPass" eq "USERPASSWORD"){
	$UserPass = $UserName;
}

unless ($debug == 0) {
	print ("AUTH = $authtype\n");
	print ("RCPTTO = $to_who\n");
	print ("HOST = $host\n");
	print ("FROM = $from\n");
	print ("PASSWORD = $UserPass\n");
	print ("PORT = $port\n");
	print ("DOMAIN = $domain\n");
	print ("starttls = $starttls\n");
}

$date = `date`;
$msg="f:../sieve/sample-nonspam.txt";

if($port == 225)
{
	if ($starttls == 1) { lmtp_tls(); }
	else { lmtp(); }
}
elsif ($port == 25 || $port == 125 || $port == 587)
{
	if ($starttls == 1) {
		$authtype = "LOGIN";
		smtp_tls();
 	}
	elsif ($starttls == 0) {
		smtp_normal();
	}
}
elsif ($port == 465 || $port == 1465) {
	smtp_ssl();
}

sub smtp_normal
{
	$smtp = Net::SMTP_auth->new("$host:$port", Debug => $debug);
	$smtp->auth("$authtype","$from","$UserPass");
	$smtp->mail("$from");
	$smtp->to("$to_who");
	$smtp->data();
	$smtp->datasend("to: $to_who\n");
	$smtp->datasend("from: $from\n");
	$smtp->datasend("Subject: ABCDEFGHIJKLMNOPQRSTUVWXYZ \n");

	if ($msg =~ /^f:/i ) {
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

sub smtp_tls()
{
	my $smtp = new Net::SMTP::TLS("$host", Hello => "$host", Port => $port, User => "$from", Password=> "$UserPass", Debug => $debug);
	$smtp->mail("$from");
	$smtp->to("$to_who");
	$smtp->data();
	$smtp->datasend("to: $to_who\n");
	$smtp->datasend("from: $from\n");
	$smtp->datasend("Subject: ABCDEFGHIJKLMNOPQRSTUVWXYZ \n");

	if ($msg =~ /^f:/i ) {
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

sub smtp_ssl()
{
	$smtps = Net::SMTP::SSL_auth->new("$host:$port", Debug => $debug);
	$smtps->auth("$authtype","$from","$UserPass");
	$smtps->mail("$from");
	$smtps->to("$to_who");
	$smtps->data();
	$smtps->datasend("to: $to_who\n");
	$smtps->datasend("from: $from\n");
	$smtps->datasend("Subject: ABCDEFGHIJKLMNOPQRSTUVWXYZ \n");

	if ($msg =~ /^f:/i ) {
		$file = substr($msg,2,100);
		chomp($file); 
		open(File,"$file");
		while(defined($tmp = <File>)) {
			$smtps->datasend("$tmp");
		}
	} else {
		$smtps->datasend("$msg\n");
	}
	$smtps->dataend();
	$smtps->quit;
}

sub lmtp_tls
{
        my $lmtp = new Net::LMTP_tls("$host", Hello => "$host", Port => $port, User => "$from", Password=> "$source", Debug => 1);
        $lmtp->mail($from);
        $lmtp->to($to_who);
        $lmtp->data();
        $lmtp->datasend("To: $to_who\n");
        $lmtp->datasend("From: $from\n");
        $lmtp->datasend("Subject: HELLO FROM LMTP SERVER\n");
        $lmtp->datasend("A simple test message\n");
        $lmtp->datasend("Bye\n");
        $lmtp->dataend();
        $lmtp->quit;
        return 1;
}
