#!/usr/bin/perl
require Net::SSLeay;
use Net::Telnet ();
use Socket;
use Getopt::Long;
use Net::SMTP;
use Net::IMAP;
use MIME::Base64;
use Cwd;

Net::SSLeay->import(qw(die_now die_if_ssl_error));
Net::SSLeay::SSLeay_add_ssl_algorithms();

if (@ARGV < 4)
 {
  print ("\nUsage: $0 mailhost user authtype Port domain\n\n");
  exit;
}

$host  = $ARGV[0];
$source = $ARGV[1];
$auth_type = $ARGV[2];
$Port = $ARGV[3];
$domain = $ARGV[4];
$password=$source;


my $EOL = "\r\n";
my $MailHost = $host;
my $Port = $Port;
my @InputCmds = ();

if ($domain eq ""){
        print "without domain\n";
        $sasl = encode_base64("$source\0$source\0$source");
}
else {
        print "with domain\n";
        $sasl = encode_base64("\000$source\@$domain\000$source");
	$source = "$source\@$domain";
}

print ("SASL encoded value = $sasl\n");
print ("Username = $source\n");

if ($auth_type =~ /CRAM-MD5/i) {
        print "Auth type = $auth_type \n";
} elsif ($auth_type =~ /NORMAL/i) {
        print "Auth type = $auth_type \n";
	test_auth_normal($Port);
} elsif ($auth_type =~ /PLAIN/i) {
        print "Auth type = $auth_type \n";
	test_auth_plain($Port);
} else{ return 1; }

sub test_auth_plain ($Port)
{
	if($Port =~ /993/){
		#IMAP commands
		@InputCmds = ("101 AUTHENTICATE PLAIN $sasl", "102 SELECT INBOX", "103 FETCH 1 rfc822", "104 CAPABILITY", "105 LOGOUT");
	}elsif($Port=~ /995/){
		#POP commands
		@InputCmds = ("AUTH PLAIN $sasl", "LIST", "RETR 1", "QUIT");
	}elsif($Port =~ /465/){
		#SMTP commands
		@InputCmds = ("ehlo","AUTH PLAIN $sasl", "mail from: $source", "rcpt to: $source", "DATA", "This is a test mail\r\n.", "QUIT");
	}elsif($Port =~ /25/){
		#SMTP commands
		@InputCmds = ("ehlo", "AUTH PLAIN $sasl", "mail from: $source", "rcpt to: $source", "DATA", "This is a test mail\r\n.", "QUIT");
	}else{
		print "Invalid Port number... exiting..\n";
		exit;
	}
} #test_auth_plain ends

sub test_auth_normal ($Port)
{
my $encoded_username = encode_base64("$source");
my $encoded_password = encode_base64("$password");

if($Port =~ /993/){
	#IMAP commands
	@InputCmds = ("101 LOGIN $source $password", "102 SELECT INBOX", "103 FETCH 1 rfc822", "104 CAPABILITY", "105 LOGOUT");
}elsif($Port=~ /995/){
	#POP commands
	@InputCmds = ("user $source", "pass $password", "LIST", "RETR 1", "QUIT");
}elsif($Port =~ /465/){
	#SMTP commands
	@InputCmds = ("ehlo","AUTH LOGIN", "$encoded_username", "$encoded_password", "mail from: $source", "rcpt to: $source", "DATA", "This is a test mail\r\n.", "QUIT");
}else{
	print "Invalid Port number... exiting..\n";
	exit;
}
} #test_auth_normal ends

$Port = getservbyname ($Port, 'tcp') unless $Port =~ /^\d+$/;
$DestIP = gethostbyname ($MailHost);
$DestServParams = sockaddr_in($Port, $DestIP);

unless (socket  (S, &AF_INET, &SOCK_STREAM, 0)) {
	print "SSL: failed on socket creation\n";
}
unless (connect (S, $DestServParams)) {
	print "SSL: Socket connect failed\n";
}

select  (S);  $| = 1; select (STDOUT);

unless ($CTX = Net::SSLeay::CTX_new()) {
	print "Failed to create SSL_CTX\n";
}
unless ($SSL = Net::SSLeay::new($CTX)) {
	print "Failed to create SSL\n";
}

Net::SSLeay::set_fd($SSL, fileno(S));   # Must use fileno
$Result = Net::SSLeay::connect($SSL);
print "SSL connect result: $Result\n";
if ($Result <= 0) {
	print "SSL connect failed!. Return: $Result\n";
	# Free the resources
	Net::SSLeay::free ($SSL);       # Tear down connection
	Net::SSLeay::CTX_free ($CTX);
	close S;
}
print "SSL Connect Result for $Port of $MailHost is : $Result\n";
my $strCipher = Net::SSLeay::get_cipher($SSL);
my $strCert =  Net::SSLeay::dump_peer_certificate($SSL);

print "SSL Connect Result for $MailHost is : $Result\n";
print "Cipher Used: $strCipher\n";
print "Certificate Used: $strCert\n";

# Write all the commands and do only one read
foreach $Command (@InputCmds) {
	#print "Issuing command $Command\n";
	$Command = "$Command$EOL";
	unless ($Result = Net::SSLeay::write($SSL, $Command)) {
		print "Failed on SSL write\n";
	}
}

$SSLOutput = Net::SSLeay::ssl_read_all($SSL);  # Perl returns undef on failure
$SSLOutput =~ s/\^M//g; # Remove control-M
print "$SSLOutput\n"; # Write output to outputfile
shutdown S, 1; # Shutdown write
Net::SSLeay::free ($SSL);               # Tear down connection
Net::SSLeay::CTX_free ($CTX);
close S;
