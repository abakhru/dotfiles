#!/usr/bin/perl
use Net::SMTP;
use MIME::Base64;
use Authen::SASL;
 
#To enable(1) or disable(0) debugging
$debug=0;
$port=25;

if (@ARGV < 4)
 {
  print ("\nUsage: $0 message mailhost sender <folder+>rcpt1 no_of_mails domain\n\n");
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
$domain = $ARGV[5];
$date = `date`;

if ($domain eq "") {
       $username=$source;
} else {
       $username="$source\@$domain";
}

if("$to_who" =~ /\+/){
        MailDeliver($m, "TestMail", $msg, $host, $source, $to_who);
}else{
	for(my $i=1;$i<=$m;$i++){
		yeah("TestMail$i");
		print "#$i message sent\n";
	}
}

sub yeah {
  my ($subject) = @_;
  $smtp = Net::SMTP->new("$host", Port => $port, Debug => $debug);
  $smtp->auth("$username","$source");
  $smtp->mail("$username");
  $smtp->to("$to_who");
  $smtp->data();
  $smtp->datasend("from: $username\n");
  $smtp->datasend("to: $to_who\n");
  $smtp->datasend("Subject: $subject \n");
  if ($msg =~ /^f:/i )
  {
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

	if($debug){
		print "from = $from\n";
		print "folder = $folder\n";
		print "to_who = $to_who\n";
		print "file = $file\n";
	}
        for(my $i=1;$i<=$num;$i++){
        	print "$i Email delivered to $to_who...\n";
		system("$GENV_MSHOME1/sbin/deliver -a $from -cF -m $folder $to_who < $file");
        }
#        print "Now sleeping for $timeout seconds for mails to deliver...\n";
# 	sleep($timeout);
        return 1; #Success
}
