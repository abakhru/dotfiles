#!/usr/bin/perl

#variable to store tests to run
my @non_tle_tests_dir;

chomp(my $dir=`pwd`);
if(-d "$dir/logs") { _system("rm -rf $dir/logs/*"); }
_system("mkdir -p $dir/logs");
chomp(my $date=`date +%Y%m%d%H%M`);

if(@ARGV < 1){
	print "==== Running All non-tle-module tests ====\n";
	#listing and storing all directories
	opendir my($dh), $dir or die "Couldn't open dir '$dir': $!";
	@non_tle_tests_dir = readdir $dh;
	closedir $dh;
}else {
	@non_tle_tests_dir = @ARGV;
}


#importing all GENV variables from param.minimal file
import_GENV();

foreach $test (@non_tle_tests_dir)
{
	my $script_name = "start_test.sh";
	#my $script_name = "Bug_14032336.sh";
	chomp(my $start_test_path = `find $test|grep $script_name`);
	my (@a) = split('/', $start_test_path);
	if("$a[1]" eq "$script_name"){
		print "==== Starting run of \'$test\' non-tle-module ====\n";
		_system("cd $test; sh -x $script_name > $dir/logs/$test.$date.log ; cd $dir");
		print "==== End of \"$test\" non-tle-module run ====\n";
	}elsif ("$a[2]" eq "$script_name"){
		print "==== Starting run of \'$a[0]/$a[1]\' non-tle-module ====\n";
		_system("cd $a[0]/$a[1]; sh -x $script_name > $dir/logs/$a[1].$date.log ; cd $dir");
		print "==== End of \"$a[0]/$a[1]\" non-tle-module run ====\n";
	}else { 
		print "==== \'$script_name\' scipt not found for \'$test\' module====\n";
		next;
	}
}

sub _system
{
        use IPC::Open3;
        my (@cmd) = @_;
        print "Running: \"@cmd\"\n";
        my $pid = open3(\*WRITER, \*READER, \*ERROR, @cmd);
        #if \*ERROR is 0, stderr goes to stdout
        my @output, @error;
        while( my $output = <READER> ) {
                print "OUTPUT -> $output";
                push(@OutputContents,$output);
        }
        while( my $errout = <ERROR> ) {
                print "ERROR -> $errout";
                push(@ErrorContents,$errout);
        }
        waitpid( $pid, 0 ) or die "$!\n";
        $retval = $?;
        $SysResult = $? >> 8;
        if( $SysResult == 0 ) {
                $SysResult = 1;
        } else {
                print "\"@cmd\" command FAILED: return code $SysResult\n";
                $SysResult = 0;
        }
        return ($SysResult, $retval, \@OutputContents, \@ErrorContents);
}

sub import_GENV()
{
	use Env;
        my $data_file="/export/nightly/tmp/param.minimal";
        unless(-e "$data_file"){
                $data_file="/export/nightly/tmp/param";
        }
        unless(-e "$data_file") {
                print "==== $data_file NOT FOUND ==== \n";
                print "==== Please provide the correct path to the param file ==== \n";
                exit 0;
        }
        print "==== Param file being used: $data_file ====\n";

        # use internal perl
        my $PERLLOC="/usr/bin/perl.qa";
        unless (-e "$PERLLOC") {
                $PERLLOC = "/usr/bin/perl";
        }
        $ENV{GENV_PERLLOC} = $PERLLOC;
        print "==== Perl at $PERLLOC ==== \n";

        open(PARAM, $data_file) || die("Could not open $data_file!");
        @param_data=<PARAM>;
        close(PARAM);

        foreach $param (@param_data) {
                chomp($param);
                unless($param =~ /#/) {
                        if($param =~ /=o=/) {
                                ($field1,$field2,$field3) = split '=', $param;
                                $ENV{$field1} = "$field2=$field3";
                                #print TEMP "\$$field1=\"$field2=$field3\";\n";
                                next;
                        }
                        ($field1,$field2) = split '=', $param;
                        unless("x$field1" eq "x" || "x$field2" eq "x"){
                                $ENV{$field1} = "$field2";
                                #print TEMP "\$$field1=\"$field2\";\n";
                        }
                }
        }
        Env::import();
        return 1;
}
