#!/usr/bin/perl
use Expect;
use Net::Domain qw(hostname hostfqdn hostdomain domainname);

$debug=1;
$timeout=3;
$USERS=$ARGV[0];
if(@ARGV < 1)
{
	print "Usage:  $0 num-users-to-run-stress-with <num-of-iterations>\n";
	exit(0);
}
print "Num users specified: $USERS\n";
$numiterations=$ARGV[1];
#print "Num iterations specified: $numiterations\n";
if ( $numiterations == "" ) { $numiterations = 1 };
$iterations=($USERS*$numiterations);
print "Total iterations : $iterations\n";
$GENV_MSHOST1=hostname();
#$GENV_DOMAIN=domainname();
$GENV_DOMAIN="us.oracle.com";
print "===GENV_MSHOST1 = $GENV_MSHOST1; GENV_DOMAIN = $GENV_DOMAIN ====\n" if($debug);

sub start_remote
{
	my ($client, $first_user, $last_user) = @_;
	if($client =~ /bakhru/){
		$host_user = "root";
	}else { 
		$host_user = "uadmin";
	}

	if("$client" =~ /$GENV_MSHOST1/){
		$cmd="nohup ./no_of_connections.pl $iterations";
		$cmd5="scp no_of_connections.pl $host_user\@$client:/tmp/\n";
	}else {
		$cmd="nohup ./mini_autostress.pl $first_user $last_user $numiterations";
		$cmd5="scp mini_autostress.pl $host_user\@$client:/tmp/\n";
	}
	chomp($a=`grep $client /.ssh/known_hosts`);
	print "==== Copying the relevant files to remote host $client ====\n";
	$exp2 = new Expect();
        $exp2->raw_pty(1);
        $exp2->debug(0);
        $exp2->spawn($cmd5);
        if($a eq ""){
                $exp1->expect($timeout,'-re', '\?\s$');
                $exp1->send ("yes\n");
        }
        $exp2->expect($timeout,'-re', ':\s$');
        $exp2->send ("iplanet\n");
       	$exp2->expect($timeout,'-re', '#\s$');
       	$exp2->hard_close();

	print "==== Now starting remote client/server processes on $client ====\n";
       	$cmd6="ssh -l $host_user $client\n";
       	$exp1 = new Expect();
       	$exp1->raw_pty(1);
       	$exp1->debug(0);
       	$exp1->spawn($cmd6);
        if($a eq ""){
                $exp1->expect($timeout,'-re', '\?\s$');
                $exp1->send ("yes\n");
        }
	unless("$client" eq "$GENV_MSHOST1.$GENV_DOMAIN"){
       		$exp1->expect($timeout,'-re', ':\s$');
       		$exp1->send ("iplanet\n");
	}
       	$exp1->expect($timeout,'-re', '#\s$');
       	$exp1->send ("cd /tmp\n");
       	$exp1->expect($timeout,'-re', '#\s$');
       	$exp1->send (">nohup.out\n");
       	$exp1->expect($timeout,'-re', '#\s$');
       	$exp1->send ("\n echo \"==== launching command : $cmd ====\n\"\n");
       	$exp1->expect($timeout,'-re', '#\s$');
       	$exp1->send("$cmd &\n");
       	$exp1->expect(5,'-re', '#\s$');
       	$exp1->send("exit\n");
       	$exp1->hard_close();
	return 1;
}

#system("./run.pl adduser neo $USERS");
#system("./clean_store.pl");
#for(my $i=1;$i<=$USERS;$i++){
#        system("./sasl_sendmail.sh $GENV_MSHOST1.$GENV_DOMAIN neo1 neo$i $numiterations");
#}
start_remote("$GENV_MSHOST1.$GENV_DOMAIN", $first_user, $last_user);
@stress_clients=("algy.us.oracle.com","dianthos.us.oracle.com","bakhru.us.oracle.com");
if ($USERS % scalar(@stress_clients) == 0){
	$no_of_users_for_each_client = ($USERS/(scalar(@stress_clients)));
}
$first_user=1;
$last_user=$no_of_users_for_each_client;
for (my $i=0; $i<scalar(@stress_clients); $i++) {
	print "==== client = $stress_clients[$i] ==== \n";
	print "==== first_user = $first_user ==== \n";
	print "==== last_user = $last_user ==== \n";
	start_remote($stress_clients[$i], $first_user, $last_user);
	$first_user=($last_user+1);
	$last_user=($last_user+$no_of_users_for_each_client);
}
