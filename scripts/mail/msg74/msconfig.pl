use Net::Domain qw(hostname hostfqdn hostdomain);
use File::Copy;
use Cwd;
use Expect;
use Net::LDAP;
use Net::LDAP::LDIF;
use IPC::Open3;
use Env;

import_GENV();
$mspassword = "password";
$cwd = getcwd();
$timeout=2;
$debug=0;
print "==== GENV_MAILSERVERUSERID = $GENV_MAILSERVERUSERID ====\n" if($debug);
chomp($dir=`grep $GENV_MAILSERVERUSERID /etc/passwd`);
print "dir = $dir\n" if($debug);
@b = split(':', $dir);
print "b = @b\n" if($debug);
$home_dir = $b[5];
print "home_dir = $home_dir\n" if($debug);
$date = `date +%Y%m%d%H%M`;
$logfile="/tmp/msconfig.log_$date" if($debug);
$GENV_MSADMINPSWD="password";
$ARCHIVE_DIR="./DSBACKUP";
$GENV_ENCRYPTHOTFIXLOC="/net/comms-nfs.us.oracle.com/export/megan/wspace/ab155742/common_files";
$use_msgcert="0";
$os=`uname -s`;
unless(-d $GENV_CERTIFICATELOC){
        _system("mkdir -p $GENV_CERTIFICATELOC");
}
_system("echo \"asdflkjadfjasdlfjlasfjlksadjflkajdflkasdjflsakjdflakdjflkadsjflsakdjflakdfjasdkjf\" > $GENV_CERTIFICATELOC/noise.txt");
chomp($os);
if(length($GENV_MSHOME1) == 0){
	print "==== GENV_MSHOME1 not defined : FAILED ====\n";
	exit 0;
}
if(length($GENV_MSHOST1) == 0){
        $GENV_MSHOST1=`hostname`;
        chomp($GENV_MSHOST1);
        $GENV_MSHOST1=~s/.us.oracle.com//;
        print "assigning GENV_MSHOST1 to $GENV_MSHOST1\n";
}

chomp($DSADM_PATH = `find $GENV_DSHOME1 -perm -755 |grep "bin/dsadm"`);
if ($os eq "SunOS") {
        #$CERT_TOOLS_PATH = "/usr/sfw/bin";
	@a = split('dsadm',$DSADM_PATH);
        $CERT_TOOLS_PATH = $a[0];
} elsif ( $os eq "Linux" ) {
        $CERT_TOOLS_PATH = "/opt/sun/private/bin";
}
chomp($LDAP_CMD = `find $GENV_DSHOME1 -perm -755 |grep "bin/dsadm"`);
#print "$LDAP_CMD";
if ( $GENV_DS1INSTANCE eq "") {
	chomp($GENV_DS1INSTANCE = `find /var/opt/SUNWdsee -name dsins1`);
}
chomp($LDAPMODIFY_PATH = `find /opt/sun -perm -755 |grep "bin/ldapmodify"|tail -1`);
        
$TLE_ModuleSourceDir=$cwd;

if (-e "$GENV_MSHOME1/config/msg.conf") {
	if (($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = lstat("$GENV_MSHOME1/config/msg.conf")) 	  {
		$user = getpwuid($uid);
		$group = getgrgid($gid);
	}
} else {
	$user = "$GENV_MAILSERVERUSERID";
        $group = "mail";
}

if (@ARGV < 1)
{
print ("\nUsage: msconfig.pl [enable|disable|new]\n\n");
}
else {
	#Logging();
	$option=$ARGV[0];
	if ( $option eq "enable" ) {
		enable();
	}
	elsif ( $option eq "disable" ) {
		config_undo();
#		hula_RestoreDs();
	}
	elsif ( $option eq "new" ) {
#		hula_SetupDs();
		MS_NewConfig();
		enable();
	}
	elsif($option eq "encrypt"){
		enable_encrypt();
	}
	_system("chown -R $user:$group $GENV_MSHOME1/config/*");
	_system("chown -R $user:$group /var/$GENV_MSHOME1");
	# if ARGV[1] is 1, need to set libumem
	if ($ARGV[1] == 1) {
		_system("$GENV_MSHOME1/sbin/stop-msg; $GENV_MSHOME1/sbin/imsimta cnbuild; $GENV_MSHOME1/sbin/imsimta chbuild; export MEM_DEBUG; UMEM_DEBUG=default; export MEM_LOGGING; UMEM_LOGGING=transaction; export LD_PRELOAD; LD_PRELOAD=libumem.so.1; $GENV_MSHOME1/sbin/start-msg");
		# now do pldd command to show that libumem is loaded
		$ipidvals= `ps -ef | grep imapd | grep -v grep`; 
	        @ipidarray=split(" ", $ipidvals);
		$ipid=@ipidarray[1];
		$plddcmd="pldd $ipid | head -4";
		_system($plddcmd);
	} else {
		_system("$GENV_MSHOME1/sbin/stop-msg; $GENV_MSHOME1/sbin/imsimta cnbuild; $GENV_MSHOME1/sbin/imsimta chbuild; $GENV_MSHOME1/sbin/start-msg");
	}

	if($debug){
		_system("less $logfile");
		unlink ("$logfile");
	}
	exit;
}

sub enable() {
	config_mmp();
	enable_ssl();
	enable_logging();
	return;
}

sub config_mmp() {
        _system("$GENV_MSHOME1/sbin/configutil -o local.mmp.enable -v 1");
        _system("cp $TLE_ModuleSourceDir/certmap.conf $GENV_MSHOME1/config/");
        _system("cp $TLE_ModuleSourceDir/tcp_local_option $GENV_MSHOME1/config/");
        _system("cp $TLE_ModuleSourceDir/AService.cfg $GENV_MSHOME1/config/");

        @mmp_config_files=("ImapProxyAService", "PopProxyAService", "SmtpProxyAService");
        foreach $file (@mmp_config_files)
        {
                $mmp_file = "$GENV_MSHOME1/config/$file";
                _system("cp $TLE_ModuleSourceDir/$file.cfg $mmp_file.cfg");
                #replacing required variables in $mmp_file.cfg
                 unless( open (FH, "$mmp_file.cfg") ) {
                         print "Unable to open file $mmp_file.cfg";
                         close(FH);
                         return 0;
                 }
                @FileContents = <FH>; close(FH);

                foreach $Line (@FileContents) {
                        $Line =~ s/MSINSTALL_LOCATION/$GENV_MSHOME1/;
                        $Line =~ s/MSPASSWORD/$GENV_MSADMINPSWD/;
                }

                unless( open(OP, ">$mmp_file.cfg") ) {
                         print "Unable to open file $mmp_file.cfg";
                         close(OP);
                         return 0;
                 }
                print OP @FileContents;
                close(OP);

                _system("grep default:LdapUrl $GENV_MSHOME1/config/$file-def.cfg|tail -1 >> $mmp_file.cfg");
                _system("grep default:UserGroupDN $GENV_MSHOME1/config/$file-def.cfg|tail -1 >> $mmp_file.cfg");
		_system("grep default:BindDN $GENV_MSHOME1/config/$file-def.cfg|tail -1 >> $mmp_file.cfg");
                _system("grep default:BindPass $GENV_MSHOME1/config/$file-def.cfg|tail -1 >> $mmp_file.cfg");
                _system("grep default:DefaultDomain $GENV_MSHOME1/config/$file-def.cfg|tail -1 >> $mmp_file.cfg");
                #Setting SMTP relay host
                if ("$mmp_file.cfg" =~ /Smtp/) {
                        _system("echo \"default:SmtpRelays $GENV_MSHOST1.$GENV_DOMAIN\" >> $mmp_file.cfg");
                }
        }#foreach loop ends
	_system("chown -R $user:$group $GENV_MSHOME1/config/*");
        return 1;
} #config_MMP ends

sub enable_ssl() {
	_system ("echo $mspassword > /tmp/.pwd.txt");
	_system ("$GENV_MSHOME1/sbin/configutil -o service.pop.enablesslport -v yes");
	_system ("$GENV_MSHOME1/sbin/configutil -o service.pop.sslport -v 995");
	_system ("$GENV_MSHOME1/sbin/configutil -o service.pop.sslusessl -v 1");
	_system ("$GENV_MSHOME1/sbin/configutil -o service.imap.enablesslport -v yes");
	_system ("$GENV_MSHOME1/sbin/configutil -o service.imap.sslport -v 993");
	_system ("$GENV_MSHOME1/sbin/configutil -o service.imap.sslusessl -v yes");
	_system ("$GENV_MSHOME1/sbin/configutil -o service.http.enablesslport -v yes");
	_system ("$GENV_MSHOME1/sbin/configutil -o service.http.sslusessl -v yes");
	_system ("$GENV_MSHOME1/sbin/configutil -o service.http.sslport -v 8991");
	_system ("$GENV_MSHOME1/sbin/configutil -o sasl.default.ldap.has_plain_passwords -v 1");
	_system ("$GENV_MSHOME1/sbin/configutil -o sasl.default.auto_transition -v 1");
	_system ("$GENV_MSHOME1/sbin/configutil -o service.imap.plaintextmincipher -v 0");
	_system ("$GENV_MSHOME1/sbin/configutil -o local.service.pab.ldapport -v 636");
	_system ("$GENV_MSHOME1/sbin/configutil -o local.ugldapport -v 636");
	_system ("$GENV_MSHOME1/sbin/configutil -o local.ugldapusessl -v yes");
	_system ("$GENV_MSHOME1/sbin/configutil -o local.service.pab.ldapusessl -v yes");
	_system ("$GENV_MSHOME1/sbin/configutil -o local.ldapcheckcert -v 0");
        _system ("echo $GENV_MSADMINPSWD > /tmp/.pwd.txt");
        _system ("rm $GENV_MSHOME1/config/*.db $GENV_MSHOME1/config/pkcs11.txt")if(-e "$GENV_MSHOME1/config/key4.db");
        if((-e "$GENV_MSHOME1/sbin/msgcert") && ("$use_msgcert" eq "1")){
                _system ("$GENV_MSHOME1/sbin/msgcert generate-certDB -W /tmp/.pwd.txt");
        }
        else{
                _system("$CERT_TOOLS_PATH/certutil -N -d $GENV_MSHOME1/config/ -f /tmp/.pwd.txt");
                _system("$CERT_TOOLS_PATH/certutil -S -x -n \"Server-Cert\" -t \"u,u,u\" -v 120 -s \"CN=$GENV_MSHOST1.$GENV_DOMAIN\" -d $GENV_MSHOME1/config/ -z $GENV_CERTIFICATELOC/noise.txt -f /tmp/.pwd.txt");
                #To list all certificates
                _system("$CERT_TOOLS_PATH/certutil -d $GENV_MSHOME1/config -L");
        }
        unless((-e "$GENV_MSHOME1/config/key4.db") || (-e "$GENV_MSHOME1/config/key3.db")){
                print "======== SSL CERTIFICATE CREATION FAILED ======\n";
                return 0;
        }

	_system ("$GENV_MSHOME1/sbin/configutil -o local.webmail.smime.enable -v yes");
        _system ("$GENV_MSHOME1/sbin/configutil -o local.webmail.cert.enable -v yes");
	copy("$GENV_MSHOME1/config/dispatcher.cnf","$GENV_MSHOME1/config/dispatcher.cnf.ORIG");
	MTA_DispatcherRemove("$GENV_MSHOME1","TLS_PORT","465","SERVICE=SMTP_SUBMIT");
	MTA_DispatcherAdd("$GENV_MSHOME1","TLS_PORT","465","SERVICE=SMTP_SUBMIT");
	unlink ("/tmp/.pwd.txt");
	_system("chown -R $user:$group $GENV_MSHOME1/config/*");
	return;
}

sub enable_logging() {
	_system ("$GENV_MSHOME1/sbin/configutil -o logfile.admin.loglevel -v Debug");
	_system ("$GENV_MSHOME1/sbin/configutil -o logfile.default.loglevel -v Debug");
	_system ("$GENV_MSHOME1/sbin/configutil -o logfile.http.loglevel -v Debug");
	_system ("$GENV_MSHOME1/sbin/configutil -o logfile.imap.loglevel -v Debug");
	_system ("$GENV_MSHOME1/sbin/configutil -o logfile.imta.loglevel -v Debug");
	_system ("$GENV_MSHOME1/sbin/configutil -o logfile.pop.loglevel -v Debug");
	_system ("$GENV_MSHOME1/sbin/configutil -o logfile.mmp.loglevel -v Debug");
	_system ("$GENV_MSHOME1/sbin/configutil -o logfile.imapproxy.loglevel -v Debug");
	_system ("$GENV_MSHOME1/sbin/configutil -o logfile.popproxy.loglevel -v Debug");
	_system ("$GENV_MSHOME1/sbin/configutil -o logfile.submitproxy.loglevel -v Debug");
	_system ("$GENV_MSHOME1/sbin/configutil -o local.ldaptrace -v 1");
	#Editing option.dat file
	my $option_file = "$GENV_MSHOME1/config/option.dat";
        copy("$option_file","$option_file.ORIG");

	unless( open(OP, ">>$option_file") ) {
		print "Unable to open file $option_file";
		close(OP);
		return 0;
	}
	print OP
	"!\n" .
	"LOG_MESSAGE_ID=1\n" .
	"LOG_FILTER=1\n" .
	"LOG_MESSAGES_SYSLOG=20\n" .
	"LOG_CONNECTION=3\n" .
	"!LOG_HEADER=1\n" .
	"LOG_FILENAME=1\n" .
	"LOG_USERNAME=1\n" .
	"LOG_SNDOPR=1\n" .
	"LOG_REASON=1\n" .
	"DEQUEUE_DEBUG=1\n" .
	"!\n" .
	"MM_DEBUG=10\n" .
	"OS_DEBUG=1\n" .
	"MAX_NOTIFYS = 2\n" .
	"! Log to syslog\n" .
	"SEPARATE_CONNECTION_LOG=1\n" .
	"!\n" .
	"ENABLE_SIEVE_BODY=1\n" .
	"!SPAMFILTER1_CONFIG_FILE=/opt/sun/comms/messaging64/config/bmiconfig.xml\n" .
	"!SPAMFILTER1_LIBRARY=/opt/sun/comms/messaging64/lib/libbmiclient.so\n" .
	"!SPAMFILTER1_OPTIONAL=1\n" .
	"!SPAMFILTER1_STRING_ACTION=data:,\$M\n";
	close(OP);
	_system ("$cwd/MTA_ChannelKeywordDo.pl");
	
	#Adding debug configuration to dispatcher.cnf file
	my $file = "$GENV_MSHOME1/config/dispatcher.cnf";
	unless( open(FH, "$file") ) {
        	print "Unable to open file $file";
        	close(FH); return 0;
	}
	@FileContents = <FH>; close(FH);

	unless( open(OP, ">$file") ) {
        	print "Unable to open file $file";
        	close(OP); return 0;
	}
	print OP "!\n" .
	"USE_NSLOG=1\n" .
	"DEBUG=-1\n";
	print OP @FileContents;
	close(OP);

	#Enabling job_controller logging
	copy ("$GENV_MSHOME1/config/job_controller.cnf","$GENV_MSHOME1/config/job_controller.cnf.ORIG");
	my $job_controller_file = "$GENV_MSHOME1/config/job_controller.cnf";
	unless( open(FH1, "$job_controller_file") ) {
        	print "Unable to open $job_controller_file";
        	close(FH1); return 0;
	}
	@FileContents1 = <FH1>; close(FH1);

	unless( open(OP1, ">$job_controller_file") ) {
        	print "Unable to open $job_controller_file";
        	close(OP1); return 0;
	}
	print OP1 "!\n" .
	"use_nslog=1\n" .
	"debug=10\n";
	print OP1 @FileContents1;
	close(OP1);

	copy("$GENV_MSHOME1/config/imta.cnf","$GENV_MSHOME1/config/imta.cnf.ORIG");
	unless (MTA_ChannelKeywordAdd("$GENV_MSHOME1","defaults","logging","") &&
         	MTA_ChannelKeywordRemove("$GENV_MSHOME1","tcp_intranet","mustsaslserver","") &&
		MTA_ChannelKeywordRemove("$GENV_MSHOME1","tcp_local","mustsaslserver","") &&
         	MTA_ChannelKeywordRemove("$GENV_MSHOME1","tcp_submit","mustsaslserver","") &&
         	MTA_ChannelKeywordAdd("$GENV_MSHOME1","tcp_intranet","maysaslserver","") &&
         	MTA_ChannelKeywordAdd("$GENV_MSHOME1","tcp_local","maysaslserver","") &&
         	MTA_ChannelKeywordAdd("$GENV_MSHOME1","tcp_submit","maysaslserver","") &&
         	MTA_ChannelKeywordAdd("$GENV_MSHOME1","ims-ms","master_debug slave_debug","") &&
         	MTA_ChannelKeywordAdd("$GENV_MSHOME1","tcp_local","master_debug slave_debug","") &&
        	MTA_ChannelKeywordAdd("$GENV_MSHOME1","tcp_intranet","master_debug slave_debug","") &&
         	MTA_ChannelKeywordAdd("$GENV_MSHOME1","tcp_submit","master_debug slave_debug","") &&
         	MTA_ChannelKeywordAdd("$GENV_MSHOME1","tcp_auth","master_debug slave_debug","") &&
         	MTA_ChannelKeywordAdd("$GENV_MSHOME1","reprocess","master_debug slave_debug","") &&
         	MTA_ChannelKeywordAdd("$GENV_MSHOME1","process","master_debug slave_debug","") &&
         	MTA_ChannelKeywordAdd("$GENV_MSHOME1","conversion","master_debug slave_debug","")) {
		print "keyword modification failed\n"; 
	}
	_system("chown -R $user:$group $GENV_MSHOME1/config/*");
	return;
}

sub config_undo() {
	my @config_files=("tcp_local_option", "job_controller.cnf", "option.dat", "dispatcher.cnf", "ImapProxyAService.cfg", "PopProxyAService.cfg", "SmtpProxyAService.cfg", "imta.cnf");
	foreach $file (@config_files)
	{
              	copy("$GENV_MSHOME1/config/$file.ORIG","$GENV_MSHOME1/config/$file");
		unlink ("$GENV_MSHOME1/config/$file.ORIG");
	}
	_system ("$GENV_MSHOME1/sbin/configutil -o service.pop.enablesslport -d");
	_system ("$GENV_MSHOME1/sbin/configutil -o service.pop.sslport -d");
	_system ("$GENV_MSHOME1/sbin/configutil -o service.pop.sslusessl -d");
	_system ("$GENV_MSHOME1/sbin/configutil -o service.imap.enablesslport -d");
	_system ("$GENV_MSHOME1/sbin/configutil -o service.imap.sslport -d");
	_system ("$GENV_MSHOME1/sbin/configutil -o service.imap.sslusessl -d");
	_system ("$GENV_MSHOME1/sbin/configutil -o service.http.enablesslport -d");
	_system ("$GENV_MSHOME1/sbin/configutil -o service.http.sslusessl -d");
	_system ("$GENV_MSHOME1/sbin/configutil -o service.http.sslport -d");
	_system ("$GENV_MSHOME1/sbin/configutil -o sasl.default.ldap.has_plain_passwords -d");
	_system ("$GENV_MSHOME1/sbin/configutil -o service.imap.plaintextmincipher -d");
	_system ("$GENV_MSHOME1/sbin/configutil -o local.service.pab.ldapport -d");
	_system ("$GENV_MSHOME1/sbin/configutil -o local.ugldapport -d");
	_system ("$GENV_MSHOME1/sbin/configutil -o local.ugldapusessl -d");
	_system ("$GENV_MSHOME1/sbin/configutil -o local.service.pab.ldapusessl -d");
	_system ("$GENV_MSHOME1/sbin/configutil -o local.ldapcheckcert -d");
	_system ("$GENV_MSHOME1/sbin/configutil -o local.webmail.smime.enable -d");
        _system ("$GENV_MSHOME1/sbin/configutil -o local.webmail.cert.enable -d");
	_system ("$GENV_MSHOME1/sbin/configutil -o logfile.admin.loglevel -d");
        _system ("$GENV_MSHOME1/sbin/configutil -o logfile.default.loglevel -d");
        _system ("$GENV_MSHOME1/sbin/configutil -o logfile.http.loglevel -d");
        _system ("$GENV_MSHOME1/sbin/configutil -o logfile.imap.loglevel -d");
        _system ("$GENV_MSHOME1/sbin/configutil -o logfile.imta.loglevel -d");
        _system ("$GENV_MSHOME1/sbin/configutil -o logfile.pop.loglevel -d");
        _system ("$GENV_MSHOME1/sbin/configutil -o logfile.mmp.loglevel -d");
        _system ("$GENV_MSHOME1/sbin/configutil -o logfile.imapproxy.loglevel -d");
        _system ("$GENV_MSHOME1/sbin/configutil -o logfile.popproxy.loglevel -d");
        _system ("$GENV_MSHOME1/sbin/configutil -o logfile.submitproxy.loglevel -d");
        _system ("$GENV_MSHOME1/sbin/configutil -o local.ldaptrace -d");
	_system("$GENV_MSHOME1/sbin/configutil -o local.mmp.enable -d");
	unlink ("$GENV_MSHOME1/config/pkcs11.txt");
	unlink ("$GENV_MSHOME1/config/key4.db");
	unlink ("$GENV_MSHOME1/config/cert9.db");
	unlink ("$GENV_MSHOME1/config/tcp_local_option");
	return;
}

sub MTA_DispatcherDo {
	($add, $server_path, $option_name, $option_value, $section) = @_;
        unless( open (FH, "$server_path/config/dispatcher.cnf") ) {
                print "Unable to open file $server_path/config/dispatcher.cnf";
                close(FH);return 0;
        }
        @FileContents = <FH>;
	close(FH);

        foreach $Line (@FileContents) {
			$line = $Line;
			chomp($line);
			if ( $add == 1 ) {
			   	if ($line eq "$option_name=$option_value") {
					print "line\n";
					print "already exists\n";last;
					last;
			   	}
			   	elsif ($line eq "!$option_name=$option_value") {
					print "line\n";
					print "Uncommenting out $option_name option from $section section\n";
					$Line =~ s/!$option_name/$option_name/;
					last;
				}
			}
			elsif ( $add == 0 ) {	
			   	if ($line eq "$option_name=$option_value") {
					print "Commenting out $option_name option from $section section\n";
					$Line =~ s/$option_name/!$option_name/;
				}
				elsif ($line eq "!$option_name=$option_value") {
					print "!$option_name=$option_value already Commented out\n";last;
                                }
			}
        }#foreach

        unless( open(OP, ">$server_path/config/dispatcher.cnf") ) {
                print "Unable to open file $server_path/config/dispatcher.cnf";
                close(OP); return 0;
        }
        print OP @FileContents;
        close(OP);
        return 1;
}

sub MTA_DispatcherRemove {
	my ($server_path, $option_name, $option_value, $section) = @_;
	return(MTA_DispatcherDo(0, $server_path, $option_name, $option_value, $section));
}

sub MTA_DispatcherAdd {
	my ($server_path, $option_name, $option_value, $section) = @_;
	return(MTA_DispatcherDo(1, $server_path, $option_name, $option_value, $section));
}

sub MTA_ChannelKeywordDo {
	($server_path, $channel, $keyword, $keyword_p, $param_count, $add) = @_;
        unless( open (FH, "$server_path/config/imta.cnf") ) {
                print "Unable to open file $server_path/config/imta.cnf";
                close(FH);return 0;
        }
        @FileContents = <FH>;
	close(FH);

        foreach $Line (@FileContents) {
		if ( $Line =~ $channel ) {
			# continue if its a comment
			@line_array = $Line;
			if ($line_array[0] =~ "!" || $line_array[0] =~ "daemon") { 
				next; 
			}
			if ( $add == 1 ) {
			   if ($Line =~ $keyword) {print "already exists\n";next;}
				chomp($Line);
				print "Adding $keyword keyword in $channel channel\n";
				$Line = $Line . " " . $keyword . "\n";
			} elsif ( $add == 0 ) {	
				print "Removing $keyword keyword from $channel channel\n";
				$Line =~ s/$keyword //g;
			}
		}
        }#foreach

        unless( open(OP, ">$server_path/config/imta.cnf") ) {
                print "Unable to open file $server_path/config/imta.cnf";
                close(OP); return 0;
        }
        print OP @FileContents;
        close(OP);
	return 1;
}

sub MTA_ChannelKeywordRemove {
        my ($server_path, $channel, $keyword, $param_count) = @_;
        return(MTA_ChannelKeywordDo($server_path, $channel, $keyword, '', $param_count, 0));
}

sub MTA_ChannelKeywordAdd {
        return(MTA_ChannelKeywordDo(@_, 0, 1));
}

sub MS_NewConfig () {
	# Deleting previous admin user
	my $ldap = Net::LDAP->new( "$GENV_DSHOST1.$GENV_DOMAIN", debug => $debug, version => 3 ) or die "$@";
        my $mesg = $ldap->bind ( "$GENV_DM", password => $GENV_DMPASSWORD, version => 3 );
	unless($ldap){
                print "==== Directory Server is Down, MS Configuration cannot proceed ====\n";
                die @;
        }
        my $mesg = $ldap->search ( base  => "$GENV_OSIROOT", filter  => "uid=msg-admin-$GENV_MSHOST1*");
        foreach $entry ($mesg->entries) { $ldap->delete($entry); }
        $mesg = $ldap->unbind;   # take down session

	my $cmd = "$GENV_MSHOME1/sbin/configure --debug";
	_system("$GENV_MSHOME1/sbin/stop-msg");
	_system("rm -rf /var/$GENV_MSHOME1");
	$exp = new Expect();
        $exp->raw_pty(1);
        $exp->debug($debug);
        $exp->spawn($cmd);
	print "==== Running: $cmd\n";
        $exp->expect($timeout,'-re', ':\s$');
        $exp->send("/var/$GENV_MSHOME1\n"); #ms dir
        $exp->expect($timeout,'-re', ':\s$');
        $exp->send("$GENV_MAILSERVERUSERID\n");#mailserver user id
        $exp->expect($timeout,'-re', ':\s$');
        $exp->send("$GENV_MSHOST1.$GENV_DOMAIN\n");#mailserver hostname.domainname
        $exp->expect($timeout,'-re', ':\s$');
        $exp->send("$GENV_MAILHOSTDOMAIN\n");#mail server domain
        $exp->expect($timeout,'-re', ':\s$');
        $exp->send("$GENV_DSHOST1.$GENV_DOMAIN\n");#ldapserver hostname.domainname
        $exp->expect($timeout,'-re', ':\s$');
        $exp->send("$GENV_DM\n");#DM cn=directory manager
        $exp->expect($timeout,'-re', ':\s$');
        $exp->send("$GENV_DMPASSWORD\n"); #DMPASSWORD
        $exp->expect($timeout,'-re', ':\s$');
        $exp->send("admin\@$GENV_MAILHOSTDOMAIN\n");#postmaster email id
        $exp->expect($timeout,'-re', ':\s$');
        $exp->send("password\n");
        $exp->expect($timeout,'-re', ':\s$');
        $exp->send("password\n");
        $exp->expect(10,'-re', 'log\s$');
        $exp->hard_close();

	#Creating new users
	#_system ("cd $cwd/../../s10-scripts; ./add-user.sh neo 1 11 $host.$domain; cd -")if(-e "$cwd/../../s10-scripts/add-user.sh");
        return;
}

#This function is used to enable logging and redirect all STDOUT, STDIN and STDERR to a log file
sub Logging() {
	# Set up main log
	open  LOG, ">$logfile" || die "$0: Can't open log file!";
	open ( STDERR, ">>$logfile" );
	open ( STDOUT, ">>$logfile" );
	select( LOG );
	$| = 1; # Turn on buffer autoflush for log output
	select( STDOUT );
}

###########################################################################
# [ hula_SetupDs ]
# Description:
#	Modify the DS configuration file and restart slapd 
# Returns: 
#	True: if DS restart successfully
#	False: if any error occurs
###########################################################################
sub hula_SetupDs()
{
	# back up the original slapd.conf 
   	print "Backing Up Directory Server...............\n";
	unless (hula_BackupDs()) {
		print "failed to backup Directory Server\n";
		return 0;
	}

   	print "Enabling cleartext password storage in Directory Server ...............\n";
        unless ( hula_ModifyDs() ) {
		print "failed to update slapd.conf on $Host\n";
		return 0;
	}
   	print "Restarting Directory Server ...............\n";
   	unless ( hula_RestartDs() ) {
   		print "failed to restart slapd process on $Host\n";
   		return 0;
   	}
	return 1;
}

############################################################################
# [ hula_ModifyDs ]
# Description:
#   	Modify DS configuration by using ldapmodify
# Returns: 
#	True: if directory server is updated successfully 
#	False: if any error occurs
###########################################################################
sub hula_ModifyDs()
{
	print "HELLO\n";
		my $LdapLoc;
		my $LdapFile = "./clear_password.ldif";
		my $LdapCmd;

		print "Enabling cleartext password storage in Directory Server ....\n";
		$LdapCmd = "$LDAPMODIFY_PATH -D \"$GENV_DM\" -v -w $GENV_DMPASSWORD -c -f $LdapFile -h $GENV_DSHOST1 ";
                _system("$LdapCmd"); 
		unless ($? == 0) {
			print "ldapmodify failed\n";
			return 0;
		}
	return 1;
}


############################################################################
# [ hula_BackupDs ]
# Description:
# Returns: 
#	True: if backup successfully
#	False: if any error occurs
###########################################################################
sub hula_BackupDs()
{
	if (-d $ARCHIVE_DIR) {
		_system("rm -rf $ARCHIVE_DIR");
	}
	print("Backing Up the existing Directory Server.......\n");
        _system ("$LDAP_CMD stop $GENV_DS1INSTANCE");
	print("$LDAP_CMD backup $GENV_DS1INSTANCE $ARCHIVE_DIR\n");
	_system("$LDAP_CMD backup $GENV_DS1INSTANCE $ARCHIVE_DIR");
        unless ($? == 0)
        {
   		print "==============Directory Server Backup FAILED\n";
                exit 0;
        }
	sleep(2);
        _system ("$LDAP_CMD start $GENV_DS1INSTANCE");
   	return 1;
}
    
############################################################################
# [ hula_RestoreDs ]
# Description:
#	Restore original slapd configuration to each individual 
#	directory server machines.
# Returns: 
#	True: if restored successfully
#	False: if any error occurs
###########################################################################
sub hula_RestoreDs()
{
	print "Restoring Directory to its previous state ... \n";
	_system("$LDAP_CMD stop $GENV_DS1INSTANCE");
	unless( -d $ARCHIVE_DIR ){
		print "Backup Directory doesn't exists ... \n";
	}
	_system("$LDAP_CMD restore -i $GENV_DS1INSTANCE $ARCHIVE_DIR");
        unless ($? == 0)
        {
   		print "==============Directory Server restart FAILED\n";
                exit 0;
        }
	_system("$LDAP_CMD start $GENV_DS1INSTANCE $TLE_ModuleDirectory");
   	return 1;
}

#############################################################################
# [ hula_RestartDs ]
# Description:
#	restart slapd process
# Returns: 
#	True: if slapd restarted successfully
#       False: if any error occurs
#############################################################################
sub hula_RestartDs()
{
   	# do a restart on the _system since the configuration changed
	print "Restarting slapd.....\n";
	unless ( -d $GENV_DS1INSTANCE){
		chomp($GENV_DS1INSTANCE = `find /var/opt/SUNWdsee -name dsins1`);
	}
	print "Stopping slapd.....\n";
        _system ("$LDAP_CMD stop $GENV_DS1INSTANCE");
	print "Starting slapd.....\n";
        _system ("$LDAP_CMD start $GENV_DS1INSTANCE");
        unless ($? == 0)
        {
   		print "==============Directory Server restart FAILED\n";
                exit 0;
        }
   	sleep(5);
	print "hula_RestartDs end.....\n";
   	return 1;
}

sub enable_encrypt()
{
	#uncomment the below variable to install the latest solaris patch on your machine
	my $update_solaris=0;
	$grepres="`showrev -p | grep \"Patch: 142909-17\"`";    
        if ( $grepres ) { 
                print "Patch 142909-17 has been applied\n";
        } else {
                print "Patch 142909-17 has not been applied\n";
                print "Need solaris update\n";
		$update_solaris=1;
        }
        chomp($plat=`uname -p`);
        if($plat =~ /sparc/){
                _system("cd $GENV_MSHOME1; tar xvf $GENV_ENCRYPTHOTFIXLOC/msgenc-sparc.tar");
		if($update_solaris){
			_system("unzip $GENV_ENCRYPTHOTFIXLOC/10_Recommended_SPARC.zip -d /export/"); 
			_system("cd /export/10_Recommended; ./installpatchset --s10patchset");
		}
        }elsif($plat =~ /i386/){
                _system("cd $GENV_MSHOME1; tar xvf $GENV_ENCRYPTHOTFIXLOC/msgenc-i386.tar");
		if($update_solaris){
			_system("unzip $GENV_ENCRYPTHOTFIXLOC/10_x86_Recommended.zip -d /export/");
			_system("cd /export/10_x86_Recommended; ./installpatchset --s10patchset");
		}
        } else {
	    print "Encryption not available on this platform\n";
	    exit 0;
   	}
        genkey();
        _system ("$GENV_MSHOME1/sbin/configutil -o store.encryptnew -v yes");
        _system ("$GENV_MSHOME1/sbin/configutil -o store.keypass -v iplanet");
        _system ("$GENV_MSHOME1/sbin/configutil -o store.checkpoint.debug -v 1");
	exec `unset HOME`;
	_system ("chown -R bin:bin $GENV_MSHOME1/bin/");
	_system ("chown -R bin:bin $GENV_MSHOME1/lib/");
        return 1;
}

sub genkey {
        _system("rm -rf $home_dir/.sunw/") if(-d "$home_dir/.sunw");
        print "=== mailuid = $GENV_MAILSERVERUSERID and home_dir = $home_dir =====\n";
        $exp = new Expect();
        $exp->raw_pty(1);
        $exp->log_file("$output_file", "w");
        $exp->debug($debug);
        $exp->spawn("su - $GENV_MAILSERVERUSERID\n");
        $exp->expect($timeout,'-re', '\$\s$');
#creating the keystore and setting the pin
        $exp->send("pktool setpin\n");
        $exp->expect($timeout,'-re', ':$');
        $exp->send("changeme\n");
        $exp->expect($timeout,'-re', ':$');
        $exp->send("iplanet\n");
        $exp->expect($timeout,'-re', ':$');
        $exp->send("iplanet\n");
        $exp->expect($timeout,'-re', '\$');
#generating the key
        $exp->send("pktool genkey label=msgstore keytype=aes keylen=256\n");
        $exp->expect($timeout,'-re', ':$');
        $exp->send("iplanet\n");
        $exp->expect($timeout,'-re', '\$');
#listing the key
        $exp->send("pktool list objtype=key\n");
        $exp->expect($timeout,'-re', ':$');
        $exp->send("iplanet\n");
        $exp->expect($timeout,'-re', '\$');
        $exp->hard_close();
        _system("find $home_dir");
}

sub _system
{
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
        $PERLLOC="/usr/bin/perl.qa";
        if (-e "$PERLLOC") {
                print "==== Perl at $PERLLOC ==== \n";
        } else {
                $PERLLOC="/usr/bin/perl";
                print "==== Perl at $PERLLOC ==== \n";
        }

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
