#!/usr/bin/perl
use Net::LDAP;
use Net::LDAP::LDIF;

$result=1;
$user="kiwong4";
#$ldap = Net::LDAP->new( "lickitung.sfbay.sun.com", debug => 3, version => 3 ) or die "$@";
$ldap = Net::LDAP->new( "lickitung.sfbay.sun.com") or die "$@";
$DN="uid=$user,ou=people,o=sfbay.sun.com,o=usergroup";
$Password=$user;
$mesg = $ldap->bind ( "$DN", password => "$Password", version => 3);

#for deleting all the users
$mesg = $ldap->search ( base  => "o=usergroup", scope => "subtree", filter  => "(cn=ami*)");
foreach $entry ($mesg->entries) {$entry->dump;}
#Net::LDAP::LDIF->new( \*STDOUT,"w" )->write( $mesg->entries );
$mesg = $ldap->unbind;   # take down session
