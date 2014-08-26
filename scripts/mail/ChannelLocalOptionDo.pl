#!/usr/bin/perl
use File::Copy;
use Mail::IMAPClient;
use Getopt::Long;

$GENV_MSHOME1="/opt/sun/comms/messaging64";
$GENV_XMLCONFIG=0;
$GENV_VERYVERYNOISY=1;

sub ChannelLocalOptionDo {
	my ($channel, $Option, $Value, $add) = @_;

	if("$GENV_XMLCONFIG" eq "1")
	{
        	if($add >= 1){
			return 0 unless(system("$GENV_MSHOME1/sbin/msconfig set channel:$channel.options.$Option $Value"));
        	} elsif($add == 0){
                	return 0 unless(system("$GENV_MSHOME1/sbin/msconfig unset channel:$channel.options.$Option"));
        	}
        	if($GENV_VERYVERYNOISY){
                	print "==== \"$channel\" channel options after Modification ====\n";
                	system("$GENV_MSHOME1/sbin/msconfig show channel:$channel");
        	}
        	return 1;
	} elsif(("$GENV_XMLCONFIG" eq "0") || ("$GENV_XMLCONFIG" eq "2")) {
                my $NewOptionFile = "$GENV_MSHOME1/config/$channel" . "_option";
                if($add == 1){
                        print "==== Adding $Option=$Value to $channel options\n";
                        unless(open(FH, ">$NewOptionFile")) {
                                print "Unable to open file $NewOptionFile\n";
                                close(FH);return 0;
                        }
                        print FH "$Option=$Value\n";
                        close(FH);
		}elsif($add == 2){
                        print "==== Appending $Option=$Value to $channel options\n";
                        unless(open(FH, ">>$NewOptionFile")) {
                                print "Unable to open file $NewOptionFile\n";
                                close(FH);return 0;
                        }
                        print FH "$Option=$Value\n";
                        close(FH);
                } elsif($add == 0){
                        if(-e "$NewOptionFile"){
                                unless (open(FD, "$NewOptionFile")) {
                                        print "Unable to open temporary file to write\n";
                                        close FD; return 0;
                                }
                                my @FileContents = <FD>;
                                close(FD);
                                unless( open(OP, ">$NewOptionFile") ) {
                                        print "Unable to open file $NewOptionFile";
                                        close(OP); return 0;
                                }
                                foreach my $Line (@FileContents) {
					print OP $Line unless ($Line =~ m/$Option/);
                                }
                                close(OP);
                        }else{
                                print "==== $NewOptionFile doesn't exists, nothing to delete\n";
                        }
                }
                if($GENV_VERYVERYNOISY){
                        print "==== \"$channel\" channel options after Modification ====\n";
                        system("more $NewOptionFile");
                }
	}
	return 1;
}

sub ChannelLocalOptionRemove {
        return(ChannelLocalOptionDo(@_, 0));
}

sub ChannelLocalOptionAdd {
        return(ChannelLocalOptionDo(@_, 1));
}

sub ChannelLocalOptionAppend {
        return(ChannelLocalOptionDo(@_, 2));
}

#ChannelLocalOptionAdd("managesieve", "CUSTOM_BANNER_STRING", "ABC");
#ChannelLocalOptionAppend("managesieve", "CUSTOM_VERSION_STRING", "5.5");
ChannelLocalOptionRemove("managesieve", "TRACE_LEVEL", "2");
