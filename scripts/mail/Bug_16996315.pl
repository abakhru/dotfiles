#!/usr/bin/perl
use Mail::IMAPClient;

$user=$ARGV[0];

sub create_folders()
{
	$imap = Mail::IMAPClient->new(Server => "localhost",Port => 143, Debug => 1, User => $user, Password => $user);
	$imap->select("INBOX");
	$imap->create("LongFolderName0");
	for(my $i=1;$i<=8;$i++){
		$imap->create("LongFolderName$i");
		for(my $j=0;$j<10;$j++){
			$imap->create("LongFolderName$i/LongSubFolderName$j");
			for(my $k=0;$k<10;$k++){
				$imap->create("LongFolderName$i/LongSubFolderName$j/LongSubSubFolderName$k");
			}
		}
	}
	$imap->logout();
	return 1;
}

sub AddUsers {
        my ($username, $domain, $thehost) = @_;
        if(length($domain) == 0){
                $domain = $GENV_DOMAIN;
        }
        print "==== Deleting $username users on ldap_server:$GENV_DSHOST1.$GENV_DOMAIN & domain:$domain ====\n";
        DeleteUsers($username);
        print "==== Adding $username users on ldap_server:$GENV_DSHOST1.$GENV_DOMAIN & domain:$domain & host $thehost ====\n";
        $ldap = Net::LDAP->new("$GENV_DSHOST1.$GENV_DOMAIN", $debug => "1");
        $mesg = $ldap->bind("cn=Directory Manager", password => "$GENV_DMPASSWORD", version => 3);

        for(my $i=1; $i<=1; $i++)
        {
                my $uid = "$username";
                my $entry = Net::LDAP::Entry->new;
                $entry->dn("uid=$uid, ou=People, o=$domain, $GENV_OSIROOT");
                $entry->changetype("add");
                $entry->add( 'objectclass' => ['top', 'person', 'userPresenceProfile', 'inetUser','ipUser','inetMailUser',
                                'inetLocalMailRecipient', 'icscalendaruser', 'icscalendardomain',
                                'iplanet-am-auth-configuration-service','organizationalPerson', 'inetOrgPerson'],
                                'cn'   => "$uid $uid",
                                'sn'   => "$uid",
                                'mail' => "$uid\@$domain",
                                'mailuserstatus' => 'active',
                                'mailquota' => '-1',
                                'mailhost' => "$GENV_MSHOST1.$GENV_DOMAIN",
                                'initials' => "$uid",
                                'givenname' => "$uid",
                                'uid' => "$uid",
                                'mailmsgquota' => '-1',
                                'maildeliveryoption' => 'mailbox',
                                'preferredlanguage' => 'en',
                                'nswmextendeduserprefs' => 'meDraftFolder=Drafts',
                                'nswmextendeduserprefs' => 'meSentFolder=Sent',
                                'nswmextendeduserprefs' => 'meTrashFolder=Trash',
                                'nswmextendeduserprefs' => 'meInitialized=true',
                                'mailAllowedServiceAccess' => '+imap,pop,http,smtp,imaps,smtps,pops,https:*',
                                'inetuserstatus' => 'active',
                                'userpassword' => "$uid",
                                'icsStatus' => 'active',
                        );
                $entry->update($ldap);
                my $dn = $entry->dn();
                print "Adding user $dn\n";
        }#for loop ends
        $ldap->unbind();
        return 1;
}

sub DeleteUsers {
        my ($uid) = @_;
        print "==== Deleting the existing $uid* users from ldap ====\n";
        my $ldap = Net::LDAP->new("$GENV_DSHOST1.$GENV_DOMAIN", debug => 0, version => 3 ) or die "$@";
        my $mesg = $ldap->bind("cn=Directory Manager", password => $GENV_DMPASSWORD, version => 3 ) or die "$@";
        my $mesg = $ldap->search(base => "$GENV_OSIROOT", filter => "uid=$uid*");
        foreach $entry ($mesg->entries) {
                $ldap->delete($entry);
                my $dn = $entry->dn();
        }
        $mesg = $ldap->unbind;
        return;
}

sub smtp
{
        my ($host, $from, $to, $subject) = @_;
        $smtp = Net::SMTP->new("$host", Port => "25", Debug => 0);
        $smtp->auth("$from","$from");
        $smtp->mail("$from");
        $smtp->to("$to");
        $smtp->data();
        $smtp->datasend("From: $from\n");
        $smtp->datasend("To: $to\n");
        $smtp->datasend("Subject: $subject\n");
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
print "==== Cleaning $user 's mailbox on localhost\n";
system("$GENV_MSHOME1/sbin/mboxutil -d -P \'\\S*\'");
print "====  about to delete/create \"$user\" named user\n";
AddUsers($user, $GENV_DOMAIN, $GENV_DSHOST1.$GENV_DOMAIN);
print "==== Creating folders for $user\n";
create_folders();
$a = LOL_CompareOutput("output3", "Test069_a.exp", "-b");
print "\n==== TESTCASE PASSED ====\n\n" if($a);
print "\n==== TESTCASE FAILED ====\n\n" unless($a);
