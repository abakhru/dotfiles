#!/usr/bin/perl
use MIME::Base64;

$a  = "tester241\@mtassr.com";
print ("$a");
$b = `echo $a|cut -f2 -d"@"`;
print ("$b");
$c = `echo $a|cut -f1 -d"@"`;
print ("$c");

print encode_base64("\0$a\0$c");
print "AHRlc3RlcjI0MUBtdGFzc3IuY29tAHRlc3RlcjI0MQ==";
