#!/usr/bin/perl
use Expect;
use MIME::Base64;

#Global Variables
$debug=0;
$GENV_MSHOME="/opt/sun/comms/messaging64";
$CERT_LOC="/export/nightly/tmp/certs";
$pwd="netscape";
$USE_LOCAL_CA=1;
$timeout=5;
$OPENSSL_PATH="/usr/local/ssl/bin/openssl";
unless(-f "$OPENSSL_PATH"){
	$OPENSSL_PATH = `which openssl`;
}

unless(-d "$CERT_LOC"){
	print "\"$CERT_LOC\" directory doesn't exists\n";
	print "Please set the certificate dir location\n";
	exit 0;
}

if (@ARGV < 4)
{
  print ("\nUsage: ./s_client.pl user host domain receiver port\n\n");
  exit 0;
}

$check_ms_status = `netstat -na|grep 143|grep LISTEN`;
if ( $check_ms_status eq "" ) {
          print "MS Server is not running\n";
          print "$GENV_MSHOME/sbin/start-msg\n";
          system ("$GENV_MSHOME/sbin/start-msg");
}

$user=$ARGV[0];
$host=$ARGV[1];
$domain=$ARGV[2];
$receiver=$ARGV[3];
$port=$ARGV[4];
$sasl=encode_base64("$user");


#IMAPS
if ($port == 993 || $port == 1993){
	$imap_cmd = "$OPENSSL_PATH s_client -host $host -port $port -verify -msg -state -cert $CERT_LOC/newcerts/$user-cert.pem -CAfile $CERT_LOC/newcerts/cacert.pem -key $CERT_LOC/private/$user-key.pem";
	imap($imap_cmd);
}
#IMAP+STARTLS
elsif ($port == 143 || $port == 1143) {
	$imap_cmd = "$OPENSSL_PATH s_client -host $host -port $port -verify -msg -state -cert $CERT_LOC/newcerts/$user-cert.pem -CAfile $CERT_LOC/newcerts/cacert.pem -key $CERT_LOC/private/$user-key.pem -starttls imap";
	if ($port == 1143) { $source="=";}
	imap_starttls($imap_cmd);
}
#SMTPS
elsif ($port == 465 || $port == 1465) {
	$smtp_cmd = "$OPENSSL_PATH s_client -host $host -port $port -verify -msg -state -crlf -cert $CERT_LOC/newcerts/$user-cert.pem -CAfile $CERT_LOC/newcerts/cacert.pem -key $CERT_LOC/private/$user-key.pem";
	smtp($smtp_cmd,$user,$receiver,$domain);
}
# SMTP+STARTLS OR SUBMIT+STARTTLS
elsif ($port == 25 || $port == 587 || $port == 125) {
	$smtp_cmd = "$OPENSSL_PATH s_client -host $host -port $port -verify -msg -state -crlf -cert $CERT_LOC/newcerts/$user-cert.pem -CAfile $CERT_LOC/newcerts/cacert.pem -key $CERT_LOC/private/$user-key.pem -starttls smtp";
	smtp($smtp_cmd,$user,$receiver,$domain);
}
#POPS
elsif ($port == 995 || $port == 1995){
	$pop_cmd = "$OPENSSL_PATH s_client -host $host -port $port -verify -msg -state -cert $CERT_LOC/newcerts/$user-cert.pem -CAfile $CERT_LOC/newcerts/cacert.pem -key $CERT_LOC/private/$user-key.pem";
	pops($pop_cmd);
#POP+STARTLS
}elsif ($port == 110 || $port == 1110) {
	$pop_cmd = "$OPENSSL_PATH s_client -host $host -port $port -verify -msg -state -cert $CERT_LOC/newcerts/$user-cert.pem -CAfile $CERT_LOC/newcerts/cacert.pem -key $CERT_LOC/private/$user-key.pem -starttls pop3";
	pops($pop_cmd);
}elsif ($port == 81) {
	https();
}

sub imap {
	($cmd) = @_;
        print "==== Inside imap function\n";
        print "==== IMAP session after client-cert AUTH EXTERNAL\n";
	print "$cmd\n";
	$exp = new Expect();
        $exp->debug($debug);
        $exp->spawn($cmd);
        $exp->expect($timeout,'-re', ':\s$');
        $exp->send("a001 SELECT INBOX\n");
        $exp->expect($timeout,'-re', 'ed\s$');
        $exp->send("a002 FETCH 1 RFC822\n");
        $exp->expect($timeout,'-re', 'ed\s$');
        $exp->send("a003 CAPABILITY\n");
        $exp->expect($timeout,'-re', 'ed\s$');
        $exp->send("a004 LOGOUT\n");
        $exp->expect($timeout,'-re', 'ed\s$');
        $exp->send("quit\n");
        $exp->hard_close();
	return;
}

sub smtp {
        ($cmd,$sender,$receiver,$domain) = @_;
        print "==== Inside smtp function\n";
        print "====  SMTP session after client-cert AUTH EXTERNAL\n";
	print "$cmd\n";
        $exp = new Expect();
        $exp->debug($debug);
        $exp->spawn($cmd);
        $exp->expect(10,'-re','\)\).\n$');
        $exp->send("ehlo $domain\n");
        $exp->expect($timeout,'-re','^250.*\n');
        $exp->send("AUTH EXTERNAL =\n");
        $exp->expect($timeout,'-re','ul.\s$');
        $exp->send("mail from: $sender\@$domain\n");
        $exp->expect($timeout,'-re','Ok.\s$');
        $exp->send("rcpt to: $receiver\@$domain\n");
        $exp->expect($timeout,'-re','OK.\s$');
        $exp->send("DATA\n");
        $exp->expect($timeout,'-re','^354.*\s');
        $exp->send(".\n");
        $exp->expect($timeout,'-re','^250.*\n');
        $exp->send("quit\n");
        $exp->expect($timeout,'-re','^221.*\n');
        $exp->hard_close();
        return;
}

sub imap_starttls {
	($cmd) = @_;
        print "==== Inside imap_starttls function\n";
        print "==== IMAP session after client-cert AUTH EXTERNAL\n";
	print "$cmd\n";
	$exp = new Expect();
        $exp->debug($debug);
        $exp->spawn($cmd);
        $exp->expect($timeout,'-re', ':\s$');
        $exp->send("a003 CAPABILITY\n");
        $exp->expect($timeout,'-re', 'ed\s$');
        #$exp->send("a000 AUTHENTICATE GSSAPI\n");
        #$exp->expect($timeout,'-re', 'le\s$');
        #$exp->send("a000 AUTHENTICATE KERBEROS_V4\n");
        #$exp->expect($timeout,'-re', 'le\s$');
        #$exp->send("a000 AUTHENTICATE SKEY\n");
        #$exp->expect($timeout,'-re', 'le\s$');
        $exp->send("a000 AUTHENTICATE EXTERNAL =\n");
        #$exp->send("a000 AUTHENTICATE EXTERNAL YW1pdDE==\n");
        #$exp->send("a000 AUTHENTICATE EXTERNAL $sasl\n");
        $exp->expect($timeout,'-re', 'ed\s$');
        $exp->send("a001 SELECT INBOX\n");
        $exp->expect($timeout,'-re', 'ed\s$');
        $exp->send("a002 FETCH 1 RFC822\n");
        $exp->expect($timeout,'-re', 'ed\s$');
        $exp->send("a003 CAPABILITY\n");
        $exp->expect($timeout,'-re', 'ed\s$');
        $exp->send("a004 LOGOUT\n");
        $exp->expect($timeout,'-re', 'ed\s$');
        $exp->send("quit\n");
        $exp->hard_close();
	return;
}

sub pops {
	($cmd) = @_;
        print "==== Inside pops function\n";
        print "==== POPS session after client-cert AUTH EXTERNAL\n";
	print "$cmd\n";
	$exp = new Expect();
        $exp->debug($debug);
        $exp->spawn($cmd);
        $exp->expect($timeout,'-re', '>\s$');
        $exp->send("LIST\n");
        $exp->expect($timeout,'-re', '.\s$');
        $exp->send("RETR 1\n");
        $exp->expect($timeout,'-re', '.\s$');
        $exp->send("CAPA\n");
        $exp->expect($timeout,'-re', '.\s$');
        $exp->send("QUIT\n");
        $exp->expect($timeout,'-re', '.\s$');
        $exp->send("quit\n");
        $exp->hard_close();
	return;
}


sub https () {
	$cmd1="$OPENSSL_PATH s_client -connect $host.$domain:$port -verify -msg -state -cert $CERT_LOC/newcerts/$user-cert.pem -CAfile $CERT_LOC/newcerts/cacert.pem -key $CERT_LOC/private/$user-key.pem";
        print "==== Inside https function\n";
        print "==== HTTPS session after client-cert AUTH EXTERNAL\n";
	print "$cmd1\n";
	$exp = new Expect();
        $exp->debug($debug);
        $exp->spawn($cmd1);
        $exp->expect(20,'-re', ':\s$');
        $exp->send("/opt/csw/bin/curl --sslv3 --cert $CERT_LOC/$user-cert.pem --cacert $CERT_LOC/newcerts/cacert.pem -c /tmp/cookies.txt https://$host.$domain:$port/iwc/svc/wabp/login.wabp\n");
        $exp->expect(20,'-re', ':\s$');
	sleep(10);
        $exp->hard_close();
	return;
}
