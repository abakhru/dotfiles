#!/usr/bin/perl

use Net::LDAP;
use Authen::SASL;

if (@ARGV < 2)
{
  print ("\nUsage: ./ldap_sasl_external.pl user <user_to_search>\n\n");
  exit;
}

$user=$ARGV[0];
$search=$ARGV[1];
# UW Person Directory Service config
$ldaphost = "lickitung.sfbay.sun.com";	
$baseDN = "o=usergroup";
$filter = "uid=$search*";

# SASL EXTERNAL authentication config
$tls_cacert = "/opt/certs/newcerts/cacert.pem";
$tls_cert = "/opt/certs/newcerts/$user-cert.pem";
$tls_key  = "/opt/certs/private/$user-key.pem";

$ldap = Net::LDAP->new($ldaphost, debug => 0) or die "$@";

$mesg = $ldap->start_tls(
        verify => 'require'
        , clientcert => $tls_cert
        , clientkey => $tls_key
	, keydecrypt => sub { 'password'; },
        , cafile => $tls_cacert
        );

$mesg->code && die $mesg->error;

$sasl = Authen::SASL->new(
          mechanism => 'EXTERNAL'
        , callback => { user => '' }
        ) or die "$@";

$mesg = $ldap->bind(sasl => $sasl);
$mesg->code && die $mesg->error;
$result = $ldap->search(
          base => $baseDN
        , filter => $filter
        );

$result->code && warn "failed to find entry: ", $result->error;
foreach $entry ($result->entries) {
                $entry->dump;
        }
$mesg = $ldap->unbind;
