#!/usr/bin/perl
use Expect;
 
if (@ARGV < 2)
{
  print ("\nUsage: ./telnet_expect.pl <filename> [143|25|110] <timeout> <output_file>\n\n");
  exit;
}

$file  = $ARGV[0];
$port  = $ARGV[1];
$debug=0;

if ($ARGV[2] =~ /^[+-]?\d+$/ ) {
        $timeout = $ARGV[2];
        $output_file = $ARGV[3];
} elsif ($ARGV[2] eq "" && $ARGV[3] eq ""){
        $timeout = ".5";
        $output_file = "";
} else {
        $timeout = "10";
	$output_file  = $ARGV[2];
}

yeah();

sub yeah {
	chomp($file); 
	# start the smtp/telnet session
        $exp = new Expect();
        $exp->raw_pty(1);
        $exp->log_file("$output_file", "w");
        $exp->debug($debug);
        $exp->spawn("telnet localhost $port");
	if("$port" =~ /110/){
        	$exp->expect($timeout,'-re', '\>\s$');
	}else{
        	$exp->expect($timeout,'-re', '\)\s$');
	}
	#open the input file
	open(File,"$file");
	while(defined($tmp = <File>)) {
		if("$tmp" =~ /EHLO/){
        		$exp->send("$tmp");
        		$exp->expect($timeout,'-re', '0\s$'); 
		}elsif(("$tmp" =~ /SENDSTART/) || ("$tmp" =~ /SENDEND/) || ("$tmp" =~ /#/)){
			next;
		}else{
        		$exp->send("$tmp");
        		$exp->expect($timeout,'-re', '\.$'); 
		}
	}
        $exp->send("quit\n");
        $exp->expect($timeout,'-re', '\.$'); 
        $exp->hard_close();
}
