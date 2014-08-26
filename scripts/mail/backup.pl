#!/usr/bin/perl
require Mail::IMAPClient;

$GENV_MSHOME1="/opt/sun/comms/messaging64";
$username="neo2";
$mailbox="folder1\/folder11\/folder111";
unlink("/tmp/$username.backup");
system("$GENV_MSHOME1/sbin/mboxutil -d user/$username/inbox");
system("$GENV_MSHOME1/sbin/mboxutil -c \'user/$username/$mailbox\'");
system("./SASL.pl f:text bakhru.us.oracle.com neo1 $username 10");
imap_move();
get_mail($mailbox);
system("$GENV_MSHOME1/sbin/imsbackup -v -f /tmp/$username.backup /primary/user/$username");
system("$GENV_MSHOME1/sbin/mboxutil -d user/$username/inbox");
system("$GENV_MSHOME1/sbin/imsrestore -g -f /tmp/$username.backup /primary/user/$username");
sleep(2);
get_mail($mailbox);

sub imap_move(){
	
	my $imap = Mail::IMAPClient->new(Server => "bakhru.us.oracle.com",Port => 143, Debug => 0, User => "$username", Password => "$username");
	if (!$imap) {
        	print "Connection failed: $@\n";
	} else {
		@res = $imap->Results();
        	print "========= Res : @res\n";
	}
	$a = $imap->message_count("INBOX");
	if($a) {
        	$imap->select("INBOX");
     		$newUid = $imap->move("folder1/folder11","1"); @res = $imap->Results(); print "==== Res: @res\n";
   		$newUid = $imap->move("folder1/folder11","2"); @res = $imap->Results(); print "==== Res: @res\n";
		$newUid = $imap->move("folder1/folder11/folder111","3");@res = $imap->Results(); print "==== Res: @res\n";
      		$newUid = $imap->move("folder1/folder11/folder111","4"); @res = $imap->Results(); print "==== Res: @res\n";
        	$newUid = $imap->move("folder1","6"); @res = $imap->Results();@res = $imap->Results(); print "==== Res: @res\n";
        	$newUid = $imap->move("folder1","5"); @res = $imap->Results();@res = $imap->Results(); print "==== Res: @res\n";
	}
	$imap->expunge;
	$imap->logout;
	return 1;
}

sub get_mail(){
	print "==== MAILBOX = $mailbox\n";
	my $imap = Mail::IMAPClient->new(Server => "bakhru.us.oracle.com",Port => 143, Debug => 0, User => "$username", Password => "$username");
	$a = $imap->message_count("$mailbox");@res = $imap->Results(); print "==== Res: @res\n";
	unless($a){
		$a=0;
	}
	print "==== \"$username\" has \"$a\" no. of messages in mailbox: \"$mailbox\"\n";
	$imap->logout;
	return 1;
}
