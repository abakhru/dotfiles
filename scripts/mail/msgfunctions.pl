#!/usr/bin/perl
use Mail::IMAPClient;
use Getopt::Long;
require "msconfig.pl";

import_GENV();

sub MSG_Trim($)
{
        my $string = shift;
        $string =~ s/^\s+//;
        $string =~ s/\s+$//;
        return $string;
}

sub MSG_HeaderCheck(@)
{
        my $FunctionName = "MSG_HeaderCheck";   # The name of this function
        my $Domain = $GENV_MAILHOSTDOMAIN;      # The domain the id is in
        my @ErrorArray = (0, 0, 0, 0, 0, 0, 0, 0, 0); # The error array to return
        my $Username;                           # The ID of the user to get the number of messages from
        my $MailBox;                    # NOTE: This is not used in this function.  It is simply
        my $Password = "";              # NOTE: This is not used in this function.  It is simply
        my $exp_header_value = "";
        my $actual_header_value = "";
        my $header_name = "";
        my $Result = 1;         # The result to return
        my $ReturnMsg = ();     # The message structure to be returned

        (undef, $FileName, $LineNum ) = caller();
        @ARGV = @_;
        # Set the option to allow bundling of options (ie: -pv)
        Getopt::Long::config ('bundling');
        $Result = eval{GetOptions ('p=s' => \$Password,
		                   'm=s' => \$Mailbox,
		                   'd=s' => \$Domain )
        };

        unless($Result){
                print "Invalid parameters passed in call to $FunctionName\n";
                return $Result;
        }
        unless(@ARGV){
                print "Username/ID must be passed to $FunctionName\n";
                return 0;
        }
        $Username = shift @ARGV;
        $header_name = shift @ARGV;
        $exp_header_value = shift @ARGV;
        if(@ARGV){
                print "Too many parameters passed to $FunctionName\n";
                return 0;
        }
        unless($Password){ $Password = $Username; }
        unless($Mailbox){ $Mailbox = "INBOX"; }
        unless($Domain){ $Domain = "$GENV_MAILHOSTDOMAIN"; }

        $Password = MSG_Trim($Password);
        $Mailbox  = MSG_Trim($Mailbox);
        $Domain   = MSG_Trim($Domain);

        $Username .= "@".$Domain unless ($Domain eq $GENV_MAILHOSTDOMAIN);

        my $imap = Mail::IMAPClient->new(Server => "$GENV_MSHOST1.$GENV_DOMAIN",Port => $GENV_IMAPPORT, Debug => 1, User => "$Username", Password => "$Password");
        if (!$imap) {
                print "Connection failed\n";
        } else {
                @ImapResponse = $imap->Results();
                print "==== OUT : @ImapResponse\n";
        }
        if ("@ImapResponse" !~ /logged in/) {
                print "==== uid = $Username, pwd = $Password\n";
                print "==== Login failed, response : @ImapResponse\n";
        }
        $imap->select("$Mailbox");
        int($nextUid = $imap->uidnext("$Mailbox"));
        $actual_header_value = $imap->get_header(--$nextUid, "$header_name");
        $imap->logout();

        $actual_header_value = MSG_Trim($actual_header_value);
        print "==== Actual value: \"$header_name: $actual_header_value\"\n";
        print "==== Expect value: \"$header_name: $exp_header_value\"\n";

        if ("$exp_header_value" eq "$actual_header_value") {
                print "==== Actual & Expected Header value MATCHED\n";
                return 1;
        }else{
                print "==== NO match found\n";
                return 0;
        }
}

#$a = MSG_HeaderCheck("mtaChannel1", "-d mtaChannel.com", "-p mtaChannel1", "-m inbox", "Comments", "Removed header field(s) - Return-path:, From:, on-bakhru=us.oracle.com\\\@us.oracle.com; x-software=spfmilter 0.97 http:, PT bakhru\\\@us.oracle.com); Sun, 26 May 2013 19:, :, Date-warning:, Message-id:, Original-recipient:, Received:");
$a = MSG_HeaderCheck("mtaChannel1", "-d mtaChannel.com", "-p mtaChannel1", "-m inbox", "Subject", "0123456789101112131415161718192021222324252627282930313233343536373839404142434445464748495051525354555657585960616263646566676869707172737475767778798081828384858687888990919293949596979899");
