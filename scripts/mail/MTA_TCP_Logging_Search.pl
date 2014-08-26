#!/usr/bin/perl

$GENV_MSHOME1="/opt/sun/comms/messaging64";
$GENV_DSHOST1="sc11e0405";
$GENV_MSHOST1="sc11e0405";
$GENV_DOMAIN="us.oracle.com";

sub MTA_TCP_Logging_Search
{
        my ($pattern, $file_prefix) = @_;
	my $size = "30k";
	my $retry = 1;

	if($file_prefix eq ""){
                $file_prefix = "tcp_local_slave";
        }

        #chomp ($search_file = `find $GENV_MSHOME1/log/ -size +30k -name "tcp_local_slave*"|xargs ls -rt|tail -1`);
        my $directory = "$GENV_MSHOME1/log";
        opendir DIR, $directory or die "Error reading $directory: $!\n";
        my @sorted1 = sort {-s "$directory/$a" <=> -s "$directory/$b"} readdir(DIR);
        closedir DIR;
	foreach $i (@sorted1) {
		#print "i = $i\n";
		if ($i =~ /$file_prefix/) {
	#		print "Pushing $i into LIST array\n";
			push (@LIST, $i);
		}
	}
        my @sorted = sort {-s "$directory/$a" <=> -s "$directory/$b"} @LIST;
	print "\n\nAll $file_prefix log files in $directory are as follows: \n\n";
	system("ls -larth $directory/$file_prefix*");
	print "\n\nSorted array contents are as follows: \n\n";
	foreach $j (@sorted) {
		print "$j\n";
	}
        print "\n\nLargest file in $directory is $sorted[-1]\n";
        my $search_file = "$GENV_MSHOME1/log/$sorted[-1]";
        #print "Largest file in $directory is $LIST[-1]\n";
        #my $search_file = "$GENV_MSHOME1/log/$LIST[-1]";
        print "Going to search the pattern: \"$pattern\" in \"$search_file\"\n";

        $found = 0;
        while ($retry && !$found) {
                print "retry count down: $retry\n";
                unless (MTA_Logging_Search("$pattern", "$search_file")) {
                        print "Unable to find pattern: $pattern in $search_file\n";
                        unless ($retry > 1) {
                                return 0;
                        }
                }
                else {
                        $found = 1;
                        last;
                }
                $retry--;
                sleep(60);
        }
        return 1;
}

sub MTA_Logging_Search {

      my ($pattern, $OutFile) = @_;
      my $line;
      my @InputText = ();

      print "Searching file: $OutFile\n";

      unless (open(INFO, "<$OutFile")) {
            print "Cannot read input file $OutFile\n";
            return 0;
      }
      @InputText = <INFO>;
      close(INFO);

      foreach $line (@InputText) {
            print "Searching for pattern: $pattern in the following line:\n";
            print "$line\n";
            if ($line =~ /$pattern/) {
  		print "Found match of pattern: $pattern\n";
		return 1;
            }
      }
      return 0;
}

sub hula_login_verify {
    my ($searchPattern,$file) = @_;
    my $logLocation = "$GENV_MSHOME1/data/log/";
        print "Searching for pattern : $searchPattern in $file ";

        if (MTA_Logging_Search("$searchPattern","$file")) {
                  print "pattern FOUND";
                  return 1;
        }
        print "\n No match FOUND";
        return 0;
}

#$a = MTA_Logging_Search("VEA 0 logaction1\@us.oracle.com rfc822\;logaction2 logaction2\@ims-ms-daemon   \*logaction1\@us.oracle.com \[127.0.0.1\] \(\[127.0.0.1\]\) \'\' data/big_smtp_read Error reading SMTP packet", "./mail.log_current");
#$a = MTA_Logging_Search("VEA 0 logaction1\@us.oracle.com rfc822\;logaction2 logaction2\@ims-ms-daemon", "./mail.log_current");
#$a = MTA_Logging_Search("VEA 0 logaction1\@us.oracle.com rfc822\;logaction2 logaction2\@ims-ms-daemon   \\*logaction1\@us.oracle.com \\[127.0.0.1\\] \\(\\[127.0.0.1\\]\\) \\'\\' data/big_smtp_read Error reading SMTP packet", "./mail.log_current");
#$a = MTA_TCP_Logging_Search("LPOOL - tsock_connectbyname\\\(\\\): calling getaddrinfo\\\(\\\"$GENV_DSHOST1.$GENV_DOMAIN\\\"");
#$a= MTA_TCP_Logging_Search("URL lookup for \\\"ldap\\\:\\\/\\\/\\\/o=usergroup\\\?mail\\\?sub\\\?\\\(mailAlternateAddress=mta_mappings\\\%25\\\@sc11g1309.us.oracle.com\\\)\\\"");
#$a = MTA_Logging_Search("500 5.5.1 Unknown command \\\"From: mta_mappings\\\?\\\@sc11g1309.us.oracle.com\\\" specified", "/space/src/results/mta_mappings/Test066_smtp.out");
#$a = MTA_Logging_Search("500 5.5.1 Unknown command \"From: mta_mappings\?\@sc11g1309.us.oracle.com\" specified", "/space/src/results/mta_mappings/Test066_smtp.out");
<<<<<<< MTA_TCP_Logging_Search.pl
#$GENV_MSHOST1="sc11e0405";
#$GENV_DOMAIN="us.oracle.com";
#$a = MTA_Logging_Search("unknown or illegal alias: }\@$GENV_MSHOST1.$GENV_DOMAIN","$GENV_MSHOME1/log/mail.log_current");
#$a = MTA_Logging_Search("Subject: money is importan\\\"","$GENV_MSHOME1/log/mail.log_current");
#$a = MTA_Logging_Search("neo1 CRAM-MD5 \\\d\+ TLS_RSA_WITH_AES_256_CBC_SHA","$GENV_MSHOME1/log/pop");
#$a = MTA_Logging_Search("conn=\\d\+ op=-?\\d\+ msgId=-?\\d\+ - SSL 256-bit AES-256", "/var/opt/sun/dsins1/logs/access");
#$a = MTA_Logging_Search("tcp_bounceit \\\(stopped\\\)         1        0.0","/export/nightly/tmp/results/mta_channel/Test027a.out");
=======
$GENV_MSHOST1="sc11136620";
$GENV_DOMAIN="us.oracle.com";
#$a = MTA_Logging_Search("/export/nightly/tmp/results/axsoneArchiving/store_archive/\\\w+\@$GENV_MSHOST1.$GENV_DOMAIN\@body.txt","$GENV_MSHOME1/log/imap");
>>>>>>> 1.6
#$a = hula_login_verify("CRAM-MD5  Mechanism not available", "$GENV_MSHOME1/log/imap");
<<<<<<< MTA_TCP_Logging_Search.pl
$a=MTA_TCP_Logging_Search("Debug output enabled, system $GENV_MSHOST1.$GENV_DOMAIN, process \\\w\+\.\\\d\+, managesieve server version","managesieve_server");
=======
$a = MTA_Logging_Search("\\\\* BYE LOGOUT received","/export/nightly/tmp/results/imap_condstore/Test018.out");
>>>>>>> 1.6
print "==== a = $a ====\n";
