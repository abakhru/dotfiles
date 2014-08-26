#!/usr/bin/perl

$GENV_DSVERSION1=7.0;
$GENV_DSHOME1="/opt/sun";
$GENV_DM="cn=directory manager";
$GENV_DMPASSWORD="netscape";
$GENV_DSHOST1="bakhru";
$GENV_MSHOST1="bakhru";
$ARCHIVE_DIR="./DSBACKUP";
chomp($LDAP_CMD = `find $GENV_DSHOME1 -perm -755 |grep "bin/dsadm"`);
#print "$LDAP_CMD";
if ( $GENV_DS1INSTANCE eq "") {
	chomp($GENV_DS1INSTANCE = `find /var/opt/sun/ds7/ -name dsins1`);
}
###########################################################################
# [ hula_SetupDs ]
# Description:
#	Modify the DS configuration file and restart slapd 
# Returns: 
#	True: if DS restart successfully
#	False: if any error occurs
###########################################################################
sub hula_SetupDs()
{
	# back up the original slapd.conf 
   	print "Backing Up Directory Server...............\n";
	unless (hula_BackupDs()) {
		print "failed to backup Directory Server\n";
		return 0;
	}

   	print "Enabling cleartext password storage in Directory Server ...............\n";
        unless ( hula_ModifyDs() ) {
		print "failed to update slapd.conf on $Host\n";
		return 0;
	}
   	print "Restarting Directory Server ...............\n";
   	unless ( hula_RestartDs() ) {
   		print "failed to restart slapd process on $Host\n";
   		return 0;
   	}
	return 1;
}

############################################################################
# [ hula_ModifyDs ]
# Description:
#   	Modify DS configuration by using ldapmodify
# Returns: 
#	True: if directory server is updated successfully 
#	False: if any error occurs
###########################################################################
sub hula_ModifyDs()
{
	print "HELLO\n";
		my $LdapLoc;
		my $LdapFile = "./clear_password.ldif";
		my $LdapCmd;

		if ( -d "$GENV_DSHOME1/dsee6/bin" ) {
			$LdapLoc =  "$GENV_DSHOME1/dsee6/bin";
		}
		elsif ( -d "$GENV_DSHOME1/dsee7/bin" ) {
                        $LdapLoc =  "$GENV_DSHOME1/dsee7/bin";
                }
		else {
			$LdapLoc =  "/usr/bin";
		}
		print "Enabling cleartext password storage in Directory Server ....\n";
		$LdapCmd = "$LdapLoc/ldapmodify -D \"$GENV_DM\" -v -w $GENV_DMPASSWORD -c -f $LdapFile -h $GENV_DSHOST1 ";
                print("$LdapCmd\n"); 
                system("$LdapCmd"); 
		unless ($? == 0) {
			print "ldapmodify failed\n";
			return 0;
		}
	return 1;
}


############################################################################
# [ hula_BackupDs ]
# Description:
# Returns: 
#	True: if backup successfully
#	False: if any error occurs
###########################################################################
sub hula_BackupDs()
{
	if (-d $ARCHIVE_DIR) {
		system("rm -rf $ARCHIVE_DIR");
	}
	print("Backing Up the existing Directory Server.......\n");
        system ("$LDAP_CMD stop $GENV_DS1INSTANCE");
	print("$LDAP_CMD backup $GENV_DS1INSTANCE $ARCHIVE_DIR\n");
	system("$LDAP_CMD backup $GENV_DS1INSTANCE $ARCHIVE_DIR");
        unless ($? == 0)
        {
   		print "==============Directory Server Backup FAILED\n";
                exit 0;
        }
	sleep(2);
        system ("$LDAP_CMD start $GENV_DS1INSTANCE");
   	return 1;
}
    
############################################################################
# [ hula_RestoreDs ]
# Description:
#	Restore original slapd configuration to each individual 
#	directory server machines.
# Returns: 
#	True: if restored successfully
#	False: if any error occurs
###########################################################################
sub hula_RestoreDs()
{
	print "Restoring Directory to its previous state ... \n";
	system("$LDAP_CMD stop $GENV_DS1INSTANCE");
	unless( -d $ARCHIVE_DIR ){
		print "Backup Directory doesn't exists ... \n";
	}
	system("$LDAP_CMD restore -i $GENV_DS1INSTANCE $ARCHIVE_DIR");
        unless ($? == 0)
        {
   		print "==============Directory Server restart FAILED\n";
                exit 0;
        }
	system("$LDAP_CMD start $GENV_DS1INSTANCE $TLE_ModuleDirectory");
   	return 1;
}

#############################################################################
# [ hula_RestartDs ]
# Description:
#	restart slapd process
# Returns: 
#	True: if slapd restarted successfully
#       False: if any error occurs
#############################################################################
sub hula_RestartDs()
{
   	# do a restart on the system since the configuration changed
	print "Restarting slapd.....\n";
	unless ( -d $GENV_DS1INSTANCE){
		chomp($GENV_DS1INSTANCE = `find /var/opt/sun/ds7/ -name dsins1`);
	}
	print "Stopping slapd.....\n";
        system ("$LDAP_CMD stop $GENV_DS1INSTANCE");
	print "Starting slapd.....\n";
        system ("$LDAP_CMD start $GENV_DS1INSTANCE");
        unless ($? == 0)
        {
   		print "==============Directory Server restart FAILED\n";
                exit 0;
        }
   	sleep(5);
	print "hula_RestartDs end.....\n";
   	return 1;
}

hula_ModifyDs();
#hula_BackupDs();
#hula_RestartDs();
#hula_SetupDs();
hula_RestoreDs();
