##!/usr/bin/perl
#
#if (@ARGV < 2)
# {
#  print ("\nUsage: $0 <PATTERN> <directory_to_search>\n\n");
#  exit;
#}

#my $pattern = $ARGV[0];
#my $directory = $ARGV[1];

#opendir DIR, $directory or die "Error reading $directory: $!\n";
#my @sorted = sort {-s "$directory/$a" <=> -s "$directory/$b"} readdir(DIR);
#closedir DIR;
#
#print "Largest file in $directory is $sorted[-1]\n";
#
#foreach $i (@sorted) {
#    if ($i =~ /tcp_local_slave/) {
#	$search_file="$directory/$i";
#	print "Searching for pattern: \"$pattern\" in file: \"$search_file\"\n";
#	unless (open(INFO, "<$search_file")) {
#            print "-e", "Can not read input file $search_file";
#            print "Cannot read input file $search_file";
#            return 0;
#        }
#        @InputText = <INFO>;
#        close(INFO);
#
#        foreach $line (@InputText) {
#                #print "Searching for pattern: $pattern in the following line:";
#                #print "$line";
#            if ($line =~ /$pattern/) {
#                print "==========PATTERN MATCH FOUND - PASS\n\n";
#		last;
#               return 1;
#            }
#        }
#    }
#}



#!/usr/bin/perl
eval 'exec /usr/bin/perl -S $0 ${1+"$@"}' if 0; #$running_under_some_shell

use strict;
use File::Find ();

if (@ARGV < 2)
 {
  print ("\nUsage: $0 <PATTERN> <directory_to_search>\n\n");
  exit;
}

my $pattern = $ARGV[0];
my $directory = $ARGV[1];

# for the convenience of &wanted calls, including -eval statements:
use vars qw/*name *dir *prune/;
*name   = *File::Find::name;
*dir    = *File::Find::dir;
*prune  = *File::Find::prune;

sub wanted;

# Traverse desired filesystems
File::Find::find({wanted => \&wanted}, "$directory");
exit;

sub wanted {
    /^$pattern\z/s &&
    print("$name\n");
}

