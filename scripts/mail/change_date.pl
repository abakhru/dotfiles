#!/usr/bin/perl
if(@ARGV < 3){
	print "==== Usage : ./change_date.pl <year/month/day/hour/min> <value> <1(add)/0(substract)>\n";
	exit 0;
}

sub change_date
####################
#
# Usage : change_date ("year/month/date/hour/min","value to increase of decreate","0/1");
# Example: change_date("year","10","1") // This will add 10 years to current date
# Example: change_date("month","1,"1") // This will add 1 month to current date
#
####################
{
	my ($timeflag, $value, $addflag) = @_;

#Date formatting notations:
#To get current time from another machine
#date +%m%d%H%M%Y (year, month, date, hour, mins)
#date MMDDHHmmYYYY(month,day,hour,min,year)
#date 1201010106
#Fri Dec  1 01:01:00 PST 2006

	if("$timeflag" eq "reset"){
		system("/usr/sbin/ntpdate -s -b -p 8 -u whq4op3u33-rtr-1.us.oracle.com");
		print "==== Date Reset with Current Time Successfully ====\n";
		exit 0;
	}
	my $new_date="";
	my $olddate = time;
	print "Current system time is: " . scalar localtime time . " \n";
	my $current_year=`date +%Y`;
	my $current_month=`date +%m`;
	my $current_day=`date +%d`;
	my $current_hour=`date +%H`;
	my $current_min=`date +%M`;

    	if("$timeflag" =~ /year/i) {
		$years = 60 * 60 * 24 * 365;  # seconds in a day
		if ( $addflag == 0 ){
			$then = time - ($value * $years);
		}
		elsif ( $addflag == 1 ){
			$then = time + ($value * $years);
		}
    	}
        elsif ("$timeflag" =~ /month/i) {
		$months = 60 * 60 * 24 * 30;  # seconds in a day
		if ( $addflag == 0 ){
			$then = time - ($value * $months);
		}
		elsif ( $addflag == 1 ){
			$then = time + ($value * $months);
		}
	}
	elsif ("$timeflag" =~ /day/i) {
		$days = 60 * 60 * 24;  # seconds in a day
		if ( $addflag == 0 ){
			$then = time - ($value * $days);
		}
		elsif ( $addflag == 1 ){
			$then = time + ($value * $days);
		}
	}
	elsif ("$timeflag" =~ /hour/i) {
		$hours = 60 * 60;  # seconds in a hour
		if ( $addflag == 0 ){
			$then = time - ($value * $hours);
		}
		elsif ( $addflag == 1 ){
			$then = time + ($value * $hours);
		}
	}
	elsif ("$timeflag" =~ /min/i) {
		$mins = 60;  # seconds in a min
		if ( $addflag == 0 ){
			$then = time - ($value * $mins);
		}
		elsif ( $addflag == 1 ){
			$then = time + ($value * $mins);
		}
	}
	#$new_date = localtime $then;
	#print "\nUpdating now.....\n";
	#print "new_date = $new_date\n";
	$set_date = get_date_format($then);
	system("date $set_date");
	$updated_date = scalar localtime time;
	print "Updated system time is: $updated_date\n";
	if ("$updated_date" ne "$olddate") {
		#print "olddate: $olddate\n";
		#print "   then: $then\n";
		print "==== Date Changed Successfully ====\n";
		return 1;
	} else {
		print "Date Chang FAILED\n\n";
		return 0;
	}
}

sub get_date_format
{

	my ($date_to_change) = @_;
	#print "date_to_change = " . localtime $date_to_change . "\n";
	@months = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
	@weekDays = qw(Sun Mon Tue Wed Thu Fri Sat Sun);
	($second, $minute, $hour, $dayOfMonth, $month, $yearOffset, $dayOfWeek, $dayOfYear, $daylightSavings) = localtime $date_to_change;
	$year = 1900 + $yearOffset;
	#if($ARGV[2]){ $month = $month + $ARGV[1]; }
	#else{ $month = $month - $ARGV[1]; }
	$month = $month + 1;

	#if($ARGV[2]) { $hour = $hour + $ARGV[1]; }
	#else{ $hour = $hour - $ARGV[1]; }

	if($month < 10){ $month = "0" . "$month"; }
	if($dayOfMonth < 10){ $dayOfMonth = "0" . "$dayOfMonth"; }
	if($minute < 10){ $minute = "0" . "$minute"; }
	if($hour < 10){ $hour = "0" . "$hour"; }

	#date MMDDHHmmYYYY(month,day,hour,min,year)
	$theTime = "$month$dayOfMonth$hour$minute$year";
	#print "date_to_change = $date_to_change\n"; 
	#print "       theTime = $theTime\n"; 
	return $theTime;
}

change_date("$ARGV[0]","$ARGV[1]","$ARGV[2]");

#10 years change
#change_date("year","10","1");
#change_date("year","10","0");

#1 months change
#change_date("month","2","1");
#change_date("month","2","0");

#2 days change
#change_date("day","7","1");
#change_date("day","7","0");

#2 hours change
#change_date("hour","2","1");
#change_date("hour","2","0");

#10 min change
#change_date("min","50","1");
#change_date("min","11","0");
