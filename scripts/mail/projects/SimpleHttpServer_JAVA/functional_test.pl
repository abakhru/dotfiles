#!/usr/bin/perl
use LWP::UserAgent;

#hashmap of url context with expected output
%testcases = ("response", "This is the response",
		"null", "404 Not Found", 
		"cpu_usage", "java",
		"amit", "404 Not Found");

$ua = LWP::UserAgent->new;
$host = "localhost:8845";
$ua->agent("MyApp/0.1 ");
$pass=0;
$fail=0;

while (($key, $value) = each(%testcases)){
	$url = HTTP::Request->new(GET => "http://$host/$key");
	$url->content_type('application/x-www-form-urlencoded');
	$url->content('query=libwww-perl&mode=dist');

	my $res = $ua->request($url);
	my $uri = $res->base;
	print "HTTP REQUEST: $uri \n\n";
	my $response = $res->as_string;
	print "HTTP REPONSE: $response \n\n";
	if ($j == 1) {
		my $ct = $res->header('Location');
	}
	sleep 1;
	#checking if expected output matches the actual output
	if($response =~ /$value/){
		print "==== Testcase for $key context PASSED\n";
		$pass++;
	}else{
		print "==== Testcase for $key context FAILED\n";
		$fail++;
	}
}

print "==== Total Testcases PASSED = $pass\n";
print "==== Total Testcases FAILED = $fail\n";
