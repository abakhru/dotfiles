#!/usr/bin/perl
use Mail::IMAPClient;
use Net::SMTP;
use MIME::Base64;
use Authen::SASL;
 
#To enable(1) or disable(0) debugging
$debug=0;
$msg="f:text";
$host="lickitung.us.oracle.com";
$from="neo1";
$to="neo4";
$num_of_messages="30";
system("/opt/sun/comms/messaging64/sbin/mboxutil -d user/$to/INBOX");

if ($domain eq "") {
       $username=$source;
} else {
       $username="$source\@$domain";
}

sub smtp
{
	my ($host, $from, $to, $subject, $thread_ref, $previous_id) = @_;
	if("$subject" eq "") { $subject = "Re: bug verification strategy discussion"; }

	$smtp = Net::SMTP->new("$host", Port => $port, Debug => $debug);
	$smtp->auth("$from","$from");
	$smtp->mail("$from");
	$smtp->to("$to");
	$smtp->data();
	$smtp->datasend("From: $from\n");
	$smtp->datasend("To: $to\n");
	$smtp->datasend("Subject: $subject\n");
	$smtp->datasend("References: $thread_ref\n") if("$thread_ref" ne "");
	$smtp->datasend("In-Reply-To: $previous_id\n") if("$previous_id" ne "");
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

sub imap_getMessageId
{
	my ($host, $user, $msg_seq_no) = @_;
	my @msg_id = "";
	my @ref_id = "";
	my $thread_ref = "";

	$imap = Mail::IMAPClient->new(Server => "$host",Port => 143, Debug => $debug, User => $user, Password => $user);
        $imap->select("INBOX");
	$msgcount = $imap->message_count("INBOX");
	print "==== No. of Messages: $msgcount\n";
	for(my $i=$msg_seq_no;$i<=$msgcount;$i++){
		$msg_id[$i] = $imap->get_header($i, "Message-Id");
		$thread_ref = "$thread_ref" . "$msg_id[$i]";
		print "==== msg_id[$i] : $msg_id[$i]\n";
		print "thread_ref after $i loop : $thread_ref\n";
		if($i > 23) { last; }
	}
	$imap->logout();
	print "==== thread_ref : $thread_ref\n";
	return $thread_ref;
}

sub imap_getMessageThreadRef
{
        my ($host, $user, $msg_seq_no) = @_;
        my $thread_ref = "";
        $imap = Mail::IMAPClient->new(Server => "$host",Port => 143, Debug => $debug, User => $user, Password => $user);
        $imap->select("INBOX");
        $thread_ref = $imap->get_header($msg_seq_no,"Refrences");
        $msg_id = $imap->get_header($msg_seq_no,"Message-Id");
        $imap->logout();
        print "==== thread_ref : $thread_ref\n";
        print "==== msg_id : $msg_id\n";
        return ($thread_ref,$msg_id);
}

sub main()
{
	smtp($host, $from, $to, "bug verification strategy discussion");
	sleep(1);
	for(my $j=1;$j<=$num_of_messages;$j++){
		($ref,$previous_id) = imap_getMessageThreadRef($host, $to, $j);
		chomp($ref);
		chomp($previous_id);
		$thread = "$ref" . "$previous_id";
		smtp($host, $from, $to, "Re: bug verification strategy discussion", $thread, $previous_id);
		for(my $i=$j;$i<=($j+15);$i++){
			$ref = imap_getMessageId($host, $to, $j);
			smtp($host, $from, $to,"Re: bug verification strategy discussion", $ref, $previous_id);
			sleep(1);
		}
	}
	return 1;
}

main(); 
