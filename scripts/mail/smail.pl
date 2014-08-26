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
# This method is for additional mail from options enabled
#  $smtp->mail($source, AUTH => "algy8\@sfbay.sun.com");
  $smtp->to("$to_who");
# This is to have Delivery State Notification enabled (DSN)
#  $smtp->recipient($to_who, { Notify => ['SUCCESS','FAILURE','DELAY'], SkipBad => 1 });
  $smtp->data();
  $smtp->datasend("from: $source\n");
  $smtp->datasend("to: $to_who\n");
#  $smtp->datasend("Approve:hong\n");
#  $smtp->datasend("to: $to_who,$to_who,$to_who,$to_who,$to_who,$to_who,$to_who,$to_who,$to_who,$to_who,$to_who,$to_who,$to_who,$to_who,$to_who,$to_who,$to_who,$to_who,$to_who,$to_who,$to_who,$to_who,$to_who,$to_who,$to_who,$to_who,$to_who,$to_who,$to_who,$to_who,$to_who,$to_who,$to_who,$to_who,$to_who,$to_who,$to_who,$to_who,$to_who,$to_who,$to_who,$to_who,$to_who,$to_who,$to_who,$to_who,$to_who,$to_who,$to_who,$to_who,$to_who,$to_who,$to_who,$to_who,$to_who,$to_who,$to_who,$to_who,$to_who,$to_who,$to_who,$to_who,$to_who,$to_who,$to_who\n");
  $smtp->datasend("Subject: money Mail $m\n");
#  $smtp->datasend("Subject: ABCDEFGHIJKLMNOPQRSTUVWXYZ \n");

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

sub MailDeliver{
        my ($num, $subject, $file, $host, $from, $to_who) = @_;
        my $timeout = 5;
	my $GENV_MSHOME1="/opt/sun/comms/messaging64";

        #when to_who is mailboxpurgeuser207+folder3\@mailboxpurge.com
        my @a = split('\+',$to_who);
        if($to_who =~ /@/){
                my @b = split('@',$a[1]);
                $folder = $b[0];
                $to_who = "$a[0]" . "@" . "$b[1]";
        }else{
                $folder = $a[1];
                $to_who = $a[0];
        }

        @a = split(":",$file);
        $file = $a[1];

        print "Now delivering $num emails to $to_who...\n";
        for(my $i=0;$i<$num;$i++){
		system("$GENV_MSHOME1/sbin/deliver -a $from -cF -m $folder $to_who < $file");
        }
        print "Now sleeping for $timeout seconds for mails to deliver...\n";
        sleep($timeout);

        return 1; #Success
}
