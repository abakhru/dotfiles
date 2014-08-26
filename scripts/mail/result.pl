#!/usr/bin/perl

$LOGFILE = "./xml-report.txt";
open("INFO","<$LOGFILE") or die("Could not open log file.");
@LINES = <INFO>;
close(INFO);

foreach $line (@LINES) {
        @LINES=sort(@LINES);
        #print "@LINES\n";
        @array = split('-',$line);
        push(@array_date,$array[0]);
        push(@array_osName,$array[1]);
        push(@array_moduleName,$array[4]);
        push(@array_totalTest,$array[6]);
        push(@array_passedTest,$array[7]);
        push(@array_failedTest,$array[8]);
}

$a = scalar(@array_passedTest);
print "array_length = $a\n";
#print "@array_passedTest\n";
#print "@array_totalTest\n";
my $best_result = "0";
for(my $i=$a;$i>0;$i--){
        if(("$array_totalTest[$i]" eq "0") || ($array_moduleName[$i] =~ /i18n/)){
                next;
        }
        if(("$array_totalTest[$i]" ne "$array_passedTest[$i]") && ("$array_failedTest[$i]" ne "0")){
                #$best_result = $i;
        	#print "module: $array_moduleName[$i] : total: $array_totalTest[$i] : passed: $array_passedTest[$i] : failed: $array_failedTest[$i]\n";
        	print "module: $array_moduleName[$i] \t failed: $array_failedTest[$i]\n";
		print "=============================================================\n";
        }
}

#print "Last Best Result on date: $array_date[$best_result]\n";
#print "$LINES[$best_result]\n";
