#!/usr/bin/perl
#Require SSL here
require Net::SSLeay;
use Net::Telnet ();
use Socket;
use Getopt::Long;
use Net::SMTP;
use Net::IMAP;
use MIME::Base64;
use Cwd;

Net::SSLeay->import(qw(die_now die_if_ssl_error));
#Net::SSLeay::load_error_susergs();
Net::SSLeay::SSLeay_add_ssl_algorithms();

if (@ARGV < 3)
 {
  print ("\nUsage: $0 mailhost user port_to_connect\n\n");
  exit;
}

$host  = $ARGV[0];
print ("$host\n");
$user = $ARGV[1];
print ("$user\n");
$port = $ARGV[2];
print ("$port\n");

my $EOL = "\r\n";
#my $MailHost = shift || "user.sfbay.sun.com";
my $MailHost = $host;
my $Port = $port;
#my $Port = shift || 993;
my @InputCmds = ();

#$sasl = `./encode.pl $user`;
$sasl = encode_base64("$user\0$user\0$user");
print ("$sasl\n");

if($Port =~ /993/){
	@InputCmds = ("101 LOGIN $user $user", "102 SELECT INBOX", "103 FETCH 1 rfc822", "105 CAPABILITY", "104 LOGOUT");
}elsif($Port =~ /1993/){
	@InputCmds = ("101 LOGIN $user $user", "102 SELECT INBOX", "103 FETCH 1 rfc822", "105 CAPABILITY", "104 LOGOUT");
}elsif($Port=~ /1995/){
	#POP commands
	@InputCmds = ("user $user", "pass $user", "LIST", "RETR 1", "QUIT");
}elsif($Port=~ /995/){
	#POP commands
	@InputCmds = ("user $user", "pass $user", "LIST", "RETR 1", "QUIT");
	#@InputCmds = ("user amit\@sfbay.sun.com", "pass user1", "LIST", "RETR 1", "QUIT");
}elsif($Port =~ /1465/){
	@InputCmds = ("ehlo","AUTH PLAIN $sasl", "mail from: $user", "rcpt to: $user", "DATA", "This is a test mail\r\n.", "QUIT");
}elsif($Port =~ /465/){
	@InputCmds = ("ehlo", "AUTH PLAIN $sasl", "mail from: $user", "rcpt to: $user", "DATA", "This is a test mail\r\n.", "QUIT");
}else{
	print "Invalid port number... exiting..\n";
	exit;
}

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
