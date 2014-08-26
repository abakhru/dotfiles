#!/usr/bin/perl
#
#
# Autostress automation script
#
# Purpose: Enable large scale stress testing to be fully automated. This script
# is intended to be run from a cron job, which will check for the existance of a
# new build, create the appropriate ATH/TLE param & workload files, clean up 
# the existing machine state, and executes a new stress run.
#
#
# Author: Rob Vassar
# Last Update:
#
# 1/24/2008 - Added "clean up only" flag.  Shuts down server, calls Clean_Store() 
# and exits. When used with force flag, it will run even if shutdown fails.
#
# 1/14/2008 - Fixed horrible tagged build age determination.  Added optional $MAX_AGE config parameter
# with a default 15 day expiration age. Also, may proceed if lastbuild file is corrupt, or otherwise
# unuseable.
#
# 12/1/2006 - Added "--force" flag to force override in Sanity_Check() and elsewhere.
# Also added "--build=" flag to force a specific build be used.
#
# 12/13/2005 - Added Globals for executable paths (Linux fix). Added sleep
# loop in Sanity_Check() so we wait up to 30 minutes for the load to fall.
#
# Sept 28, 2005  - ENTERED PRODUCTION
# Created: August 16, 2005
#
# Development Notes: 
# Need to convert $STOREPATH to an array, and alter code to permit multiple store partitions.
# This can wait until Geetha's "Store Tools" module is ready. 
#
# Future Additions: 
# Need to improve the Sanity_Check() routine, both install detection as well as 
# check /var/core.
# Need to support multiple workload file support via templates, where multiple 
# stress runs may be invoked for each tagged build. This will allow a basic run, 
# followed by a SSL run, or a MMP run, etc...
use Carp;
use File::Path;
use File::stat;
use Getopt::Long;
#
#
my $CONFIGFILE = "/autostress/run_stress.cfg";
#
# The config file must follow the following format/example:
#DEBUGFLAG 	= TRUE
#PKGTOCHK 	= "SUNWmsgco"
#BUILDPATH 	= "/share/builds/sca-re3/msg/m62/ships"
#LASTBUILDFILE 	= "/tmp/autostress_lastbuild"
#PARAMTEMPLATE	= "/autostress/configuration/param.autotemplate"
#PARAMFILE 	= "/autostress/configuration/param"
#STOREPATH 	= "/var/opt/SUNWmsgsr/store/partition/primary/=user"
#SHUTDOWNCMD 	= "/opt/SUNWmsgsr/sbin/stop-msg"
#RE_arch_name 	= "ponk_SunOS5.8"
#TLE_Exec 	= "/autostress/go.sh"
#TLEEXECLOG 	= "/tmp/tle.output"
#INHIBITFILE	= "/no_autostress"


#
# Set up paths by OS
if ($^O eq "solaris") {
	$COPY = "/usr/bin/cp";
	$MOVE = "/usr/bin/mv";
	$DELETE = "/usr/bin/rm";
	$NETSTAT = "/usr/bin/netstat";
	$GREP = "/usr/bin/grep";
	$WORDCOUNT = "/usr/bin/wc";
	$UPTIME = "/usr/bin/uptime";
}
if ($^O eq "linux") {
	$COPY = "/bin/cp";
	$MOVE = "/bin/mv";
	$DELETE = "/bin/rm";
	$NETSTAT = "/bin/netstat";
	$GREP = "/bin/grep";
	$WORDCOUNT = "/usr/bin/wc";
	$UPTIME = "/usr/bin/uptime";
}
if ($^O eq "hp-ux") {
	Debug_Me("This script doesn't work yet on HP\n");
	exit (1);
}

###############################################################################
# Sanity_Check
#
# Description: This routine check the system's current status.  The following
# checks are performed:
#	1. Are we executing as root?
#	2. Is the messaging server installed?
#	3. Is the messaging server running?
#	4. Are there established imap/pop connections?
# If these checks fail, we probably don't want to proceed.
#
#
# Parameters: None.
#
# Return Value: 1 is everything is sane.  0 for all failures.
###############################################################################
sub Sanity_Check() {
	# Probably need to figure out if we're Unix, then what flavor....
	my $Installed = 0; # Prove we are.
	my $Running = 1; # Prove we're not.
	my $Sane = 0; # Prove we're sane.
	unless ($^O != "solaris" || $^O == "linux" || $^O == "hpux") {
		carp "This is a Unix specific script. We're running on $^O which is not currently supported.\n";
		return(0);
	}
	if ( $> != 0) {  
		carp "This script must run with root privlege. We're uid $>.\n";
		return(0);
	}
	# My thinking for the next section is that if it's not already installed, we've
	# either suffered very bad JESINSTALL failure previously and shouldn't loop, or 
	# are attempting to run on a new/unconfigured machine.
	if ($^O eq "solaris" ) {
		# Check and see if our core libraries are installed.
		$status = system("/usr/bin/pkginfo $PKGTOCHK 1>/dev/null 2>/dev/null" );
		unless ($status) {
			$Installed=1;
		}
	}
	if ($^O eq "linux" || $^O eq "hpux" ) {
		# Just check for some common messaging directories
		if ( -e "/var/opt/SUNWmsgsr" && -e "/opt/SUNWmsgsr") {
			$Installed = 1;
		}
	}
	if ( -e $INHIBITFILE) {
		Debug_Me("Execution inhibited by $INHIBITFILE");
		return(0) unless defined $FORCED;
	}
	my ($sleep_condition) = 1;
	my ($loop_count) = 0;
	while ( $sleep_condition == 1) {
		$loop_count++;
		$sleep_condition = 0;
		$output = `$UPTIME`; # This is rather lightweight, so it doesn't disturb a system under heavy load.
		if ( $? == 0 ) {
			Debug_Me("Uptime Returned: $output ");
			@temp = split(/\s+/, $output);
			$load = @temp[$temp -1];
			
			Debug_Me("15 minute average load is: $load. Should be less than 0.15.");
		} else {
			Debug_Me("Can't execute $UPTIME\n");
			return(0);
		}
		if ($load < 0.51 && $load > 0.15 && $loop_count < 3) { # Maybe we can proceed in 10 - 30 minutes
			$sleep_condition = 1;
			Debug_Me("Waiting for load to fall\n");
			if (not defined $FORCED) {
				sleep (600);
			} 
		}
	}
	if ($load < 0.15 ) {
		# Ok... We're probably not doing anything useful.
		# This is rather error prone, and won't work on small simulations.
		# So we'll do a few more checks. These are more invasive, and may push a heavily loaded
		# system over the edge.
		
		$output_imap = `$NETSTAT | $GREP imap | $GREP ESTAB | $WORDCOUNT -l`;
		$output_pop = `$NETSTAT | $GREP pop | $GREP ESTAB | $WORDCOUNT -l`;
		$output_smtp = `$NETSTAT | $GREP smtp | $GREP ESTAB | $WORDCOUNT -l`;
		
		Debug_Me("OS Detected: $^O \nImap Connections: $output_imap \nPop Connections: $output_pop \nSMTP Connectons: $output_smtp");
		if (($output_imap + $output_pop + $output_smtp) < 2) {
			$Running = 0;
		}
	}
	# Sanity is kind of difficult to judge
	Debug_Me("Checking for $BUILDPATH $TLE_Exec $PARAMTEMPLATE $SHUTDOWNCMD");
	if ( -e $BUILDPATH && -e $TLE_Exec && -e $PARAMTEMPLATE && -e $SHUTDOWNCMD ) { 
		# At least we have:
		# 1. NFS connectivity
		# 2. a TLE execution script
		# 3. a param file template
		# 4. We might be able to stop the server
		Debug_Me("Found $BUILDPATH $TLE_Exec $PARAMTEMPLATE $SHUTDOWNCMD");
		$Sane = 1;
	}
	Debug_Me("Running: $Running (should be 0) Installed: $Installed (Should be 1) Sane: $Sane (Should be 1)");
	if ( $Running == 0 && $Installed == 1 && $Sane == 1) {
		return(1);
	}
	if ($FORCED && -e $BUILDPATH && -e $TLE_Exec && -e $PARAMTEMPLATE) { 
		return(1); # Marginal sanity... Just do it!
	}
	return(0);
} # End of Sanity_Check()

###############################################################################
# ID_Build
#
# Description:  This routine identifies the most recent "qa" tagged build. It
# then writes a flag in $LASTBUILDFILE so that a build doesn't get repeated. If
# the system gets rebooted, and the $LASTBUILDFILE deleted, we probably need to pick up
# the latest build and run it anyway. We may wish to keep a running list at some
# point.  But for now this will suffice.
#
# Parameters: String containing filesystem directory to check.
#
# Return Value: String of build to install, or "NULL" if no build or dup.
#
###############################################################################
sub ID_Build {
	my $Path_to_Builds = $_[0];
	my @TaggedBuilds;
	opendir (DIR, $Path_to_Builds) or die "Can't opendir $Path_to_Builds: $!\n";
	while (defined($filename = readdir(DIR))) {
		next if $filename =~ /^\.\.?$/; # Skip the . and .. files
		next if $filename =~ /^\./; # No hidden files either
		next if $filename =~ /tcov/; # Added to eliminate code coverage builds
		next if $filename !~ /\.qa$/; # No files not tagged ".qa"
		push (@TaggedBuilds, $filename);
	}
	closedir(DIR);
	# @TaggedBuilds now contains all the builds marked ".qa".
	# These are formatted as YYYYMMDD_<trailing junk>.qa
	Debug_Me("@TaggedBuilds\n");
	($Day, $Month, $Year) = (localtime)[3,4,5];
	$Year+=1900;
	$Month+=1;
	if ($Month < 10) {
		$temp = $Month;
		$Month = "0$temp"; # There has to be a better way to pad these.
	}
	if ($Day < 10) {
		$temp = $Day;
		$Day = "0$temp";
	}
	$Today = "$Year$Month$Day"; #Which should be YYYYMMDD
	# Check to see if we have a "last build tested" file.
	if ( -e $LASTBUILDFILE ) {
		open (FH, $LASTBUILDFILE) || die "Can't open last build file.\n";
		while (<FH>) { # We're going to do this this way, so we can record data 
			#	 as comments in the last build file for future use.
			Debug_Me("LASTBUILDFILE: $_");
			chomp;
			s/#.*//;	# No comments
			s/^\s+//;	# No leading whitespace
			s/\s+$//;	# No trailing whitespace
			next unless length;
			$last_build_ran = $_; # we hope.
			Debug_Me("Extracted $last_build_ran from $LASTBUILDFILE");
		}
		close (FH);
	} else {
		$last_build_ran = "";
		Debug_Me("No $LASTBUILDFILE to work with.");
		}
	# else, we don't have a last build file.  The system may have been rebooted.
	# So at this point we have $Today, our list of tagged builds in @TaggedBuilds
	# and possibly a $last_build_ran.
	@SortedTaggedBuilds = sort (@TaggedBuilds);
	$LastTaggedBuild = $SortedTaggedBuilds[$#SortedTaggedBuilds];
	Debug_Me("Last QA Tagged Build is: $LastTaggedBuild");
	if (length $last_build_ran > 8) {
		$last_date = substr($last_build_ran, 0 , 8);
		$last_tagged = substr($LastTaggedBuild, 0 , 8);
		if ($last_tagged > $last_date || $FORCED ) {
			# Ok... We have determined we need to run stress against
			# the build in $LastTaggedBuild, or the --force flag is set.
			if ( -e $LASTBUILDFILE ) {
				unlink ($LASTBUILDFILE);
			}
			open (FH, "> $LASTBUILDFILE") or die "can't create $LASTBUILDFILE. $!\n";
			print FH "# $Today\n";
			print FH "$LastTaggedBuild\n";
			close (FH);
			return ($LastTaggedBuild);
		} else {
			Debug_Me("$last_tagged is greater than $last_date");
			Debug_Me("This isn't supposed to happen. Perhaps a corrupt $LASTBUILDFILE");
			# return("NULL"); # Not quite sure how you get here, but...
		}
	}
	# Ok... We probably don't have a valid $last_build_ran. We could return the
	# $LastTaggedBuild anyways, but that might have us stress testing builds 
	# that are weeks old.
	if ($FORCED) { # Just do it. Updating the $LASTBUILDFILE...
		if ( -e $LASTBUILDFILE ) {
			unlink ($LASTBUILDFILE);
		}
		open (FH, "> $LASTBUILDFILE") or die "can't create $LASTBUILDFILE. $!\n";
		print FH "# $Today\n";
		print FH "$LastTaggedBuild\n";
		close (FH);
		return($LastTaggedBuild); 
	}
	# If the tag is older than $MAX_AGE we want to skip it. We use lstat
	# because we're interested in the symlink tag time, not the actual build
	# directory mtime.
	my $ModTime = lstat("$Path_to_Builds/$LastTaggedBuild")->mtime;
	Debug_Me("Last tagged build modification time is: $Modtime \n");
	if ( (time() - $ModTime) > $MAX_AGE ) {
		# Exceeds build expiration date.  Don't bother, a new build is probably forthcoming.
		Debug_Me("Build exceeds expiration time of $MAX_AGE seconds\n Last tagged is: $last_tagged");
		return ("NULL");
	}
	else {
		if ( -e $LASTBUILDFILE ) {
			unlink ($LASTBUILDFILE);
		}
		open (FH, "> $LASTBUILDFILE") or die "Can't create $LASTBUILDFILE. $!\n";
		print FH "# $Today\n";
		print FH "$LastTaggedBuild\n";
		close (FH);
		return ($LastTaggedBuild);
	}
} #End of sub ID_Build

###############################################################################
# Clean_Store
#
# Description: Performs a quick dirty message store clean up. The ATH/TLE
# install usually times out while trying to execute a single threaded "rm -rf"
# on the message store.  This subroutine executes multiple "rm" commands in 
# parallel, to maximize the delete rate. Configuration with multiple store 
# partitions may need to call this more than once.
#
#
# Parameters: Requires a path string to the message store partition to be deleted
#
#
# Return Value: 1 if success, 0 for all failures.
#
###############################################################################
sub Clean_Store {
	my $Path_to_Delete = $_[0];
	Debug_Me("Clean_Store got passed: $Path_to_Delete");
	if (length($Path_to_Delete) < 3) { # Let's not rmtree "/"
		return(0);
	}
	# Ok... I need this working now, so I cheated and used rmtree.
	# Will fix later... Need to clean up the MTA queue too.
	Debug_Me("Cleaning up $Path_to_Delete");
	rmtree($Path_to_Delete);
	return(1);
}


###############################################################################
# Craft_Param
# 
# Description: Assembles a new param file from an existing template.
#
# Parameters: Requires a path string to the target build.
#
# Return Value: 1 if success, 0 for all failures.
###############################################################################
sub Craft_Param {
	$Target_Build = $_[0];
	Debug_Me("Craft_Param got passed: $Target_Build");
	my $Success = 0; # Assume failure.
	# So what we're expecting here is a string that contains an absolute
	# path, which we can then append to the param file template stored in
	# $PARAMTEMPLATE to create a finished TLE param.
	if (-e $PARAMFILE ) {
		$output = `$DELETE -f $PARAMFILE.old`;
		if ($? == 0) {
			$output = `$MOVE $PARAMFILE $PARAMFILE.old`;
			unless ($? == 0) {
				die "Can't rename old param file.\n $output\n";
			}
		} else {
			carp "Can't rename old param file. \n";
			return($Success); # Failure
		}
	}
		
	if ( -e $PARAMTEMPLATE ) {
		$output = `$COPY $PARAMTEMPLATE $PARAMFILE`;
		open (FH, ">> $PARAMFILE") || die "Can't append to $PARAMFILE \n";
		print FH "GENV_MSPATCHBUILDDIR=$Target_Build\n";
		Debug_Me("Added GENV_MSPATCHBUILDDIR=$Target_Build to $PARAMFILE");
		close (FH);
		$Success = 1; # Successful completion
	}
	else {
		carp "Param file template is missing\n";
	}
	return ($Success);
} # End of Craft_Param
###############################################################################
# Debug_Me()
#
# Description: This function just cleans up the insertion of debug statements
# in various locations.  All it does is print the string passed to it if
# $DEBUGFLAG eq TRUE.
#
# Parameters: Requires a string printable by print()
#
# Return Value: None.
###############################################################################
sub Debug_Me {
	$Debug_String = @_[0];
	if ($DEBUGFLAG eq "TRUE") {
		my $call_line = (caller(0))[2];
		print "Line $call_line: $Debug_String\n";
	}
	return;
}	
###############################################################################
# Main()
#
###############################################################################
my $now = scalar localtime;
# --force flag overrides certain checks.
# It may also contain the path to a build.
GetOptions( 	"force" => \$FORCED,
		"cleanup" => \$CLEANUPONLY,
		"build=s" => \$FORCEBUILD  );
if ( -e $CONFIGFILE ) {
	open (CONFIG, $CONFIGFILE) || die "Can't open my config file! $!\n";
	while (<CONFIG>) {
		chomp; #no newline
		s/#.*//; # no comments
		s/^\s+//; # no leading white space
		s/\s+$//; # no trailing white space
		next unless length; # anything left?
		my ($token, $value) = split(/\s*=\s*/, $_, 2); # TOKEN = VALUE
		$Config_File{$token} = $value;
	}
} else {
	die "Can't find my config file!\n";
}
# These reassignments are Rob's laziness.  Config file was added after things were working. Already crufty...
$DEBUGFLAG = $Config_File{"DEBUGFLAG"};
$PKGTOCHK = $Config_File{"PKGTOCHK"}; 
$BUILDPATH = $Config_File{"BUILDPATH"}; 
$LASTBUILDFILE = $Config_File{"LASTBUILDFILE"}; 
$PARAMTEMPLATE = $Config_File{"PARAMTEMPLATE"};
$PARAMFILE = $Config_File{"PARAMFILE"};
$STOREPATH = $Config_File{"STOREPATH"};
$SHUTDOWNCMD = $Config_File{"SHUTDOWNCMD"};
$RE_arch_name = $Config_File{"RE_arch_name"};
$TLE_Exec = $Config_File{"TLE_Exec"};
$TLEEXECLOG = $Config_File{"TLEEXECLOG"};
$INHIBITFILE = $Config_File{"INHIBITFILE"};
if (defined $Config_File{"MAX_AGE"}) {
	$MAX_AGE = $Config_File{"MAX_AGE"};
} else {
$MAX_AGE = 1296000; # 86400 seconds in a day * 15 days
}
Debug_Me("$now");
Debug_Me("DEBUGFLAG: $DEBUGFLAG");
Debug_Me("PKGTOCHK: $PKGTOCHK");
Debug_Me("BUILDPATH: $BUILDPATH");
Debug_Me("LASTBUILDFILE: $LASTBUILDFILE");
Debug_Me("PARAMTEMPLATE: $PARAMTEMPLATE");
Debug_Me("PARAMFILE: $PARAMFILE");
Debug_Me("STOREPATH: $STOREPATH");
Debug_Me("SHUTDOWNCMD: $SHUTDOWNCMD");
Debug_Me("RE_arch_name: $RE_arch_name");
Debug_Me("TLE_Exec: $TLE_Exec");
Debug_Me("TLEEXECLOG: $TLEEXECLOG");
Debug_Me("MAX_AGE: $MAX_AGE");
Debug_Me("INHIBITFILE: $INHIBITFILE");
if ($CLEANUPONLY) {
	print "Clean up only mode.\n";
	$start_time = scalar localtime;
	print "Started at: $start_time\n";
	$Shutdown = `$SHUTDOWNCMD 2>&1`;
	unless ($? == 0 ) {
	  print "$Shutdown\n";
	  print "\nShutdown exited abnormally. $? \nERROR: Cannot Proceed.\n";
	  unless ($FORCED) {
		exit(1);
	  }
	}
	unless (Clean_Store($STOREPATH) == 1) {
	  print "ERROR: Failed to clean up old message store.\n";
	  exit(1);
	}
	$end_time = scalar localtime;
	print "Completed at: $end_time\n";
	exit(0);
}
if ($FORCED) {
	$DEBUGFLAG = "TRUE"; # Override config file.
	Debug_Me("FORCED OPTION INVOKED!!!!\n $FORCED\n");
}
$Sanity = Sanity_Check();
if ($Sanity != 1) {
	Debug_Me("Sanity check failed. Is the system busy?");
	exit (0); # There's really no point in complaining here.  I expect this script
	# to fail more often than succeed.
}
if ($FORCEBUILD) {
	$Build_to_Install = "NULL";
} else {
	$Build_to_Install = ID_Build($BUILDPATH);
}
if ($Build_to_Install eq "NULL"  && not defined $FORCEBUILD ) {
	# Nothing for us to do.
	Debug_Me("No new build to run.");
	exit(0);
}
# Need to shutdown the messaging server here...
$Shutdown = `$SHUTDOWNCMD 2>&1`;
unless ($? == 0 ) {
	print "$Shutdown\n";
	print "\nShutdown exited abnormally. $? \nERROR: Cannot Proceed.\n";
	unless ($FORCED) {
		exit(1);
	}
}
unless (Clean_Store($STOREPATH) == 1) {
	print "ERROR: Failed to clean up old message store.\n";
	exit(1);
}
# At this point we have $Build_to_Install, which contains only the pointer. The
# whole path is $BUILDPATH + $Build_to_Install + $RE_arch_name
if ($FORCEBUILD) {
	print "Build selection override!!!!!\n";
	print "Trying: $FORCEBUILD/$RE_arch_name\n";
	$TempString = "$FORCEBUILD/$RE_arch_name"; # Use the build we specify
} else {
	$TempString = "$BUILDPATH/$Build_to_Install/$RE_arch_name";
}
if ( -e $TempString ) { # have to make sure the build actually exists for our platform.
	unless (Craft_Param($TempString) == 1) {
		print "ERROR: Craft_Param Failed. Can't Proceed.\n";
		exit(1);
	}
}
	else {
		print "Build $RE_arch_name not found.\n $TempString\n";
		exit(1);
	}
# We're done.  Hand off to ATH/TLE
if (-e $TLE_Exec ) {
	if ($FORCED || $FORCEBUILD){
		print ("\n\nManual options used... Sleeping 15 seconds before running ATH.\n");
		print ("Hit crtl-C now to stop!\n");
		sleep (15); # We'll just wait here a couple secs.
	}
	if (!defined($kidpid = fork())) { #This is mostly a future thing.  We could just exec without the fork.
		# fork returned undef, we can't fork, time to die.
		die "Cannot fork $!\n";
	}
	elsif ($kidpid ==0 ) {
		# Fork returns 0, so we're the child proc.
		if ($DEBUGFLAG == 1) {
			exec ("$TLE_Exec");
			die "Can't exec $TLE_Exec $! \n";
		} else {
			$output = `$DELETE -f $TLEEXECLOG`;
			exec ("$TLE_Exec 2>&1 >$TLEEXECLOG");
			die "Can't exec $TLE_Exec $! \n";
		}
	}
	else {
		# fork returned niether 0 nor undef, we're the parent.
		waitpid($kidpid, 0);
		# and go do something else here, like run a monitoring module...
	}
}

