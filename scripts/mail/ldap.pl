#!/opt/perl5.10/bin/perl
use Net::LDAP;
use Net::LDAP::LDIF;


$host = "marceau.us.oracle.com";
$BindDN="cn=directory manager";
$ldap = Net::LDAP->new( "$host", debug => 1);
$mesg = $ldap->bind ( "$BindDN", password => "password", version => 3);

#import_ldif("/space/src/results/imap_response/user_pwd_policy.ldif");
#ldapsearch("$ARGV[0]");
#ldapmodify("response7");

sub ldapmodify {
	my ($user) = @_;
	$def = $ldap->search ( base => "o=usergroup", scope => "subtree", filter => "(uid=$user)");
	foreach $entry ($def->entries) {
               $dn=$entry->dn();
               print "Adding pwdPolicySubentry for user = $dn ";
               $entry->add ({pwdPolicySubentry => "cn=TempPolicy,o=usergroup"});
               $entry->update ($ldap);
        }
        $def = $ldap->unbind;
}

sub ldapdelete {
	my ($user) = @_;
	#for deleting all the users
	$mesg = $ldap->search(base => "o=usergroup", filter => "uid=$user");
	foreach $entry ($mesg->entries) {
		if($entry->exists("usercertificate;binary")){
               		print "Removing userCertificate Binary for user = $user\n";
			$entry->delete("usercertificate;binary");
			$entry->update($ldap);
		}
		if($entry->exists("userCertificate")){
			print "Cert deletion FAILED\n";
		}
	        #$ldap->delete($entry);
		#$entry->dump();
	}
	$ldap->unbind();
	return 1;
}

sub delete_domain {
	my ($domain) = @_;
	$sieve = $ldap->search ( base  => "o=usergroup", scope => "base", filter  => "(o=$domain.com)");
	$ldap->delete($sieve);
}

#sub ldap_add_attr() {
#	#for adding mailsieverulesource attribute to logaction13 users
#	$mesg = $ldap->search ( base  => "dc=sfbay,dc=sun,dc=com", scope => "subtree", filter  => "(uid=logaction13)" );
#	foreach $entry ($mesg->entries) {
#                $dn=$entry->dn();
#                print "Adding mailsieverulesource for user = $dn ";
#                $entry->add ( mailsieverulesource => "require [\"fileinto\",\"body\"]; if header :contains [\"return-path\",\"from\",\"resent-from\",\"sender\",\"resent-sender\"] [\"siroe.com\"] { fileinto \"QMSG\"; } if header :contains [\"return-path\",\"from\",\"resent-from\",\"sender\",\"resent-sender\"] [\"xyz\"] {redirect \"logaction14\@sieve.com\";} if body :contains \"VIRUS\" { addtag \"BODYSPAMDETECTED\"\; }" );
#                $entry->update ($ldap);
#       }
#       $mesg = $ldap->unbind;
#       $mesg->code && die $mesg->error;
#	if ($entries->exists("user3") {
#		print "ABCD\n";
#	}
#}

#foreach $entry ($mesg->entries) {$entry->dump;}
#Net::LDAP::LDIF->new( \*STDOUT,"w" )->write( $mesg->entries );
#$mesg = $ldap->unbind;   # take down session

#Executing ldapsearch cli comand:
# /opt/sun/dsee7/dsrk/bin/ldapsearch -D"cn=directory manager" -w password -b "o=mlusers" "(&(objectClass=inetMailingListSubscription)(mlsubListIdentifier=m1259876544.3341-192.18.127.81))"
#/opt/sun/dsee7/dsrk/bin/ldapsearch -D "cn=directory manager" -w password -b "o=usergroup" "(uid=*)" "userPassword"

#Importing LDIF file into LDAP Server
sub import_ldif {
	my ($ldap_file) = @_;
	my $ldap = Net::LDAP->new( "marceau.us.oracle.com", debug => 3) or die "$@";
	my $BindDN="cn=directory manager";
	my $mesg = $ldap->bind ( "$BindDN", password => "password", version => 3);

	my $ldif = Net::LDAP::LDIF->new("$ldif_file", "r", onerror => 'undef' );
	my $entry = Net::LDAP::Entry->new();

	## Loop until the end-of-file.
	while ( ! $ldif->eof() ) {
    		$entry = $ldif->read_entry();
      
    		## Skip the entry if there is an error. 
    		if ( $ldif->error() ) {
        		print "Error msg: ", $ldif->error(  ), "\n";
        		print "Error lines:\n", $ldif->error_lines(  ), "\n";
        		next;
    		}
      
    		## Log to STDERR and continue in case of failure.
    		$result = $ldap->add( $entry );
    		warn $result->error( ) if $result->code( );
	}
	return 1;
}

sub ldapsearch {

	my ($user) = @_;
	$mesg = $ldap->search ( base  => "o=usergroup", scope => "subtree", filter  => "(uid=$user)" );
	foreach $entry ($mesg->entries) {
		$entry->dump;
	#	$ref = $entry->get_value ( "pwdChangedTime", alloptions => 1 );
	#	print "\t  pwdChangedTime: $ref\n";
	#	$ref1 = $entry->get_value ( "pwdreset", alloptions => 1 );
	#	print "\t  pwdreset: $ref1\n";
	#	$ref1 = $entry->get_value("userCertificate;binary", alloptions => 1);
	#	print "\t  userCertificate;binary: $ref1\n";
	}
	$ldap->unbind();
	return 1;
}

ldapdelete("neo2");
