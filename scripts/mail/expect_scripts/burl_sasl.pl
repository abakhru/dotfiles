#!/usr/bin/perl
use Net::SMTP;
use MIME::Base64;
use Authen::SASL;
 
if (@ARGV < 3)
 {
  print ("\nUsage: $0 mailhost sender rcpt1 urlauthcode\n\n");
  exit;
}

$host = $ARGV[0];
print ("$host\n");
$source = $ARGV[1];
print ("$source\n");
$to_who = $ARGV[2];
print ("$to_who\n");
$urlauthcode = $ARGV[3];
print ("$urlauthcode\n");

yeah();

sub yeah {
  $smtp = Net::SMTP->new("$host:587");
#  $smtp = Net::SMTP.start("$host, 25, sfbay.sun.com, $source, $source, :plain");
#  $smtp->auth("$source","$source");
  $smtp->auth("$source","$source");
  $smtp->mail("$source");
  $smtp->recipient($to_who);
  $smtp->datasend("burl imap://$source\@$host.sfbay.sun.com/INBOX/;uid=1;urlauth=submit+$source:internal:$urlauthcode LAST");
  $smtp->quit;
}
