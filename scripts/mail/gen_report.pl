#!/usr/bin/perl
use Expect;

$debug=1;
$GENV_MSHOME1="/opt/sun/comms/messaging64";
$GENV_DOMAIN="us.oracle.com";
$GENV_DMPASSWORD="password";
$GENV_OSIROOT="o=usergroup";
#$GENV_HOTFIXLOC="/net/comms-nfs.us.oracle.com/export/megan/wspace/ab155742/common_files";
$GENV_HOTFIXLOC="/tmp";
$imap_report="./imapreport";
$final_report="./finalreport";
$pop_report="./popreport";
$smtp_report="./smtpreport";
$http_report="./httpreport";
$stats_file="./statsfile";
$FORMAT = "%-6s %-10s %-8s %-24s %s\n";

sub processStat
{
        my ($pname) = @_;
        my @p_stat = `grep $pname $GENV_HOTFIXLOC/statsfile`;
        my $conn_file_name = "$GENV_HOTFIXLOC/$pname" . "_conn_count";
        my @openConns=`grep ESTABLISHED $conn_file_name`;
	my @total = "";

        print "p_stat :\n @p_stat\n" if($debug);
        print "conn_file_name : $conn_file_name\n" if($debug);
        #p_stat :  25059 mailuser  213M   51M sleep   59    0   0:00:02 0.0% imapd/56
        for($i=0;$i<scalar(@p_stat); $i++){
                @p_details = split(" ",$p_stat[$i]);
                $mem_size[$i] = $p_details[2];
                $cpu_perc[$i] = $p_details[8];
                ($a, $num_threads[$i]) = split( /\//, $p_details[9]);
                if($cpu_perc[$i] eq ""){
                        next;
                }
                ($total[$i], $a) = split(" ",$openConns[$i]);
                print "cpu_perc: $cpu_perc[$i]\t mem_size: $mem_size[$i]\t num_threads : $num_threads[$i]\t total_conns: $total[$i]\n" if($debug);
        }
        return (\@cpu_perc, \@mem_size, \@num_threads, \@total);
}

sub gen_report()
{
#	$mmp_imap_count = getConnCount("imap");
	my $mmp_imap_count=0;
	my ($r1,$r2,$r3,$r4) = processStat("imap");
	my (@imap_cpu_perc) = @$r1;
	my (@imap_mem_size) = @$r2;
	my (@imap_num_threads) = @$r3;
	my (@imap_count) = @$r4;
	print "imap_cpu_perc : @imap_cpu_perc\n" if($debug);
	print "imap_mem_size : @imap_mem_size\n" if($debug);
	print "imap_num_threads : @imap_num_threads\n" if($debug);
	print "imap_count : @imap_count\n" if($debug);

	my ($r5) = consolidate_reports();
	my (@Lines) = @$r5;
	if($debug){
		print "====consolidated_report====\n";
		print @Lines;
	}

	open(FINAL, ">$final_report");

	for($i=1, $j=0; $i<=scalar(@Lines); $i++)
	{
		if(($Lines[$i] =~ /===/) || ($Lines[$i] =~ /username/)){
			next;
		}
		@details = split(" ",$Lines[$i]);
		$details[4]=chomp($imap_count[$j]);
		$details[5]=$mmp_imap_count;
		if($imap_cpu_perc[$j] eq ""){
			$j--;
		}
		$details[6]=$imap_cpu_perc[$j];
		$details[7]=$imap_mem_size[$j];
		$details[8]=$imap_num_threads[$j];
		$Lines[$i] = join("\t", @details, "\n");
		print "$Lines[$i]\n" if($debug);
		if ($i % 5 == 0) { $j++; }
	}
	print FINAL @Lines;
	close(FINAL);
	return 1;
}

sub consolidate_reports
{

	#my $directory = $ARGV[0];
	my $directory = $GENV_HOTFIXLOC;
	my @total_report = "";
	
	opendir DIR, $directory or die "Error reading $directory: $!\n";
	my @sorted = sort {-s "$directory/$a" <=> -s "$directory/$b"} readdir(DIR);
	closedir DIR;
	
	for(my $i=0;$i<scalar(@sorted);$i++)
	{
		if ($sorted[$i] =~ /imapreport/) 
		{
			$search_file="$directory/$sorted[$i]";
			unless (open(INFO, "<$search_file")) {
	            		print "-e", "Can not read input file $search_file\n";
	            		print "Cannot read input file $search_file\n";
	            		return 0;
	        	}
	        	@InputText = <INFO>;
			push (@total_report, @InputText);
	        	close(INFO);
		}
	}
	
	for ($i=3; $i<(scalar(@total_report)-1); $i++) {
		if (($total_report[$i] =~ /username/) || ($total_report[$i] =~ /====/)){
			delete($total_report[$i]);
		}
	}
	#print "==== total_report ==== \n@total_report\n";
	return (\@total_report);
}

#gen_report();
processStat("imap");
