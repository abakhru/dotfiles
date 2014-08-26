#!/usr/bin/perl
use Net::LDAP;
use Net::LDAP::LDIF;
use Net::LDAP::Search;

<<<<<<< USR_ModifyUserAttr.pl
$GENV_MSHOST1="sc11e0405";
=======
$GENV_MSHOST1="sc11136620";
$GENV_MAILHOSTDOMAIN="us.oracle.com";
>>>>>>> 1.4
$GENV_DOMAIN="us.oracle.com";
$GENV_OSIROOT="o=usergroup";
$GENV_DM="cn=directory manager";
$GENV_DMPASSWORD="password";
$GENV_VERYVERYNOISY="1";

system(">./detaillog");

sub USR_ModifyAttr {
        my ($user_group_flag, $user, $domain, $attribute_name, $attribute_value, $add_delete_flag) = @_ ;
        open($FD,">> ./detaillog");
        my $ldap = Net::LDAP->new("$GENV_MSHOST1.$GENV_DOMAIN", debug => 0);
        my $mesg = $ldap->bind ("$GENV_DM", password => "$GENV_DMPASSWORD", version => 3, debug => 3);
   	if ("$user_group_flag" eq "user") {
        	$mesg = $ldap->search (base => "o=$domain,$GENV_OSIROOT", scope => "subtree", filter => "(uid=$user)");
   	}elsif ("$user_group_flag" eq "group") {
       		$mesg = $ldap->search (base => "o=$domain,$GENV_OSIROOT", scope => "subtree", filter => "(cn=$user)");
   	}elsif ("$user_group_flag" eq "domain") {
		($field1, $field2, $field3) = split("\\.", $domain);
        	$mesg = $ldap->search (base => "o=internet", scope => "subtree", filter => "(dc=$field1)");
   	}
        @entries = $mesg->entries;
        my $entry = $mesg->entry(0);
        $dn = $entry->dn();
        print $FD "Modifying the following dn : $dn\n";
        #don't replace
    if($add_delete_flag == 2) {
        $mesg = $entry->add( $attribute_name => "$attribute_value" );
        #TLE_DetailMsg "New value is : $attribute_name : $attribute_value";
        $entry->update($ldap);
        $value = $entry->get_value($attribute_name);
        if("$value" eq "$attribute_value") {
                $resul=1;
        } else {
                $resul=0;
        }
        #replace if already exists
    } elsif( $add_delete_flag == 1) {
                if ($entry->exists($attribute_name)) {
                my $currentValue = $entry->get_value($attribute_name);
                print "Old value is : $attribute_name : $currentValue\n";
                $mesg = $entry->replace( $attribute_name => "$attribute_value" );
        } else {
                $mesg = $entry->add( $attribute_name => "$attribute_value" );
        }
        print "New value is : $attribute_name : $attribute_value\n";
        $entry->update($ldap);
        $value = $entry->get_value($attribute_name);
        if("$value" eq "$attribute_value") {
                $resul=1;
        } else {
                $resul=0;
        }
        #delete if exists

    } elsif( $add_delete_flag == 0) {
        if ($entry->exists($attribute_name)) {
                $currentValue = $entry->get_value($attribute_name);
                print $FD "Deleting the $attribute_name";
                $mesg = $entry->delete( $attribute_name );
        } else {
		print $FD "$attribute_name doesn't exists";
        }
        $entry->update($ldap);
        $value = $entry->get_value($attribute_name);
        if("$value" eq "") {
                $result = 1;
        } else {
                $result = 0;
        }
    }
    $entry->dump($FD);
    close($FD);
    $ldap->unbind;
    return ($result);
} #USR_ModifyAttr Ends

sub USR_ImportLdif {
#############################################################################################
#Description: Importing LDIF file into LDAP Server
#Example Usage: USR_AddLdif("/space/amit/scripts/mail/mta_mappings_group46.ldif","1");
#               USR_AddLdif("/space/amit/scripts/mail/mta_mappings_group46.ldif","0");
# Returns 0 for false and 1 for true
#############################################################################################

        my ($file, $add_delete_flag) = @_;
        my $ldap = Net::LDAP->new( "$GENV_MSHOST1.$GENV_DOMAIN", debug => 0) or die "$@";
        my $mesg = $ldap->bind ( "$GENV_DM", password => "$GENV_DMPASSWORD", version => 3);
        my $cn = `head -1 $file |cut -d':' -f2|cut -d',' -f1`;
        print "====================== CN is :$cn =========================";
        my $entry = Net::LDAP::Entry->new();

        if ($add_delete_flag == 1) {
                my $ldif = Net::LDAP::LDIF->new($file, "r", onerror => 'undef');
                while (!$ldif->eof()) {
                        $entry = $ldif->read_entry();
                        if ($ldif->error()) {
                                print "Error msg: ", $ldif->error(), "\n";
                                print "Error lines:", $ldif->error_lines(), "\n";
                                next;
                        }
                        $result = $ldap->add($entry);
                        warn $result->error( ) if $result->code( );
                }
                $entry->update($ldap);
                $search = $ldap->search (base => "$GENV_OSIROOT", scope => "subtree", filter => "($cn)");
                $entry = $search->entry(0);
                $DN = $entry->dn();
                if ("$DN" eq "") { return 0; }
                #$entry->dump;
                $ldif->done();
        } elsif ($add_delete_flag == 0) {
                $mesg = $ldap->search(base => "$GENV_OSIROOT", scope => "subtree", filter => "($cn)");
                $entry = $mesg->entry(0);
                $dn = $entry->dn();
               #$entry->dump;
                print "Deleting the following dn : $dn";
                $mesg = $ldap->delete("$dn");
                $entry->update($ldap);
        }
        $ldap->unbind();
        return 1;
}

#$f = USR_ModifyAttr("user","mta_mappings37","us.oracle.com","mailConversionTag","conversion_tag37","0");
#$a = USR_ModifyAttr("user","mta_mappings37","us.oracle.com","mailConversionTag","conversion_tag37","1");
#$b = USR_ModifyAttr("group","mta_mappings_group46","$GENV_DOMAIN","description","LDAP-MAPPING","1");
#$c = USR_ModifyAttr("group","mta_mappings_group46","$GENV_DOMAIN","mgrpdeliverto","ldap:///$GENV_OSIROOT??sub?(uid=mta_mappings47)","1");
#$e = USR_ModifyAttr("domain","","$GENV_DOMAIN","street","", "0");
#$d = USR_ModifyAttr("domain","","$GENV_DOMAIN","street","XYZ","1");
#my $a = USR_ModifyAttr("user","testuser32","$GENV_MAILHOSTDOMAIN","mailAlternateAddress"," testzzxadj\@$GENV_MAILHOSTDOMAIN","1");

<<<<<<< USR_ModifyUserAttr.pl
#USR_ImportLdif("/space/amit/scripts/mail/a.ldif","1");
#USR_ImportLdif("/space/amit/scripts/mail/a.ldif","0");
for(my $i=1;$i<=500;$i++){
	$f = USR_ModifyAttr("user","neo$i","us.oracle.com","inetUserStatus","deleted","1");
}
=======
USR_ModifyAttr("user","testuser32","$GENV_MAILHOSTDOMAIN","mailAlternateAddress"," testzzxadj\@$GENV_MAILHOSTDOMAIN","2");
USR_ModifyAttr("user","testuser32","$GENV_MAILHOSTDOMAIN","mailAlternateAddress"," testzzxbdj\@$GENV_MAILHOSTDOMAIN","2");
USR_ModifyAttr("user","testuser32","$GENV_MAILHOSTDOMAIN","mailAlternateAddress"," testzzxcdj\@$GENV_MAILHOSTDOMAIN","2");
USR_ModifyAttr("user","testuser32","$GENV_MAILHOSTDOMAIN","mailAlternateAddress"," testzzxddj\@$GENV_MAILHOSTDOMAIN","2");
USR_ModifyAttr("user","testuser32","$GENV_MAILHOSTDOMAIN","mailAlternateAddress"," testzzxedj\@$GENV_MAILHOSTDOMAIN","2");
USR_ModifyAttr("user","testuser32","$GENV_MAILHOSTDOMAIN","mailAlternateAddress"," testzzxfdj\@$GENV_MAILHOSTDOMAIN","2");
USR_ModifyAttr("user","testuser32","$GENV_MAILHOSTDOMAIN","mailAlternateAddress"," testzzxgdj\@$GENV_MAILHOSTDOMAIN","2");
USR_ModifyAttr("user","testuser32","$GENV_MAILHOSTDOMAIN","mailAlternateAddress"," testzzxhdj\@$GENV_MAILHOSTDOMAIN","2");
USR_ModifyAttr("user","testuser32","$GENV_MAILHOSTDOMAIN","mailAlternateAddress"," testzzxidj\@$GENV_MAILHOSTDOMAIN","2");
USR_ModifyAttr("user","testuser32","$GENV_MAILHOSTDOMAIN","mailAlternateAddress"," testzzxjdj\@cle.com","2");
USR_ModifyAttr("user","testuser32","$GENV_MAILHOSTDOMAIN","mailAlternateAddress"," testzzxkdj\@$GENV_MAILHOSTDOMAIN","2");
USR_ModifyAttr("user","testuser32","$GENV_MAILHOSTDOMAIN","mailAlternateAddress"," testzzxkdj\@$GENV_MAILHOSTDOMAIN","2");
USR_ModifyAttr("user","testuser32","$GENV_MAILHOSTDOMAIN","mailAlternateAddress"," testzzxldj\@$GENV_MAILHOSTDOMAIN","2");
USR_ModifyAttr("user","testuser32","$GENV_MAILHOSTDOMAIN","mailAlternateAddress"," testzzxmdj\@$GENV_MAILHOSTDOMAIN","2");

print "==== $a ====\n";
#print "\nA = $a : B = $b : C = $c : D = $d : E = $e\n";
>>>>>>> 1.4
