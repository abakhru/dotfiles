#!/usr/bin/perl
use IPC::Open3;

if (@ARGV < 2){
	print "====         USAGE : grab_ci_builds.pl <branch> <build_num> <plat>(optional)\n";
	print "====        For eg : grab_ci_builds.pl 7u5 20130408.1\n";
	print "==== branch values : tip/7u5/7u4\n";
	print "====   plat values : sparc/x86/linux/linux32\n";
	exit 0;
}

my $branch = $ARGV[0]; 	# could be tip/7u5/7u4
my $build_num = $ARGV[1];

my @plats;

if ($ARGV[2] eq ""){
	@plats = ("sc11sbs008_SunOS5.10", "comms08-s10-x_SunOS5.10_x86", "redhat50as_Linux2.6.18_x86", "redhat40as_Linux2.6.9_x86");
}else{
	if($ARGV[2] eq "sparc") { @plats = ("sc11sbs008_SunOS5.10"); }
	elsif($ARGV[2] eq "x86") { @plats = ("comms08-s10-x_SunOS5.10_x86"); }
	elsif($ARGV[2] eq "linux") { @plats = ("redhat50as_Linux2.6.18_x86"); }
	elsif($ARGV[2] eq "linux32") { @plats = ("redhat40as_Linux2.6.9_x86"); }
}

my $loc = "/share/builds/products/msg/$branch/builds/$build_num";

foreach my $plat (@plats)
{
	my $ci_build_loc = "$loc/$plat/msg/test/ci_retrofit";
	if(-d $ci_build_loc)
	{
		chomp(my $build_zip = `ls $ci_build_loc/*zip`);
		my (@a) = split('ci-',$build_zip);
		my $final_build_name;
		if($branch eq "7u5"){
			$final_build_name = "ci75-$a[1]";
		}elsif($branch eq "7u4"){
			$final_build_name = "ci74-$a[1]";
		}elsif($branch eq "tip"){
			$final_build_name = "ci-$a[1]";
		}
		if($plat =~ /redhat4/){
			my $a = $final_build_name . "-32";
			$final_build_name = $a;
		}
		_system("cp $build_zip /export/home/$final_build_name");
	}else{
		print "==== \"$ci_build_loc\" directory doesn't exists\n";
		print "==== $plat build may be NOT done yet or some erros \n";
	}
}

sub _system
{
        my (@cmd) = @_;
        print "Running: \"@cmd\"\n";
        my $pid = open3(\*WRITER, \*READER, \*ERROR, @cmd);
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
