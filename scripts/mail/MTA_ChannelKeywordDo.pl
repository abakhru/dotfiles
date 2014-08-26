#!/usr/bin/perl
use File::Copy;
use Mail::IMAPClient;
use Getopt::Long;
#use strict;

$GENV_MSHOME1="/opt/sun/comms/messaging64";
$GENV_XMLCONFIG=1;
$GENV_VERYVERYNOISY=1;

sub ChannelKeywordDo {
	($server_path, $channel, $keyword, $keyword_p, $param_count, $add) = @_;

   if("$GENV_XMLCONFIG" eq "1")
   {
        if($add == 1){
                if(length($keyword_p) == 0){
                        return 0 unless(system("$GENV_MSHOME1/sbin/msconfig set channel:$channel.$keyword"));
                }else { 
                        print ("keyword_p = $keyword_p\n") if($GENV_VERYVERYNOISY);
			if("$keyword_p" =~ /,/){
				#set_option("channel:" . "tcp_local" . ".sourcenosolicit","net.example:ADV,com.example:ADV");
                		system("echo \"set_option\(\\\"channel:\\\" \. \\\"$channel\\\" \. \\\"\.$keyword\\\"\,\\\"$keyword_p\\\"\)\;\" > $TLE_ModuleDirectory/t.rcp");
				system("cat $TLE_ModuleDirectory/t.rcp")if($GENV_VERYVERYNOISY);
                		return 0 unless(system("$GENV_MSHOME1/sbin/msconfig run $TLE_ModuleDirectory/t.rcp"));
        			unlink("$TLE_ModuleDirectory/t.rcp") unless($GENV_VERYVERYNOISY);
			}else {
                        return 0 unless(system("$GENV_MSHOME1/sbin/msconfig set channel:$channel.$keyword $keyword_p"));
			}
                }
        } elsif($add == 0){
                return 0 unless(system("$GENV_MSHOME1/sbin/msconfig unset channel:$channel.$keyword"));
        }
        if($GENV_VERYVERYNOISY){
                print "==== \"$channel\" channel definition after Modification ====";
                system("$GENV_MSHOME1/sbin/msconfig show channel:$channel");
        }
        return 1;

   } else {

        unless( open (FH, "$server_path/imta.cnf") ) {
                print "Unable to open file $server_path/imta.cnf";
                close(FH);return 0;
        }
        @FileContents = <FH>;
	close(FH);

        foreach $Line (@FileContents) {
		if ( $Line =~ $channel ) {
			# continue if its a comment
		@line_array = $Line;
			if ($line_array[0] =~ "!" || $line_array[0] =~ "daemon") { 
				next; 
			}
			if ( $add == 1 ) {
			   if ($Line =~ $keyword) {print "already exists\n";next;}
				$Line = trim($Line);
				print "Adding $keyword keyword in $channel channel\n";
				$Line = $Line . " " . $keyword . "\n";
			} elsif ( $add == 0 ) {	
				print "Removing $keyword keyword from $channel channel\n";
				$Line =~ s/$keyword //g;
				$Line = trim($Line);
			}
		}
        }#foreach

        unless( open(OP, ">$server_path/imta.cnf") ) {
                print "Unable to open file $server_path/imta.cnf";
                close(OP); return 0;
        }
        print OP @FileContents;
        close(OP);
    }
    return 1;
}

sub ChannelKeywordRemove {
        my ($server_path, $channel, $keyword, $param_count) = @_;
        return(ChannelKeywordDo($server_path, $channel, $keyword, '', $param_count, 0));
}

sub ChannelKeywordAdd {
        return(ChannelKeywordDo(@_, 0, 1));
}

#unless ( ChannelKeywordAdd("$GENV_MSHOME1/config","defaults","logging","") &&
#         ChannelKeywordRemove("$GENV_MSHOME1/config","tcp_submit","mustsaslserver","") &&
#         ChannelKeywordAdd("$GENV_MSHOME1/config","tcp_intranet","maysaslserver","") &&
#         ChannelKeywordAdd("$GENV_MSHOME1/config","tcp_local","maysaslserver","") &&
#         ChannelKeywordAdd("$GENV_MSHOME1/config","tcp_submit","maysaslserver","") &&
#         ChannelKeywordAdd("$GENV_MSHOME1/config","ims-ms","master_debug slave_debug","") &&
#         ChannelKeywordAdd("$GENV_MSHOME1/config","tcp_local","master_debug slave_debug","") &&
#         ChannelKeywordAdd("$GENV_MSHOME1/config","tcp_intranet","master_debug slave_debug","") &&
#         ChannelKeywordAdd("$GENV_MSHOME1/config","tcp_submit","master_debug slave_debug","") &&
#         ChannelKeywordAdd("$GENV_MSHOME1/config","tcp_auth","master_debug slave_debug","") &&
#         ChannelKeywordAdd("$GENV_MSHOME1/config","reprocess","master_debug slave_debug","") &&
#         ChannelKeywordAdd("$GENV_MSHOME1/config","process","master_debug slave_debug","") &&
#         ChannelKeywordAdd("$GENV_MSHOME1/config","conversion","master_debug slave_debug","")) {
#	print "keyword modification failed\n"; 
#}

#ChannelKeywordRemove("$GENV_MSHOME1/config","tcp_intranet","maysaslserver","");
#ChannelKeywordRemove("$GENV_MSHOME1/config","tcp_submit","maysaslserver","");
#ChannelKeywordAdd("$GENV_MSHOME1/config","tcp_intranet","mustsaslserver","");
#ChannelKeywordAdd("$GENV_MSHOME1/config","tcp_local","sourcenosolicit","net.example:ADV,com.example:ADV");
#ChannelKeywordAdd("$GENV_MSHOME1/config","tcp_local","sourcenosolicit","net.example:ADV");
#ChannelKeywordAdd("$GENV_MSHOME1/config","tcp_local","sourcenosolicit","net.example:ADV,com.example:ADV");
#ChannelKeywordAdd("$GENV_MSHOME1/config","tcp_local","slave_debug","");
#ChannelKeywordRemove("$GENV_MSHOME1/config","tcp_local","maysaslserver","");
#ChannelKeywordAdd("$GENV_MSHOME1/config","tcp_local","mustsaslserver","");
#system("diff $server_path/imta.cnf.ORIG $server_path/imta.cnf");

sub GetNumMailMessages {

        my $FunctionName = "GetNumMailMessages";# The name of this function
        my $Mailbox = "";                                  # The mailbox to delete the messages from
        my $Port = "";
        my $MailHost;                                                   # The mailhost
        my $UserName;                                                   # The user name
        my $UserPass;                                                   # The user password
        my $Result = -1;                                                # The result to return
        my $imap;                                                               # An instance of the IMAP class
        my $NumMessages = -1;                                   # The number of messages
        my $Domain = "";
	my $MessageArrayRef;                    # ref to array of msgs

        ($Dummy, $FileName, $LineNum ) = caller();
        @ARGV = @_;
	#print "========= ARGV = @ARGV\n";
	my @copy_ARGV = @ARGV;
	my @unusedArgs = "";

	while (scalar(@copy_ARGV)>0) {
		$arg = shift(@copy_ARGV);
		$arg1 = substr($arg,2);
		if ($arg =~ /-m/) {
			$Mailbox = $arg1;
		} elsif ($arg =~ /-d/) {
			$Domain = $arg1;
		} elsif ($arg =~ /-p/) {
			$Port = $arg1;
		} else {
			push(@unusedArgs,"$arg");
		}
	} #end while
	#print "Values: Mailbox = $Mailbox, Domain = $Domain, Port = $Port\n";

        #$Result = eval { GetOptions('m:s' => \$Mailbox,
        #                            'p:i' => \$Port,
        #                            'd:s' => \$Domain
        #                     );
        #               };

        #unless ($Result) {
        #        print("-e", "-d $FileName", "-l $LineNum", " Invalid parameter passed in call to $FunctionName.  Error occurred parsing:", "\'@_\'\n");
	#	print "Parsing error\n";
        #        return $Result;
        #}

        # Put the remaining arguments back into ARG
        @_ = @ARGV;
	#print "UnusedArgs = @unusedArgs\n";
	my $a = scalar(@unusedArgs);
	#print "length of unusedArgs array is = $a\n";
        #@_ = @ARGV;
        if (scalar(@unusedArgs) != 4)  {
                print("-e", "-d$FileName", "-l$LineNum", "Invalid syntax calling $FunctionName.  Must pass mailhost, usename and password.", "Received: \'@_\'");
                return $Result;
        }
	$a = shift @unusedArgs;
        $MailHost = shift @unusedArgs;
        $UserName = shift @unusedArgs;
        $UserPass = shift @unusedArgs;
        $UserName = $UserName."@".$Domain unless ("$GENV_MAILHOSTDOMAIN" eq "$Domain");

	#print "All Values:MailHost = $MailHost,UserName = $UserName,UserPass = $UserPass\n";
	$imap = Mail::IMAPClient->new(Server => $MailHost, Debug => 1, Port => $Port, User => $UserName, Password => $UserPass);
	$NumMessages = $imap->message_count("$Mailbox");
        if ($NumMessages >= 1) {
		print "==== $UserName has $NumMessages in $Mailbox\n";
	} else {
		#print "==== $UserName has NO in $Mailbox\n";
		print "==== $UserName has $NumMessages in $Mailbox\n";
	}
#	    $imap->select("$Mailbox");
#            for (my $i=1;$i<=$NumMessages;$i++) {
#		my @string = $imap->message_string($i);
#                print "****** msg $i start *******\n";
#                print @string;
#                print "****** msg $i end *******\n";
#            }
#        }
	$imap->logout;
        return $NumMessages;
}

sub NumMailMessages {

	Getopt::Long::Configure("bundling");
	my $debug = 1 if $GENV_VERYVERYNOISY;
	#$Getopt::Long::debug = $debug;

        my $FunctionName = "NumMailMessages";# The name of this function
        my $Mailbox = "inbox";                                  # The mailbox to delete the messages from
        my $Port = "143";
        my $Domain = "us.oracle.com";
        my $MailHost;                                                   # The mailhost
        my $UserName;                                                   # The user name
        my $UserPass;                                                   # The user password
        my $Result = -1;                                                # The result to return
        my $imap;                                                       # An instance of the IMAP class
        my $NumMessages = -1;                                   # The number of messages

        ($Dummy, $FileName, $LineNum ) = caller();
	@ARGV = @_;
	$Result = eval { GetOptions("m=s" => \$Mailbox,
				    "p=s" => \$Port,
				    "d=s" => \$Domain,)
		       };

        unless ($Result) {
                print("-e", "-d $FileName", "-l $LineNum", " Invalid parameter passed in call to $FunctionName.  Error occurred parsing:", "\'@_\'\n");
                return $Result;
        }

        # Put the remaining arguments back into ARG
        @_ = @ARGV;
        if (@_ != 3)  {
                print("-e", "-d$FileName", "-l$LineNum", "Invalid syntax calling $FunctionName.  Must pass mailhost, usename and password.", "Received: \'@_\'");
                return $Result;
        }
        $MailHost = shift;
        $UserName = shift;
        $UserPass = shift;
	#$Port = chop($Port);
        $UserName = $UserName."@".$Domain unless ("$GENV_MAILHOSTDOMAIN" eq "$Domain");

	print "Values: Mailbox = $Mailbox, Domain = $Domain, Port = $Port\n" if($GENV_VERYVERYNOISY);
	print "All Values:MailHost = $MailHost,UserName = $UserName,UserPass = $UserPass\n" if $GENV_VERYVERYNOISY;
	$imap = Mail::IMAPClient->new(Server => $MailHost, Debug => 1, Port => $Port, User => $UserName, Password => $UserPass);
	$NumMessages = $imap->message_count("$Mailbox");
        if ($NumMessages >= 1) {
#	    $imap->select("$Mailbox");
#            for (my $i=1;$i<=$NumMessages;$i++) {
#		$imap->delete_message($i);
#		my @string = $imap->message_string($i);
#                print "****** msg $i start *******\n";
#                print @string;
#                print "****** msg $i end *******\n";
#            }
	    $imap->expunge();
        }
	$imap->logout;
        #return $NumMessages;
}

#GetNumMailMessages("-p$portnum","$GENV_MMPALIAS.$GENV_DOMAIN", "$tester$j", "$tester$j","-d$domain_name$i.$domain_ext");
$GENV_VERYVERYNOISY = 1;
$portnum="143";
$GENV_MMPALIAS = "bakhru";
$GENV_DOMAIN = "us.oracle.com";
$j="0";
$i="3";
$domain ="mmpimap"."$i"."domain"."$j".".com";
$mailbox = "folder1/folder11/folder111";
#GetNumMailMessages("-m$mailbox","-p$portnum","$GENV_MMPALIAS.$GENV_DOMAIN", "backupnrestore22", "backupnrestore22","-d$GENV_DOMAIN");
#NumMailMessages("-m$mailbox","-p$portnum","$GENV_MMPALIAS.$GENV_DOMAIN", "tester$j", "tester$j","-d$domain");
#NumMailMessages("-m$mailbox","-p$portnum","$GENV_MMPALIAS.$GENV_DOMAIN", "neo1", "neo1");
#NumMailMessages("-m$mailbox","-p$portnum","$GENV_MMPALIAS.$GENV_DOMAIN", "tester$j", "tester$j","-d$domain");
#GetNumMailMessages("$GENV_MMPALIAS.$GENV_DOMAIN", "tester$j", "tester$j");

sub MTA_ChannelAdd
{
	my ($server_path, $channel_block, $replace) = @_;

        my ($channel, $channel_seen, $imta_cnf, $imta_cnf_tmp, $line, $new_channel_block, @tokens);

	$TLE_ModuleSourceDir = "/space/src/msg_next/msg/test/tle/MTA_Config";
	$TLE_ModuleDirectory = ".";
        # Determine the name of the channel to be added
        ($channel, $tokens) = split(' ', $channel_block, 2);
	print "channel : $channel\n";
	print "tokens : $tokens\n";
        unless( open (FH, "<$TLE_ModuleSourceDir/../MSGCONFIGURE/recipes/channel_add.rcp")) {
                print "Unable to open file $TLE_ModuleSourceDir/../MSGCONFIGURE/channel_add.rcp";
                close(FH);return 0;
        }
        @FileContents = <FH>;
	close(FH);

        foreach $Line (@FileContents) 
	{
		#chomp(@tokens);
		$Line =~ s/CHANNEL_BLOCK/$tokens/g;
		$Line =~ s/CHANNEL/$channel/g;
		if($replace) {
			$Line =~ s/add_channel/replace_channel/; 
		}
	}

        unless( open (OUT, ">$TLE_ModuleDirectory/channel_add.rcp")) {
                print "Unable to open file $TLE_ModuleDirectory/channel_add.rcp";
                close(OUT);return 0;
        }
	print OUT @FileContents;
	close(OUT);
	system("cat $TLE_ModuleDirectory/channel_add.rcp")if($GENV_VERYVERYNOISY);
	print("$GENV_MSHOME1/sbin/msconfig run $TLE_ModuleDirectory/channel_add.rcp\n");
	system("$GENV_MSHOME1/sbin/msconfig run $TLE_ModuleDirectory/channel_add.rcp");
	system("$GENV_MSHOME1/sbin/msconfig show channel:$channel");
	#unlink("$TLE_ModuleDirectory");
	return 1;
}

#MTA_ChannelAdd("$GENV_MSHOME1/bin/","domain_attr_test \ndomain_attr_test-daemon",0);
#MTA_ChannelAdd("$GENV_MSHOME1/bin/","user_attr_test \nuser_attr_test-daemon");
