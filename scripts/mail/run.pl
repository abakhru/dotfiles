#!/usr/bin/perl
use Env qw(SHELL PWD);

$data_file="/export/nightly/tmp/param.minimal";
unless(-e "$data_file"){
	$data_file="/export/nightly/tmp/param";
}
unless(-e "$data_file") {
	print "==== $data_file NOT FOUND ==== \n";
	print "==== Please provide the correct path to the param file ==== \n";
	exit;
}
print "==== Param file being used: $data_file ====\n";

# use internal perl
$PERLLOC="/usr/bin/perl.qa";
if (-e "$PERLLOC") {
  print "==== Perl at $PERLLOC ==== \n";
} else {
  $PERLLOC="/usr/bin/perl";
  print "==== Perl at $PERLLOC ==== \n";
}

$temp_file="temp.pl";
$msconfig_file="msconfig.pl";
system("echo > $temp_file");
open(PARAM, $data_file) || die("Could not open $data_file!");
open(TEMP,">$temp_file") || die("Could not open $temp_file!");
open(MSCONF, $msconfig_file) || die("Could not open $msconfig_file!");
@param_data=<PARAM>;
@msconfig=<MSCONF>;
close(PARAM);
close(MSCONF);

print TEMP "#!$PERLLOC\n";
foreach $param (@param_data) {
	chomp($param);
	unless($param =~ /#/) {
		if($param =~ /=o=/) {
  			($field1,$field2,$field3) = split '=', $param;
			print TEMP "\$$field1=\"$field2=$field3\";\n";
			next;
		}
  		($field1,$field2) = split '=', $param;
		unless("x$field1" eq "x" || "x$field2" eq "x"){
			print TEMP "\$$field1=\"$field2\";\n";
		}
	}
}
print TEMP @msconfig;
close(TEMP);
system("chmod 777 $temp_file");
system("$PERLLOC $temp_file $ARGV[0] $ARGV[1] $ARGV[2] $ARGV[3]");
unlink("$temp_file");
