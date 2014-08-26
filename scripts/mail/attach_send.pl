#!/usr/bin/perl

#############
# Use files #
#############
use Getopt::Long;
use Net::IMAP;
use Net::SMTP;
use MIME::Base64;
use File::Basename;
use FileHandle;

if(@ARGV < 3){
	print "==== USAGE: ./attach.pl host from to\n";
	exit 0;
}

my $dir = ".";
my $host = "$ARGV[0]";
my $userFrom = "$ARGV[1]";
my $userTo = "$ARGV[2]";
#my $mailFile = "$dir/invite.ics";
my $mailFile = "/export/amit/msg_next/msg/test/tle/pop3_new/msg4989866";
#my $mailFile = "/export/amit/msg75/msg/test/tle/mailBoxPurge/1KB_File";
#my $mailFile = "/export/amit/msg75/msg/test/tle/sys_userquota/10KB_file";
my $NextAvailableSendID = 100;

my ($sendResult, $SendID) = MSG_SendMessage("-f $userFrom", "-t $userTo", "-a $mailFile","-l $dir/mailfile");
unless($sendResult){
	print  "Cannot send emails to user $userTo, $SendID, $sendResult\n";
}

sub MSG_SendMessage(@) {
	my 	$FunctionName = "MSG_SendMessage";	# The name of this function
	my	$FromID = "";		# The from id
	my	$ToID = "";			# The to id
	my	$CCID = "";			# The cc id
	my	$BCCID = "";		# The bcc id
	my	$Subject = "";		# The message subject
	my	$Attach = "";		# The message attachment
	my	$SigFile = "";		# The message signature file
	my	$MailHost = "$host";		# The host to send mail to
	my	$MailBox = "INBOX";		# The mailbox to send messages to
	my	$Pri = "";			# The priority to be used for the message
	my	$Result = 1;		# The result of calling a routine
	my	@TempArray = ();	# A temporary array used for splitting inputs
	my	@TOArray = ();		# The array of TO recipients
	my	$Keep = 0;			# TRUE if the message should be kept in the
	my  $ContentType = "";      #The content-type header value
	my  $ContentLength = "";    #The Content-language header value
	my  $XAcceptLang = "";      #The X-Accept-Language header value
	my  $ContEncode = "";       #The Content-transfer-encoding header value sent message hash
	my	%SentMessage = %DefaultSendOptions; # The options to be used to send or retrieve this message
	my	$Smtp;				# The instance of net::smtp
	my	$SmtpPort = 25;	# The smtp port to use to send the message
	my	$MessageSize = 0;	# The size of the message to be sent
	my	$MessageFile = "";	# The name of the file containing the body of the message
	my	$fhMESSAGE;			# The file handle for the message file
	my	@MessageIn = ();	# The array to hold the message from the message file
	my	$MessageLine;		# A single line of the message
	my	$Message = "";		# The message to send
	my  $AttachFile = new FileHandle;	# The file handle for the attachment
	my  @AttachLines;	# The lines in the attachment file
	my  $AttachContents = "";	# The contents of the attachment file
	my  @AttachEncoded = "";	# The encoded attachment files
	my  @Attach_FileName = ();			# The filename of the the attached file (not the absolute path)
	my  $EncodeType = "base64";	# The encode type
	my  $SigFileHandle = new FileHandle; # The file handle for the signature file
	my  @SigLines;	# The lines in the signature file
	my  $SigContents = "";	# The contents of the signature file
	my  $SigEncoded = "";	# The encoded signature file
	my  $SigFileName = "";	# The filename of the the signature file (not the absolute path)
	my  $PlusMailbox = "";  # The mailbox name with "+"" prepended to it, or a null string if no mailbox is specified.
	my  @PresetPsw;			# The passwords preset by one of the Set... functions
	my  $WaitSecs = "3";     # The number of secs to wait if SMTP is not available
	my  $NoPrint = 0;       # When set, do not call__Msg_PrintSentMessage()
	my ( $id, $psw, $dom ); # temp vars for sorting out values of Id, Password, and Domain
	
	($Dummy, $FileName, $LineNum ) = caller();
	@ARGV = @_;
	# Set the option to allow bundling of options (ie: -pv)
	Getopt::Long::config ('bundling');
	$Result = eval { GetOptions('f=s' => \$FromID,
		't=s' => \$ToID,
		'c=s' => \$CCID,
		'b=s' => \$BCCID,
		's=s' => \$Subject,
		'a=s' => \$Attach,
		'g=s' => \$SigFile,
		'h=s' => \$MailHost,
		'd=s' => \$Domain,
		'k'   => \$Keep,
		'm=s' => \$MailBox,
		'p=i' => \$SmtpPort,
		'i=s' => \$Pri,
		'r'   => \$SentMessage{ReturnReceipt},
		'e'   => \$SentMessage{Encrypt},
		'n'   => \$SentMessage{Sign},
		'u'   => \$SentMessage{UUEncode},
		'w=s' => \$WaitSecs,
		'z=i' => \$MessageSize,
		'l=s' => \$MessageFile,
		'y=s' => \$ContentType,
		'j=s' => \$ContentLang,
		'q=s' => \$XAcceptLang,
		'o=s' => \$ContEncode,
		'x'   => \$NoPrint
		)
	};
	
	unless ($Result) {
		 print "Invalid parameter passed in call to $FunctionName.  Error occurred parsing:", "\'@_\'";
		return $Result;
	}
	if (@ARGV) {
		# If there is anything left, it must be the message
		$Message = shift @ARGV;
		if (ref($Message) ne 'ARRAY') {
			print "Message passed to $FunctionName must be a reference to an array\n";
			$Result = 0;
		}
	}
	$Attach =~ s/\s+//g;
	my @Attach_Files = split /,/, $Attach;
	my $xx=@Attach_Files;
	
	if (($Message and ($MessageFile or $MessageSize)) or
	($MessageFile and $MessageSize) ) {
		 print "Can't use the -z flag, -l flag and a message in the same call\n";
		$Result = 0;
	}
	if ($Domain) {
		$SentMessage{DefaultDomain} = TLE_StripLine($Domain);
	}
	if ($MailHost) {
		$SentMessage{MailHost} = TLE_StripLine($MailHost);
	}
	$SentMessage{Subject} = "TestMail";
	
	if ($xx gt 0) {
		my $i=0;
		foreach $Attach_File (@Attach_Files){
			if (-e $Attach_File) {
				if (-r $Attach_File) {
					$SentMessage{Attachment} = $Attach_File;
					unless (open($AttachFile, "$Attach_File")) {
						 print "Attachment file \'$Attach_File\' cannot be opened in call to $FunctionName\n";
					}
					binmode $AttachFile;
					@AttachLines = <$AttachFile>;
					close($AttachFile);
					$AttachContents[$i] = join '', @AttachLines;
					if ($SentMessage{UUEncode}) {
						$AttachEncoded[$i] = pack "u", $AttachContents[$i];
						$EncodeType = "uuencode";
					} else {
						$AttachEncoded[$i] = encode_base64($AttachContents[$i]);
					}
					$Attach_FileName[$i] = basename($Attach_File);
				}
				else {
					 print "Attachment file - $Attach_File - is not readable in call to $FunctionName\n";
					$Result = 0;
				}
			}
			else {
				 print "Attachment file - $Attach_File - does not exist in call to $FunctionName\n";
				$Result = 0;
			}
			$i++;
		}
	}
	
	$MailBox = TLE_StripLine($MailBox);
	if ($MailBox) {
		$SentMessage{MailBox} = $MailBox;
	}
	$PlusMailbox = "+" . $SentMessage{MailBox}
	unless( $SentMessage{MailBox} eq "INBOX" );
	
	if ($FromID) {
		$FromID = TLE_StripLine($FromID);
		@TempArray = split / /, $FromID;
		$SentMessage{SenderString} = $TempArray[0];
		#  See if our sender is in the form of name@domain.  If so, split it out
		#  to keep the id separate from the domain.
		if ($TempArray[0] =~ /\@/) {
			$SentMessage{SenderID} = $`;
			$SentMessage{SenderDomain} = $';
		}
		else {
			$SentMessage{SenderID} = $TempArray[0];
			$SentMessage{SenderDomain} = "";
		}
		if (@TempArray == 1) {
			# Only have an ID (no password) so assume password is same as ID
			$SentMessage{SenderPsw} = $SentMessage{SenderID};
		}
		elsif (@TempArray == 2) {
			$SentMessage{SenderPsw} = $TempArray[1];
		}
		else {
			 print "Incorrect call to $FunctionName. Too may parameters for \'-f\' flag, only 2 parameters allowed\n";
			$Result = 0;
		}
	}
	unless ($Result) {
		# We have some type of error in parameters.  Let's bail.
		return $Result;
	}
	
	
	if ($ToID) {
		# we are replacing the pre-set To and ToPsw, if any
		$SentMessage{To} = TLE_StripLine($ToID);
		@PresetPsw = ();
	}
	else { # use the preset (current value of) $SentMessage{To} and {ToPsw}
		@PresetPsw = @{$SentMessage{ToPsw}};
	}
	
	# Start with empty arrays
	@{$SentMessage{ToID}} = ();
	@{$SentMessage{ToPsw}} = ();
	@{$SentMessage{ToDomain}} = ();
	
	@TempArray = split /;/, $SentMessage{To};
	foreach $IdItem (@TempArray) {
		# if this id contains no domain itself, and a defaultdomain has been supplied,
		# add the default domain
		$IdItem .= "\@$SentMessage{DefaultDomain}"
		if ($IdItem !~ /\@/   &&
		$SentMessage{DefaultDomain} ne "");
		
		# sort out the values for id, password, and domain
		if ($IdItem =~ /\@/) {
			( $id, $psw, $dom ) = ($`, $`, $');
		} else {   # no domain supplied; let the product provide it
			( $id, $psw, $dom ) = ($IdItem, $IdItem, "");
		}
		$psw = shift @PresetPsw if( @PresetPsw );
		
		# make the assignments
		push( @{$SentMessage{ToID}},     $id  );
		push( @{$SentMessage{ToDomain}}, $dom );
		push( @{$SentMessage{ToPsw}},    $psw );
		$SentMessage{TOString} .= "," if ($SentMessage{TOString});
		$SentMessage{TOString} .= $IdItem;
		
		unless( exists $SentMessage{$IdItem} ) {
			$SentMessage{$IdItem}{Domain}  = $dom;
			$SentMessage{$IdItem}{Psw}     = $psw;
		}
		
		if( $dom eq "" ) {
			push ( @TOArray,  "\"$id$PlusMailbox\""       );
		} else {
			push ( @TOArray,  "\"$id$PlusMailbox\"\@$dom" );
		}
	}
	
	if ($CCID) {
		# we are replacing the pre-set CC and CCPsw, if any
		$SentMessage{CC} = TLE_StripLine($CCID);
		@PresetPsw = ();
	}
	else { # use the preset (current value of) $SentMessage{CC} and {CCPsw}
		@PresetPsw = @{$SentMessage{CCPsw}};
	}
	
	# Start with empty arrays
	@{$SentMessage{CCID}} = ();
	@{$SentMessage{CCPsw}} = ();
	@{$SentMessage{CCDomain}} = ();
	
	@TempArray = split /;/, $SentMessage{CC};
	foreach $IdItem (@TempArray) {
		# if this id contains no domain itself, and a defaultdomain has been supplied,
		# add the default domain
		$IdItem .= "\@$SentMessage{DefaultDomain}"
		if ($IdItem !~ /\@/   &&
		$SentMessage{DefaultDomain} ne "");
		
		# sort out the values for id, password, and domain
		if ($IdItem =~ /\@/) {
			( $id, $psw, $dom ) = ($`, $`, $');
		} else {   # no domain supplied; let the product provide it
			( $id, $psw, $dom ) = ($IdItem, $IdItem, "");
		}
		$psw = shift @PresetPsw if( @PresetPsw );
		
		# make the assignments
		push( @{$SentMessage{CCID}},     $id  );
		push( @{$SentMessage{CCDomain}}, $dom );
		push( @{$SentMessage{CCPsw}},    $psw );
		$SentMessage{CCString} .= "," if ($SentMessage{CCString});
		$SentMessage{CCString} .= $IdItem;
		
		unless( exists $SentMessage{$IdItem} ) {
			$SentMessage{$IdItem}{Domain}  = $dom;
			$SentMessage{$IdItem}{Psw}     = $psw;
		}
		push ( @TOArray,  $IdItem );
	}
	
	if ($BCCID) {
		# we are replacing the pre-set BCC and BCCPsw, if any
		$SentMessage{BCC} = TLE_StripLine($BCCID);
		@PresetPsw = ();
	}
	else { # use the preset (current value of) $SentMessage{BCC} and {BCCPsw}
		@PresetPsw = @{$SentMessage{BCCPsw}};
	}
	
	# Start with empty arrays
	@{$SentMessage{BCCID}} = ();
	@{$SentMessage{BCCPsw}} = ();
	@{$SentMessage{BCCDomain}} = ();
	
	@TempArray = split /;/, $SentMessage{BCC};
	foreach $IdItem (@TempArray) {
		# if this id contains no domain itself, and a defaultdomain has been supplied,
		# add the default domain
		$IdItem .= "\@$SentMessage{DefaultDomain}"
		if ($IdItem !~ /\@/   &&
		$SentMessage{DefaultDomain} ne "");
		
		# sort out the values for id, password, and domain
		if ($IdItem =~ /\@/) {
			( $id, $psw, $dom ) = ($`, $`, $');
		} else {   # no domain supplied; let the product provide it
			( $id, $psw, $dom ) = ($IdItem, $IdItem, "");
		}
		$psw = shift @PresetPsw if( @PresetPsw );
		
		# make the assignments
		push( @{$SentMessage{BCCID}},     $id  );
		push( @{$SentMessage{BCCDomain}}, $dom );
		push( @{$SentMessage{BCCPsw}},    $psw );
		$SentMessage{BCCString} .= "," if ($SentMessage{BCCString});
		$SentMessage{BCCString} .= $IdItem;
		
		unless( exists $SentMessage{$IdItem} ) {
			$SentMessage{$IdItem}{Domain}  = $dom;
			$SentMessage{$IdItem}{Psw}     = $psw;
		}
		push ( @TOArray,  $IdItem );
	}
	
	if ($ContentType) {
		$SentMessage{ContType} = TLE_StripLine($ContentType);
	}  else {
		$SendMessage{ContType} = "";
	}
	
	if ($ContentLang) {
		$SentMessage{ContLang} = TLE_StripLine($ContentLang);
	}  else {
		$SendMessage{ContLang} = "";
	}
	
	if ($XAcceptLang) {
		$SentMessage{XLang} = TLE_StripLine($XAcceptLang);
	}  else {
		$SendMessage{XLang} = "";
	}
	
	if ($ContEncode) {
		$SentMessage{ContEncode} = TLE_StripLine($ContEncode);
	}  else {
		$SendMessage{ContEncode} = "";
	}
	
	
	if ($MessageSize) {
		# Generate a message to be sent
		$Message = __Msg_GenerateMsg($MessageSize);
	}
	$MessageFile = TLE_StripLine($MessageFile);
	if ($MessageFile) {
		if (-e $MessageFile) {
			if (-r $MessageFile) {
				$fhMESSAGE = new FileHandle "$MessageFile", "r";
				unless (defined $fhMESSAGE)  {
					 "e", "Can't open the message file - $MessageFile.";
					return 0;
				}
				@MessageIn = <$fhMESSAGE>;	# Read the message contents into an array
				$fhMESSAGE -> close;
				chomp @MessageIn;
				$Message = \@MessageIn;
			}
			else {
				print "Message file - $MessageFile - is not readable in call to $FunctionName\n";
				return 0;
			}
		}
		else {
			 print "Message file - $MessageFile - does not exist in call to $FunctionName\n";
			return 0;
		}
	}
	$SentMessage{Message} = $Message;
	$SentMessage{MessageSize} = 0;
	
	###### Add more code here to handle encrypting, etc	later.
	
	CONNECT:   # Send the message
	$Smtp = Net::SMTP->new("$SentMessage{MailHost}", Port => "$SmtpPort", Hello => "$SentMessage{MailHost}", Debug => 0);
	if ($Smtp) {
		print "Obtained an SMTP connection to $SentMessage{MailHost}\n";
	}
	else {
		if ($WaitSecs) {
			print "SMTP unavailable; sleeping $WaitSecs secs to retry\n";
			sleep $WaitSecs;
			$WaitSecs = 0;
			goto CONNECT;
		}
		print "Can't get an SMTP connection to $SentMessage{MailHost}\n";
		return 0;
	}
	$Smtp->auth("$SentMessage{SenderString}","$SentMessage{SenderString}");
	
	$SentMessage{TimeSent} = time();
	unless ($Smtp->mail("$SentMessage{SenderString}\n")) {
		print "Invalid id used in -f parameter: $SentMessage{SenderString}\n";
		return 0;
	}
	unless ($Smtp->to(@TOArray)) {
		print "Invalid id used in To, CC, or BCC parameter: @TOArray\n";
		return 0;
	}
	
	unless ($Smtp->data()) {
		 print "Response beginning with 3 not received from a data command: Received\n",
		$Smtp->code();
		return 0;
	}
	unless ($Smtp->datasend("Subject:  $SentMessage{Subject}\n")) {
		print "Response beginning with 3 not received from a data command: Received\n",
		$Smtp->code();
		print "Sent: Subject:  $SentMessage{Subject}\n";
		$Result = 0;
	}
	unless ($Smtp->datasend("To:  $SentMessage{TOString}\n")) {
		 print "Response beginning with 3 not received from a data command: Received\n";
		$Smtp->code();
		 print "Sent: To:  $SentMessage{TOString}\n";
		$Result = 0;
	}

	if ($SentMessage{CCString}) {
		unless ($Smtp->datasend("Cc:  $SentMessage{CCString}\n")) {
			print "Response beginning with 3 not received from a data command: Received\n";
			$Smtp->code();
			print "Sent:  Cc:  $SentMessage{CCString}\n";
			$Result = 0;
		}
	}
	if ($SentMessage{BCCString}) {
		unless ($Smtp->datasend("Bcc:  $SentMessage{BCCString}\n")) {
			print "Response beginning with 3 not received from a data command: Received\n";
			$Smtp->code();
			print "Sent:  Bcc:  $SentMessage{BCCString}\n";
			$Result = 0;
		}
	}
	if ($SentMessage{ContType}) {
		unless ($Smtp->datasend("Content-type:  $SentMessage{ContType}\n")) {
			print "Response beginning with 3 not received from a data command: Received\n";
			$Smtp->code();
			print "Sent:  Content-Type:  $SentMessage{ContType}";
			$Result = 0;
		}
	}
	if ($SentMessage{ContLang}) {
		unless ($Smtp->datasend("Content-language:  $SentMessage{ContLang}\n")) {
			 print "Response beginning with 3 not received from a data command: Received\n";
			$Smtp->code();
			print "Sent:  Content-language:  $SentMessage{ContLang}\n";
			$Result = 0;
		}
	}
	if ($SentMessage{XLang}) {
		unless ($Smtp->datasend("X-Accept-Language:  $SentMessage{XLang}\n")) {
			print "Response beginning with 3 not received from a data command: Received", $Smtp->code();
			print "Sent:  X-Accept-Language:  $SentMessage{XLang}";
			$Result = 0;
		}
	}

	if ($SentMessage{ContEncode}) {
		unless ($Smtp->datasend("Content-transfer-encoding:  $SentMessage{ContEncode}\n")) {
			print "Response beginning with 3 not received from a data command: Received", $Smtp->code();
			print "Sent:  Content-transfer-encoding:  $SentMessage{ContEncode}";
			$Result = 0;
		}
	}

	if ($SentMessage{ReturnReceipt}) {
		unless ($Smtp->datasend("Return-Receipt-To: $SentMessage{SenderID}\@$SentMessage{SenderDomain}\n")) {
			print "Can not add Return-Receipt-To: Received", $Smtp->code();
			print "Sent: Return-Receipt-To: $SentMessage{SenderID}\@$SentMessage{SenderDomain}\n";
			return 0;
		}
	}

	if ($SentMessage{Attachment}) {
		if("$userTo" eq "caltest6"){
			unless ($Smtp->datasend("X-Oracle-CS-iSchedule-Ignore: Yes\n")) {
				print "Response beginning with 3 not received from a data command: Received\n";
				$Smtp->code();
				print "Sent: X-Oracle-CS-iSchedule-Ignore: Yes\n";
				$Result = 0;
			}
			print "Sent: X-Oracle-CS-iSchedule-Ignore: Yes\n";
           	}
	  
		unless ($Smtp->datasend("MIME-Version: 1.0\n"
					. "Content-type: multipart/mixed; boundary=20cf30549e012f66ee04a2f1cb79\n"
					. "--20cf30549e012f66ee04a2f1cb79\n"
					. "Content-Type: multipart/alternative; boundary=\"20cf30549e012f66e304a2f1cb77\"\n"
					. "Content-Transfer-Encoding: 7bit\n\n" )) {
            		print "Can not write MIME header lines: Received", $Smtp->code();
            		$Result = 0;
		}
	}

	foreach $MessageLine (@$Message) {
          unless ($Smtp->datasend("$MessageLine\n")) {
            print "Response beginning with 3 not received from a data command: Received", $Smtp->code();
            $Result = 0;
          }
	}
    if ($SentMessage{Attachment}) {
	if("$userTo" eq "caltest2"){ $METHOD = "REPLY"; }
	elsif("$userTo" eq "caltest3"){ $METHOD = "CANCEL"; }
	else { $METHOD = "REQUEST"; }

        for($i=0; $i<$xx; $i++){
            unless ($Smtp->datasend("--20cf30549e012f66ee04a2f1cb79\n" .
            #unless( $Smtp->datasend("Content-Type: text/calendar\n" .
            "Content-Type: text/calendar; method=$METHOD\n" .
            "Content-Transfer-Encoding: $EncodeType\n" .
            "Content-Disposition: attachment; filename=$Attach_FileName[$i]\n\n" .
            "$AttachEncoded[$i]" .
            "--20cf30549e012f66ee04a2f1cb79--\n")){
            	print "Can not write MIME header lines: Received", $Smtp->code();
                $Result = 0;
            }
        }
    }
	unless ($Smtp->dataend()) {
		print "Response beginning with 2 not received from a dataend command. Received", $Smtp->code();
		$Result = 0;
	}
	unless ($Smtp->quit) {
		 print "Response beginning with 2 not received from a quit command. Received", $Smtp->code();
		$Result = 0;
	}
	
	# Automatically do some sleeping for the message to arrive where ever the
	#	caller expects.  They will probably have to do some more but I don't
	#	want to always wait any more than this.
	sleep 3;
	if ($Result) {
		# Increment the send id after it gets returned
		return ($NextAvailableSendID++, $SentMessage{MessageSize});
	}
	else {
		return (0, 0);
	}
}
sub TLE_StripLine ($)  {
    my $Line = $_[0];   # The text to be stripped
    chomp $Line;

    # Delete leading whitespace
    $Line = $' if ( $Line =~ /^\s+/ );

    # Strip comments
    $Line = $` if ( $Line =~ /#/ );

    # Delete trailing whitespace
    $Line = $` if ( $Line =~ /\s+$/ );

    return $Line;
}
