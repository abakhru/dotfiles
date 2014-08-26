#!/usr/bin/perl

use File::Find;
use File::Compare;

my $cvs = $ARGV[0];
find(sub {push @cvsfiles,"$File::Find::name$/" if (/\.pm$/)},$cvs);

my $hg = $ARGV[1];
find(sub {push @hgfiles,"$File::Find::name$/" if (/\.pm$/)},$hg);

for(my $i=0; $i<=$#hgfiles; $i++){
#for(my $i=0; $i<10; $i++){
 foreach $fileA (@cvsfiles) {
	#my $fileA = $cvsfiles[$i];
	my $fileB = $hgfiles[$i];
	chomp($fileA);
	chomp($fileB);
	my @a = split('/', $fileA);
	my @b = split('/', $fileB);
	$fA = "$a[7]" . "/" . "$a[8]";
	$fB = "$b[7]" . "/" . "$b[8]";
   if ("$fA" eq "$fB") {
	print "COMPARING: $fA\n";
	open TXT1, "$fileA" or die "$!";
	open TXT2, "$fileB" or die "$!";
	my %diff;

	$diff{$_}=1 while (<TXT2>);

	while(<TXT1>){
		print unless $diff{$_};
	}
	close TXT2;
	close TXT1;
   } #if loop ends
  } #foreach loop ends
  print "==================================\n\n";
}
