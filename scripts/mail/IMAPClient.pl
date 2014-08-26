#!/usr/bin/perl

use Mail::IMAPClient;
use Getopt::Long;
$GENV_VERYVERYNOISY=1;

sub MSG_GetMessage(@) {
        my  $FunctionName = "MSG_GetMessage";       # The name of this function
        my  $Domain = "us.oracle.com"; # The domain the id is in
        my  $GetHeader = 0;         # True if the header should be retrieved
        my  $GetBody = 0;           # True if the body should be retrieved
        my  $GetBoth = 0;           # True if both the header and the body should be retrieved
        my  $ID;                    # The ID of the user to get the number of messages from
        my  $IDString;              # The ID and the domain if it is not the default domain
        my  $Imap = "";             # The imap object
        my  $Index = 0;             # Array index
        my  $Internal = 0;          # True if this is an internal call
        my  $MailBox = "";          # The mailbox to get the number of messages from
        my  $MailHostDomain = "bakhru.us.oracle.com"; # The mailhost plus the domain
        my  $Line = "";             # A single line from the IMAP call
        my  $Lines = "";            # The array of lines returned from the IMAP call
        my  $NoRecipientCheck = 0;  # True if we should not check that the ID passed
        my  $NoPrint = 0;           # when set, do not call __Msg_PrintReturnedMessage
        my  $NumMessages;           # The number of messages in a mailbox
        my  $MsgToGet = 0;          # The message number to retrieve
        my  $Password = "";         # The password to be used to access the mailbox
        my  $Result = 1;            # The result of calling a routine
        my  %ReturnStruct =();      # The structure to be returned
        my  $SendId = 0;            # The send id returned from the call to MSG_SendMessage
        my  $SendIdLine = "";       # The string to search for with the send id
        my  $SearchString = "";     # The search string
        my  $SearchNumber = "";     # The msg number to retrieve
	my  @Lines = "";

        @ARGV = @_;
        # Set the option to allow bundling of options (ie: -pv)
        Getopt::Long::config ('bundling');
        $Result = eval {GetOptions ('p=s' => \$Password,
                'd=s' => \$Domain,
                'm=s' => \$MailBox,
                'h'   => \$GetHeader,
                'i'   => \$NoRecipientCheck,
                'b'   => \$GetBody,
                's=s' => \$SearchString,
                'n=s' => \$SearchNumber,
                'F=s' => \$FunctionName,
                'I'   => \$Internal,
                'x'   => \$NoPrint
                )
        };

        unless ($Internal) {
                ($Dummy, $FileName, $LineNum ) = caller();
        }
        unless ($Result) {
                print "-d$FileName", "-l$LineNum", "Invalid parameter passed in call to $FunctionName. Error occurred parsing: \'@_\'";
                return undef;
        }

	if($MailBox){MSG_Trim($MailBox);}
	if($Password){MSG_Trim($Password);}

        if ($SearchString || $SearchNumber) {
                $SearchString = MSG_Trim($SearchString);
                if( $SearchNumber ne "" ) {
                        $SearchNumber = MSG_Trim($SearchNumber);
                        unless( $SearchNumber =~ /^\d+$/ ) {
                                print "-d$FileName", "-l$LineNum",
                                "Invalid parameter passed in call to $FunctionName.",
                                "Invalid Search Number given with -n flag.",
                                "Error occurred parsing \'@_\'";
                                return undef;
                        }
                }
                $NoRecipientCheck = 1;
                unless (@ARGV >= 0) {
                        print "-e", "-d$FileName", "-l$LineNum",
                        "ID must be passed to $FunctionName, received nothing.";
                        return undef;
                }
                $ID = shift @ARGV;
                if ($SearchString && $SearchNumber) {
                        print "-e", "-d$FileName", "-l$LineNum",
                        "Cannot use the -s and -n flag together.";
                        return undef;
                }
                unless ($MailBox and $Password) {
                        print "-e", "-d$FileName", "-l$LineNum",
                        "The Mailbox and Password must be entered.";
                        return undef;
                }
        } else {
                unless (@ARGV >= 1) {
                        print "-e", "-d$FileName", "-l$LineNum",
                        "ID and SendID must be passed to $FunctionName, received nothing.";
                        return undef;
                }
                $ID = shift @ARGV;
                unless (@ARGV >= 1) {
                        print "-e", "-d$FileName", "-l$LineNum",
                        "SendID must be passed to $FunctionName, received nothing.";
                        return undef;
                }
                $SendId = shift @ARGV;
                unless (exists ($MessagesSent {$SendId})) {
                        print "-e", "-d$FileName", "-l$LineNum",
                        "Send Id passed to $FunctionName was not a kept message.  You must",
                        "pass the \'-k\' flag to MSG_SendMessage to store the message";
                        $Result = 0;
                }
        }
        if (@ARGV) {
                print "-e", "-d$FileName", "-l$LineNum",
                "Too many parameters passed in call to $FunctionName.",
                "Error occurred parsing: \'@_\'";
                $Result = 0;
        }
        unless ($Result) {
                return undef;
        }

        if ($Domain eq $GENV_MAILHOSTDOMAIN) {
                $IDString = $ID;
        }
        else {
                $IDString = "$ID\@$Domain";
        }

        # If both the flags or neither of the flags were passed, we get both parts.
        if (($GetHeader && $GetBody) || (!$GetHeader && !$GetBody)) {
                $GetBoth = 1;
        }
	#$Imap = Mail::IMAPClient->new(Server => $MailHostDomain, Debug => $GENV_VERYVERYNOISY, Debug_fh => IO::File->new(">>$TLE_ModuleDirectory/detaillog"), Port => $GENV_IMAPPORT, User => $ID, Password => $Password);
	$Imap = Mail::IMAPClient->new(Server => $MailHostDomain, Debug => 0, Port => 143, User => $IDString, Password => $Password);
        if ($Imap) {
                print "==== $FunctionName obtained an IMAP connection for user \'$IDString\'" if $TLE_Verbose;
		@Lines = $Imap->Results();
		print @Lines;
        }
        else {
                print "==== Can't get an IMAP connection to $MailHostDomain using port $GENV_IMAPPORT";
                return undef;
        }

        @Lines = $Imap->select("$MailBox");
	@Lines = $Imap->Results();
        print "==== Output from IMAP Select for mailbox $MailBox\n";
	print @Lines;
	$NumMessages = $Imap->message_count($MailBox);
        unless ($NumMessages) {
                print "==== No messages exist in mailbox $MailBox for user $IDString";
                return 0;
        }else {
                print "==== Total $NumMessages messages found in mailbox $MailBox for user $IDString\n";
	}

        if ($SearchString) {
		my @msgs  = $Imap->search("TEXT \"$SearchString\"") or warn "search failed: $@\n";
		@Lines = $Imap->Results();
		print @Lines;
		if (@msgs) {
      			print "=== Search matches: @msgs\n";
			$MsgToGet = $msgs[0];
		}
		else {
      			print "Error in search: $@\n";
		}
        } else {
                $MsgToGet = $SearchNumber;
        }

        unless ($MsgToGet) {
                print "==== Message not found in mailbox $MailBox for user $IDString";
                return 0;
        }

        if ($GetHeader) {
                @Lines = $Imap->fetch($MsgToGet, "RFC822.HEADER");
		@Lines = $Imap->Results();
                print "==== Output from IMAP fetch for HEADER ONLY:\n";
		print "@Lines\n";
        } # end if ($GetHeader)

        if ($GetBody) {
                @Lines = $Imap->fetch($MsgToGet, "RFC822.TEXT");
		@Lines = $Imap->Results();
                print "==== Output from IMAP fetch for BODY ONLY:\n";
		print "@Lines\n";
        } # end if ($GetBody)

	if($GetBoth) {
                @Lines = $Imap->message_string($MsgToGet);
                print "==== Output from IMAP fetch for ALL:\n";
		print "@Lines\n";
	}
        return @Lines;
}

sub MSG_Trim($)
{
        my $string = shift;
        $string =~ s/^\s+//;
        $string =~ s/\s+$//;
        return $string;
}

sub MSG_Search {
        my ($pattern, @SearchArray) = @_;
        my $line;
        #searching the pattern in @SearchArray
        foreach $line (@SearchArray) {
                print "Searching for pattern: $pattern in the following line:";
                print "$line";
                if ($line =~ /$pattern/) {
                        print "Found match of pattern: $pattern";
                        return 1;
                }
        } #foreach loop ends
        return 0;
}

#my @lsMsg = MSG_GetMessage("-pmta_futurerelease4", "mta_futurerelease4", "-mINBOX", "-n2");
#my @lsMsg = MSG_GetMessage("-ppassword", "18n_snd1297470491test002", "-mINBOX", "-sBody autoresponder.untagged");
#my @lsMsg = MSG_GetMessage("-pneo1", "neo1", "-mINBOX", "-sBody autoresponder.untagged");
#$a = MSG_Search("Future-release-request: until;", "@lsMsg");
#MSG_GetMessage("-dus.oracle.com", "-pneo1", "neo1", "-mINBOX", "-n 1", "-b");
my @lsMsg = MSG_GetMessage("-dus.oracle.com", "-pneo5", "neo5", "-mINBOX", "-n 1", "-h");
print "Result = @lsMsg\n";
#MSG_GetMessage("-dus.oracle.com", "-pneo1", "neo1", "-mINBOX","-sTest");
#MSG_GetMessage("-dus.oracle.com", "-pneo1", "neo1", "-mINBOX","-sTest", "-b");
#MSG_GetMessage("-dus.oracle.com", "-pneo1", "neo1", "-mINBOX","-sTest", "-h");
