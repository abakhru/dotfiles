#!/usr/bin/perl
use MIME::Base64;
use Net::Telnet ();

if (@ARGV < 1)
 {
  print ("Usage: $0 user <domain> <password>\n");
  exit;
}

$source  = $ARGV[0];
$domain = $ARGV[1];
$userpass= $ARGV[2];

if(length($userpass) == 0){ $userpass = $source; }

if(length($domain) == 0){
	$sasl = encode_base64("$source\0$source\0$userpass");
} else {
	$sasl = encode_base64("\000$source\@$domain\000$userpass");
}


#print "Encoded AUTH PLAIN value: $sasl \n";
print "$sasl";
#return $sasl;
