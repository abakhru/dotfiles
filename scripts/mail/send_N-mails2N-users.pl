#!/usr/bin/perl
use Net::SMTP;
 
if (@ARGV < 5)
 {
  print ("\nUsage: ./smail.pl message mailhost sender rcpt1 no_of_users no_of_mails\n");
  print ("\nExample: ./smail.pl f:text algy.red.iplanet.com neo1 neo32 100 2\n");
  exit;
}

$msg  = $ARGV[0];
$host = $ARGV[1];
$source = $ARGV[2];
$to_who = $ARGV[3];
$no_users = $ARGV[4];
$m = $ARGV[5];

yeah();

sub yeah {
  $smtp = Net::SMTP->new("$host");
  $smtp->mail("$source");
  $smtp->to("$to_who");
  $smtp->data();
  $smtp->datasend("from: $source\n");
  $smtp->datasend("to: $to_who\n");
  $smtp->datasend("Subject: TestMail$m\n");

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
