#!/usr/bin/perl
use Net::SMTP;
 
if (@ARGV < 4)
 {
  print ("\nUsage: ./smail.pl message mailhost sender rcpt1 no_of_mails\n\n");
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
  $smtp = Net::SMTP->new("$host");
  $smtp->mail("$source");
  $smtp->to("$to_who");
  $smtp->data();
  $smtp->datasend("from: $source\n");
  $smtp->datasend("to: $to_who\n");
#  $smtp->datasend("Deferred-delivery: Thu, 24 Jul 2009 18:49:05 -0700 \(PDT\)\n");
#  $smtp->datasend("Deferred-delivery: 2009-W29-5 T17:49-0700\n");
  $smtp->datasend("Deferred-delivery: pt5m\n");
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
