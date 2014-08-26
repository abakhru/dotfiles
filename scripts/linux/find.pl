#!/usr/bin/perl -w
eval 'exec /usr/bin/perl -S $0 ${1+"$@"}'
if 0;
if (@ARGV < 2)
{
  print ("\nUsage: $0 [directory] [searchpattern]\n");
  exit;
}

use strict;
use File::Find ();

use vars qw/*name *dir *prune/;
*name   = *File::Find::name;
*dir    = *File::Find::dir;
*prune  = *File::Find::prune;

sub wanted;

File::Find::find({wanted => \&wanted}, "$ARGV[0]");
exit;

sub wanted {
    /^$ARGV[1]\z/s
    && print("$dir\n") && return $name;
}
