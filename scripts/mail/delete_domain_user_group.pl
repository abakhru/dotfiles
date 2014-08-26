#!/usr/bin/perl
use Net::LDAP;
use Net::Domain qw(hostname hostfqdn hostdomain);

$GENV_OSIROOT="o=usergroup";
$GENV_DCROOT="o=internet";
$GENV_MSHOST1=hostname();
$GENV_DOMAIN=hostdomain();
$GENV_DMPASSWORD="password";

if (@ARGV < 2) {
	print ("\nUsage: ./rmtree.pl <username> <domainname>\n\n");
	exit 0;
}
else {
	$user = $ARGV[0];
	$domain = $ARGV[1];
	USR_DeleteDomains($domain);
	#USR_DeleteUsers($user);
}

sub USR_DeleteDomains {
        my ($DN) = @_;
        my $ldap = Net::LDAP->new( "$GENV_MSHOST1.$GENV_DOMAIN", debug => 1, version => 3 ) or die "$@";
	my $result = $ldap->bind( "cn=Directory Manager", password => $GENV_DMPASSWORD);
	if($DN =~ /\./) {
		print "DN = $DN\n";
                ($field1,$field2,$field3) = split '\.', $DN;
		if($field3 eq "" ){
        		DeleteLdapTree($ldap, "o=$field1.$field2,$GENV_OSIROOT");
			DeleteLdapTree($ldap, "dc=$field1,dc=$field2,$GENV_DCROOT");
		}else {
        		DeleteLdapTree($ldap, "o=$field1.$field2.$field3,$GENV_OSIROOT");
			DeleteLdapTree($ldap, "dc=$field1,dc=$field2,dc=$field3,$GENV_DCROOT");
		}
        } else {
        	DeleteLdapTree($ldap, "o=$DN.com,$GENV_OSIROOT");
		DeleteLdapTree($ldap, "dc=$DN,dc=com,$GENV_DCROOT");
	}
        $ldap->unbind();
        return 0;
}

sub DeleteLdapTree {
    my ($handle, $dn) = @_;
    my ($result);

    print "================ Deleting DN =  $dn =================== \n";
    $msg = $handle->search( base => $dn, scope => one, filter => "(objectclass=*)" );
    if ( $msg->code() ) {
        $msg->error();
        return;
    }

    foreach $entry ($msg->all_entries) {
        DeleteLdapTree($handle, $entry->dn());
    }

    $result = $handle->delete($dn);
    warn $result->error() if $result->code();

    print "Removed $dn \n";
    return;
}

sub USR_DeleteUsers {
        my ($uid) = @_;
        print "================ Deleting the existing $uid* users from ldap ===============  \n";
        my $ldap = Net::LDAP->new( "$GENV_MSHOST1.$GENV_DOMAIN", debug => 0, version => 3 ) or die "$@";
        my $mesg = $ldap->bind ( "cn=Directory Manager", password => $GENV_DMPASSWORD, version => 3 ) or die "$@";
        my $mesg = $ldap->search ( base  => "$GENV_OSIROOT", filter  => "uid=$uid*");
        foreach $entry ($mesg->entries) { $ldap->delete($entry); }
        $mesg = $ldap->unbind;
        return;
}

sub USR_DeleteGroups {
        my ($group) = @_;
        print "================= Deleting the existing $group* groups from ldap ================= \n";
        my $ldap = Net::LDAP->new( "$GENV_MSHOST1.$GENV_DOMAIN", debug => 0, version => 3 ) or die "$@";
        my $mesg = $ldap->bind ( "cn=Directory Manager", password => $GENV_DMPASSWORD, version => 3 ) or die "$@";
        my $mesg = $ldap->search ( base  => "$GENV_OSIROOT", filter  => "cn=$group*");
        foreach $entry ($mesg->entries) { $ldap->delete($entry); }
        $mesg = $ldap->unbind;
        return;
}
