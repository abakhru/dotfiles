#!/usr/bin/perl
#$FILE=$ARGV[0];
chomp($FILE=`find /space/src/results/|grep detaillog|grep -v SUPPORT|xargs ls -rt|tail -1`);
#print "$FILE\n"; 
for(my $i=0;$i<=100;$i++)
{ 
	if (-e "$FILE"){
#		print "less +F $FILE\n";
		system("less +F $FILE");
		last;
	}
	else {
#		print "$i\n";
		next;
	}
}
