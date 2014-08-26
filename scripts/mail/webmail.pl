#!/usr/bin/perl
# Create a user agent object
use LWP::UserAgent;

$__uid = "wmap17";
$__sid = "";

$ua = LWP::UserAgent->new;
$host = "localhost:8990";
$ua->agent("MyApp/0.1 ");

for (my $j=1; $j < 4; $j++) {
	print "SID = $__sid \n";
	if ( $j == 1 ) {
	    $url = HTTP::Request->new(POST => "http://$host/login.mjs?user=$__uid&password=$__uid");
	}
	elsif ( $j == 2 ) {
		#proxyauth
	    #$url = HTTP::Request->new(POST => "http://$host/login.msc?user=admin&proxyauth=$__uid&password=password");
	    #$url = HTTP::Request->new(GET => "http://$host/mbox.msc?sid=$__sid&mbox=INBOX&start=0&count=1&date=true&sortorder=R&sortby=recv&headerv=Content-type&lang=en&security=false");
	    #$url = HTTP::Request->new(GET => "http://$host/listfolders.msc?rev=3&unread=1&sid=$__sid&lang=en&security=false");
	    #$url = HTTP::Request->new(GET => "http://$host/listfolders.mjs?rev=3&unread=1&sid=$__sid");
	    $url = HTTP::Request->new(GET => "http://$host/cmd.mjs?mbox=work&cmd=create&sid=$__sid");
	}
	elsif ( $j == 3 ) {
	    #$url = HTTP::Request->new(POST => "http://$host/cmd.msc?sid=$__sid&security=false&mbox=&cmd=logout");
	    $url = HTTP::Request->new(POST => "http://$host/msg.mjs?sid=$__sid&subject=subject&from=wmap7\@us.oracle.com&to=wmap7&cc=&bcc=&text=body&html=&mbox=INBOX&uid=1&parts=0,1&attachments=&copy=work&smtp=true&draft=&priority=1&xpriority=3&receipt=&remove=false&replyto=&tzoffset=8&security=false&vcard=");
	}
	$url->content_type('application/x-www-form-urlencoded');
	$url->content('query=libwww-perl&mode=dist');

	my $res = $ua->request($url);
	my $uri = $res->base;
	print "HTTP REQUEST: $uri \n\n";
	my $response = $res->as_string;
	print "HTTP REPONSE: $response \n\n";
	if ($j == 1) {
		my $ct = $res->header('Location');
		$__sid = GetSid("$ct");
	}
	sleep 2;
}

sub GetSid {
        my $raw= shift;
        unless ( $raw =~ /sid=/ ) {
                return 0;
        }
        $raw = $';
        $raw =~ /&/;
        return $`;
}
