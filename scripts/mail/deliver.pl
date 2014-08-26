#!/usr/bin/perl
require Mail::IMAPClient;

$GENV_MSHOME1="/opt/sun/comms/messaging64";
$username="neo2";
$mailbox="INBOX";
$flag="Answered";

#system("$GENV_MSHOME1/sbin/mboxutil -d user/$username/inbox");

my $imap = Mail::IMAPClient->new(Server => "localhost",Port => 143, Debug => 1, User => "$username", Password => "$username");
$imap->logout;
#print "su mailsrv -c \"$GENV_MSHOME1/bin/deliver neo1 -g \\\\Answered $username < /space/src/msg_next/msg/test/tle/deliver/text\"";
#system("su mailsrv -c \"$GENV_MSHOME1/bin/deliver neo1 -g \\\\Answered $username < /space/src/msg_next/msg/test/tle/deliver/text\"");
print "$GENV_MSHOME1/bin/deliver neo1 -g \"\\Amit\" $username < /space/src/msg_next/msg/test/tle/deliver/text\n";
#system("$GENV_MSHOME1/bin/deliver neo1 -g \"\\Amit\" $username < /space/src/msg_next/msg/test/tle/deliver/text");
system("$GENV_MSHOME1/bin/deliver neo1 -g \\\\Amit $username < /space/src/msg_next/msg/test/tle/deliver/text");
#get_mail($mailbox);

sub get_mail(){
	print "==== MAILBOX = $mailbox\n";
	my $imap = Mail::IMAPClient->new(Server => "bakhru.us.oracle.com",Port => 143, Debug => 1, User => "$username", Password => "$username");
	$imap->select($mailbox);
	#int($nextUid = $imap->uidnext($mailbox));
        #@Lines = $imap->flags(--$nextUid); print @Lines;
	#my @msgs  = $imap->search("Seen"); print @msgs;
	#$flags = "\\Answered \\Seen";
	#my $uidort = $imap->append_string( $mailbox, "From:neo1\nTo:neo2\nSubject:Hello" ,$flags ) or die "Could not append_string: ", $imap->LastError;
	my @msgs  = $imap->search("Answered"); print @msgs;
	my @seenMsgs = $imap->seen or warn "No seen msgs: $@\n"; @Res = $imap->Results(); print "Res : @Res\n";
	$imap->flags("1");
	$imap->logout;
	return 1;
}
