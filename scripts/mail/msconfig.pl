#!/usr/bin/perl
use File::Copy;
use Cwd;
use Expect;
use Net::LDAP;
use Net::LDAP::LDIF;
use Net::LDAP::Entry;
use Net::Domain qw(hostname hostfqdn hostdomain);
use IPC::Open3;
use MIME::Base64;
use Env;

#importing all GENV_* variables from param.minimal file
#TODO: copy imaport_GENV() to MailTools.pm file, so that any perl script can use this subroutine and access all the TLE GENV_* variables.
import_GENV();

$TLE_ModuleSourceDir = getcwd();
$USE_LOCAL_CA="1";
$USE_STATE_FILE="0";
$timeout=10;
$debug=0;
$date = `date +%Y%m%d%H%M`;
$logfile="/tmp/msconfig.log_$date";
$host_root_pwd="iplanet";
$user="neo1";
$receiver="admin" ;
$use_msgcert="0";

if(length($GENV_MSHOST1) == 0){
	$GENV_MSHOST1=`hostname`;
	chomp($GENV_MSHOST1);
	$GENV_MSHOST1=~s/.us.oracle.com//;
	print "assigning GENV_MSHOST1 to $GENV_MSHOST1\n";
}

if(length($GENV_MSHOME1) == 0){ $GENV_MSHOME1="/opt/sun/comms/messaging64"; }
if(length($GENV_DS1INSTANCE1) == 0) { chomp($GENV_DS1INSTANCE1 = `find /var/opt/ -name dsins1`); }
if(length($GENV_DSHOME1) == 0) { $GENV_DSHOME1 = "/opt/SUNWdsee"; }
if(length($GENV_XMLCONFIG) == 0) { $GENV_XMLCONFIG = "0"; }
if(length($GENV_DM) == 0) { $GENV_DM = "cn=Directory Manager"; }
if(length($GENV_DMPASSWORD) == 0) { $GENV_DMPASSWORD = "password"; }
if(length($GENV_STOREENCRYPTKEYLEN) == 0) { $GENV_STOREENCRYPTKEYLEN = "256"; }
if(length($GENV_OSIROOT) == 0) { $GENV_OSIROOT = "o=usergroup"; }
if(length($GENV_SEPARATOR) == 0) { $GENV_SEPARATOR = "\@"; }
if(length($GENV_POSTMASTER) == 0) { $GENV_POSTMASTER = "$GENV_MSHOST1"."99"; }
if(length($GENV_DSLDAPPORT1) == 0) { $GENV_DSLDAPPORT1 = "389"; }
if(length($GENV_DSSSLLDAPPORT1) == 0) { $GENV_DSSSLLDAPPORT1 = "636"; }
if(length($GENV_DSHOST1) == 0) { $GENV_DSHOST1 = $GENV_MSHOST1; }
if(length($GENV_DOMAIN) == 0) { $GENV_DOMAIN = `hostdomain`; }
if(length($GENV_MAILHOSTDOMAIN) == 0) { $GENV_MAILHOSTDOMAIN = "us.oracle.com"; }
if(length($GENV_POSTMASTER) == 0) { $GENV_POSTMASTER = "$GENV_MSHOST1"."99"; }
if(length($GENV_MAILSERVERUSERID) == 0) { $GENV_MAILSERVERUSERID = "mailuser"; }
if(length($GENV_MAILSERVERUSERGROUP) == 0) {
	# get user info
	($name, $pass, $uid, $gid, $quota, $comment, $gcos, $dir, $shell, $expire) = getpwnam("$GENV_MAILSERVERUSERID");
	# get group info
	($GENV_MAILSERVERUSERGROUP, $passwd, $gid, $members) = getgrgid("$gid");
}
chomp($DSADM_PATH = `find $GENV_DSHOME1 -perm -755 |grep "bin/dsadm"`);
chomp($DSCONF_PATH = `find $GENV_DSHOME1 -perm -755 |grep "bin/dsconf"`);
chomp($JAVA_CMD = `find $GENV_DSHOME1 -perm -755 |grep "bin/java" | grep -v "vm" |grep -v "ws" | head -1`);
# When directory server is not running the same host as messaging
# server, the above logic will not be able to find java. Use the
# default java in that case.
unless($JAVA_CMD) {
    $JAVA_CMD = "java"
}
chomp($LDAPMODIFY_PATH = `find $GENV_DSHOME1 -perm -755 |grep "bin/ldapmodify"|tail -1`);
chomp($LDAPSEARCH_PATH = `find $GENV_DSHOME1 -perm -755 |grep "bin/ldapsearch"|tail -1`);

chomp($os=`uname -s`);
chomp($version=`uname -r`);
if ($os eq "SunOS") {
        $CERT_TOOLS_PATH = "$GENV_DSHOME1/bin";
	if($version =~ /11/){
		$CERT_TOOLS_PATH = "/usr/bin";
	}
} elsif ( $os eq "Linux" ) {
        $CERT_TOOLS_PATH = "/opt/sun/private/bin";
}
unless(-d $GENV_CERTIFICATELOC){
        _system("mkdir -p $GENV_CERTIFICATELOC");
}

# simplification.  Look in /opt/ssl/bin/openssl or /usr/local/ssl/bin/openssl
$OPENSSL_PATH="/opt/ssl/bin";
# need to make sure openssl exists
if (-f "$OPENSSL_PATH/openssl") {
        print "found openssl in $OPENSSL_PATH\n";
} elsif (-f "/usr/local/ssl/bin/openssl") {
        $OPENSSL_PATH="/usr/local/ssl/bin";
        print "found openssl in $OPENSSL_PATH\n";
} elsif (-f "/usr/sfw/bin/openssl") {
        $OPENSSL_PATH="/usr/sfw/bin";
        print "found openssl in $OPENSSL_PATH\n";
} elsif (-f "/usr/bin/openssl") {
        $OPENSSL_PATH="/usr/bin";
        print "==== Openssl PATH = $OPENSSL_PATH\n";
} else {
        print "can't find openssl - openssl path $OPENSSL_PATH\n";
        print "failed to set openssl path\n";
        return 0;
}
if($version =~ /11/){
	$OPENSSL_PATH = "/usr/bin";
}
# the problem is, if we get here and openssl path is not defined, we're
# in trouble
if (length($OPENSSL_PATH) == 0) {
    print "No open ssl path defined\n";
    return 0;
}
system("echo \"asdflkjadfjasdlfjlasfjlksadjflkajdflkasdjflsakjdflakdjflkadsjflsakdjflakdfjasdkjf\" > $GENV_CERTIFICATELOC/noise.txt");
        
if (@ARGV < 1)
{
	print ("\nUsage: run.pl [enable|disable|new|test|dsnew|user|adduser|SSL] [username|GENV_GCOREUSE]\n\n");
}
else {
	$option=$ARGV[0];
	Default_files();
	print "==== VALUE of GENV_XMLCONFIG is : $GENV_XMLCONFIG ==== \n";
	if ( $option eq "enable" ) {
		restore();
		if("$GENV_XMLCONFIG" eq "1") {
			enable_xml();
		} else {
			enable();
		}
	}
	elsif ( $option eq "disable" ) {
		unless(restore()){
			config_undo();
			logging_disable();
		}
	}
	elsif ( $option eq "new" ) {
		MS_NewConfig();
		if("$GENV_XMLCONFIG" eq "1") {
			copy("$GENV_MSHOME1/config/config.xml","$GENV_MSHOME1/config/config.xml.ORIG");
			enable_xml();
		} else {
			enable();
		}
	}
	elsif ( $option eq "test" ) {
		test_ALL();
		exit 0;
	}
	elsif ( $option eq "encrypt" ) {
		enable_encrypt();
	}
	elsif ( $option eq "enableplaintext" ) {
		DS_enable_plaintext();
	}
	elsif ( $option =~ /dsnew/i ) {
		dsnew_instance();
		DS_enable_plaintext();
	}
	elsif ( $option eq "user" ) {
		 #delete_user_cert_fromLDAP($ARGV[1],$GENV_DOMAIN);
		create_user_cert($ARGV[1],$GENV_MAILHOSTDOMAIN);
		#ldapsearch($ARGV[1]);
		if(-e "AService.cfg") {
			_system("rm *.cfg certmap.conf tcp_local_option sample_statefile");
		}
		exit 0;
	}
	elsif ( $option =~ /adduser/ ) {
		print "argv[0] = $ARGV[0]; argv[1] = $ARGV[1]; argv[2] = $ARGV[2]\n";
                AddUsers($ARGV[1],$ARGV[2],$GENV_MAILHOSTDOMAIN);
                if(-e "AService.cfg") {
                        _system("rm *.cfg certmap.conf tcp_local_option sample_statefile");
                }
                exit 0;
	}
	elsif ( $option =~ /SSL/i ) {
		MS_NewConfig();
		create_servercert();
		if("$GENV_XMLCONFIG" eq "1") {
			copy("$GENV_MSHOME1/config/config.xml","$GENV_MSHOME1/config/config.xml.ORIG");
			enable_xml();
		} else {
			enable();
		}
	}else{
		print "==== Wrong option ====\n";
		print ("\nUsage: run.pl [enable|disable|new|test|ds|user|adduser|SSL] [username|GENV_GCOREUSE]\n\n");
		exit 0;
	}

	system("chown -R $GENV_MAILSERVERUSERID:$GENV_MAILSERVERUSERGROUP $GENV_MSHOME1/config/*");
	system("chown -R $GENV_MAILSERVERUSERID:$GENV_MAILSERVERUSERGROUP /var/$GENV_MSHOME1");
	system("chown root:root $GENV_MSHOME1/config/restricted.cnf");

	if ($ARGV[1] == 1) {
		if($GENV_STOREENCRYPT) {
			unless(_system("unset HOME; $GENV_MSHOME1/bin/stop-msg; $GENV_MSHOME1/bin/imsimta cnbuild; $GENV_MSHOME1/bin/imsimta chbuild; export MEM_DEBUG; UMEM_DEBUG=default; export MEM_LOGGING; UMEM_LOGGING=transaction; export LD_PRELOAD; LD_PRELOAD=libumem.so.1; $GENV_MSHOME1/bin/start-msg")) { print "==== MS STARTUP FAILED ====\n"; }
		} else {
			if ( $os eq "SunOS" ) {
                        unless(_system("$GENV_MSHOME1/bin/stop-msg; $GENV_MSHOME1/bin/imsimta cnbuild; $GENV_MSHOME1/bin/imsimta chbuild; export MEM_DEBUG; UMEM_DEBUG=default; export MEM_LOGGING; UMEM_LOGGING=transaction; export LD_PRELOAD; LD_PRELOAD=libumem.so.1; $GENV_MSHOME1/bin/start-msg")) { print "==== MS STARTUP FAILED ====\n"; }
                        } else {
                        unless(_system("$GENV_MSHOME1/bin/stop-msg; $GENV_MSHOME1/bin/imsimta cnbuild; $GENV_MSHOME1/bin/imsimta chbuild; export MALLOC_CHECK_=2;  $GENV_MSHOME1/bin/start-msg")) { print "==== MS STARTUP FAILED ====\n"; }
                        }
		}
	} else {
		if($GENV_STOREENCRYPT){
			unless(_system("unset HOME; $GENV_MSHOME1/bin/stop-msg; $GENV_MSHOME1/bin/imsimta cnbuild; $GENV_MSHOME1/bin/imsimta chbuild; $GENV_MSHOME1/bin/start-msg")) { print "==== MS STARTUP FAILED ====\n"; }
		}else{
			unless(_system("$GENV_MSHOME1/bin/stop-msg; $GENV_MSHOME1/bin/imsimta cnbuild; $GENV_MSHOME1/bin/imsimta chbuild; $GENV_MSHOME1/bin/start-msg")) { print "==== MS STARTUP FAILED ====\n"; }
		}
	}
# for libumem testing
# check imapd process for libumem
  $imagename = "imapd";
# now do pldd command to show that libumem is loaded
  $ipidvals= `ps -ef | grep $imagename | grep messaging | grep -v grep`; 
  @ipidarray=split(" ", $ipidvals);
  $ipid=@ipidarray[1];
  print "looking for $imagename pid $ipid\n";
  if ( length($ipid) == 0 ) {
    print " $imagename is AWOL, no pid found\n";
    exit 0;
  }
	if ($os eq "SunOS") {
  		$plddcmd="pldd $ipid | head -4";
	} elsif ( $os eq "Linux" ) {
  		$plddcmd="cat /proc/$ipid/maps";
	}
  $result =_system("$plddcmd > /tmp/pldd.out");
  $pldd=`cat /tmp/pldd.out`;
  if ($pldd =~ /libumem/) {
    print " ---libumem is enabled for $imagename---\n";
  }

	check_ports();
	if(-e "AService.cfg") {
		#where is this happening?
		system("rm *.cfg certmap.conf tcp_local_option sample_statefile");
	}
	exit;
}

sub enable() {
	unless ((config_mmp()) &&
		(enable_ssl()) &&
		(enable_logging())) {
		return 0;
	}
	if($GENV_STOREENCRYPT){
		unless(enable_encrypt()) {
			return 0;
		}
	}
	return 1;
}

sub enable_xml() {
	unless ((config_mmp_xml()) &&
		(enable_ssl_xml()) &&
		(enable_logging_xml())) {
		return 0;
	}
	if($GENV_STOREENCRYPT){
		unless(enable_encrypt()) {
			return 0;
		}
	}
	return 1;
}

sub config_mmp_xml() {
	print "==== Configuring MMP in XML format ====\n";
	unless(-d "$GENV_MSHOME1/config/recipes"){
		system("mkdir -p $GENV_MSHOME1/config/recipes");
	}
	adjust_file("mmp.rcp","./recipes/","$GENV_MSHOME1/config/recipes/");
	unless(_system("$GENV_MSHOME1/bin/msconfig run $GENV_MSHOME1/config/recipes/mmp.rcp") && 
	       _system("$GENV_MSHOME1/bin/msconfig set submitproxy.smtprelays $GENV_MSHOST1.$GENV_DOMAIN")) {
		print "==== Configuring MMP in XML format FAILED ====\n";
		return 0;
	}
	return 1;
}

sub enable_logging_xml() {
	print "==== Enabling MAX Debug logging for all services\n";
	copy("./recipes/logging.rcp","$GENV_MSHOME1/config/recipes/logging.rcp");
	copy("./recipes/channel_setup.rcp","$GENV_MSHOME1/config/recipes/channel_setup.rcp");
	copy("./recipes/disable.rcp","$GENV_MSHOME1/config/recipes/disable.rcp");
	unless( _system("$GENV_MSHOME1/bin/msconfig run $GENV_MSHOME1/config/recipes/logging.rcp") &&
		_system("$GENV_MSHOME1/bin/msconfig run $GENV_MSHOME1/config/recipes/channel_setup.rcp") &&
		#setting up restricted debugging options
		_system("$GENV_MSHOME1/bin/msconfig set -restricted os_debug 1") &&
		_system("$GENV_MSHOME1/bin/msconfig set -restricted job_controller.debug 10") &&
		_system("$GENV_MSHOME1/bin/msconfig set -restricted dispatcher.debug -1")) {
		print "==== Logging SETUP FAILED ====\n";
		return 0;
	}
	return 1;
}

sub enable_ssl_xml() {
    print "==== Enabling SSL for all services\n";
    unless ( $option eq "SSL" ) {
	system ("echo $GENV_MSADMINPSWD > $GENV_CERTIFICATELOC/.pwd.txt");
	system ("rm $GENV_MSHOME1/config/*.db $GENV_MSHOME1/config/pkcs11.txt")if((-e "$GENV_MSHOME1/config/key4.db") || ( -e "$GENV_MSHOME1/config/key3.db"));
    	if(("$use_msgcert" eq "1") && (-e "$GENV_MSHOME1/lib/msgcert")){
        	_system ("$GENV_MSHOME1/lib/msgcert generate-certDB -W $GENV_CERTIFICATELOC/.pwd.txt");
	}
	else{
		$ENV{'NSS_DEFAULT_DB_TYPE'} = 'sql';
		_system("$CERT_TOOLS_PATH/certutil -N -d $GENV_MSHOME1/config/ -f $GENV_CERTIFICATELOC/.pwd.txt");
		_system("$CERT_TOOLS_PATH/certutil -S -x -n \"Server-Cert\" -t \"u,u,u\" -v 120 -s \"CN=$GENV_MSHOST1.$GENV_DOMAIN\" -d $GENV_MSHOME1/config/ -z $GENV_CERTIFICATELOC/noise.txt -f $GENV_CERTIFICATELOC/.pwd.txt");
		#To list all certificates
		_system("$CERT_TOOLS_PATH/certutil -d $GENV_MSHOME1/config -L");
	}
	unless((-e "$GENV_MSHOME1/config/key4.db") || (-e "$GENV_MSHOME1/config/key3.db")){
		print "==== SSL CERTIFICATE CREATION FAILED ====\n";
		return 0;
	}
	$GENV_SSLCERTNICKNAMES=0;
     }
	adjust_file("ssl.rcp","./recipes/","$GENV_MSHOME1/config/recipes/");
	#($SystemResult, $ReturnVal, $OutputRef, $StderrRef) = _system("/opt/sun/comms/messaging64/bin/start-msg store");
	unless(_system("$GENV_MSHOME1/bin/msconfig run $GENV_MSHOME1/config/recipes/ssl.rcp")) {
		print "==== SSL Setup FAILED ====:\n";
		return 0;
	}
	return 1;
}

sub config_mmp() {
	print "==== CONFIGURING MMP PORTS ====\n";
	_system("$GENV_MSHOME1/bin/configutil -o local.mmp.enable -v 1");
	copy("$TLE_ModuleSourceDir/certmap.conf","$GENV_MSHOME1/config/");
	copy("$TLE_ModuleSourceDir/AService.cfg","$GENV_MSHOME1/config/");
	copy("$TLE_ModuleSourceDir/tcp_local_option","$GENV_MSHOME1/config/");

	my @mmp_config_files=("ImapProxyAService.cfg", "PopProxyAService.cfg", "SmtpProxyAService.cfg", "tcp_local_option");
	foreach $file (@mmp_config_files)
	{
		my $mmp_file = "$GENV_MSHOME1/config/$file";
              	copy("$mmp_file","$mmp_file.ORIG");
               	copy("$TLE_ModuleSourceDir/$file","$mmp_file");
	
       	        unless( open (FH, "$mmp_file") ) {
                         print "Unable to open file $mmp_file\n";
                         close(FH);
                         return 0;
                }
                @FileContents = <FH>; close(FH);

                foreach $Line (@FileContents) {
                        $Line =~ s/GENV_MSADMINPSWD/$GENV_MSADMINPSWD/;
			$Line =~ s/SMTPRELAY/$GENV_MSHOST1.$GENV_DOMAIN/;
			$Line =~ s/GENV_MSHOME1/$GENV_MSHOME1/;
                }

                unless( open(OP, ">$mmp_file") ) {
                         print "Unable to open file $mmp_file\n";
                         close(OP);
                         return 0;
                 }
                print OP @FileContents;
                close(OP);
	}#foreach loop ends
	return 1;
}

sub enable_ssl() {
	print "==== ENABLING SSL PORTS ====\n";
	system ("echo $GENV_MSADMINPSWD > $GENV_CERTIFICATELOC/.pwd.txt");
	unless( _system ("$GENV_MSHOME1/bin/configutil -o service.pop.enablesslport -v yes") &&
		_system ("$GENV_MSHOME1/bin/configutil -o service.pop.sslport -v 995") &&
		_system ("$GENV_MSHOME1/bin/configutil -o service.pop.sslusessl -v 1") &&
		_system ("$GENV_MSHOME1/bin/configutil -o service.imap.enablesslport -v yes") &&
		_system ("$GENV_MSHOME1/bin/configutil -o service.imap.sslport -v 993") &&
		_system ("$GENV_MSHOME1/bin/configutil -o service.imap.sslusessl -v yes") &&
		_system ("$GENV_MSHOME1/bin/configutil -o service.http.enablesslport -v yes") &&
		_system ("$GENV_MSHOME1/bin/configutil -o service.http.sslusessl -v yes") &&
		_system ("$GENV_MSHOME1/bin/configutil -o service.http.sslport -v 8991") &&
		_system ("$GENV_MSHOME1/bin/configutil -o sasl.default.ldap.has_plain_passwords -v 1") &&
		_system ("$GENV_MSHOME1/bin/configutil -o service.imap.plaintextmincipher -v 0") &&
		_system ("$GENV_MSHOME1/bin/configutil -o local.service.pab.ldapport -v 636") &&
		_system ("$GENV_MSHOME1/bin/configutil -o local.ugldapport -v 636") &&
		_system ("$GENV_MSHOME1/bin/configutil -o local.ugldapusessl -v yes") &&
		_system ("$GENV_MSHOME1/bin/configutil -o local.service.pab.ldapusessl -v yes") &&
		_system ("$GENV_MSHOME1/bin/configutil -o local.ldapcheckcert -v 0")) {
		print "==== SSL Configuration for Legacy Config FAILED ====\n";
		return 0;
	} 

	if("$GENV_SSLCERTNICKNAMES" eq "0"){
		$certname = "Server-Cert";
	}elsif("$GENV_SSLCERTNICKNAMES" eq "1"){
		$certname = "$GENV_MSHOST1.$GENV_DOMAIN";
	}

    unless ( $option eq "SSL" ) {
	system ("rm $GENV_MSHOME1/config/*.db $GENV_MSHOME1/config/pkcs11.txt")if(-e "$GENV_MSHOME1/config/key4.db");
    	if(("$use_msgcert" eq "1") && (-e "$GENV_MSHOME1/lib/msgcert")){
        	unless(_system ("$GENV_MSHOME1/lib/msgcert generate-certDB -W $GENV_CERTIFICATELOC/.pwd.txt")){
			print "==== Cert-DB generation FAILED ====\n";
			return 0;
		}
	}
	else{
		$ENV{'NSS_DEFAULT_DB_TYPE'} = 'sql';
		unless( _system("$CERT_TOOLS_PATH/certutil -N -d $GENV_MSHOME1/config/ -f $GENV_CERTIFICATELOC/.pwd.txt") &&
			_system("$CERT_TOOLS_PATH/certutil -S -x -n \"$certname\" -t \"u,u,u\" -v 120 -s \"CN=$GENV_MSHOST1.$GENV_DOMAIN\" -d $GENV_MSHOME1/config/ -z $GENV_CERTIFICATELOC/noise.txt -f $GENV_CERTIFICATELOC/.pwd.txt")){
			print "=== Cert-DB generation FAILED ====\n";
			return 0;
		}
		#To list all certificates
		_system("$CERT_TOOLS_PATH/certutil -d $GENV_MSHOME1/config -L");
	}
	unless((-e "$GENV_MSHOME1/config/key4.db") || (-e "$GENV_MSHOME1/config/key3.db")){
		print "==== SSL CERTIFICATE CREATION FAILED ====\n";
	}
     }
	copy("$GENV_MSHOME1/config/dispatcher.cnf","$GENV_MSHOME1/config/dispatcher.cnf.ORIG");
	copy("$GENV_MSHOME1/config/mappings","$GENV_MSHOME1/config/mappings.ORIG");
	unless( DispatcherRemove("$GENV_MSHOME1","TLS_PORT","465","SERVICE=SMTP_SUBMIT") &&
		DispatcherAdd("$GENV_MSHOME1","TLS_PORT","465","SERVICE=SMTP_SUBMIT") &&
		_system ("$GENV_MSHOME1/bin/configutil -o local.webmail.smime.enable -v yes") &&
        	_system ("$GENV_MSHOME1/bin/configutil -o local.webmail.cert.enable -v yes") &&
		_system ("$GENV_MSHOME1/bin/configutil -o local.imap.sslnicknames -v \"$certname\"") &&
		_system ("$GENV_MSHOME1/bin/configutil -o local.http.sslnicknames -v \"$certname\"") &&
		_system ("$GENV_MSHOME1/bin/configutil -o local.imta.sslnicknames -v \"$certname\"") &&
		_system ("$GENV_MSHOME1/bin/configutil -o local.pop.sslnicknames -v \"$certname\"") &&
		_system ("$GENV_MSHOME1/bin/configutil -o encryption.rsa.nssslpersonalityssl -v \"$certname\"")) {
		print "==== configutil FAILED to set ssl parameters ====\n";
		return 0;
	}
	return 1;
}

sub enable_logging() {
	print "==== ENABLING MAXIMUM DEBUG LOGGING ====\n";
	_system ("$GENV_MSHOME1/bin/configutil -o logfile.admin.loglevel -v debug");
	_system ("$GENV_MSHOME1/bin/configutil -o logfile.default.loglevel -v debug");
	_system ("$GENV_MSHOME1/bin/configutil -o logfile.http.loglevel -v debug");
	_system ("$GENV_MSHOME1/bin/configutil -o logfile.imap.loglevel -v Debug");
	_system ("$GENV_MSHOME1/bin/configutil -o logfile.imta.loglevel -v debug");
	_system ("$GENV_MSHOME1/bin/configutil -o logfile.pop.loglevel -v Debug");
	_system ("$GENV_MSHOME1/bin/configutil -o logfile.mmp.loglevel -v debug");
	_system ("$GENV_MSHOME1/bin/configutil -o logfile.imapproxy.loglevel -v Debug");
	_system ("$GENV_MSHOME1/bin/configutil -o logfile.popproxy.loglevel -v debug");
	_system ("$GENV_MSHOME1/bin/configutil -o logfile.submitproxy.loglevel -v Debug");
	_system ("$GENV_MSHOME1/bin/configutil -o local.debugkeys -v \"metermaid connect ldap lpool tls certmap\"");
	#Editing option.dat file
	my $orig_option_file = "$GENV_MSHOME1/config/option.dat.ORIG";
	my $option_file = "$GENV_MSHOME1/config/option.dat";
        copy("$orig_option_file","$option_file")if(-e "$orig_option_file");
        copy("$option_file","$orig_option_file")unless(-e "$orig_option_file");

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
	#_system ("$cwd/ChannelKeywordDo.pl");
	
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
	unless (ChannelKeywordAdd("$GENV_MSHOME1","defaults","logging","") &&
         	ChannelKeywordRemove("$GENV_MSHOME1","tcp_intranet","mustsaslserver","") &&
		ChannelKeywordRemove("$GENV_MSHOME1","tcp_local","mustsaslserver","") &&
         	ChannelKeywordRemove("$GENV_MSHOME1","tcp_submit","mustsaslserver","") &&
         	ChannelKeywordAdd("$GENV_MSHOME1","tcp_intranet","maysaslserver","") &&
         	ChannelKeywordAdd("$GENV_MSHOME1","tcp_local","maysaslserver","") &&
         	ChannelKeywordAdd("$GENV_MSHOME1","tcp_submit","maysaslserver","") &&
         	ChannelKeywordAdd("$GENV_MSHOME1","ims-ms","master_debug slave_debug","") &&
         	ChannelKeywordAdd("$GENV_MSHOME1","tcp_local","master_debug slave_debug","") &&
        	ChannelKeywordAdd("$GENV_MSHOME1","tcp_intranet","master_debug slave_debug","") &&
         	ChannelKeywordAdd("$GENV_MSHOME1","tcp_submit","master_debug slave_debug","") &&
         	ChannelKeywordAdd("$GENV_MSHOME1","tcp_auth","master_debug slave_debug","") &&
         	ChannelKeywordAdd("$GENV_MSHOME1","reprocess","master_debug slave_debug","") &&
         	ChannelKeywordAdd("$GENV_MSHOME1","process","master_debug slave_debug","") &&
         	ChannelKeywordAdd("$GENV_MSHOME1","conversion","master_debug slave_debug","")) {
		print "keyword modification failed\n"; 
	}
	return 1;
}

sub config_undo() {
	my @config_files=("tcp_local_option", "job_controller.cnf", "option.dat", "dispatcher.cnf", "ImapProxyAService.cfg", "PopProxyAService.cfg", "SmtpProxyAService.cfg", "imta.cnf");
	foreach $file (@config_files)
	{
              	copy("$GENV_MSHOME1/config/$file.ORIG","$GENV_MSHOME1/config/$file");
		unlink ("$GENV_MSHOME1/config/$file.ORIG");
	}
	_system ("$GENV_MSHOME1/bin/configutil -o service.pop.enablesslport -d");
	_system ("$GENV_MSHOME1/bin/configutil -o service.pop.sslport -d");
	_system ("$GENV_MSHOME1/bin/configutil -o service.pop.sslusessl -d");
	_system ("$GENV_MSHOME1/bin/configutil -o service.imap.enablesslport -d");
	_system ("$GENV_MSHOME1/bin/configutil -o service.imap.sslport -d");
	_system ("$GENV_MSHOME1/bin/configutil -o service.imap.sslusessl -d");
	_system ("$GENV_MSHOME1/bin/configutil -o service.http.enablesslport -d");
	_system ("$GENV_MSHOME1/bin/configutil -o service.http.sslusessl -d");
	_system ("$GENV_MSHOME1/bin/configutil -o service.http.sslport -d");
	_system ("$GENV_MSHOME1/bin/configutil -o sasl.default.ldap.has_plain_passwords -d");
	_system ("$GENV_MSHOME1/bin/configutil -o service.imap.plaintextmincipher -d");
	_system ("$GENV_MSHOME1/bin/configutil -o local.service.pab.ldapport -d");
	_system ("$GENV_MSHOME1/bin/configutil -o local.ugldapport -d");
	_system ("$GENV_MSHOME1/bin/configutil -o local.ugldapusessl -d");
	_system ("$GENV_MSHOME1/bin/configutil -o local.service.pab.ldapusessl -d");
	_system ("$GENV_MSHOME1/bin/configutil -o local.ldapcheckcert -d");
	_system ("$GENV_MSHOME1/bin/configutil -o local.webmail.smime.enable -d");
        _system ("$GENV_MSHOME1/bin/configutil -o local.webmail.cert.enable -d");
	_system ("$GENV_MSHOME1/bin/configutil -o logfile.admin.loglevel -d");
        _system ("$GENV_MSHOME1/bin/configutil -o logfile.default.loglevel -d");
        _system ("$GENV_MSHOME1/bin/configutil -o logfile.http.loglevel -d");
        _system ("$GENV_MSHOME1/bin/configutil -o logfile.imap.loglevel -d");
        _system ("$GENV_MSHOME1/bin/configutil -o logfile.imta.loglevel -d");
        _system ("$GENV_MSHOME1/bin/configutil -o logfile.pop.loglevel -d");
        _system ("$GENV_MSHOME1/bin/configutil -o logfile.mmp.loglevel -d");
        _system ("$GENV_MSHOME1/bin/configutil -o logfile.imapproxy.loglevel -d");
        _system ("$GENV_MSHOME1/bin/configutil -o logfile.popproxy.loglevel -d");
        _system ("$GENV_MSHOME1/bin/configutil -o logfile.submitproxy.loglevel -d");
        _system ("$GENV_MSHOME1/bin/configutil -o local.ldaptrace -d");
	_system ("$GENV_MSHOME1/bin/configutil -o local.mmp.enable -d");
	unlink ("$GENV_MSHOME1/config/pkcs11.txt");
	unlink ("$GENV_MSHOME1/config/key4.db");
	unlink ("$GENV_MSHOME1/config/cert9.db");
	unlink ("$GENV_MSHOME1/config/tcp_local_option");
	return 1;
}

sub DispatcherDo {
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
					print "$option_name already exists with value $option_value\n";last;
					last;
			   	}
			   	elsif ($line eq "!$option_name=$option_value") {
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

sub DispatcherRemove {
	my ($server_path, $option_name, $option_value, $section) = @_;
	return(DispatcherDo(0, $server_path, $option_name, $option_value, $section));
}

sub DispatcherAdd {
	my ($server_path, $option_name, $option_value, $section) = @_;
	return(DispatcherDo(1, $server_path, $option_name, $option_value, $section));
}

sub ChannelKeywordDo {
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
			   if ($Line =~ $keyword) {print "$keyword already exists,Current Line is:\n".$Line."\n";next;}
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

sub ChannelKeywordRemove {
        my ($server_path, $channel, $keyword, $param_count) = @_;
        return(ChannelKeywordDo($server_path, $channel, $keyword, '', $param_count, 0));
}

sub ChannelKeywordAdd {
        return(ChannelKeywordDo(@_, 0, 1));
}

sub MS_NewConfig () {
	# Deleting previous admin user
	print "==== STARTING NEW MS CONFIGURATION ====\n";
	_system("$GENV_MSHOME1/bin/stop-msg")if(-d "$GENV_MSHOME1/config");
	_system("rm -rf /var/$GENV_MSHOME1");
	my $ldap = Net::LDAP->new( "$GENV_DSHOST1.$GENV_DOMAIN", debug => $debug, version => 3 );
	unless($ldap){
		print "==== Directory Server is Down, MS Configuration cannot proceed ====\n";
		die @;
	}
        my $mesg = $ldap->bind ( "$GENV_DM", password => $GENV_DMPASSWORD, version => 3 ) or die "$@";
        my $mesg = $ldap->search ( base  => "$GENV_OSIROOT", filter  => "uid=msg-admin-$GENV_MSHOST1*");
        foreach $entry ($mesg->entries) { $ldap->delete($entry); }
        $mesg = $ldap->unbind;   # take down session
	my $cmd = "";
	unless($USE_STATE_FILE){
		if("$GENV_XMLCONFIG" eq "1"){
			$cmd = "$GENV_MSHOME1/bin/configure --debug --xml";
		}else {
			$cmd = "$GENV_MSHOME1/bin/configure --debug --noxml";
		}
		$exp = new Expect();
	        $exp->raw_pty(1);
	        $exp->debug($debug);
	        $exp->spawn($cmd);
		print "==== Running: $cmd\n";
	        $exp->expect($timeout,'-re', ':\s$'); #dir
	        $exp->send("\n");
	        $exp->expect($timeout,'-re', ':\s$'); #mailsrv
	        $exp->send("$GENV_MAILSERVERUSERID\n");
	        $exp->expect($timeout,'-re', ':\s$'); #hostname.domain
	        $exp->send("$GENV_MSHOST1.$GENV_DOMAIN\n");
	        $exp->expect($timeout,'-re', ':\s$'); #domain
	        $exp->send("$GENV_MAILHOSTDOMAIN\n");
	        $exp->expect($timeout,'-re', ':\s$'); #ldap server name
	        $exp->send("$GENV_DSHOST1.$GENV_DOMAIN\n");
	        $exp->expect($timeout,'-re', ':\s$'); #cn=DM
	        $exp->send("\n");
	        $exp->expect($timeout,'-re', ':\s$'); #dmpwd
	        $exp->send("$GENV_DMPASSWORD\n");
	        $exp->expect($timeout,'-re', ':\s$'); #admin@us.oracle.com
	        $exp->send("$GENV_POSTMASTER\@$GENV_MAILHOSTDOMAIN\n");
	        $exp->expect($timeout,'-re', ':\s$'); #Ip prefix
	        $exp->send("\n");
	        $exp->expect($timeout,'-re', ':\s$'); # msadminpwd
	        $exp->send("$GENV_MSADMINPSWD\n");
	        $exp->expect($timeout,'-re', ':\s$'); # msadminpwd
	        $exp->send("$GENV_MSADMINPSWD\n");
	        $exp->expect(40,'-re', 'successfully\s$');
	        $exp->hard_close();
	}else{
		if(-e "/tmp/sample_statefile"){
			unlink("/tmp/sample_statefile");
		}

		adjust_file("sample_statefile",".","/tmp");

		if("$GENV_XMLCONFIG" eq "1"){
                         $cmd = "$GENV_MSHOME1/bin/configure --debug --xml --state=/tmp/sample_statefile";
                }else {
                         $cmd = "$GENV_MSHOME1/bin/configure --debug --noxml --state=/tmp/sample_statefile";
                }
		print "==== Using statefile /tmp/sample_statefile ====\n";
		_system("cat /tmp/sample_statefile") if($GENV_VERYVERYNOISY);
		($SystemResult, $ReturnVal, $OutputRef, $StderrRef) = _system("$cmd");
		if(!($SystemResult) || ("@$StderrRef" =~ /FAILED/i) || ("@$StderrRef" =~ /Connection refused/)){
			print "==== MS configuration using StateFile FAILED ====\n";
			exit 0;
		}
		print "==== MS configuration using StateFile PASSED ====\n";
	}
        return 1;
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
	return 1;
}

###########################################################################
# [ DS_enable_plaintext ]
# Description:
#	Modify the DS configuration file and restart slapd 
# Returns: 
#	True: if DS restart successfully
#	False: if any error occurs
###########################################################################
sub DS_enable_plaintext()
{
	unless ( -e "$GENV_CERTIFICATELOC/.pwd.txt") {
		_system("echo \"$GENV_DMPASSWORD\" > $GENV_CERTIFICATELOC/.pwd.txt");
	}
	($SystemResult, $ReturnVal, $OutputRef, $StderrRef) = _system("$DSCONF_PATH get-server-prop -e -w $GENV_CERTIFICATELOC/.pwd.txt pwd-storage-scheme");
	if("@$OutputRef" =~ /CLEAR/i){
                return 1;
        }
   	print "==== Enabling cleartext password storage in Directory Server ...............\n";
	_system("$DSCONF_PATH set-server-prop -v -e -i -w $GENV_CERTIFICATELOC/.pwd.txt pwd-storage-scheme:CLEAR");
   	print "==== Restarting Directory Server ...............\n";
   	unless (DS_Restart()) {
   		print "failed to restart slapd process on $Host\n";
   		return 0;
   	}
	return 1;
}

#############################################################################
# [ DS_Restart ]
# Description:
#	restart slapd process
# Returns: 
#	True: if slapd restarted successfully
#       False: if any error occurs
#############################################################################
sub DS_Restart()
{
   	# do a restart on the _system since the configuration changed
	print "Restarting slapd.....\n";
	unless (-d $GENV_DS1INSTANCE1){
		chomp($GENV_DS1INSTANCE1 = `find /var/opt/ -name dsins1`);
	}
	print "Stopping slapd.....\n";
        _system ("$DSADM_PATH stop $GENV_DS1INSTANCE1");
	print "Starting slapd.....\n";
        _system ("$DSADM_PATH start $GENV_DS1INSTANCE1");
        unless ($? == 0){
   		print "====Directory Server restart FAILED\n";
                exit 0;
        }
   	sleep(5);
	print "DS_Restart end.....\n";
   	return 1;
}

sub logging_disable()
{
        _system ("$GENV_MSHOME1/bin/configutil -o logfile.admin.loglevel -d");
        _system ("$GENV_MSHOME1/bin/configutil -o logfile.default.loglevel -d");
        _system ("$GENV_MSHOME1/bin/configutil -o logfile.http.loglevel -d");
        _system ("$GENV_MSHOME1/bin/configutil -o logfile.imap.loglevel -d");
        _system ("$GENV_MSHOME1/bin/configutil -o logfile.imta.loglevel -d");
        _system ("$GENV_MSHOME1/bin/configutil -o logfile.pop.loglevel -d");
        _system ("$GENV_MSHOME1/bin/configutil -o logfile.mmp.loglevel -d");
        _system ("$GENV_MSHOME1/bin/configutil -o logfile.imapproxy.loglevel -d");
        _system ("$GENV_MSHOME1/bin/configutil -o logfile.popproxy.loglevel -d");
        _system ("$GENV_MSHOME1/bin/configutil -o logfile.submitproxy.loglevel -d");
        _system ("$GENV_MSHOME1/bin/configutil -o local.ldaptrace -d");
        return 1;
}

sub test_ALL()
{
	_system("./connectNormal.sh $GENV_MSHOST1 neo1 25");
	_system("./connectNormal.sh $GENV_MSHOST1 neo1 125");
	_system("./connectNormal.sh $GENV_MSHOST1 neo1 143");
	_system("./connectNormal.sh $GENV_MSHOST1 neo1 1143");
	_system("./connectNormal.sh $GENV_MSHOST1 neo1 110");
	_system("./connectNormal.sh $GENV_MSHOST1 neo1 1110");
	_system("./connectMMPSSL.pl $GENV_MSHOST1 neo1 465");
	_system("./connectMMPSSL.pl $GENV_MSHOST1 neo1 1465");
	_system("./connectMMPSSL.pl $GENV_MSHOST1 neo1 993");
	_system("./connectMMPSSL.pl $GENV_MSHOST1 neo1 1993");
	_system("./connectMMPSSL.pl $GENV_MSHOST1 neo1 995");
	_system("./connectMMPSSL.pl $GENV_MSHOST1 neo1 1995");
	return 1;
}

sub dsnew_instance()
{
	system ("echo $GENV_DMPASSWORD > $GENV_CERTIFICATELOC/.pwd.txt");
	if((length($GENV_SCHEMA) == 0) || ($GENV_SCHEMA == 1)){
		$SCHEMA = 1;
	}elsif($GENV_SCHEMA == 3){
		$SCHEMA = 2;
	}
	if(length($GENV_DS1INSTANCE1) == 0) {
		$GENV_DS1INSTANCE1 = "/var/opt/SUNWdsee/dsins1";
	}
	if(-d $GENV_DS1INSTANCE1){
		unless(_system("$DSADM_PATH delete $GENV_DS1INSTANCE1")){
			print "==== DSINTANCE DELTE FAILED\n";
			return 0;
		}
	}else { system("mkdir -p /var/opt/SUNWdsee");}
	_system("$DSADM_PATH create -D\"$GENV_DM\" -w $GENV_CERTIFICATELOC/.pwd.txt $GENV_DS1INSTANCE1");
	_system("$DSADM_PATH start $GENV_DS1INSTANCE1");
	my $cmd = `find /opt/sun/comms |grep "bin/comm_dssetup.pl"`;
	$exp = new Expect();
        $exp->raw_pty(1);
        $exp->debug($debug);
        $exp->spawn($cmd);
        $exp->expect($timeout,'-re', ':\s$');
        $exp->send("y\n");
        $exp->expect($timeout,'-re', ':\s$');
        $exp->send("$GENV_DS1INSTANCE1\n");
        $exp->expect($timeout,'-re', ':\s$');
        $exp->send("$GENV_DM\n");
        $exp->expect($timeout,'-re', ':\s$');
        $exp->send("$GENV_DMPASSWORD\n");
        $exp->expect($timeout,'-re', ']:\s$');
        $exp->send("yes\n");
        $exp->expect($timeout,'-re', ']:\s$');
        $exp->send("$GENV_OSIROOT\n");
        $exp->expect("$timeout",'-re', ']:\s$');
        $exp->send("$SCHEMA\n");
        $exp->expect($timeout,'-re', ':\s$');
        $exp->send("\n");
        $exp->expect($timeout,'-re', ':\s$');
        $exp->send("yes\n");
        $exp->expect($timeout,'-re', ':\s$');
        $exp->send("yes\n");
        $exp->expect($timeout,'-re', ':\s$');
        $exp->send("yes\n");
        $exp->expect($timeout,'-re', ':\s$');
        $exp->send("y\n");
        $exp->expect("30",'-re', ':\s$');
        $exp->send("y\n");
        $exp->expect("500",'-re', '^Successful');
        $exp->hard_close();
	return 1;
}

sub check_ports() 
{

   $os=`uname -s`;
   chomp($os);
   if ($os eq "SunOS") {
           $netstat_cmd = "netstat -na|grep LISTEN";
   } elsif ( $os eq "Linux" ) {
           $netstat_cmd = "netstat -nalpt|grep LISTEN";
   }
   
   @list=(25,465,110,995,143,993,899,587,389,636,63837,7997);
   foreach $i (@list) 
   {
   	if ($i =~ /143/) {
   		print "==== IMAP Related Ports Status ====\n";
   	}
   	if ($i =~ /63837/) {
   		print "==== MeterMaid Related Port Status ====\n";
   	}
   	if ($i =~ /993/) {
   		print "==== IMAPS Related Ports Status ====\n";
   	}
   	if ($i =~ /25/) {
   		print "==== SMTP Related Ports Status ====\n";
   	}
   	if ($i =~ /465/) {
   		print "==== SMTPS Related Ports Status ====\n";
   	}
   	if ($i =~ /110/) {
   		print "==== POP Related Ports Status ====\n";
   	}
   	if ($i =~ /995/) {
   		print "==== POPS Related Ports Status ====\n";
   	}
   	if ($i =~ /587/) {
   		print "==== SUBMIT Related Port Status ====\n";
   	}
   	if ($i =~ /389/) {
   		print "==== LDAP Related Ports Status ====\n";
   	}
   	if ($i =~ /636/) {
   		print "==== LDAPS Related Ports Status ====\n";
   	}
   	if ($i =~ /899/) {
   		print "==== HTTP Related Ports Status ====\n";
   	}
   	if ($i =~ /7997/) {
   		print "==== ENS Related Ports Status ====\n";
   	}
   	system ("$netstat_cmd|grep $i");
   }
}#check_ports finishes

sub Default_files(){

	#AService.cfg
	system("echo \"default:ServiceList  imapproxy\@1143|1993 popproxy\@1110|1995 submitproxy\@125|1465\" > AService.cfg");

	#ImapProxyAService.cfg
	system("echo \"default:SSLEnable         yes\" > ImapProxyAService.cfg");
	system("echo \"default:SSLPorts          1993\" >> ImapProxyAService.cfg");
	system("echo \"default:SSLBacksidePort   993\" >> ImapProxyAService.cfg");
	system("echo \"default:CertMapFile       GENV_MSHOME1/config/certmap.conf\" >> ImapProxyAService.cfg");
	system("echo \"default:ConnLimits 0.0.0.0|0.0.0.0:20\" >> ImapProxyAService.cfg");
	system("echo \"default:StoreAdminPass GENV_MSADMINPSWD\" >> ImapProxyAService.cfg");

	#PopProxyAService.cfg
	system("echo \"default:SSLEnable         yes\" > PopProxyAService.cfg");
	system("echo \"default:SSLPorts          1995\" >> PopProxyAService.cfg");
	system("echo \"default:SSLBacksidePort   995\" >> PopProxyAService.cfg");
	system("echo \"default:CertMapFile       GENV_MSHOME1/config/certmap.conf\" >> PopProxyAService.cfg");
	system("echo \"default:ConnLimits 0.0.0.0|0.0.0.0:20\" >> PopProxyAService.cfg");
	system("echo \"default:StoreAdminPass GENV_MSADMINPSWD\" >> PopProxyAService.cfg");


	#SmtpProxyAService.cfg
	system("echo \"default:SmtpRelays SMTPRELAY\" > SmtpProxyAService.cfg");
	system("echo \"default:SmtpProxyPassword GENV_MSADMINPSWD\" >> SmtpProxyAService.cfg");
	system("echo \"default:SSLEnable         yes\" >> SmtpProxyAService.cfg");
	system("echo \"default:SSLPorts          1465\" >> SmtpProxyAService.cfg");
	system("echo \"default:SSLBacksidePort   465\" >> SmtpProxyAService.cfg");
	system("echo \"default:CertMapFile       GENV_MSHOME1/config/certmap.conf\" >> SmtpProxyAService.cfg");
	system("echo \"default:ConnLimits 0.0.0.0|0.0.0.0:20\" >> SmtpProxyAService.cfg");
	system("echo \"default:StoreAdminPass GENV_MSADMINPSWD\" >> SmtpProxyAService.cfg");
	
	#tcp_local_option
	system("echo \"PROXY_PASSWORD=GENV_MSADMINPSWD\" > tcp_local_option");

	#certmap.conf
	system("echo \"certmap default		default\" > certmap.conf");
	system("echo \"default:DNComps\" >> certmap.conf");
	system("echo \"default:FilterComps	e=mail\" >> certmap.conf"); 

	#sample_statefile
        system("echo \"Fqdn.TextField = GENV_MSHOST1.GENV_DOMAIN\" > sample_statefile");
        system("echo \"msg.DataPath = /varGENV_MSHOME1\" >> sample_statefile");
        system("echo \"iMS.UserId = GENV_MAILSERVERUSERID\" >> sample_statefile");
        system("echo \"iMS.GroupId = GENV_MAILSERVERUSERGROUP\" >> sample_statefile");
        system("echo \"UGDIR_URL = ldap://GENV_DSHOST1.GENV_DOMAIN:GENV_DSLDAPPORT1\" >> sample_statefile");
        system("echo \"UGDIR_BINDDN = GENV_DM\" >> sample_statefile");
        system("echo \"UGDIR_BINDPW = ENCODED_DMPASSWORD\" >> sample_statefile");
        system("echo \"Postmaster.TextField = GENV_POSTMASTERGENV_SEPARATORGENV_MAILHOSTDOMAIN\" >> sample_statefile");
        system("echo \"admin.password = ENCODED_MSADMINPSWD\" >> sample_statefile");
        system("echo \"EmailDomain.TextField = GENV_MAILHOSTDOMAIN\" >> sample_statefile");
        system("echo \"OrgName.TextField = o=GENV_MAILHOSTDOMAIN,GENV_OSIROOT\" >> sample_statefile");
        system("echo \"InternalIPlist = \" >> sample_statefile");
        system("echo \"XMLCONFIG = GENV_XMLCONFIG\" >> sample_statefile");

	return 1;
}

system("echo $GENV_MSADMINPSWD > $GENV_CERTIFICATELOC/.pwd.txt");

sub create_servercert() {
	if ($USE_LOCAL_CA){
		adjust_file("openssl.cnf",".");
		adjust_file("openssl.cnf.SSLSERVER",".");
		create_local_CA();
		setup_certdb();
		generate_server_cert_request();
		import_server_cert();
		DirectorySSLSetup();
	}
	else {
		setup_certdb();
		generate_server_cert_request();
		import_server_cert();
	}
	_system("touch $GENV_CERTIFICATELOC/finished.CA");
}

#
# This function creates a user-cert.p12 file which contains the user's
# private key as well as identity cert
#Usage: create_user_cert("amit3", "us.oracle.com", "bakhru");
#
sub create_user_cert {
	($user,$domain) = @_;
	my $timeout=2;
	unless (-d "$GENV_CERTIFICATELOC/ldifs"){ _system("mkdir -p $GENV_CERTIFICATELOC/ldifs"); }
	adjust_file("GenerateUserCert.sh",".");
	print "==== Inside create_user_cert function\n";
	unless(delete_user_cert_fromLDAP($user,$domain)){
		print "==== Previous cert deletion failed exiting...\n";
		exit 0;
	}
	if ($USE_LOCAL_CA)
	{
		_system ("sed \'/$user/d\' $GENV_CERTIFICATELOC/index.txt> $GENV_CERTIFICATELOC/t;mv $GENV_CERTIFICATELOC/t $GENV_CERTIFICATELOC/index.txt\n");
		if(-e "$GENV_CERTIFICATELOC/newcerts/$user-cert.pem"){
			unlink ("$GENV_CERTIFICATELOC/newcerts/$user-cert.pem");
		}
		print "==== Now creating the $user-cert.p12 file\n";
		print "$GENV_CERTIFICATELOC/GenerateUserCert.sh $user $domain $GENV_DSHOST1\n";
		$cmd = "$GENV_CERTIFICATELOC/GenerateUserCert.sh $user $domain $GENV_DSHOST1";
		$exp = new Expect();
#		$exp->raw_pty(1);
		$exp->debug($debug);
		$exp->spawn($cmd);
		$exp->expect($timeout,'-re', ':\s$');
		$exp->send ("\n");
		$exp->expect($timeout,'-re', ':\s$');
		$exp->send ("\n");
		$exp->expect($timeout,'-re', ':\s$');
		$exp->send ("\n");
		$exp->expect($timeout,'-re', ':\s$');
		$exp->send ("\n");
		$exp->expect($timeout,'-re', ':\s$');
		$exp->send ("\n");
		$exp->expect($timeout,'-re', ':\s$');
		$exp->send ("$user\@$domain\n");
		$exp->expect($timeout,'-re', ':\s$');
		$exp->send ("$user\@$domain\n");
		$exp->expect($timeout,'-re', ':\s$');
		$exp->send ("$GENV_MSADMINPSWD\n");
		$exp->expect($timeout,'-re', ':\s$');
		$exp->send ("\n");
		$exp->expect($timeout,'-re', ':\s$');
		$exp->send ("$GENV_MSADMINPSWD\n");
		$exp->expect($timeout,'-re', ':\s$');
		$exp->send ("y\n");
		$exp->expect($timeout,'-re', ']\s$');
		$exp->send ("y\n");
		#$exp->expect($timeout,'-re', ':\s$');#export to pk12
		#$exp->send ("$GENV_MSADMINPSWD\n");
		#$exp->expect($timeout,'-re', ':\s$');
		#$exp->send ("$GENV_MSADMINPSWD\n");
		$exp->expect(5,'-re', 'fully\s$');
		$exp->hard_close();
	}
	else {
		print "====Now creating the $user-cert.p12 file on marceau\n";
		$cmd6="ssh -l root marceau.us.oracle.com";
		$exp1 = new Expect();
		$exp1->raw_pty(1);
		$exp1->debug($debug);
		$exp1->spawn($cmd6);
#		$exp1->expect($timeout,'-re', '?\s$');
#		$exp1->send ("yes\n");
		$exp1->expect($timeout,'-re', ':\s$');
		$exp1->send ("$host_root_pwd\n");
		$exp1->expect($timeout,'-re', '#\s$');
		$exp1->send ("export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:/usr/sfw/lib:.\n");
		$exp1->expect($timeout,'-re', '#\s$');
		$exp1->send ("cd /space/smime/\n");
		$exp1->expect($timeout,'-re', '#\s$');
		$exp1->send ("sed \'/$user/d\' index.txt > t; mv t index.txt\n");
		$exp1->expect($timeout,'-re', '#\s$');
		$exp1->send ("find . |grep $user |xargs rm\n");
		$exp1->expect($timeout,'-re', '#\s$');
		$exp1->send("./create_cert.sh $user $domain $GENV_DSHOST1\n");
		$exp1->expect(40,'-re', '#\s$');
		$exp1->send("exit\n");
		$exp1->hard_close();
		copy_cert("$user-cert.pem", "$host_root_pwd","newcerts");
		copy_cert("$user-key.pem", "$host_root_pwd","private");
	}
	return 1;
}

#
# This function copy the required cert from marceau to $host
#NOTE: ALWAYS Need to provide full cert-name to import
#Usage: copy_cert(amit3-cert.p12, password, newcerts);
#       copy_cert(bakhru-cert.pem, password, newcerts);
#
sub copy_cert {
	print "====Inside copy_cert from marceau function\n";
	($cert_to_import, $GENV_MSADMINPSWD, $dir) = @_;
 	$copy_cert = "scp root\@marceau.us.oracle.com:/space/smime/$dir/$cert_to_import $GENV_CERTIFICATELOC/$dir/";
	$exp = new Expect();
	$exp->raw_pty(1);
	$exp->debug($debug);
	$exp->spawn($copy_cert);
#	$exp->expect($timeout,'-re', '?\s$');
#	$exp->send ("yes\n");
	$exp->expect($timeout,'-re', ':\s$');
	$exp->send ("$host_root_pwd\n");
	$exp->expect($timeout,'-re', '#\s$');
	$exp->send("quit\n");
	$exp->hard_close();
	return;
}

# To list all the certs in NSS cert db
#$CERT_TOOLS_PATH/certutil -L -d /opt/sun/comms/messaging64/config/
# For Example:
#$CERT_TOOLS_PATH/pk12util -i /tmp/amit3-cert.p12 -d /opt/sun/comms/messaging64/config/
#Enter Password or Pin for "NSS Certificate DB":
#Enter password for PKCS12 file:
#pk12util: PKCS12 IMPORT SUCCESSFUL
sub import_user_cert {
	print "==== Inside import_user_cert function\n";
	($user) = @_;
	if ($USE_LOCAL_CA) {
		 print "==== Using $user-cert.12 from local CA @ $GENV_CERTIFICATELOC/newcerts/ \n";
	} else {
		print "==== Copying user_cert from marceau to $GENV_CERTIFICATELOC\n";
		copy_cert("$user-cert.p12","$host_root_pwd", "newcerts");
	}
	unless (-e "$GENV_CERTIFICATELOC/newcerts/$user-cert.p12") {
		print "==== FAILURE: $user-cert.p12 file not found\n";
		return 0;
	}
	print "==== Importing user_cert to MS-cert DB\n";
	_system("$CERT_TOOLS_PATH/pk12util -i $GENV_CERTIFICATELOC/newcerts/$user-cert.p12 -w $GENV_CERTIFICATELOC/.pwd.txt -k $GENV_CERTIFICATELOC/.pwd.txt -d $GENV_MSHOME1/config/");
	return 1;
}

#
# This function imports the CA-Cert and signed Server-Cert into ms cert-db
#
# Usage: import_server_cert("bakhru");
#
sub import_server_cert {
	print "==== Inside import_server_cert function\n";
	my $certname = "Server-Cert";
	if("$GENV_SSLCERTNICKNAMES" eq "1"){
		$certname = "$GENV_MSHOST1" . ".$GENV_DOMAIN";
	}
	if (("$use_msgcert" eq "1") && (-e "$GENV_MSHOME1/lib/msgcert")){
		print "==== Importing CA-Cert first\n";
		_system("$GENV_MSHOME1/lib/msgcert add-cert -W $GENV_CERTIFICATELOC/.pwd.txt -C CA-Cert $GENV_CERTIFICATELOC/newcerts/cacert.pem");
		print "==== Importing CA Signed \"$certname\" certificate\n";
		#import p12 file into cert9.db using pk12util
		_system("$GENV_MSHOME1/lib/msgcert add-cert -W $GENV_CERTIFICATELOC/.pwd.txt $certname $GENV_CERTIFICATELOC/newcerts/$GENV_MSHOST1-cert.pem");
	}elsif("$use_msgcert" eq "0"){
		print "==== Importing \"CA-Cert\" first ====\n";
		_system("$CERT_TOOLS_PATH/certutil -A -a -n CA-Cert -i $GENV_CERTIFICATELOC/newcerts/cacert.pem -t CT -d $GENV_MSHOME1/config/ -f $GENV_CERTIFICATELOC/.pwd.txt");
		print "==== Importing CA Signed \"$certname\" certificate ====\n";
		#import p12 file into cert9.db using certutil
		_system("$CERT_TOOLS_PATH/certutil -A -n \"$certname\" -i $GENV_CERTIFICATELOC/newcerts/$GENV_MSHOST1-cert.pem -d $GENV_MSHOME1/config/ -t \"p,p,p\" -f $GENV_CERTIFICATELOC/.pwd.txt");
	}else {
		 print "==== FAILURE : msgcert utility not found, may be MS is not installed\n";
		 exit;
	}
	print "==== LISTING Current Certificates in MS-Cert DB ====\n";
	_system("$CERT_TOOLS_PATH/certutil -d $GENV_MSHOME1/config -L");
	return 1;
}

#
# This function removes the required cert-alias from ms cert8.db
#
# Usage: remove_cert("cert-alias");
# For Eg:remove_cert("Server-Cert"); remove_cert("amit1@us.oracle.com");
#
sub remove_cert {
	($cert_alias) = @_;
	print "====Inside remove_cert function====\n\n";
	print "====Removing $cert_alias\n";
	unless (-e "$GENV_MSHOME1/lib/msgcert")
	{
		 print "====FAILURE : msgcert utility not found, may be MS is not installed\n";
		 exit;
	}
	_system("$GENV_MSHOME1/lib/msgcert remove-cert -W $GENV_CERTIFICATELOC/.pwd.txt $cert_alias");
	unless ($? == 0){ print "====FAILURE: $cert_alias removal failed : $? \n"; }
	return;
}

#
# This function generates a Server-Cert-Request, scp to marceau to be signed by local CA and
# then copy back the singed Server-Cert & CA-Cert to $host machine
#
# Usage: generate_server_cert_request("bakhru", "us.oracle.com", "password");
#
sub generate_server_cert_request
{
	print "==== Inside generate_server_cert function\n";
	my $timeout=4;
	my $certname = "Server-Cert";
	if("$GENV_SSLCERTNICKNAMES" eq "1"){
		$certname = "$GENV_MSHOST1" . ".$GENV_DOMAIN";
	}

	print "==== Generating the server-cert-request\n";
	_system("rm -rf $GENV_CERTIFICATELOC/newcerts/$GENV_MSHOST1-cert-req.txt");
	if((-e "$GENV_MSHOME1/lib/msgcert") && ("$use_msgcert" eq "1")) {
		_system("$GENV_MSHOME1/lib/msgcert request-cert -W $GENV_CERTIFICATELOC/.pwd.txt --name $certname --org \"Sun Microsystems, Inc.\" --org-unit Comms --city SCA --state CA --country US -F ascii -o $GENV_CERTIFICATELOC/newcerts/$GENV_MSHOST1-cert-req.txt");
	}else{
		_system("$CERT_TOOLS_PATH/certutil -R -s \"CN=$GENV_MSHOST1.$GENV_DOMAIN,OU=Comms,L=SCA,ST=CA,C=US\" -o $GENV_CERTIFICATELOC/newcerts/$GENV_MSHOST1-cert-req.txt -d $GENV_MSHOME1/config/ -z $GENV_CERTIFICATELOC/noise.txt -f $GENV_CERTIFICATELOC/.pwd.txt -a");
	}
	unless (-e "$GENV_CERTIFICATELOC/newcerts/$GENV_MSHOST1-cert-req.txt"){
		print "==== Server-cert-request creation failed\n";
	}

	# Checking if LOCAL_CA should be used or not
	if ($USE_LOCAL_CA) 
	{
		print "==== Getting the server-cert-request signed by local CA ====\n";
		_system ("sed \'/$GENV_MSHOST1/d\' $GENV_CERTIFICATELOC/index.txt > $GENV_CERTIFICATELOC/t; mv $GENV_CERTIFICATELOC/t $GENV_CERTIFICATELOC/index.txt");
		if(-e "$GENV_CERTIFICATELOC/newcerts/$GENV_MSHOST1-cert.pem"){
			_system ("rm $GENV_CERTIFICATELOC/newcerts/$GENV_MSHOST1-cert.pem");
		}
	        system("chmod -R 777 $GENV_CERTIFICATELOC");
		print "$OPENSSL_PATH/openssl ca -config $GENV_CERTIFICATELOC/openssl.cnf.SSLSERVER -out $GENV_CERTIFICATELOC/newcerts/$GENV_MSHOST1-cert.pem -infiles $GENV_CERTIFICATELOC/newcerts/$GENV_MSHOST1-cert-req.txt\n";
		$cmd9 = "$OPENSSL_PATH/openssl ca -config $GENV_CERTIFICATELOC/openssl.cnf.SSLSERVER -out $GENV_CERTIFICATELOC/newcerts/$GENV_MSHOST1-cert.pem -infiles $GENV_CERTIFICATELOC/newcerts/$GENV_MSHOST1-cert-req.txt";
		$exp1 = new Expect();
		$exp1->raw_pty(1);
		$exp1->debug($debug);
		$exp1->spawn($cmd9);
		$exp1->expect($timeout,'-re', ':\s$');
		$exp1->send ("$GENV_MSADMINPSWD\n");
		$exp1->expect($timeout,'-re', ':\s$');
		$exp1->send ("y\n");
		$exp1->expect($timeout,'-re', ']\s$');
		$exp1->send ("y\n");
		$exp1->expect($timeout,'-re', '#\s$');
		$exp1->hard_close();
		unless (-e "$GENV_CERTIFICATELOC/newcerts/$GENV_MSHOST1-cert.pem"){ 
			print "$GENV_MSHOST1-cert.pem file not found,copy failed\n";
		}
		unless (-e "$GENV_CERTIFICATELOC/newcerts/cacert.pem"){
			 print "cacert.pem file not found,copy failed\n";
		}
		print "==== Server-cert-request signed by local CA Successfully ====\n";
	}
	else
	{
		print "====Copying the server-cert-request to marceau, to get signed by CA\n";
 		$cmd5 = "scp $GENV_CERTIFICATELOC/newcerts/$GENV_MSHOST1-cert-req.txt root\@marceau.us.oracle.com:/space/smime/newcerts/";
		$exp = new Expect();
		$exp->raw_pty(1);
		$exp->debug($debug);
		$exp->spawn($cmd5);
#		$exp->expect($timeout,'-re', '?\s$');
#		$exp->send ("yes\n");
		$exp->expect($timeout,'-re', ':\s$');
		$exp->send ("$host_root_pwd\n");
		$exp->expect($timeout,'-re', '#\s$');
		$exp->send("quit\n");
		$exp->hard_close();
		print "====Now signing the $GENV_MSHOST1-cert-req.txt file\n";
		$cmd6="ssh -l root marceau.us.oracle.com";
		$exp1 = new Expect();
		$exp1->raw_pty(1);
		$exp1->debug($debug);
		$exp1->spawn($cmd6);
#		$exp1->expect($timeout,'-re', '?\s$');
#		$exp1->send ("yes\n");
		$exp1->expect($timeout,'-re', ':\s$');
		$exp1->send ("$host_root_pwd\n");
		$exp1->expect(10,'-re', '#\s$');
		$exp1->send ("export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:/usr/sfw/lib:.\n");
		$exp1->expect($timeout,'-re', '#\s$');
		$exp1->send ("sed \'/$GENV_MSHOST1/d\' /space/smime/index.txt > /space/smime/t; mv /space/smime/t /space/smime/index.txt\n");
		$exp1->expect($timeout,'-re', '#\s$');
		$exp1->send ("find /space/smime/newcerts |grep $GENV_MSHOST1-cert.pem |xargs rm\n");
		$exp1->expect($timeout,'-re', '#\s$');
		$exp1->send("/usr/bin/openssl ca -config /space/smime/openssl.cnf.SSL_SERVER -out /space/smime/newcerts/$GENV_MSHOST1-cert.pem -infiles /space/smime/newcerts/$GENV_MSHOST1-cert-req.txt\n");
		$exp1->expect($timeout,'-re', ':\s$');
		$exp1->send ("$GENV_MSADMINPSWD\n");
		$exp1->expect($timeout,'-re', ':\s$');
		$exp1->send ("y\n");
		$exp1->expect($timeout,'-re', ']\s$');
		$exp1->send ("y\n");
		$exp1->expect($timeout,'-re', 'ed\s$');
		$exp1->send ("exit\n");
		$exp1->hard_close();
		copy_cert("$GENV_MSHOST1-cert.pem","$host_root_pwd","newcerts");
		copy_cert("cacert.pem","$host_root_pwd","newcerts");
		unless (-e "$GENV_CERTIFICATELOC/newcerts/$GENV_MSHOST1-cert.pem")
		{ 
			print "$GENV_MSHOST1-cert.pem file not found,copy failed\n";
		}
		unless (-e "$GENV_CERTIFICATELOC/newcerts/cacert.pem") 
		{
			 print "cacert.pem file not found,copy failed\n";
		}
	}
	system("chown -R $GENV_MAILSERVERUSERID:$GENV_MAILSERVERUSERGROUP $GENV_MSHOME1/config/*");
	system("chown root:root $GENV_MSHOME1/config/restricted.cnf");
	return;
}

#
# This function removes the previously ms-cert db and create a new one and
# then ultimately delete the Self-signed certficate created by default during cert store creation
#
# Usage: setup_certdb("bakhru", "us.oracle.com", "password");
#
sub setup_certdb {
	print "==== Inside setup_certdb function\n";
	print "==== Removing previously present nss-cert db files\n";
	if (-e "$GENV_MSHOME1/config/cert9.db" || -e "$GENV_MSHOME1/config/cert8.db"){
		_system("rm -rf $GENV_MSHOME1/config/*.db");
		_system("rm -rf $GENV_MSHOME1/config/pkcs11.txt");
	}
	if (-e "$GENV_CERTIFICATELOC/$GENV_MSHOST1-cert.pem" || -e "$GENV_CERTIFICATELOC/$GENV_MSHOST1-cert-req.txt") {
		_system("rm $GENV_CERTIFICATELOC/$GENV_MSHOST1-cert*");
	}
	print "==== Stopping MS-Server before changing Server-Cert\n";
	_system("$GENV_MSHOME1/bin/stop-msg");
	unless (-e "$GENV_CERTIFICATELOC/.pwd.txt") { _system("echo $GENV_MSADMINPSWD > $GENV_CERTIFICATELOC/.pwd.txt"); }
	unless (-e "$GENV_CERTIFICATELOC/noise.txt") { _system("echo \"asdflkjadfjasdlfjlasfjlksadjflkajdflkasdjflsakjdflakdjflkadsjflsakdjflakdfjasdkjf\" > $GENV_CERTIFICATELOC/noise.txt"); }
	print "==== Generating the MS-Cert DB ====\n";
    	if(("$use_msgcert" eq "1") && (-e "$GENV_MSHOME1/lib/msgcert")){
        	_system ("$GENV_MSHOME1/lib/msgcert generate-certDB -W $GENV_CERTIFICATELOC/.pwd.txt");
		print "\n==== Removing self-signed Server-Cert\n";
		_system("$GENV_MSHOME1/lib/msgcert remove-cert -W $GENV_CERTIFICATELOC/.pwd.txt Server-Cert");
	}
	else{
		$ENV{'NSS_DEFAULT_DB_TYPE'} = 'sql';
		_system("$CERT_TOOLS_PATH/certutil -N -d $GENV_MSHOME1/config/ -f $GENV_CERTIFICATELOC/.pwd.txt");
		_system("$CERT_TOOLS_PATH/certutil -S -x -n \"Server-Cert\" -t \"u,u,u\" -v 120 -s \"CN=$GENV_MSHOST1.$GENV_DOMAIN\" -d $GENV_MSHOME1/config/ -z $GENV_CERTIFICATELOC/noise.txt -f $GENV_CERTIFICATELOC/.pwd.txt");
		#To list all certificates
		_system("$CERT_TOOLS_PATH/certutil -d $GENV_MSHOME1/config -L");
		print "\n==== Removing self-signed Server-Cert\n";
		_system("$CERT_TOOLS_PATH/certutil -D -n Server-Cert -d $GENV_MSHOME1/config/ -f $GENV_CERTIFICATELOC/.pwd.txt");
	}
	unless((-e "$GENV_MSHOME1/config/key4.db") || (-e "$GENV_MSHOME1/config/key3.db")){
		print "==== SSL CERTIFICATE CREATION FAILED ====\n";
		exit 0;
	}

	unless (-d "$GENV_CERTIFICATELOC/newcerts"){ _system("mkdir -p $GENV_CERTIFICATELOC/newcerts"); }
	unless (-d "$GENV_CERTIFICATELOC/private"){ _system("mkdir -p $GENV_CERTIFICATELOC/private"); }
	system("chmod -R 777 $GENV_CERTIFICATELOC");
	return 1;
}

#
# This function creates a local Certificate Authority in /opt/CA directory
#
# Usage: create_local_CA("bakhru", "us.oracle.com", "password");
#
sub create_local_CA
{
	_system("echo \"asdflkjadfjasdlfjlasfjlksadjflkajdflkasdjflsakjdflakdjflkadsjflsakdjflakdfjasdkjf\" > $GENV_CERTIFICATELOC/noise.txt");
	print "==== Inside create_local_CA function\n";
	if(-e "$GENV_CERTIFICATELOC/finished.CA"){
		print "==== CA already created, not created again ====\n";
		return 1;
	}
	my $timeout=4;
	print "==== Creating a local Certifying Authority ====\n";
	if(-d $GENV_CERTIFICATELOC){ _system ("rm -rf $GENV_CERTIFICATELOC/*");}
	adjust_file("openssl.cnf",".");
	adjust_file("openssl.cnf.SSLSERVER",".");
	_system("mkdir -p $GENV_CERTIFICATELOC/newcerts");
	_system("mkdir $GENV_CERTIFICATELOC/private $GENV_CERTIFICATELOC/certs $GENV_CERTIFICATELOC/crl; chmod -R 777 $GENV_CERTIFICATELOC");
	_system("touch $GENV_CERTIFICATELOC/index.txt");
	_system("echo '01' > $GENV_CERTIFICATELOC/serial");
	#Use the key to sign itself
	$cmd1 = "$OPENSSL_PATH/openssl req -new -x509 -extensions v3_ca -keyout $GENV_CERTIFICATELOC/private/cakey.pem -out $GENV_CERTIFICATELOC/newcerts/cacert.pem -days 3650 -config $GENV_CERTIFICATELOC/openssl.cnf.SSLSERVER";
	$exp = new Expect();
	$exp->raw_pty(1);
	$exp->debug($debug);
	$exp->spawn($cmd1);
	$exp->expect(5,'-re',':\s$');
	$exp->send ("$GENV_MSADMINPSWD\n");#ca password
	$exp->expect($timeout,'-re', ':\s$');
	$exp->send ("$GENV_MSADMINPSWD\n");#ca password
	$exp->expect($timeout,'-re', ':\s$');
	$exp->send ("\n");#country name
	$exp->expect($timeout,'-re', ':\s$');
	$exp->send ("\n");#state name
	$exp->expect($timeout,'-re', ':\s$');
	$exp->send ("\n");#locality name
	$exp->expect($timeout,'-re', ':\s$');
	$exp->send ("\n");#organization name
	$exp->expect($timeout,'-re', ':\s$');
	$exp->send ("\n");#organization unit name
	$exp->expect($timeout,'-re', ':\s$');
	$exp->send ("$GENV_MSHOST1.$GENV_DOMAIN\n");#common name
	$exp->expect($timeout,'-re', ':\s$');
	$exp->send ("$GENV_MSHOST1.$GENV_DOMAIN\n");#email address
	$exp->expect($timeout,'-re', '#\s$');
	$exp->hard_close();
	if (-e "$GENV_CERTIFICATELOC/newcerts/cacert.pem") {
		print "==== Displaying the created CA-Cert ====\n";
		_system("$OPENSSL_PATH/openssl x509 -noout -text -in $GENV_CERTIFICATELOC/newcerts/cacert.pem");
	} else {
		print "==== FAILURE: CA-Cert creation failed====\n";
		exit;
	}
	print "==== Exporting CA-Cert in pk12 format ====\n";
	_system("$OPENSSL_PATH/openssl pkcs12 -export -in $GENV_CERTIFICATELOC/newcerts/cacert.pem -inkey $GENV_CERTIFICATELOC/private/cakey.pem -certfile $GENV_CERTIFICATELOC/newcerts/cacert.pem -name CA-Cert -out $GENV_CERTIFICATELOC/newcerts/cacert.p12 -password \"pass:$GENV_MSADMINPSWD\" -passin \"pass:$GENV_MSADMINPSWD\"");
	if (-e "$GENV_CERTIFICATELOC/newcerts/cacert.p12") {
		print "==== Export Successful ====\n";
	}
	return 1;
}

sub create_crl() {
	print "==== Inside create_crl function\n";
	print "==== Creating the crl.pem file\n";
	print "$OPENSSL_PATH/openssl ca -config $GENV_CERTIFICATELOC/openssl.cnf.SSLSERVER -gencrl -crldays 60 -out $GENV_CERTIFICATELOC/crl/crl.pem\n";
	$cmd7="$OPENSSL_PATH/openssl ca -config $GENV_CERTIFICATELOC/openssl.cnf.SSLSERVER -gencrl -crldays 60 -out $GENV_CERTIFICATELOC/crl/crl.pem";
	$exp = new Expect();
        $exp->debug($debug);
        $exp->spawn($cmd7);
        $exp->expect($timeout,'-re',':\s$');
        $exp->send ("$GENV_MSADMINPSWD\n");
	$exp->expect($timeout,'-re', '#\s$');
	$exp->hard_close();
	print "==== Converting pem to binary der form\n";
	_system("$OPENSSL_PATH/openssl crl -outform der -in $GENV_CERTIFICATELOC/crl/crl.pem -out $GENV_CERTIFICATELOC/crl/crl.der");
	print "==== Now importing the binary crl file into ms-cert9.db\n";
	_system("$CERT_TOOLS_PATH/crlutil -I -t 1 -i $GENV_CERTIFICATELOC/crl/crl.der -d $GENV_MSHOME1/config/");
	return;
}

sub revoke_cert {
	print "==== Inside revoke_cert function\n";
	($cert_name) = @_;
	if ($USE_LOCAL_CA){
		print "==== Using LOCAL CA ==== \n";
		print "==== Revoking $cert_name certificate ====\n";
		print "$OPENSSL_PATH/openssl ca -config $GENV_CERTIFICATELOC/openssl.cnf -revoke $GENV_CERTIFICATELOC/newcerts/$cert_name-cert.pem\n";
		$cmd6="$OPENSSL_PATH/openssl ca -config $GENV_CERTIFICATELOC/openssl.cnf -revoke $GENV_CERTIFICATELOC/newcerts/$cert_name-cert.pem";
		$exp = new Expect();
       		$exp->debug($debug);
       		$exp->spawn($cmd6);
       		$exp->expect($timeout,'-re',':\s$');
       		$exp->send ("$GENV_MSADMINPSWD\n");
		$exp->expect($timeout,'-re', '#\s$');
		$exp->hard_close();
		create_crl();
	}
	else {
		print "====Using marceau CA ====\n";
		print "====Now Revoking the $cert_name certificate\n";
		$revoke_cmd="openssl ca -config /space/smime/openssl.cnf -revoke /space/smime/newcerts/$cert_name-cert.pem";
		$ssh_cmd="ssh -l root marceau.us.oracle.com";
		$exp1 = new Expect();
		$exp1->raw_pty(1);
		$exp1->debug($debug);
		$exp1->spawn($ssh_cmd);
#		$exp1->expect($timeout,'-re', '?\s$');
#		$exp1->send ("yes\n");
		$exp1->expect($timeout,'-re', ':\s$');
		$exp1->send ("$host_root_pwd\n");
		$exp1->expect(10,'-re', '#\s$');
		$exp1->send ("export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:/usr/sfw/lib:.\n");
		$exp1->expect($timeout,'-re', '#\s$');
		$exp1->send("$revoke_cmd\n");
		$exp1->expect($timeout,'-re', ':\s$');
		$exp1->send ("$GENV_MSADMINPSWD\n");
		$exp1->expect($timeout,'-re', '#\s$');
		$exp1->send ("openssl ca -config /space/smime/openssl.cnf -gencrl -crldays 60 -out /space/smime/crl/crl.pem\n");
        	$exp1->expect($timeout,'-re',':\s$');
  	  	$exp1->send ("$GENV_MSADMINPSWD\n");
		$exp1->expect($timeout,'-re', '#\s$');
		$exp1->send ("openssl crl -outform der -in /space/smime/crl/crl.pem -out /space/smime/crl/crl.der\n");
		$exp1->expect($timeout,'-re', '#\s$');
		$exp1->hard_close();
		copy_cert("crl.der",$host_pwd,"crl");
	}		
	_system("$CERT_TOOLS_PATH/crlutil -I -t 1 -i $GENV_CERTIFICATELOC/crl/crl.der -d $GENV_MSHOME1/config/");
	print "====Display the imported crl info\n";
	print "$CERT_TOOLS_PATH/crlutil -L -d $GENV_MSHOME1/config/ -n CA-Cert\n";
	_system("$CERT_TOOLS_PATH/crlutil -L -d $GENV_MSHOME1/config/ -n CA-Cert");
	return 1;
}

sub delete_user_cert_fromLDAP {
	my($user,$domain) = @_;
	print "==== Inside delete_user_cert_fromLDAP function\n";
	my $ldap = Net::LDAP->new("$GENV_DSHOST1.$GENV_DOMAIN", debug => 0);
	my $mesg = $ldap->bind("$GENV_DM", password => $GENV_DMPASSWORD, version => 3);
	$mesg = $ldap->search(base => "o=$domain,$GENV_OSIROOT", filter => "(uid=$user)");
	foreach $entry ($mesg->entries) {
                if($entry->exists("usercertificate;binary")){
                        $entry->delete("usercertificate;binary");
                	#$entry->delete("nswmExtendedUserPrefs" => [ "meSMIMEDebug=on" ]);
                        $entry->update($ldap);
                }
                if($entry->exists("usercertificate")){
                        print "==== Cert deletion FAILED ====\n";
			return 0;
                }
                #$entry->dump()if($GENV_VERYVERYNOISY);
        }
        $ldap->unbind();
	#_system("$LDAPSEARCH_PATH -D\"$BindDN\" -w $GENV_DMPASSWORD -b \"uid=$user,ou=people,o=$GENV_DOMAIN,$GENV_OSIROOT\" objectClass=* userCertificate;binary")if($GENV_VERYVERYNOISY);
        return 1;

}

sub DirectorySSLSetup {

	my $certname = "Server-Cert";
	unless("$GENV_MSHOST1" eq "$GENV_DSHOST1"){
		print "==== DS & MS should be on same host to run this subroutine ====\n";
		return 0;
	}
	if("$GENV_SSLCERTNICKNAMES" eq "1"){
		$certname = "$GENV_DSHOST1" . ".$GENV_DOMAIN";
	}
        print "\n====Executing directorySSL setup subroutine\n";
	if ("$GENV_DS1INSTANCE1" eq ""){
        	chomp($GENV_DS1INSTANCE1 = `find /var/opt/ -name dsins1`);
	}

	print "==== Stopping DS server\n";
	_system("$DSADM_PATH stop $GENV_DS1INSTANCE1");

	#list certs
	print "==== Listing existings certs in DS cert-db\n";
	($LSystemResult, $LReturnVal, $LOutputRef, $LStderrRef) = _system("$DSADM_PATH list-certs $GENV_DS1INSTANCE1");
	
	#list all supported CA-Certs
        _system("$DSADM_PATH list-certs -C $GENV_DS1INSTANCE1") if($GENV_VERYVERYNOISY);

	print "==== Removing & Importing CA-Cert \n";
	_system("$DSADM_PATH remove-cert -i -W $GENV_CERTIFICATELOC/.pwd.txt $GENV_DS1INSTANCE1 CA-Cert");
	_system("$DSADM_PATH add-cert -Ci $GENV_DS1INSTANCE1 \"CA-Cert\" $GENV_CERTIFICATELOC/newcerts/cacert.pem");

	print "==== Exporting MS \"$certname\" named Certificate ====\n";
	_system ("$CERT_TOOLS_PATH/pk12util -o $GENV_CERTIFICATELOC/newcerts/$GENV_MSHOST1-cert.p12 -n \"$certname\" -w $GENV_CERTIFICATELOC/.pwd.txt -d $GENV_MSHOME1/config/ -k $GENV_CERTIFICATELOC/.pwd.txt");

	print "==== Removing previous MS \"$certname\" named Certificate from DS-Cert-db\n";
	if("@$LOutputRef" =~ /$certname/){
		_system("$DSADM_PATH remove-cert -i -W $GENV_CERTIFICATELOC/.pwd.txt $GENV_DS1INSTANCE1 \"$certname\"");
	}elsif("@$LOutputRef" =~ /Server-Cert/){
		_system("$DSADM_PATH remove-cert -i -W $GENV_CERTIFICATELOC/.pwd.txt $GENV_DS1INSTANCE1 \"Server-Cert\"");
	}

	print "==== Importing new MS \"$certname\" named Certificate into DS-Cert-db\n";
	_system("$DSADM_PATH import-cert -i -W $GENV_CERTIFICATELOC/.pwd.txt -I $GENV_CERTIFICATELOC/.pwd.txt $GENV_DS1INSTANCE1 $GENV_CERTIFICATELOC/newcerts/$GENV_MSHOST1-cert.p12");

	_system("$DSADM_PATH start $GENV_DS1INSTANCE1");

	($LSystemResult, $LReturnVal, $LOutputRef, $LStderrRef) = _system("$DSCONF_PATH get-server-prop -i -w $GENV_CERTIFICATELOC/.pwd.txt ssl-rsa-cert-name");
	unless("@$LOutputRef" =~ /$certname/i)
	{
		print "==== Now setting default DS certificate as $certname ====\n";
		_system("$DSCONF_PATH set-server-prop -v -e -i -w $GENV_CERTIFICATELOC/.pwd.txt ssl-rsa-cert-name:$certname");

		print "==== Default DS certificate after change is: \n";
		_system("$DSCONF_PATH get-server-prop -i -w $GENV_CERTIFICATELOC/.pwd.txt ssl-rsa-cert-name");
	}

	print "==== Restarting Directory Server ====\n";
	DS_Restart();

	return 1;
}

sub adjust_file
{
	my ($mmp_config_files, $source_dir, $destination_dir) = @_;

	if(length($source_dir) == 0){
		$source_dir="$TLE_ModuleSourceDir/../certauth_setup/";
	}

	if(length($destination_dir) == 0){
		$destination_dir="$GENV_CERTIFICATELOC/";
	}

	print "==== Adjusting the Global variables in \"$destination_dir/$mmp_config_files\" file ====\n";

	copy("$source_dir/$mmp_config_files","$destination_dir");
	$mmp_file = "$destination_dir/$mmp_config_files";

	#calculating ssl cert nickname
	my $certname = "Server-Cert";
	if("$GENV_SSLCERTNICKNAMES" eq "1"){
		$certname = "$GENV_MSHOST1" . ".$GENV_DOMAIN";
	}

	if (("x$CRLHOST" == "x") || (length($CRLHOST) == 0)) {
  		$CRLHOST=$GENV_MSHOST1;
	}

	$ENCODED_MSADMINPSWD = encode_base64("$GENV_MSADMINPSWD");
        chop $ENCODED_MSADMINPSWD;

       	unless( open (FH, "$mmp_file") ) {
		print "Unable to open file $mmp_file\n";
		close(FH);
		return 0;
	}
	@FileContents = <FH>; close(FH);
        foreach $Line (@FileContents) {
		$Line =~ s/PERLLOC/$PERLLOC/;
                $Line =~ s/OPENSSLPATH/$OPENSSL_PATH/;
                $Line =~ s/GENV_DOMAIN/$GENV_DOMAIN/;
                $Line =~ s/GENV_MAILHOSTDOMAIN/$GENV_MAILHOSTDOMAIN/;
                $Line =~ s/BASHPATH/$BASHPATH/;
                $Line =~ s/GENV_VERYVERYNOISY/$GENV_VERYVERYNOISY/;
                $Line =~ s/SMTPRELAY/$GENV_MSHOST1.$GENV_DOMAIN/;
                $Line =~ s/GENV_MSADMINPSWD/$GENV_MSADMINPSWD/;
                $Line =~ s/ENCODED_MSADMINPSWD/$ENCODED_MSADMINPSWD/;
                $Line =~ s/LENV_USE_LOCAL_CA/$LENV_USE_LOCAL_CA/;
                $Line =~ s/GENV_CERTIFICATELOC/$GENV_CERTIFICATELOC/g;
                $Line =~ s/CRLHOST/$CRLHOST/;
                $Line =~ s/GENV_OSIROOT/$GENV_OSIROOT/;
                $Line =~ s/CERTNICKNAME/$GENV_SSLCERTNICKNAMES/;
                $Line =~ s/LDAPMODIFY_PATH/$LDAPMODIFY_PATH/;
                $Line =~ s/GENV_MSHOME1/$GENV_MSHOME1/;
                $Line =~ s/GENV_MSHOST1/$GENV_MSHOST1/;
                $Line =~ s/GENV_MSADMINPSWD/$GENV_MSADMINPSWD/;
                $Line =~ s/GENV_DSHOST1/$GENV_DSHOST1/;
                $Line =~ s/GENV_DSLDAPPORT1/$GENV_DSLDAPPORT1/;
                $Line =~ s/GENV_POSTMASTER/$GENV_POSTMASTER/;
                $Line =~ s/GENV_DM/$GENV_DM/;
                $Line =~ s/GENV_DMPASSWORD/$GENV_DMPASSWORD/;
		if($Line =~ /ENCODED_DMPASSWORD/){
			($SystemResult, $SystemRef, $OutputRef, $StderrRef) = _system("$JAVA_CMD -classpath ../INSTALLALL/encrypt.jar com.sun.msg.install.Encode $GENV_DMPASSWORD");
        		$ENCODED_DMPASSWORD = "@$OutputRef";
			print "==== ENCODED_DMPASSWORD = $ENCODED_DMPASSWORD" if($debug);
        		chop $ENCODED_DMPASSWORD;
                	$Line =~ s/ENCODED_DMPASSWORD/$ENCODED_DMPASSWORD/;
		}
                $Line =~ s/GENV_XMLCONFIG/$GENV_XMLCONFIG/;
                $Line =~ s/SSLCERTNAME/$certname/;
                $Line =~ s/GENV_SEPARATOR/$GENV_SEPARATOR/;
                $Line =~ s/GENV_MAILSERVERUSERID/$GENV_MAILSERVERUSERID/;
                $Line =~ s/GENV_MAILSERVERUSERGROUP/$GENV_MAILSERVERUSERGROUP/;
	}

	unless( open(OP, ">$mmp_file") ) {
		print "Unable to open file $mmp_file\n";
		close(OP);
		return 0;
	}
	print OP @FileContents;
	close(OP);
	_system("chmod -R 777 $destination_dir/*");
	return 1;
}

sub restore()
{
        if((-e "$GENV_MSHOME1/config/config.xml.ORIG") && ("$GENV_XMLCONFIG" eq "1")){
                copy("$GENV_MSHOME1/config/config.xml.ORIG","$GENV_MSHOME1/config/config.xml");
                return 1;
        }elsif((-e "$GENV_MSHOME1/config/imta.cnf.ORIG") && (("$GENV_XMLCONFIG" eq "0") || ("$GENV_XMLCONFIG" eq "2"))) {
                @ORIG_files = `find $GENV_MSHOME1/config/ |grep ORIG`;
		print "ORIG_files = @ORIG_files\n"if($debug);
                foreach $file (@ORIG_files){
			chomp($file);
			print "Current file = $file\n" if($debug);
                        ($field1, $field2) = split("\\.ORIG", $file);
			print "field1 = $field1, field2 = $field2\n" if($debug);
			print "mv $file $field1\n" if($debug);
			_system("mv $file $field1");
                }
                return 1;
        }
        return 0;
}

sub ldapsearch {

        my ($user) = @_;
        $mesg = $ldap->search ( base  => "$GENV_OSIROOT", scope => "subtree", filter  => "(uid=$user)" );
        foreach $entry ($mesg->entries) {
                $entry->dump;
        }
        $ldap->unbind();
        return 1;
}

sub AddUsers {
	my ($username, $no_of_users, $domain) = @_;
	if(length($domain) == 0){ $domain = $GENV_MAILHOSTDOMAIN; }
	if(length($no_of_users) == 0){ $no_of_users = "10"; }
	DeleteUsers($username);
        print "==== Adding $username users on ldap_server:$GENV_DSHOST1.$GENV_DOMAIN & domain:$domain ====\n";
	$ldap = Net::LDAP->new("$GENV_DSHOST1.$GENV_DOMAIN", $debug => "1");
	$mesg = $ldap->bind("$GENV_DM", password => "$GENV_DMPASSWORD", version => 3);

	for(my $i=1; $i<=$no_of_users; $i++)
	{
		my $uid = "$username" . "$i";
		#print "uid = $uid\n";
		my $entry = Net::LDAP::Entry->new;
		$entry->dn("uid=$uid, ou=People, o=$domain, $GENV_OSIROOT");
		$entry->changetype("add");
		$entry->add( 'objectclass' => ['top', 'person','inetUser','ipUser','inetMailUser',
                                'inetLocalMailRecipient', 'icscalendaruser', 'icscalendardomain',
                                'iplanet-am-auth-configuration-service','organizationalPerson', 'inetOrgPerson'],
                         	'cn'   => "$uid $uid",
                         	'sn'   => "$uid",
                         	'mail' => "$uid\@$domain",
                		'mailuserstatus' => 'active',
				'mailquota' => '-1',
				'mailhost' => "$GENV_MSHOST1.$GENV_DOMAIN",
				'initials' => "$uid",
				'givenname' => "$uid",
				'uid' => "$uid",
				'mailmsgquota' => '-1',
				'maildeliveryoption' => 'mailbox',
				'preferredlanguage' => 'en',
				'nswmextendeduserprefs' => 'meDraftFolder=Drafts',
				'nswmextendeduserprefs' => 'meSentFolder=Sent',
				'nswmextendeduserprefs' => 'meTrashFolder=Trash',
				'nswmextendeduserprefs' => 'meInitialized=true',
				'mailAllowedServiceAccess' => '+imap,pop,http,smtp,imaps,smtps,pops,https:*',
				'inetuserstatus' => 'active',
				'userpassword' => "$uid",
				#calendar related entries
				'icsStatus' => 'active',
				'icsExtendedUserPrefs' => 'ceEnableInviteNotify=true',
				'icsExtendedUserPrefs' => 'ceNotifySMSAddress=sms://',
				'icsExtendedUserPrefs' => 'ceEnableNotifySMS=false',
				'icsExtendedUserPrefs' => 'ceDefaultAlarmStart=-PT5M',
				'icsExtendedUserPrefs' => "ceNotifyEmail=$uid\@$domain",
				'icsExtendedUserPrefs' => 'ceNotifyEnable=1',
				'icsExtendedUserPrefs' => "ceDefaultAlarmEmail=$uid\@$domain",
				'icsExtendedUserPrefs' => 'ceEnableNotifyPopup=false'
			);
                #$entry->dump()if($GENV_VERYVERYNOISY);
		$entry->update($ldap);
		my $dn = $entry->dn();
		print "Adding user $dn\n";
		#$result->code && warn "failed to add entry $uid: ", $result->error;
	}#for loop ends
        $ldap->unbind();
	return 1;
}

sub DeleteUsers {
        my ($uid) = @_;
        print "==== Deleting the existing $uid* users from ldap ====\n";
        my $ldap = Net::LDAP->new( "$GENV_DSHOST1.$GENV_DOMAIN", debug => 0, version => 3 ) or die "$@";
        my $mesg = $ldap->bind ( "$GENV_DM", password => $GENV_DMPASSWORD, version => 3 ) or die "$@";
        my $mesg = $ldap->search ( base  => "o=$GENV_MAILHOSTDOMAIN,$GENV_OSIROOT", filter  => "uid=$uid*");
        foreach $entry ($mesg->entries) {
		$ldap->delete($entry);
		my $dn = $entry->dn();
		print "Deleting user $dn\n";
	}
        $mesg = $ldap->unbind;
        return;
}

sub genkey
{ 
	my ($keylen) = @_;

	chomp($dir=`grep $GENV_MAILSERVERUSERID /etc/passwd`);
	my @b=split(":",$dir);
	$home_dir=$b[5];
	my $error256 = 0;
	my $error128 = 0;

	print "==== Generating keys for STORE Encryption ====\n";
        print "==== mailuid = $GENV_MAILSERVERUSERID , mailgroup = $GENV_MAILSERVERUSERGROUP and home_dir = $home_dir ====\n";
	print "==== Running following pktool command ====\n";
	if(-d "$home_dir/.sunw"){
        	system("rm -rf $home_dir/.sunw/");
	}
        $exp = new Expect();
        $exp->raw_pty(1);
        $exp->log_file("/tmp/genkey_log_$keylen", "w");
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
        print "pktool genkey label=msgstore keytype=aes keylen=$keylen\n";
        $exp->send("pktool genkey label=msgstore keytype=aes keylen=$keylen\n");
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
	if(-e "/tmp/genkey_log_256"){
		$error256 = `grep KMF_ERR_KEYGEN_FAILED /tmp/genkey_log_256`;
		unlink("/tmp/genkey_log_256");
	}
	if(-e "/tmp/genkey_log_128"){
		$error128 = `grep KMF_ERR_KEYGEN_FAILED /tmp/genkey_log_128`;
		unlink("/tmp/genkey_log_128");
	}
	if($error256){
		print "==== 256bit KEYGEN FAILED ====\n";
		print "==== USING 128bit KEYGEN NOW ====\n";
		genkey("128");
	}
	elsif($error128){
		print "==== 128bit KEYGEN FAILED ====\n";
		print "==== PLEASE UPGRADE YOUR SOLARIS SYTEM TO LATEST PATCH ====\n";
		return 0;
	}else {
		print "==== $keylen bit KEYGEN PASSED ====\n";
	}
	return 1;
}

sub enable_encrypt()
{
        #uncomment the below variable to install the latest solaris patch on your machine
        my $update_solaris=0;
	my $osmachine=`uname -m`;
	my $plat=`uname -s`;
        chomp $osmachine;
        chomp $plat;
	if ( "$plat" eq "Linux" ) {
		print "==== Linux not supported  ====\n";
		print "==== STORE Encryption initialization FAILED ====\n";
		return 0;
	}

	#determining sparc or x86 patch number
	if ( "$osmachine" eq "i86pc" ) {
          $patchnumber="142910-17";
	} else {
          $patchnumber="142909-17";
	}

        $grepres=`showrev -p | grep $patchnumber`;
	print "grepres = $grepres\n" if($debug);

        if ( $grepres ) {
                print "==== $patchnumber has been applied ====\n";
        } else {
                print "==== $patchnumber has NOT been applied\n";
                print "==== Need Solaris Latest update\n";
                $update_solaris=1;
		# need to bail here, solaris update in a script?
		print "==== STORE Encryption initialization FAILED ====\n";
		return 0;
        }
        unless(genkey("$GENV_STOREENCRYPTKEYLEN")) {
		print "==== $GENV_STOREENCRYPTKEYLEN bit KEYGEN FAILED ====\n";
		return 0;
	}

	print "==== Enabling STORE Encryption ====\n";
	if(("$GENV_XMLCONFIG" eq "0") || ("$GENV_XMLCONFIG" eq "2")){
        	unless( _system("$GENV_MSHOME1/bin/configutil -o store.encryptnew -v yes") &&
        		_system("$GENV_MSHOME1/bin/configutil -o store.keypass -v iplanet") &&
        		_system("$GENV_MSHOME1/bin/configutil -o store.checkpoint.debug -v 1")) {
			return 0;
		}
	}elsif("$GENV_XMLCONFIG" eq "1"){
		system("echo \"set_option\(\\\"store.keypass\\\"\, \\\"iplanet\\\"\)\;\" > $TLE_ModuleDirectory/t.rcp");
        	unless( _system("$GENV_MSHOME1/bin/msconfig set store.encryptnew 1") &&
        		_system("$GENV_MSHOME1/bin/msconfig set -restricted store.checkpoint.debug 1") &&
			_system("$GENV_MSHOME1/bin/msconfig run $TLE_ModuleDirectory/t.rcp") &&
			_system("$GENV_MSHOME1/bin/msconfig show store")) {
			return 0;
		}
	}
	print "==== Enabled STORE Encryption ====\n";
        return 1;
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

#($SystemResult, $ReturnVal, $OutputRef, $StderrRef) = _system("/opt/sun/comms/messaging64/bin/start-msg store");
#print "SystemResult = $SystemResult\n";
#print "Retval = $ReturnVal\n";
#print "Output = @{$OutputRef}\n";
#print "Error = @{$StderrRef}\n";

sub import_GENV()
{
	print "==== Inside import_GENV() ====\n";
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

return 1;
