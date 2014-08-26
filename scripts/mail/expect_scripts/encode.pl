#!/usr/bin/perl
use MIME::Base64;
use Net::Telnet ();

if (@ARGV < 1)
 {
  print ("\nUsage: $0 <user> <adminpassword> <domain>(optional)\n");
  exit;
}

$UserName  = $ARGV[0];
$adminPass=$ARGV[1];
$domain = $ARGV[2];

if ($domain eq "" ){
#     $sasl = encode_base64("$UserName\0$UserName\0$adminPass");
      $sasl = encode_base64("$UserName\0admin\0$adminPass");
} else {
#      $sasl = encode_base64("\000$UserName\@$domain\000$adminPass");
      $sasl = encode_base64("$UserName\@$domain\0admin\0$adminPass");
}
print $sasl;
