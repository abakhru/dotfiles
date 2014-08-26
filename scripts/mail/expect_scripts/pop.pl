#!/usr/bin/perl
use Net::POP3;
use Net::POP3_auth;
use Net::POP3::SSLWrapper;
use MIME::Base64;
use Net::Telnet ();
use Authen::SASL;

#want to enable debugging???: make the below value 1
$debug = 1;
$ssl_use = 0;

if (@ARGV < 4)
 {
  print ("\nUsage: $0 mailhost user auth_type port domain\n");
  print ("Auth-type can be:APOP, CRAM-MD5, Normal, PLAIN (LOGIN is not supported)\n\n");
  exit;
}

$MailHost  = $ARGV[0];
$UserName = $ARGV[1];
# NOTE: only PLAIN and CRAM-MD5 SASL mechanism is supported, LOGIN is NOT
$auth_type = $ARGV[2];
$Port = $ARGV[3];
$domain = $ARGV[4];
$UserPass=$UserName;

if ($Port =~ /995/ || $Port =~/1995/){
        $ssl_use = 1;
}

# Checking and calling the appropiate auth_type method

if ($auth_type =~ /CRAM-MD5/ || $auth_type =~ /cram-md5/) {
	print "Auth type = $auth_type \n";
	if($ssl_use) { test_pop_ssl();}
	else { test_pop_crammd5();}
}
elsif ($auth_type =~ /NORMAL/ || $auth_type =~ /normal/) {
	print "Auth type = $auth_type \n";
	test_pop_normal();
}
elsif ($auth_type =~ /APOP/ || $auth_type =~ /apop/) {
	print "Auth type = $auth_type \n";
	if($ssl_use) { test_apop_ssl();}
	else { test_pop_apop();}
}
elsif ($auth_type =~ /PLAIN/ || $auth_type =~ /plain/) {
	print "Auth type = $auth_type \n";
	test_pop_plain();
}
else{ return 1;}

sub test_pop_crammd5()
{
	print "Using test_pop_crammd5 method\n";
	my $pop = Net::POP3_auth->new("$MailHost", Port => $Port, Debug => "$debug");
	if ($domain eq "" ){
		my $q = $pop->auth("CRAM-MD5", "$UserName", $UserPass);
	} else {
		my $q = $pop->auth("CRAM-MD5", "$UserName\@$domain", $UserPass);
	}
	my $msgnums = $pop->list; # hashref of msgnum => size
        foreach my $msgnum (keys %$msgnums) {
        my $msg = $pop->get($msgnum);
        print @$msg; last;
        }
    $pop->quit();
    return 1;
}

sub test_pop_normal()
{
	print "Using test_pop_normal method\n";
	my $pop = Net::POP3->new("$MailHost", Port => $Port, Debug => "$debug");
	if ($domain eq "" ){
		my $q =	$pop->login("$UserName","$UserName");
	} else {
		my $q =	$pop->login("$UserName\@$domain","$UserName");
	}
	my $msgnums = $pop->list; # hashref of msgnum => size
        foreach my $msgnum (keys %$msgnums) {
        my $msg = $pop->get($msgnum);
        print @$msg; last;
        }
    $pop->quit();
    return 1;
}

sub test_pop_plain()
{
	print "Using test_pop_plain method\n";
	if ( $domain eq "" ){
		$sasl = encode_base64("$UserName\0$UserName\0$UserPass");
	} else {
		$sasl = encode_base64("\000$UserName\@$domain\000$UserPass");
	}
	my $pop = new Net::Telnet();
	#my $pop = new Net::Telnet( Dump_Log => "./log");
	$pop->open( Host => $MailHost, Port => $Port);
	my $line1 = $pop->getline( Timeout => 1);
	print $line1;

	$pop->print("AUTH PLAIN $sasl");
	$line2 = $pop->getline(Timeout => 8);
	print $line2;

	$pop->print("list");
	@line3 = $pop->getlines( All => "", Timeout => 15);
	print @line3;

	$pop->print("retr 1");
	sleep(3);
	@line4 = $pop->getlines( All => "",  Timeout => 10);
	print @line4;
	$pop->close;
    return 1;
}

sub test_pop_apop() {

     my $pop = Net::POP3->new("$MailHost", Port => $Port, Debug => 10);
     print $pop->banner();
     print "\n";
	if ($domain eq "" ){
     		my $q =	$pop->apop($UserName,$UserPass);
	} else {
		my $q =	$pop->apop("$UserName\@$domain","$UserPass");
	}

     my $msgnums = $pop->list; # hashref of msgnum => size
      foreach my $msgnum (keys %$msgnums) {
        my $msg = $pop->get($msgnum);
        print @$msg; last;
      }
    $pop->quit();
    return 1;
}


sub test_pop_ssl()
{
    print "Using test_pop_ssl method\n";
    pop3s 
    {
        my $pop = Net::POP3->new("$MailHost", Port => $Port, Debug => $debug) or die "Can't connect";
        print $pop->banner();
	if ($domain eq "" ){
		my $q = $pop->auth($UserName, $UserPass);
	} else {
		my $q = $pop->auth("$UserName\@$domain", $UserPass);
	}
	my $msgnums = $pop->list; # hashref of msgnum => size
        #foreach my $msgnum (keys %$msgnums) {
        #	my $msg = $pop->get($msgnum);
        #	print @$msg; last;
        #}
        $pop->quit();
    }; #pops ends
    return 1;
}

sub test_apop_ssl()
{
    print "Using test_apop_ssl method\n";
    pop3s 
    {
        my $pop = Net::POP3->new("$MailHost", Port => $Port, Debug => $debug) or die "Can't connect";
	if ($domain eq "" ){
		my $q = $pop->apop($UserName, $UserPass);
	} else {
		my $q = $pop->apop("$UserName\@$domain", $UserPass);
	}
	my $msgnums = $pop->list; # hashref of msgnum => size
        #foreach my $msgnum (keys %$msgnums) {
        #	my $msg = $pop->get($msgnum);
        #	print @$msg; last;
        #}
        $pop->quit();
    }; #pops ends
    return 1;
}
