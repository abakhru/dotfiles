#!/usr/bin/perl
use File::Copy;
use Getopt::Long;
use Cwd;

$TLE_ModuleDirectory = getcwd();
$TLE_ModuleSourceDir = "$TLE_ModuleDirectory/recipes";
$GENV_MSHOME1="/opt/sun/comms/messaging64";
$GENV_VERYVERYNOISY=1;
$portnum="143";
$GENV_MMPALIAS = "bakhru";
$GENV_DOMAIN = "us.oracle.com";
$GENV_XMLCONFIG=1;

sub MTA_MappingsDo
{
        my ($server_path, $section, $rule, $add) = @_;
	print "Section: $section\n";
	print "RULE: $rule\n";

        my $FoundSection = 0;     # The flag set to 1 if section we want to modify
        # is in mappings. The section can be
        # ORIG_SEND_ACCESS, or ORIG_MAIL_ACCESS
        my $BlankLineCount = 0;       # The number of blank line after section name

        my $MappingPath;          # The path to the mappings file directory
        my @OrigMappings;             # The array holding the original mappings file

    if(("$GENV_XMLCONFIG" eq "0") || ("$GENV_XMLCONFIG" eq "2"))
    {
        $MappingPath     = "$GENV_MSHOME1/config/mappings";
        $MappingPath_old = $MappingPath . '-save-' . $$;
        $MappingPath_tmp = $MappingPath . '-tmp-' . $$;

        unless( open (MAPPINGS, "<$MappingPath") ) {
                print "Can't open the file ${MappingPath} ";
        	close MAPPINGS;
                return 0;
        }
        @OrigMappings = <MAPPINGS>;
        close MAPPINGS;


        # Open the mappings file for writing
        unless( open (MAPPINGS_NEW, ">$MappingPath_tmp") ) {
                print "Can't open the file $MappingPath_tmp for writing";
		close MAPPINGS_NEW;
                return 0;
        }

        # Put a warning comment in the modified configuration file

        print MAPPINGS_NEW
        "! " . MTA_PrettyDate . "\n" .
        "! WARNING: This is a temporary mappings file written by TLE\n";
        if ($add != 0) {
                print MAPPINGS_NEW
                "!          so as to place \"$rule\" " .
                "\"\n" .
                "!          on the \"$section\" Section.\n!\n";
        }
        else {
                print MAPPINGS_NEW
                "!          so as to remove the \"$rule\" " .
                "\"\n" .
                "!          from the \" $section\" section.\n!\n";
        }

        # we need to search for the section we want to modify, and
        # add/remove the new rule
        for my $index (0.. $#OrigMappings ) {
                $_ = $OrigMappings[$index];
                $AddCurrentRule = 1;
                if ( $FoundSection && ($_ eq "\n") ) {
                        $BlankLineCount++;
                }
                if ( $add && $FoundSection) {
                        if ($BlankLineCount == 2) {
                            print MAPPINGS_NEW $rule."\n";
                        } elsif ($BlankLineCount == 1 && $index == $#OrigMappings) {
                            #this is last rule in last section in mappings
                            print MAPPINGS_NEW $_;
                            print MAPPINGS_NEW $rule."\n";
                            $AddCurrentRule = 0;
                        }
                }
                elsif ( $add == 0 && $FoundSection && /^$rule$/ ) {
                        $AddCurrentRule = 0; #found the rule to be removed
                }
                if ($AddCurrentRule) {
                        print MAPPINGS_NEW $_;
                }
                if ( /^$section/ ) {
                        $FoundSection = 1;
                }
        }

        if (!($FoundSection)) {
                if ($add) {
                    # If we didn't spot the section, then just add it
                    print MAPPINGS_NEW "\n\n$section\n".
                                       "\n$rule\n";
                } else {
                    close(MAPPINGS_NEW);
                    unlink($MappingPath_tmp);  # Delete mappings-tmp-nnnn
                    print "Mappings file, \"$MappingPath\" lacks a \"$section\" section";
                    return(1);
                }
        }

        # Close our files
        close(MAPPINGS_NEW);

        # Ensure that the file is world readable
        chmod(0777, $MappingPath_tmp);

        $result = MTA_FileShuffle($MappingPath, $MappingPath_old, $MappingPath_tmp);
    }
    elsif("$GENV_XMLCONFIG" eq "1")
    {
	copy("$GENV_MSHOME1/config/config.xml","$GENV_MSHOME1/config/config.xml.MAPPING");
	print "==== BEFORE MODIFICATION \"$section\" mapping configuration\n";
	system("$GENV_MSHOME1/sbin/msconfig show mapping:$section");

        $file = "mapping.rcp";
        # Replace required variables
        unless( open (FH1, "<$TLE_ModuleSourceDir/$file") ) {
        	print "Unable to open file $TLE_ModuleSourceDir/$file\n";
                close(FH1);return 0;
        }
        @FileContents = <FH1>; close(FH1);

	($field1,$field2) = split(" ",$rule, 2);
	print "==========\n";
	print "field1 = $field1 \n";
	print "field2 = $field2 \n";
	print "==========\n";
        foreach $Line (@FileContents) {
    		if("$add" eq "1"){
                	$Line =~ s/MAPPING_NAME/$section/;
                	$Line =~ s/MAPPING_RULE/$field1\"\,\"$field2/;
    		}
		elsif("$add" eq "0"){
                	$Line =~ s/replace_mapping/delete_mapping/;
                	$Line =~ s/MAPPING_NAME/$section/;
                	$Line =~ s/\,\[m \. \"MAPPING_RULE\"\]//;
    		}
	}

        unless( open(OP1, ">$TLE_ModuleDirectory/$file") ) {
        	print "Unable to open file $TLE_ModuleDirectory/$file";
                close(OP1); return 0;
        }
        print OP1 @FileContents;
        close(OP1);
	system("cat $TLE_ModuleDirectory/$file");
	system("$GENV_MSHOME1/sbin/msconfig run $TLE_ModuleDirectory/$file");

    	if("$add" eq "1"){
		print "==== AFTER MODIFYING \"$section\" mapping\n";
	}
	elsif("$add" eq "0"){
		print "==== AFTER DELETING \"$section\" mapping\n";
	}
	system("$GENV_MSHOME1/sbin/msconfig show mapping:$section");
    }
        # Save cleanup info
        if ($result) {
                $MTA_MAPPINGSUNDO = 1;
                $MTA_mappingsundo_server_path = $server_path;
        }

        return $result;
}

sub MTA_MappingsAdd {
        return(MTA_MappingsDo(@_,1));
}

sub MTA_MappingsRemove {
        return(MTA_MappingsDo(@_, 0));
}

sub MTA_FileShuffle {

        my ($fnam, $fnam_old, $fnam_tmp) = @_;
        my $remove = 0;

        if (!(-e $fnam) && !(-e $fnam_old)) {
                if (!open(TMP, '>' . $fnam_old)) {
                        $MTA_ErrMsg = "Cannot open the file \"$fnam_old\" for writing;\n$!";
                        return(0);
                }
                close(TMP);
                chmod(0777, $fnam_old);
                $remove = 1;
        }

        my $save = (-e $fnam) ? ((-e $fnam_old) ? 0 : 1) : 0;

        if (!$save || (rename($fnam, $fnam_old))) {
                # Step (1) of the shuffle worked
                if ((rename($fnam_tmp, $fnam))) {
                        # ... and step (2) worked also
                        return(1);
                }
                else {  
                        # Step (2) of the shuffle failed                        # attempt to restore $fnam by moving $fnam_old
                        # back.  Note that this loses any intermediate
                        # changes which succeeded.
                        $MTA_ErrMsg = "Unable to rename the file " .
                        "\"$fnam_tmp\" to \"$fnam_old\";\n$!";
                        if ($save) {
                                rename($fnam_old, $fnam);
                        }
                        unlink($fnam_tmp);
                        if ($remove) {
                                unlink($fnam_old);
                        }
                        return(0);
                }
        }
        else {  
                # Step (1) of the shuffle failed.
                # Delete $fnam_tmp and return a failure.
                $MTA_ErrMsg = "Unable to rename the file \"$fnam\"" .
                " to \"$fnam_old\";\n$!";
                unlink($fnam_tmp);
                if ($remove) {
                        unlink($fnam_old);
                }
                return(0);
        }
	return 1;
}

MTA_MappingsRemove("$GENV_MSHOME1/bin/","PORT_ACCESS","");
$Line = "  TCP|*|25|*|*  \$C\$[IMTA_LIB:conn_throttle.so,throttle,\$1,10]\$N421\$ Connection\$ not\$ accepted\$E";
MTA_MappingsAdd("$GENV_MSHOME1/bin/","PORT_ACCESS","$Line");
MTA_MappingsAdd("$GENV_MSHOME1/bin/","PORT_ACCESS"," *|*|*|*|* \$C\$|INTERNAL_IP;\$3|\$Y\$E");
MTA_MappingsAdd("$GENV_MSHOME1/bin/","PORT_ACCESS"," * \$YEXTERNAL");
