#!/usr/bin/perl
use Getopt::Long;
$debug=1;

sub LOL_CompareOutput ($$;$) {
    @ARGV = @_;
    # Set the option to allow bundling of options (ie: -pv)
    Getopt::Long::config ('bundling');
    my $Subset = 0;
    my $BigOutput = 0;
    my $Result = eval { GetOptions ('s' => \$Subset, 'b' => \$BigOutput,) };
     my ($output, $expected) = @_;
     my (@expected_result, $expected_line, @result, $result_line);
     my @patterns;
     my $index = 0;
     my $status = 1;
     if (length($GENV_ARRAYVALMAX) == 0) {
        $ARRAYVALMAX=25;
     } else {
        $ARRAYVALMAX=$GENV_ARRAYVALMAX;
     }
    (undef, $FileName, $LineNum ) = caller();

    unless ($Result) {
        print("-e", "-d$sFromFile", "-l$sFromLine", "Invalid parameter entry in $FunctionName.  Parameters not valid:", "\'@_\'");
    }

    unless (open(FD,"<$output")) {
        print ("-e", "-d$FileName", "-l$LineNum", "Cannot read output file: $output");
        return 0;
    }
    @result = <FD>;
    close (FD);

    unless (open(FD,"<$expected")) {
        print ("-e", "-d$FileName", "-l$LineNum", "Cannot read expected file: $expected");
        return 0;
    }
    @expected_result = <FD>;
    close (FD);
        $arraycount=@expected_result;
	print "EXPECTED OUTPUT: $arraycount lines\n";
	if ($arraycount > $ARRAYVALMAX) {
	   $arraycount = $ARRAYVALMAX; # only output $ARRAYVALMAX lines
	}
	for ($icount=0;$icount<=$arraycount;$icount++) {
	    print "EXPECTED OUTPUT: $icount: @expected_result[$icount]\n" if($debug);
	}
	print "EXPECTED OUTPUT: @expected_result" if($debug);
     while ($expected_line = shift @expected_result) {

          # continuations...
          while ($expected_line =~ /\\\s*$/) {
                $expected_line = $`;
                $expected_line .= shift @expected_result;
          }
        	  # Expand any variables in the expected line
        	  $expected_line =~ s/(\$\w+)/$1/eeg;


          my @new_patterns = ($expected_line =~ m'(?:[^\\]|^)\/(.*?[^\\])\/'go);

          push @patterns, [@new_patterns] if (@new_patterns);
     }

        $arraycount=@result;
	print "ACTUAL OUTPUT: $arraycount lines\n";
	if ($arraycount > $ARRAYVALMAX) {
	   $arraycount = $ARRAYVALMAX; # only output $ARRAYVALMAX lines
	}
	for ($icount=0;$icount<=$arraycount;$icount++) {
	    print "ACTUAL OUTPUT: $icount: @result[$icount]\n" if($debug);
	}
	print "ACTUAL OUTPUT: @result" if($debug);

    if ($BigOutput) {
	my $res_index=0;
      RESULT:
        while ($index < scalar(@patterns)) {
            foreach $pattern (@{$patterns[$index]}) {
                my $failure = 0;
                
		if (scalar(@result) ==0) {
		    print " LOL_CompareOutput: pushing DUMMYOUTPUT to results\n";
		    push @result,"DUMMYOUTPUT";
		}
		while ($result_line = shift @result) {
                    
                    my $IfAnswer = 0;  #This is the result of the if statement
                    my $IsAnError = 0; #Whether there was an eval error
                    
                    my $re = eval("\"\Q$pattern\E\"");
                    
		    $res_index++;
                    if ($@) {
                        $IsAnError = 1;
                    }  else {
                        eval {
                            if ($result_line =~ /$re/) {
                                $IfAnswer = 1;
                            } else {
                                $IfAnswer = 0;
				print " LOL_CompareOutput: no match: data_index=$res_index, pattern_index=$index\n";
				print "    : comparing pattern: $re\n";
				print "    : to data: $result_line\n";
                            }
                        };
                        if ($@) {
                            $IsAnError = 1;
                        } elsif ($IfAnswer) {
                            $index++;
                            next RESULT;
                        }
                    }
                    
                    if ($IsAnError) {
                        print "Error evaluating pattern /" . $pattern . "/...\n";
                        print "Eval() syntax error: $@\n";
                        $status = 0;
                        last;
                    }
                    
                    $failure = 1;
                }
            
                
                if ($failure) {
                    
                    my $pattern_str;
                    foreach $pattern (@{$patterns[$index]}) {
                        $pattern_str .= '/' . $pattern . '/ ';
                    }
                    
                    print "No matches for line " . ($index) . "!\n";
                    print "-c", "Patterns: $pattern_str\n";
                    print "-c", "Received: $result_line\n";
                    $status = 0;
                    
                }
            }
            $index++;
        }

    } else {
      LABELRESULT:
        foreach $result_line (@result) {
            
            if ($index+1 > scalar(@patterns)) {
                unless ($Subset) {
                    print "Error: Actual results file is longer than Reference file.\n";
                    $status = 0;
                }
                last;
            }
            
            my $failure = 0;
            foreach $pattern (@{$patterns[$index]}) {
                
                my $IfAnswer = 0;  #This is the result of the if statement
                my $IsAnError = 0; #Whether there was an eval error
                
                my $re = eval("\"\Q$pattern\E\"");
                
                if ($@) {
                    $IsAnError = 1;
                }  else {
                    eval {
                        if ($result_line =~ /$re/) {
                            $IfAnswer = 1;
                        } else {
                            $IfAnswer = 0;
                        }
                    };
                    if ($@) {
                        $IsAnError = 1;
                    } elsif ($IfAnswer) {
                        $index++;
                        next LABELRESULT;
                    }
                }
                
                if ($IsAnError) {
                    print "Error evaluating pattern /" . $pattern . "/...\n";
                    print "-c", "Eval() syntax error: $@\n";
                    $status = 0;
                    last;
                }
                
                $failure = 1;
            }
            
            
            if ($failure) {
                
                my $pattern_str;
                foreach $pattern (@{$patterns[$index]}) {
                    $pattern_str .= '/' . $pattern . '/ ';
                }
                
                print "No matches for line " . ($index) . "!\n";
                print "-c", "Patterns: $pattern_str\n";
                print "-c", "Received: $result_line\n";
                $status = 0;
            }

            $index++;
        }
    }

    if ($index < scalar(@patterns) && (!$BigOutput)) {
        print "Error: Error: Actual results file is shorter than Reference file.\n";
	$status = 0;
    }
	if($status){
		print "\n==== Expected and Actual Output MATCHED ====\n";
	}

	return $status;
}

#LOL_CompareOutput("/export/nightly/tmp/results/imap_condstore/Test013.out", "/export/nightly/tmp/msg_next/msg/test/tle/imap_condstore/Test013.exp", "-b");
#LOL_CompareOutput("./test0$ARGV[0].out", "/export/nightly/tmp/msg74/msg/test/tle/nameSpaceSupport/test0$ARGV[0].exp", "-b");
#LOL_CompareOutput("/export/nightly/tmp/results/nameSpaceSupport/test0$ARGV[0].out", "/export/nightly/tmp/msg74/msg/test/tle/nameSpaceSupport/test0$ARGV[0]v5.exp", "-b");
#LOL_CompareOutput("/export/nightly/tmp/results/mailBoxPurge/Test$ARGV[0].out_1", "/export/nightly/tmp/msg_next/msg/test/tle/mailBoxPurge/Test$ARGV[0].exp_1", "-b");
#LOL_CompareOutput("/export/nightly/tmp/results/imap/Test0$ARGV[0].tmp", "/export/nightly/tmp/msg_next/msg/test/tle/imap/tests.ver5/test0$ARGV[0].exp", "-b");
#LOL_CompareOutput("/space/src/results/mta_option/test$ARGV[0].out", "/export/amit/msg75/msg/test/tle/mta_option/test$ARGV[0].exp", "-b");
#LOL_CompareOutput("/space/src/results/imapStatus/Test$ARGV[0].out","/export/amit/msg75/msg/test/tle/imapStatus/Test$ARGV[0].exp","-b");
#LOL_CompareOutput("/opt/sun/comms/messaging64/log/mail.log_current","/export/amit/msg75/msg/test/tle/mta_option/test19.exp","-b");
if(@ARGV < 2){
	print "==== USAGE: $0 <actual output file> <expected output file> ====\n";
	exit 0;
}
LOL_CompareOutput("$ARGV[0]", "$ARGV[1]","-b");
