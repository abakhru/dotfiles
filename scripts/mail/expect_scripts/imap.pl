#!/usr/bin/perl

#NOTE:: This script requires Mail::IMAPClient perl module.

use Mail::IMAPClient;
use MIME::Base64;
use Net::Telnet ();

#want to enable debugging???: make the below value 1
$debug = 0;
$ssl_use = 0;

if (@ARGV < 4)
 {
  print ("\nUsage: $0 mailhost user auth_type Port domain\n");
  print ("Auth-type can be: CRAM-MD5, LOGIN(plaintext), PLAIN(SASL), STARTTLS(with LOGIN)\n\n");
  exit;
}

$MailHost  = $ARGV[0];
$UserName = $ARGV[1];
$auth_type = $ARGV[2];
$Port = $ARGV[3];
$domain = $ARGV[4];
$UserPass=$UserName;

if ($Port =~ /993/ || $Port =~/1993/){
        $ssl_use = 1;
}

# Checking and calling the appropiate auth_type method

if ($auth_type =~ /CRAM-MD5/ || $auth_type =~ /cram-md5/) {
	print "Auth type = CRAM-MD5 \n";
	$auth_type = "CRAM-MD5";
	test_imap_crammd5();
}
elsif ($auth_type =~ /LOGIN/ || $auth_type =~ /login/) {
	print "Auth type = LOGIN \n";
	$auth_type = "LOGIN";
	test_imap_login();
}
elsif ($auth_type =~ /PLAIN/ || $auth_type =~ /plain/) {
	print "Auth type = PLAIN \n";
	$auth_type = "PLAIN";
	test_imap_plain();
}
elsif ($auth_type =~ /STARTTLS/ || $auth_type =~ /starttls/) {
	print "Auth type = STARTTLS \n";
	test_imap_starttls();
}
else{ print "Wrong choice!!!\n\n"; exit 0;}

sub test_imap_crammd5()
{
	print "Using test_imap_crammd5 method\n";
	if ($domain eq "" ){
        	$imap = Mail::IMAPClient->new(Server => "$MailHost", Port => $Port, User => "$UserName", Password => "$UserPass", Ssl => $ssl_use, Authmechanism => $auth_type, Debug => $debug, Uid => 0) or die "Cannot connect to $MailHost as $UserName: $@";
	} else {
        	$imap = Mail::IMAPClient->new(Server => "$MailHost", Port => $Port, User => "$UserName\@$domain", Password => "$UserPass", Ssl => $ssl_use, Authmechanism => $auth_type, Debug => $debug, Uid => 0) or die "Cannot connect to $MailHost as $UserName: $@";
	}

        my @features = $imap->capability or die "Could not determine capability: ", $imap->LastError;
        print "@features \n";

        my @arr1 = $imap->select(INBOX) or die "Select INBOX error: ", $imap->LastError, "\n";
        print @arr1;

        my @arr2 = $imap->fetch("1", "RFC822") or die "Fetch error: ", $imap->LastError, "\n";
        print @arr2;

	$imap->logout;
}

sub test_imap_starttls()
{
        print "Using test_imap_starttls method\n";
        my $authmech = "LOGIN";
        if ($domain eq "" ){
                $imap = Mail::IMAPClient->new(Server => "$MailHost", Port => $Port, User => "$UserName", Password => "$UserPass", Proxy => "$UserName", Starttls => 1, Authmechanism => $authmech, Debug => $debug, Uid => 0) or die "Cannot connect to $MailHost as $UserName: $@";
        } else {
                $imap = Mail::IMAPClient->new(Server => "$MailHost", Port => $Port, User => "$UserName\@$domain", Password => "$UserPass", Proxy => "$UserName\@$domain", Starttls => 1, Authmechanism => $authmech, Debug => $debug, Uid => 0,);
        }

        my @arr1 = $imap->select(INBOX) or die "Select INBOX error: ", $imap->LastError, "\n";
        print @arr1;

        my @arr2 = $imap->fetch("1", "RFC822") or die "Fetch error: ", $imap->LastError, "\n";
        print @arr2;

        my @features = $imap->capability or die "Could not determine capability: ", $imap->LastError;
        print "@features \n";

        $imap->logout or die "Logout error: ", $imap->LastError, "\n";
}

sub test_imap_plain()
{
        print "Using test_imap_plain (SASL) encoded auth method\n";
        if ($domain eq "" ){
                $imap = Mail::IMAPClient->new(Server => "$MailHost", Port => $Port, User => "$UserName", Proxy => "$UserName", Password => "$UserPass", Proxy => "$UserName", Ssl => $ssl_use, Authmechanism => $auth_type, Debug => $debug, Uid => 0) or die "Cannot connect to $MailHost as $UserName: $@";
        } else {
                $imap = Mail::IMAPClient->new(Server => "$MailHost", Port => $Port, User => "$UserName\@$domain", Password => "$UserPass", Proxy => "$UserName\@$domain", Ssl => $ssl_use, Authmechanism => $auth_type, Debug => $debug, Uid => 0,);
        }

        my @arr1 = $imap->select(INBOX) or die "Select INBOX error: ", $imap->LastError, "\n";
        print @arr1;

        my @arr2 = $imap->fetch("1", "RFC822") or die "Fetch error: ", $imap->LastError, "\n";
        print @arr2;

        my @features = $imap->capability or die "Could not determine capability: ", $imap->LastError;
        print "@features \n";

        $imap->logout or die "Logout error: ", $imap->LastError, "\n";
}

sub test_imap_login()
{
        print "Using test_imap_login (plaintext) authentication mechanism\n";
        if ($domain eq "" ){
                $imap = Mail::IMAPClient->new(Server => "$MailHost", Port => $Port, User => "$UserName", Password => "$UserPass", Ssl => $ssl_use, Debug => $debug, Uid => 1) or die "Cannot connect to $MailHost as $UserName: $@";
        } else {
                $imap = Mail::IMAPClient->new(Server => "$MailHost", Port => $Port, User => "$UserName\@$domain", Password => "$UserPass", Ssl => $ssl_use, Debug => $debug, Uid => 0) or die "Cannot connect to $MailHost as $UserName: $@";
        }

        my @arr1 = $imap->select(INBOX) or die "Select INBOX error: ", $imap->LastError, "\n";
        print "@arr1\n";

        my @arr2 = $imap->fetch("1", "RFC822") or die "Fetch error: ", $imap->LastError, "\n";
        print "@arr2 \n";

        my @features = $imap->capability or die "Could not determine capability: ", $imap->LastError;
        print "@features \n";

        $imap->logout or die "Logout error: ", $imap->LastError, "\n";
}
