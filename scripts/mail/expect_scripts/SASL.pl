#!/usr/bin/perl
use Net::SMTP;
use MIME::Base64;
use Authen::SASL;
 
if (@ARGV < 4)
 {
  print ("\nUsage: $0 message mailhost sender rcpt1 no_of_mails\n\n");
  exit;
}

$msg  = $ARGV[0];
print ("$msg\n");
$host = $ARGV[1];
print ("$host\n");
$source = $ARGV[2];
print ("$source\n");
$to_who = $ARGV[3];
print ("$to_who\n");
$m = $ARGV[4];
print ("$m\n");

yeah();

sub yeah {
  $smtp = Net::SMTP->new("$host:587");
  $smtp->auth("$source","test1");
  $smtp->mail("$source");
  $smtp->recipient($to_who);
  $smtp->datasend("burl imap://test1%40abc.com\@dianthos.sfbay.sun.com/INBOX/;uid=2;urlauth=submit+test1%40abc.com:internal:54778c9813064e51a30b6d79777e94f4 LAST");
  $smtp->quit;
}
