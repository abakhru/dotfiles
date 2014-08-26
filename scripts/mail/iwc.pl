#!/usr/bin/perl
use LWP::UserAgent;

#$__uid = $ARGV[0];
$__uid = "caltest4";
$__sid = "";
$__token = "";

$ua = LWP::UserAgent->new;
$host = "lickitung.us.oracle.com:8080";
$ua->agent("MyApp/0.1 ");

for (my $j=1; $j < 3; $j++) {
	print "SID = $__sid \n";
	print "TOKEN = $__token \n";
	if ( $j == 1 ) {
	    $url = HTTP::Request->new(POST => "http://$host/iwc/svc/iwcp/login.iwc?username=$__uid&password=$__uid");
	}
	elsif ( $j == 2 ) {
	    #$url = HTTP::Request->new(GET => "http://$host/iwc/svc/wmap/mbox.msc?sid=$__sid&mbox=INBOX&start=0&count=20&date=true&sortorder=R&sortby=recv&headerv=Content-type&lang=en&security=false");
	    #$url = HTTP::Request->new(GET => "http://$host/iwc/svc/wmap/mbox.msc?sid=$__sid&rev=3&token=$__token&mbox=INBOX&start=0&count=20&date=true&sortorder=R&sortby=recv&headerv=Content-type&lang=en&security=false");
	    #$url = HTTP::Request->new(GET => "http://$host/iwc/svc/wmap/mbox.msc?sid=$__sid&rev=3&token=$__token&mbox=INBOX");
	    #$url = HTTP::Request->new(GET => "http://$host/iwc/svc/wmap/mbox.msc?sid=$__token&rev=3&token=$__token&mbox=INBOX");
	    #$url = HTTP::Request->new(GET => "http://$host/iwc/svc/wcap/version.wcap?token=$__token&fmt-out=text/json");
	    $url = HTTP::Request->new(POST => "http://$host/iwc/svc/iwcp/logout.iwc?token=$__token");
	}
	elsif ( $j == 3 ) {
	    $url = HTTP::Request->new(POST => "http://$host/iwc/logout.iwc");
	    #$url = HTTP::Request->new(POST => "http://$host/iwc/svp/iwcp/logout.iwc?token=$__token");
	}
	$url->content_type('application/x-www-form-urlencoded');
	$url->content('query=libwww-perl&mode=dist');

	my $res = $ua->request($url);
	my $uri = $res->base;
	print "HTTP REQUEST: $uri \n\n";
	my $response = $res->as_string;
	print "HTTP REPONSE: $response \n\n";
	if ($j == 1) {
		my $ct = $res->header('Set-Cookie');
		print "==== ct = $ct\n";
		$__token = GetToken("$ct");
		$__sid = GetSid("$ct");
	}
	sleep 1;
}

sub GetToken {
#==== ct = JSESSIONID=1975aaf1cbb317b962c8d9d8e3bb; Path=/iwc, iwc-auth=lang=en:token=C21Q7fAHmF:path=/iwc; Path=/iwc_static
#SID = JSESSIONID=1975aaf1cbb317b962c8d9d8e3bb; Path=/iwc, iwc-auth=lang=en:
        my $raw= shift;
        unless ( $raw =~ /token=/ ) {
                return 0;
        }
	(@field) = split(";", $raw);
	#Path=/iwc, iwc-auth=lang=en:token=C21Q7fAHmF:path=/iwc
	(@sub_field) = split(":", $field[1]);
	#token=C21Q7fAHmF
	(@field) = split("=", $sub_field[1]);
	$token = $field[1];
	chomp($token);
        return $token;
}

sub GetSid {
#==== ct = JSESSIONID=1975aaf1cbb317b962c8d9d8e3bb; Path=/iwc, iwc-auth=lang=en:token=C21Q7fAHmF:path=/iwc; Path=/iwc_static
#SID = JSESSIONID=1975aaf1cbb317b962c8d9d8e3bb; Path=/iwc, iwc-auth=lang=en:
        my $raw= shift;
        unless ( $raw =~ /JSESSIONID=/ ) {
                return 0;
        }
        (@field) = split(";", $raw);
        #Path=/iwc, iwc-auth=lang=en:token=C21Q7fAHmF:path=/iwc
        (@sub_field) = split("=", $field[0]);
        $sid = $sub_field[1];
	chomp($sid);
        return $sid;
}
