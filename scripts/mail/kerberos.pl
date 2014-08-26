#!/usr/bin/perl
#!/usr/local/bin/perl -w    

# How to connect to an LDAP server using GSSAPI Kerberos auth.    

use strict;    

use Net::LDAP;
use Authen::SASL qw(Perl);
# This module makes doing the kinit much easier
use Authen::Krb5::Easy qw(kinit kdestroy kerror);    

# Location of the keytab which contains testuser's key
# exported in kadmin by: ktadd -k /tmp/test.keytab testuser
my $keytab = '/tmp/test.keytab';
# Where to store the credentials
my $ccache = '/tmp/test.ccache';    

$ENV{KRB5CCNAME} = $ccache;    

# Get credentials for testuser
kinit($keytab, 'testuser@CS.UKC.AC.UK') || die kerror();    

# Set up a SASL object
my $sasl = Authen::SASL->new(mechanism => 'GSSAPI') || die "$@";    

# Set up an LDAP connection
my $ldap = Net::LDAP->new('bakhru.us.oracle.com') || die "$@";    

# Finally bind to LDAP using our SASL object
my $mesg = $ldap->bind(sasl => $sasl);    

# This should say "0 (Success)" if it worked
print "Message is ". $mesg->code ." (". $mesg->error .").\n";    

# Clear up the credentials
kdestroy();
