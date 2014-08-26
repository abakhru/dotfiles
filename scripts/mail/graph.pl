#!/usr/bin/perl
use GIFgraph::lines;

open(SARU, "/usr/sbin/sar -u|");
@saru = <SARU>;
close(SARU);
$my_graph = new GIFgraph::lines(800,600);
$my_graph->set( 
 x_label => 'Time',
 y1_label => 'Percentage',
 y2_label => 'Percentage',
 title => 'CPU Usage By Server - host',
 y1_max_value => 100,
 y2_max_value => 100,
 y_min_value => 0,
 y_tick_number => 5,
 long_ticks => 1,
 x_ticks => 0,
 legend_marker_width => 24,
 line_width => 10,
 bar_spacing => 0,
 gifx => 800,
 gify => 600,
 transparent => 1,
 dclrs => [ qw( red green ) ],
);
$my_graph->set_legend( qw( CPU_Utilization ) );
$a = $b = 0;
foreach $line (@saru) {
 next if ( ($line !~ /:/) || ($line =~ /\//));
 @line=split(" ", $line);
 if ( ( $a % 12 ) != 0 ) {
  $pandata0[$a] = undef;
 } else {
  $line[0] =~ s/:00$//;
  $pandata0[$a] = $line[0];
 }
 $pandata1[$b] = 100-$line[4];
 $a++;
 $b++;
}
if ( ! $c ) {
 @pandata0[0] = `date "+%H:%M"`;
 @pandata1[1] = 0;
}
@data = (\@pandata0, \@pandata1);
$my_graph->plot_to_gif( "/my/stats/directory/saru.gif", \@data );
