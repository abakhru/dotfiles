#!/usr/bin/perl
use File::Copy;
use Getopt::Long;
use Cwd;

$TLE_ModuleDirectory = getcwd();
$GENV_MSHOME1="/opt/sun/comms/messaging64";
$GENV_VERYVERYNOISY=1;
$portnum="143";
$GENV_MMPALIAS = "dianthos";
$GENV_DOMAIN = "us.oracle.com";
$GENV_XMLCONFIG=1;

sub MTA_OptionDo {

        @ARGV = @_;
        my $file = '';
        $Result = eval { GetOptions ('f=s' => \$file) };

        @_ = @ARGV;

        my ($server_path, $option_name, $option_value, $add) = @_;
        my ($opt, $option_file, $option_file_old, $option_file_tmp, $val);
        my %opts = ();

   if("$GENV_XMLCONFIG" == 1){
	$result = 1;
	#set_option("LOG_USERNAME", "1");
	#unset_option("LOG_USERNAME", "1");
	if($add == 1){
		system("echo \"set_option\(\\\"$option_name\\\"\, \\\"$option_value\\\"\)\;\" > $TLE_ModuleDirectory/t.rcp");
		$result = system("$GENV_MSHOME1/sbin/msconfig run $TLE_ModuleDirectory/t.rcp");
		#$result = LOL_SystemCall("$GENV_MSHOME1/sbin/msconfig run $TLE_ModuleDirectory/t.rcp");
	} elsif($add == 0){
		system("echo \"unset_option\(\\\"$option_name\\\"\)\;\" > $TLE_ModuleDirectory/t.rcp");
		#$result = LOL_SystemCall("$GENV_MSHOME1/sbin/msconfig run $TLE_ModuleDirectory/t.rcp");
		$result = system("$GENV_MSHOME1/sbin/msconfig run $TLE_ModuleDirectory/t.rcp");
	}

	system("cat $TLE_ModuleDirectory/t.rcp");
	#unlink("$TLE_ModuleDirectory/t.rcp");

   } else {
        $option_file      = $GENV_MSHOME1.$MTA_CONFIGDIR. 'option.dat';
        $option_file_old = $option_file . '-save-' . $$;
        $option_file_tmp = $option_file . '-tmp-' . $$;

        if (-e $option_file) {
                if (!open(OPTIONS, $option_file)) {
                        $MTA_ErrMsg = "Unable to open the file " .  "\"$option_file\" for reading;\n$!";
                        return(0);
                }
                while (defined ($_ = <OPTIONS>)) {
                        chomp($_);
                        $_ =~ s/\s*(.*?)/$1/;
                        next if ($_ eq '' || m/^!/);
                        m/\s*(.*?)\s*=(.*)/;
                        $opts{$1} = $2;
                }
                close(OPTIONS);
        }

        if ($file ne '') {
                $add = 3;
                if (-e $file) {
                    if (!open(OPT, $file)) {
                        $MTA_ErrMsg = "Unable to open the file " .  "\"$file\" for reading;\n$!";
                        return(0);
                    }
                    while (defined ($_ = <OPT>)) {
                        chomp($_);
                        $_ =~ s/(\$GENV_\w+)/$1/eeg;
                        $_ =~ s/\s*(.*?)/$1/;
                        next if ($_ eq '' || m/^!/);
                        m/\s*(.*?)\s*=(.*)/;
                        $opts{$1} = $2;
                    }
                    close(OPT);
                }
        }
        if ($add == 0) {
                delete $opts{$option_name};
        } elsif ($add == 1) {
                $opts{$option_name} = $option_value;
        }

        if (!open(OPTIONS, '>' . $option_file_tmp)) {
                $MTA_ErrMsg = "Unable to open the file " .  "\"$option_file_tmp\" for writing;\n$!";
                return(0);
        }

        if ($add == 2) {
                print OPTIONS "$option_name=$option_value\n";
        }

        print OPTIONS "! " . MTA_PrettyDate . "\n" . "! WARNING: This is a temporary option.dat file written by TLE\n";
        if ($add == 3) {
                print OPTIONS "! so as to merge \"$file\".\n!\n";
        } elsif ($add == 0) {
                print OPTIONS "! so as to remove the \"$option_name\"" .  " option.\n!\n";
        } else {
                print OPTIONS "! so as to set \"$option_name=" .  "$option_value\".\n!\n";
        }

        while (($opt, $val) = each %opts) {
                print OPTIONS "$opt=$val\n";
        }
        close(OPTIONS);

        chmod(0777, $option_file_tmp);

        my $result = MTA_FileShuffle($option_file, $option_file_old, $option_file_tmp);

        if ($result) {
                $MTA_OPTIONUNDO = 1;
                $MTA_optionundo_server_path = $server_path;
        }
    }
    return($result);
}

sub MTA_OptionAdd {
        ($Dummy, $FileName, $LineNum ) = caller();

        my $Result = 1;
        my $AddAtBeginning = 0;
        my $FN = '';

        @ARGV = @_;
        $Result = eval { GetOptions ('a' => \$AddAtBeginning,'f=s' => \$FN) };
        unless ($Result) {
                print("-d$FileName", "-l$LineNum", "Invalid parameter passed in call to $FunctionName.  Error occurred parsing:", "\'@_\'");
                return $Result;
        }

        @_ = @ARGV;

        if ($AddAtBeginning) {
                return(MTA_OptionDo(@_, 2));
        } elsif ($FN ne '') {
                 return(MTA_OptionDo(@_,"-f$FN",3));
        } else {
                return(MTA_OptionDo(@_, 1));
        }
}

sub MTA_OptionRemove {
        return (MTA_OptionDo(@_, '', 0));
}

#MTA_OptionRemove("$GENV_MSHOME1/bin", "LOG_CONNECTION", "2");
MTA_OptionAdd("$GENV_MSHOME1/bin", "GROUP_DN_TEMPLATE", "ldap:///o=usergroup??sub?(memberof=\\\$A)");
#MTA_OptionRemove("$GENV_MSHOME1/bin", "MM_DEBUG", "10");

sub config_spamassassin
{
		$file=$ARGV[0];
                print "Calculated name for src of options file: $file\n";
                system("cat $file");
                unless(open (FH, "$file") ) {
                        print "Unable to open file $file\n";
                        close(FH);
                        return 0;
                }
                @FileContents = <FH>; close(FH);

                foreach $Line (@FileContents) {
                        print "==== checking : $Line\n";
                        $Line =~ s/\$GENV_MSHOME1/$GENV_MSHOME1/;
                        ($field1, $field2) = split("=",$Line);
                        $field1 = lc $field1;
                        print "==== field1 : $field1, field2 : $field2";
                        if("$field1" =~ /config/ || "$field1" =~ /library/ || "$field1" =~ /!/){
                                print "==== SKIP ====\n";
                                next;
                        } elsif("$field1" =~ /optional/ || "$field1" =~ /action/) {
                                print "==== Now adding $field1 using MTA_OptionAdd\n";
				chomp($field2);
                                if("$field2" =~ /\"/ || /\$/ || /\;/){
                                        print "previous field2: $field2\n";
                                        #$field2 =~ s/\"/\\\"/g;
                                        $field2 =~ s/\"/\\\\\\"/g;
                                        $field2 =~ s/\$/\\\$/g;
                                        $field2 =~ s/\;/\\\;/g;
                                        print "latest field2: $field2\n";
                                }
                                MTA_OptionAdd("$GENV_MSHOME1/sbin","$field1", "$field2");
                        }
                }#foreach ends
	return 1;
}

#config_spamassassin();
