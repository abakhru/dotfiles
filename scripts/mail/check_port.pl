#!/usr/bin/perl
$os=`uname -s`;
chomp($os);
if ($os eq "SunOS") {
        $netstat_cmd = "netstat -na|grep LISTEN";
} elsif ( $os eq "Linux" ) {
        $netstat_cmd = "netstat -nalpt|grep LISTEN";
}

@list=(25,465,110,995,143,993,899,587,389,636,63837,7997,22,4994);
foreach $i (@list) 
{
	if ($i =~ /143/) {
		print "==== IMAP Related Ports Status ====\n";
	}
	if ($i =~ /63837/) {
		print "==== MeterMaid Related Port Status ====\n";
	}
	if ($i =~ /993/) {
		print "==== IMAPS Related Ports Status ====\n";
	}
	if ($i =~ /25/) {
		print "==== SMTP Related Ports Status ====\n";
	}
	if ($i =~ /465/) {
		print "==== SMTPS Related Ports Status ====\n";
	}
	if ($i =~ /110/) {
		print "==== POP Related Ports Status ====\n";
	}
	if ($i =~ /995/) {
		print "==== POPS Related Ports Status ====\n";
	}
	if ($i =~ /587/) {
		print "==== SUBMIT Related Port Status ====\n";
	}
	if ($i =~ /389/) {
		print "==== LDAP Related Ports Status ====\n";
	}
	if ($i =~ /636/) {
		print "==== LDAPS Related Ports Status ====\n";
	}
	if ($i =~ /899/) {
		print "==== HTTP Related Ports Status ====\n";
	}
	if ($i =~ /7997/) {
		print "==== ENS Related Ports Status ====\n";
	}
	system ("$netstat_cmd|grep $i");
}
