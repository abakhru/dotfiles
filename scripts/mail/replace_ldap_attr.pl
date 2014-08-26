#!/usr/bin/perl
use Net::LDAP;
use Net::LDAP::LDIF;

#########################################################################################
# This script will replace existing 'cn' entry in ldap with same-user's 'mail' entry
# value, for all users.
#########################################################################################

$result=1;
$ldap = Net::LDAP->new( "greenmeadow.red.iplanet.com") or die "$@";
$BindDN="cn=directory manager";
$Password=password;
$mesg = $ldap->bind ( "$BindDN",
		       password => "$Password",
		       version => 3
		    );

$mesg = $ldap->search ( base  => "o=red.iplanet.com,o=usergroup", scope => "subtree", filter  => "(uid=*)");
foreach $entry ($mesg->entries) {
	$mail = $entry->get_value ( 'mail' );
	print "MAIL = $mail\n";
	$dn = $entry->dn();
	print "DN = $dn\n\n";
	$mesg = $ldap->modify( $dn, replace => { 'cn' => "$mail" } );
	$entry->update($ldap);
}
$ldap->unbind;   # take down session
