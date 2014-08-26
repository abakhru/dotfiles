#!/usr/bin/perl

use Mail::IMAPClient;
use IO::File;

$GENV_MSHOME1="/opt/sun/comms/messaging64";
#$debug="1";
$debug="1";
$test_ID=$ARGV[0];
($test,$id) = split("0",$test_ID, 2);
#$username="readeruser"."$id";
$username="neo1";
$password=$username;
system("$GENV_MSHOME1/sbin/mboxutil -d -P \'\\S*\'");
$OUTPUT = IO::File->new(">./$test_ID.out") or die "Can't open ./$test_ID.out: $!\n";

sub response {
	($hash_ref) = @_;
	my @options = "";
	%hash = %$hash_ref;
	foreach $k (keys %hash) {
		push(@options,"$k: $hash{$k}");
	}
	return @options;
}

sub get_acl {
	($folder) = @_;
	print "\n==== ACL for folder:\"$folder\" is ====\n";
	my $hash = $imap->getacl("$folder");
	my @list = response($hash);
	foreach $LIST (@list){
		($field1, $field2) = split(":","$LIST");
		if($field1){
			print "$field1 => $field2\n";
		}
	}
	return @list;
}

sub set_acl {
	($folder,$userid,$authstring) = @_;
	print "\n====Setting ACL for folder:\"$folder\" and user:\"$userid\" ====\n";
	$imap->setacl($folder,$userid,$authstring);
	@res = $imap->Results();
	print "$res[0]\n";
	return @res;
}

sub list_rights {
        ($folder,$userid) = @_;
	print "\n====Listing rights for folder:\"$folder\" and user:\"$userid\" ====\n";
        $imap->listrights($folder,$userid);
        @res = $imap->Results();
        print "$res[1]\n";
        return @res;
}

sub delete_acl {
        ($folder,$userid) = @_;
        print "\n====Deteling ACL for folder:\"$folder\" and user:\"$userid\" ====\n";
        $imap->deleteacl($folder,$userid);
        @res = $imap->Results();
        print "@res\n";
        return @res;
}

sub my_rights {
        ($folder) = @_;
        print "\n==== Displaying MYRIGHTS for folder:\"$folder\" ====\n";
        $imap->myrights($folder);
        @res = $imap->Results();
        print "@res\n";
        return @res;
}

$imap = Mail::IMAPClient->new(Server => "localhost",Port => "143", Debug => "1", User => $username, Password => $password);
$imap->create("Drafts");
$imap->create("Sents");
$imap->create("Trash");
$imap->create("ABCD");
system("$GENV_MSHOME1/bin/deliver -a $username -m \"ABCD\" -c -F $username < /space/src/msg_next/msg/test/tle/aclTesting/../deliver/text");

if($test_ID =~ /57/) {
	@res = set_acl("ABCD","neo2","lrwicdalrwicdalrwicdalrwicdalrwicdalrwicdalrwicdalrwicdalrwicda ");
	@res = get_acl("ABCD");
} elsif($test_ID =~ /56/) {
	@res = list_rights("ABCD","$username");
} elsif($test_ID =~ /58/) {
	@res = set_acl("ABCD","neo2","lrqswicda");
} elsif($test_ID =~ /59/) {
	@res = set_acl("ABCD","neo2","lrQswicda");
} elsif($test_ID =~ /60/) {
	@res = get_acl("ABCD");
	@res = delete_acl("ABCD","$username");
	@res = list_rights("ABCD", "$username");
	@res = my_rights("ABCD", "$username");
	@res = get_acl("ABCD");
} elsif($test_ID =~ /55/) {
	@res = my_rights("ABCD","$username");
} elsif($test_ID =~ /54/) {
	@res = get_acl("ABCD");
} elsif($test_ID =~ /53/) {
	@res = set_acl("ABCD","neo2","+cda");
	@res = get_acl("ABCD");
	@res = delete_acl("ABCD", "neo2");
} elsif($test_ID =~ /52/) {
	@res = set_acl("ABCD","neo2","+cda");
	@res = get_acl("ABCD");
} elsif($test_ID =~ /47/) {
	@res = set_acl("ABCD","neo2","lrwicda");
	@res = set_acl("ABCD","domreaderuser4","+cda");
	@res = get_acl("ABCD");
	@res = set_acl("ABCD","-neo2", "k");
	@res = get_acl("ABCD");
} elsif($test_ID =~ /45/) {
	@res = $imap->capability;
} elsif($test_ID =~ /48/) {
        #create mailbox permission "k"
        @res = set_acl("ABCD","neo2","+lrk");
        @res = get_acl("ABCD");
        print "Logging in second user:neo2\n";
        $imap2 = Mail::IMAPClient->new(Server => "bakhru.us.oracle.com",Port => "143", Debug => "1", Debug_fh => $OUTPUT, User => "neo2", Password => "neo2");
        @res = $imap2->list(""); print @res;
        $imap2->select("Shared Folders/User/$username/ABCD"); @res = $imap2->Results(); print @res;
        @res = $imap2->create("Shared Folders/User/$username/ABCD/ACLUSERFOLDER");  @res = $imap2->Results(); print @res;
        $imap2->select("Shared Folders/User/$username/ABCD/ACLUSERFOLDER"); @res = $imap2->Results(); print @res;
        $imap2->logout;
} elsif($test_ID =~ /49/) {
	#expung and expunge as part of close permission "e"
        @res = set_acl("ABCD","neo2","+lre");
        @res = get_acl("ABCD");
        print "Logging in second user:neo2\n";
        $imap2 = Mail::IMAPClient->new(Server => "bakhru.us.oracle.com",Port => "143", Debug => "1", Debug_fh => $OUTPUT, User => "neo2", Password => "neo2");
        @res = $imap2->list(""); print @res;
        $imap2->select("Shared Folders/User/$username/ABCD"); @res = $imap2->Results(); print @res;
        @string = $imap2->message_string(1); print "=========== Message No. 1:\n"; print $OUTPUT @string;
        @res = $imap2->store(1, '+FLAGS (\Deleted)' ); print @res;
        my @results = $imap2->History( $imap2->Transaction ); print @resulsts;
        $imap2->expunge;
        $imap2->select("Shared Folders/User/$username/ABCD"); @res = $imap2->Results(); print @res;
        $imap2->logout;
} elsif($test_ID =~ /50/) {
	#Delete messages permission "t"
        @res = set_acl("ABCD","neo2","+lrt");
        @res = get_acl("ABCD");
        print "Logging in second user:neo2\n";
        $imap2 = Mail::IMAPClient->new(Server => "bakhru.us.oracle.com",Port => "143", Debug => "1", Debug_fh => $OUTPUT, User => "neo2", Password => "neo2");
        @res = $imap2->list(""); print @res;
        $imap2->select("Shared Folders/User/$username/ABCD"); @res = $imap2->Results(); print @res;
        @string = $imap2->message_string(1); print "=========== Message No. 1:\n"; print @string;
        @res = $imap2->store(1, '+FLAGS (\Deleted)' ); print @res;
        my @results = $imap2->History( $imap2->Transaction ); print @results;
        $imap2->expunge;
        $imap2->select("Shared Folders/User/$username/ABCD");
	@res = $imap2->Results(); print @res;
        $imap2->logout;
} elsif($test_ID =~ /51/) {
	#Delete mailbox permission "x"
	system("$GENV_MSHOME1/bin/deliver -a neo2 -m \"ABCD\" -c -F neo2 < /space/src/msg_next/msg/test/tle/aclTesting/../deliver/text");
	@res = set_acl("ABCD","neo2","+lrx");
	@res = get_acl("ABCD");
	print "Logging in second user:neo2\n";
	$imap2 = Mail::IMAPClient->new(Server => "bakhru.us.oracle.com",Port => "143", Debug => "1", User => "neo2", Password => "neo2");
	@res = $imap2->list(""); print @res;
	$imap2->select("Shared Folders/User/$username/ABCD"); @res = $imap2->Results(); print @res;
	#$imap2->copy("1","INBOX"); @res = $imap2->Results(); print @res;
	$imap2->copy("INBOX","1"); @res = $imap2->Results(); print @res;
	#@res = $imap2->delete("Shared Folders/User/$username/ABCD");  @res = $imap2->Results(); print @res;
	$imap2->logout;
}
if(@res =~ /NO/){
       	print "==== $test_ID PASSED ====\n";
	$imap->logout;
      	return 0;
}elsif("@res" =~ /OK/){
       	print "==== $test_ID PASSED ====\n";
}
#close($OUTPUT);
$imap->logout;
