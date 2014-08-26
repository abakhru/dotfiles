#!/usr/bin/perl -w
use Getopt::Std;

sub usage () {
        printf("Usage: ldap-gather.pl [ -s server ] [ -p port ] [ -h ] [ -d Absolute path to statistics file ]\n");
        printf("  -s server : Hostname to connect to\n");
        printf("  -p port   : TCP port to connect to\n");
        printf("  -d file   : Statistics file to store headers and monitor DN statistics (e.g., /tmp/ldap.stats.txt )\n");
	exit(1);
}

# Borrowed from code written by Quanah Gibson-Mount
sub getImapConn {
        my $log_location = $_[0];
        my $protocol = $_[1];
        my @openConns=`grep "Account Information: login" $log_location/$protocol*`;
        my @closeConns=`grep "Account Notice: close" $log_location/$protocol*`;
	my $total = length(@openConns) - length(@closeConns);
	print "==== Currently Open Connections : $total ==== \n";
	return $total;
}

#######################################
#  Global variables get set to 0 here #
#######################################
my $timestamp = time();

###################################
# Get the arguments from the user #
###################################
%options=();
getopts("hp:s:d:",\%options);

my $statsfile = $options{d} ||  usage();
my $port = $options{p} || 389;
my $server = $options{s} || "localhost";

if (defined $options{h} ) {
	usage();
}

if ( ! defined($statsfile)) {
	usage();
}

######################################
# Open the file if it doesn't exist  #
######################################
if ( -e $statsfile ) {
        # The file exists, so there is no reason to add a heading
        open (LDAPFILE, ">>$statsfile") || die "ERROR: Couldn't open $statsfile in append mode Perl error: $@";

} else {
        # The file doesn't exist, so let's add a heading
        open(LDAPFILE, ">$statsfile") || die "ERROR: Couldn't open $statsfile in write mode: Perl error: $@";
        print LDAPFILE "TIMESTAMP TOTAL_CONNECTIONS BYTES_SENT INITIATED_OPERATIONS COMPLETED_OPERATIONS ";
        print LDAPFILE "REFERRALS_SENT ENTRIES_SENT BIND_OPERATIONS UNBIND_OPERATIONS ADD_OPERATIONS ";
        print LDAPFILE "DELETE_OPERATIONS MODIFY_OPERATIONS COMPARE_OPERATIONS SEARCH_OPERATIONS WRITE_WAITERS READ_WAITERS\n";
}

###############################################
# Collect the statistics from the server      #
###############################################
my $total_connections = getImapConn("/opt/sun/comms/messaging64/log","imap");

###############################################
# Print the values to $logfile
###############################################
print (LDAPFILE  "$timestamp $total_connections $bytes_sent $initiated_operations $completed_operations $referrals_sent $entries_sent $bind_operations $unbind_operations $add_operations $delete_operations $modify_operations $compare_operations $search_operations $write_waiters $read_waiters \n");
close(LDAPFILE);
