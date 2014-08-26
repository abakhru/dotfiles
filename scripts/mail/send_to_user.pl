unless (@ARGV > 1)
{
die "Usage : $0 username_to_send no_of_mails\n";
}

$mail_from_user="smime9";
$rcpt=$ARGV[0];
$no_of_times=$ARGV[1];
for ($j=1;$j <=$no_of_times;$j++)
{
	system("perl smail.pl f:text dianthos.red.iplanet.com $mail_from_user $rcpt $j");
	print "\nSent email message to $rcpt for $j times\n";
} 
