#!/usr/bin/perl
use Net::IMAP;
use Net::Cmd;
use Mail::IMAPClient;

$user="neo2";
sub response {
	($hash_ref) = @_;
	print "hash_ref : $hash_ref\n";
	%hash = %$hash_ref;
	foreach my $k (keys %hash) {
		if($k eq "Text") {
			print "$k: $hash{$k}\n";
			#print "$hash{$k}\n";
		}
	}	
	return 1;
}

sub login {
	my ($user,$pass) = @_;
	my $imap = Mail::IMAPClient->new(Server => "localhost",Port => 143, User => $user, Password => $pass, Debug => 0);
	#print "$@\n"; #(if imap login fails $@ contains the last error message"
	if($imap) {
		$res = $imap->Results();
		return $res;
	} else {
		my @a = $@;
#		print "A = @a\n";
		return \@a;
	}
}

#my $imap = Net::IMAP->new("bakhru.us.oracle.com",Port => 143, Debug => 0);
#my $imap = login("edsuser2\@eds001.com","edsuser2");
#if("@$imap" !~ /NO/) {
#	#print "Res 1 : @$imap\n";
#	print "Expectation failed with final output @$imap\n";
#}else { 
#	print "PASS Res 1 : @$imap\n"; 
#}
#my $imap = login("edsuser2\@eds002.com","edsuser2");
#print "Res 2 : @$imap\n";
#my $imap = Mail::IMAPClient->new(Server => "rabid.sfbay.sun.com",Port => 143, User => "edsuser2\@eds002.com", Password => "edsuser2", Debug => 0);
#print "$@\n"; #(if imap login fails $@ contains the last error message"
#$res = $imap->Results();
#response($res);
#@results = $imap->select("inbox");
#print "Res : @results\n";
##response($res);
#$res = $imap->fetch(1,"body[text]");
#print "Res : @$res\n";
#response($res);
#$imap = Mail::IMAPClient->new(Server => "algy.us.oracle.com",Port => 143, Debug => 0, User => "neo1", Password => "neo1");
$imap = Mail::IMAPClient->new(Server => "localhost",Port => 143, Debug => 1, User => $user, Password => $user);
if (!$imap) {
	print "Connection failed\n";
	@ImapResponse = $@;
	print "========= Res : @ImapResponse \n";
} else {
	@ImapResponse = $imap->Results();
	print "========= Res : @ImapResponse \n";
}
if ("@ImapResponse" =~ /NO/) {
                print "IMAP login failed in test $testId.\nReceived: @ImapResponse\n";
                exit 0;
}
if ("@ImapResponse" =~ /User logged in/) {
	print "PASSED\n";
}
#@ImapResponse = $imap->authenticate("PLAIN","neo1");
#print "========= Res : @ImapResponse\n";
#print "Res : @res\n";
#@res = $imap->select("INBOX");
#$a = $imap->message_count("INBOX");
if($a) {
	$imap->select("INBOX");
	$newUid = $imap->move("folder1","12");
	print $imap->Results();
	$newUid = $imap->move("folder1/folder11","1");
	print $imap->Results();
	$newUid = $imap->move("folder1/folder11","2");
	print $imap->Results();
	$newUid = $imap->move("folder1/folder11/folder111","4");
	print $imap->Results();
}
#	$value = "SPAM";
#	$header = "Spam-test";
#	my @msgs = $imap->messages();
#	int($nextUid = $imap->uidnext("INBOX"));
#	print "nextuid = $nextUid\n";
	#if($header eq "Subject"){
	#my $subject = $imap->subject(--$nextUid);
#	my @flags = $imap->flags(--$nextUid);
#	print "======= Message Flags: @flags\n";
	#print "======= Subject: $subject\n";
	#		if ($subject =~ /$value/) {
	#			print "Value Matched\n";
	#		}
	#		else {
	#			print "Value not FOUND\n";
	#		}
	#}elsif($header eq "Spam-test"){
	#	my $header_value = $imap->get_header( --$nextUid, "$header" );
        #        print "$header : $header_value\n";
        #        if(length($header_value) ne 0) {
        #                print "=== Header FOUND\n";
        #        }
	#}
#	print "==== @msgs\n";
#	my $a = scalar(@msgs);
#	print "==== EXISTS : $a\n";
#	my @unread = $imap->unseen;
#	print "==== @unread\n";
#	$a = scalar(@unread);
#	print "==== UNSEEN : $a\n";
	#for(my $i=0;$i<scalar(@msgs);$i++) {
#@string = $imap->message_string(1);
#print "=========== Message No. 1:\n";
#print @string;
	#}
	#$imap->delete_message(\@msgs);
	#$imap->expunge();
#}
#$a = $imap->message_count("INBOX");
#print "============== No of MESSAGES after EXPUNGE = $a\n";
#print "Res : @res\n";
#$imap->copy("1:$a","mbox");
#@res = $imap->copy("mbox","1:$a");
#print "Res copy: @res\n";
#@res = $imap->Results();
#print "===================== Response: @res\n";
#$imap->list();
#$imap->listrights("INBOX","neo2");
$imap->select("INBOX");
#my @seenMsgs = $imap->seen();
#print "Seen Messages: @seenMsgs\n";
$imap->flags("1:*");
#print "Flags : @flags\n";
$imap->logout();
#@res = $imap->Results();
#print "logout response : @res\n";
