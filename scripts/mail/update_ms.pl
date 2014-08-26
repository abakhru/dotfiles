#!/usr/bin/perl
use Cwd;

my $cwd = getcwd();
my $GENV_MSHOME1 = "/opt/sun/comms/messaging64";
my $ms_rpm = "sun-messaging-server64";
my $branch; my $ms_zip_file;

chomp($os=`uname -s`);
chomp($plat = `uname -p`);

if(@ARGV < 1){
	print "==== Usage: $0 [branch|ms-zip-file]\n";
	print "====    Eg: $0 7u4/7u5/tip\n";
	print "==== OPTION NOT FOUND!!!!\n";
	exit 0;
}

print "==== OS = $os and PLATFORM = $plat\n";
if($ARGV[0] =~ /zip/){
	$ms_zip_file=$ARGV[0];
	$branch="";
	print "==== Updating this $os machine with \"$ms_zip_file\" build\n";
}else{
	$branch=$ARGV[0];
	$ms_zip_file="";
	print "==== Updating this $os machine with \"$branch\" branch's latest build\n";
}


_system("$GENV_MSHOME1/sbin/stop-msg") if((-e "$GENV_MSHOME1/config/msg.conf") || (-e "$GENV_MSHOME1/config/config.xml"));

if ($os eq "SunOS")
{
   if(length($ms_zip_file) == 0)
   {
	if( $plat =~ /sparc/) {
		$ms_zip_file = ms_package_to_install("sc11sbs008");
	} elsif ( $plat =~ /i386/) {
		$ms_zip_file = ms_package_to_install("comms08");
	}
	print "==== MS package being used to install is : $ms_zip_file \n";
	if(length($ms_zip_file) == 0 ) {
		print "\n\n Usage: $0 <ms-zip-file> (optional)\n\n";
		print "==== MS Package NOT FOUND!!!!\n";
		exit 0;
	}
	if (update_ms_solaris()) {
		ms_restart();
	}
   }else {
	update_ms_solaris();
	ms_restart();
   }
   _system("$GENV_MSHOME1/sbin/imsimta version");
   print "==== MS package file $ms_zip_file INSTALLED SUCCESSFULLY ==== \n";
}
elsif ( $os eq "Linux" )
{
   if(length($ms_zip_file) == 0){
	$ms_zip_file = ms_package_to_install("redhat5");
	print "==== MS package file being used to install is : $ms_zip_file \n";
	if(length($ms_zip_file) == 0 ) {
		print "\n\n Usage: $0 [branch|ms-zip-file]\n\n";
		print "==== MS RPM NOT FOUND!!!!\n";
		exit 0;
	}
	if(update_ms_linux()){
		ms_restart();
	}
   }else {
	update_ms_linux();
	ms_restart();
   }
   _system("$GENV_MSHOME1/sbin/imsimta version");
}

sub update_ms_solaris() {
	
	_system("rm -rf /tmp/SUNWmessaging-server-*");
	_system("unzip -q $ms_zip_file -d /tmp");

	my $ADMIN = "/tmp/rm_pkgadmin";
        unless( open(OP, ">$ADMIN") ) {
                print "Unable to open file $ADMIN";
                close(OP);
                return 0;
        }
        print OP
"mail=root\n" .
"instance=overwrite\n" .
"partial=nocheck\n" .
"runlevel=nocheck\n" .
"idepend=nocheck\n" .
"rdepend=nocheck\n" .
"space=ask\n" .
"setuid=nocheck\n" .
"action=nocheck\n" .
"basedir=default\n";
        close(OP);

	print "==== Removing Messaging Server Package .......\n";
	_system("pkgrm -nA -a $ADMIN SUNWmessaging-server-64");
	if ($? == 0) {
		print "==== Messaging Server Package REMOVED ====\n";
		_system("rm -rf $GENV_MSHOME1/* /var/$GENV_MSHOME1/*");
	} else {
		 print "==== FAILURE Removing the package ====\n";
	}
	#_system("pkill -9 pkgserv");

	print "==== Adding Messaging Server Package .......\n";
	chdir("/tmp");
	
	#find its a local / global zone
	@list = `zoneadm list -vci|awk '{print $1}'`;
	print "Ids of zones : @list\n";
	if($list[1] >= 1){ #its a local zone
		print "==== Its a LOCAL Zone ====\n";
		_system("pkgadd -na $ADMIN -d . SUNWmessaging-server-64");
	}elsif(($list[1] == 0) && $list[2] >= 1){ 
		print "==== Its a GLOBAL Zone ====\n";
		print "==== Installing only in GLOBAL Zone ====\n";
		_system("pkgadd -G -na $ADMIN -d . SUNWmessaging-server-64");
	}elsif(($list[1] == 0) && "x$list[2]" eq "x"){ 
		print "==== No LOCAL Zone Exists ====\n";
		_system("pkgadd -na $ADMIN -d /tmp SUNWmessaging-server-64");
	}

	if ($? == 0) {
		print "==== Messaging Server Package ADDED ====\n";
	} else {
		 print "==== FAILURE Adding the package ====\n";
	}
	chdir("$cwd");

	chomp($PSTAMP = `pkginfo -l SUNWmessaging-server-64|grep PSTAMP`);
	print "==== PSTAMP for SUNWmessaging-server-64 =  is $PSTAMP\n";

	unlink("/tmp/rm_pkgadmin");
	_system("rm -rf /tmp/SUNWmessaging-server*");
	if($ms_zip_file =~ /7u4/){
		_system("cd ./msg74; perl msconfig.pl new; cd -");
	}else{
		_system("./run.pl new");
	}
	return 1;
}

sub update_ms_linux() {

	chomp($rpm = `find /tmp/ |grep rpm`);
	if (-e "$rpm") {
		unlink($rpm);
	}
	_system("unzip -q $ms_zip_file -d /tmp");

	print "==== Removing Messaging Server Package .......\n";
	_system("rpm -e $ms_rpm");
	_system("rm -rf $GENV_MSHOME1 /var/opt/sun/comms/messaging64");

	if ($? == 0) {
		print "==== Messaging Server Package removed\n";
	} else {
		 print "==== FAILURE removing the package ====\n"; 
	}

	chomp($rpm = `find /tmp/ |grep rpm`);
	print "==== Adding Messaging Server RPM : $rpm \n\n";
	_system("rpm -ivh $rpm");
	if ($? == 0) {
		print "==== Messaging Server Package Added\n";
	} else {
		 print "==== FAILURE Adding the package ====\n";
	}

	print "==== Detailed installed sun-messaging*.rpm information\n";
	_system("rpm -qi $ms_rpm ");

	unlink ($rpm);
	if($ms_zip_file =~ /7u4/){
		_system("cd ./msg74; perl ./msconfig.pl new; cd -");
	}else{
		_system("./run.pl new");
	}
	return 1;
}

sub ms_package_to_install 
{
	my ($platform) = @_;
	my $branch_path = "/share/builds/products/msg/$branch/ships/2013*";

	print "==== Calculating the build package/rpm file to install ....\n";
	#unless(-d $branch_path){
#		print "==== \"$branch_path\" directory NOT FOUND\n";
#		return 0;
#ZZ	}

	if ($os eq "Linux") {
		chomp($zip_file = `find $branch_path |grep zip|grep $platform|grep -v aru|xargs ls -rth|tail -1`);
	} elsif ($os eq "SunOS") {
		chomp($zip_file = `find $branch_path |grep zip|grep $platform|grep -v aru|xargs ls -rth|tail -1`);
	}
	unless(($zip_file =~ /zip/) && (-e $zip_file)){
		print "==== Zip File: $zip_file\n";
		print "==== Zip file not found ====\n";
		exit 0;
	}
	return $zip_file;
}

sub ms_restart {
	if((-e "$GENV_MSHOME1/config/msg.conf") || (-e "$GENV_MSHOME1/config/config.xml")){
		_system("$GENV_MSHOME1/sbin/imsimta cnbuild; $GENV_MSHOME1/sbin/imsimta chbuild; $GENV_MSHOME1/sbin/start-msg");
		return 1;
	}else{ 
		print "==== Restart Failed ====\n";
		return 0;
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
