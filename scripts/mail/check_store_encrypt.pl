#!/usr/bin/perl

use File::Find;

$GENV_MAILHOSTDOMAIN="us.oracle.com";
$GENV_MSHOME1="/opt/sun/comms/messaging64";
$GENV_STOREENCRYPT="1";
$GENV_VERYVERYNOISY="1";

#######################
#
#CountMsg("<partition-name>", "<domain>", "<username>", "<mailbox>")
#CountMsg("mailboxpurge", "mailboxpurge.com", "mailboxpurgeuser202", "INBOX")
#
#######################
sub CountMsg
{
        my $partitionName =shift;
        my $domainName = shift;
        my $user = shift;
        my $Mailbox = shift;
        my $MailPath;
        my @files = ();
	my $no_of_folders=0;
	my $no_of_files=0;
	my $encrypted_files = 0;
	my $unencrypted_files = 0;

        if($domainName eq "$GENV_MAILHOSTDOMAIN"){
                $MailPath = GetHashDir("$user", "$partitionName");
                if ($Mailbox ne "INBOX") {
                        $Mailbox =~ s/\//$&=/g;
                        $MailPath = $MailPath . "/=" . $Mailbox;
                }
                $MailPath =~ s/\.com/\%dcom/g;
        }else{
                $MailPath = GetHashDir("$user\@$domainName", "$partitionName");
                if ($Mailbox ne "INBOX") {
                        $Mailbox =~ s/\//$&=/g;
                        $MailPath = $MailPath . "/=" . $Mailbox;
                }
                $MailPath =~ s/\.com/\%dcom/g;
        }

	if($GENV_VERYVERYNOISY){
		print "Running Command: ls -lahrt $MailPath\n";
		system("ls -lhrt $MailPath");
		print "\n";
	}

	my $no_of_folders = count_folders("$MailPath");
	#unless(opendir(OPT, "$MailPath")){
	#	print "Unable to open the user's directory\n";
	#	closedir(OPT);
	#	return 0;
	#}
	#@contents=readdir OPT;
	#print "CONTENTS : @contents\n";
	#closedir(OPT);
	#foreach $file (@contents){
	#	if(($file =~ /\./) || ($file =~ /store\./)){
	#		next;
	#	}
	#	if(-d "$file"){
	#		print "Directory = $file\n";
	#		$no_of_folders++;
	#		push(@folders, $file);
	#	}
	#	if(-f "$file"){
	#		print "file = $file\n";
	#		$no_of_files++;
	#	}
	#}

	if($no_of_folders <= 0){
		print "==== User \"$user\" does NOT have a \"$Mailbox\" yet in \"$partitionName\" partition\n";
		print "==== Please check your input parameters\n";
		return 0;
	}
	
	for(my $i=0; $i < $no_of_folders; $i++)
	{
		if("$Mailbhox" eq "INBOX"){
        		$MailPath1 = "$MailPath"."0$i";
		}else{
        		$MailPath1 = "$MailPath"."/$folders[$i]/0$i";
		}
        	print "==== Now opening $user" . "'s hashdir: $MailPath1...\n";
        	unless(opendir(EFG, "$MailPath1")){
                	print "Unable to open the user's hashdir $MailPath1\n";
                	closedir(EFG);
                	return 0;
        	}
        	@files=readdir EFG;
        	closedir(EFG);
        	print "==== Now counting the message files...\n";
        	foreach $file (@files){
			if($file =~ /\.meg$/i){
				$encrypted_files++;
               	 	}elsif($file =~ /\.msg$/i){
                        	$unencrypted_files++;
                	}
        	}

		if($GENV_VERYVERYNOISY){
			print "Running Command: ls -lhrt $MailPath1\n";
			system("ls -lhrt $MailPath1");
			print "\n";
		}
	}

	print "\n==== Total ENCRYPTED messages found: $encrypted_files ====\n" if($encrypted_files);
	print "\n==== Total UN-ENCRYPTED messages found: $unencrypted_files ====\n" if($unencrypted_files);
        return $flag;
}

#GetHashDir("$user", "$partitionName");
sub GetHashDir 
{
	my ($AccountName, $Partition, $MailDir) = @_;
        my $Result = 0; 
        my $TempDir = "";
	if("$MailDir" eq ""){
        	$MailDir = $GENV_MSHOME1;
	}
	if("$Partition" eq ""){
        	$Partition="primary";
	}
        my $PartitionDir="";

        $TempDir = `$GENV_MSHOME1/bin/hashdir $AccountName`;

        if ($TempDir !~ /\// and $TempDir !~ /\\/) {
                print "Unable to get message store directory.Call returned:\n";
                print "$TempDir";
                return 0;
        }
        chomp $TempDir;
        $AccountName =~ s/[A-Z]/+$&/g;
        if($Partition =~ /primary/i){
                return "$GENV_MSHOME1/data/store/partition/primary/=user/$TempDir=$AccountName";
        }
	else {
                $PartitionDir = `$GENV_MSHOME1/bin/configutil -o store.partition.$Partition.path`;
                if ($PartitionDir !~ /\// and $PartitionDir !~ /\\/) {
                        print "Unable to get hash directory.  Call returned:\n";
                        print "-c", "$PartitionDir";
                        return 0;
                }
                chomp $PartitionDir;
                return "$PartitionDir/=user/$TempDir=$AccountName";
        }
}

sub count_folders
{
	my ($path)  = @_;
	my $folders = 0;
	my $files = 0;

	File::Find::find( sub {
    		if (-f $File::Find::name) {
        		$files++;
    		} elsif (-d $File::Find::name) {
        		$folders++;
    		};
	}, $path );

	return $folders-1;
}

CountMsg("primary", "us.oracle.com", "neo3", "INBOX")
