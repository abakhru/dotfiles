#!/usr/bin/perl
$orig_file = "./t";
$temp_file = "./temp";
unless( open (FH, "$orig_file") ) {
	print "Unable to open file $orig_file \n";
	close(FH);
	return 0;
}
@FileContents = <FH>; close(FH);

$Line=$FileContents[0];
foreach $Line (@FileContents) {
	print "$Line";
	my @values = split(/\|/, $Line);
	print "values[2] = $values[2]\n";
	$Line =~ s/$values[2]/[$values[2]|http:\/\/monaco.sfbay.sun.com\/detail.jsf?cr=$values[2]]/;
}

unless( open(OP, ">$temp_file") ) {
	print "Unable to open file $temp_file\n";
	close(OP);
	return 0;
}
print OP @FileContents;
close(OP);



##
# http://hestia.sfbay.sun.com/cgi-bin/expert?format=HTML;Go=2;cmds=set+Cutoff+%3D+2010-12-02%4023%3A05%0A%0Aset+Patchrev+%3D+21%0A%0Atitle+MS+7u4+Bugs+Fixed+Since+%24{Cutoff}+%28Build+date+of+patch+137204-%24{Patchrev}%29%0A%0Acolumn+p+format+a3+heading+PRI+justify+center%0A%0AdateFormat+MM-DD-YYYY%0A%0Ado+util%2Fabbrevs%0A%0Aset+What+%3D%
# Code :
#set Cutoff = 2010-12-02@23:05
#
#set Patchrev = 21
#
#title MS 7u4 Bugs Fixed Since ${Cutoff} (Build date of patch 137204-${Patchrev})
#
#column p format a3 heading PRI justify center
#
#dateFormat MM-DD-YYYY
#
#do util/abbrevs
#
#set What =
#  ${ID_} as main_cr, ${Priority}, cr.sub_category,
#  cr.responsible_engineer as resp_engr, synopsis, cr.sub_status
#
#break on category on sub_category on main_cr
#
#set Which =
#  fixdelivereddt >= TO_DATE('${Cutoff}','YYYY-MM-DD@HH24:MI') and 
#  cr.status = '10-Fix Delivered' and
#  product = 'iplanet_messaging_server' and
#  (cr.responsible_engineer = 'harendra.rawat@oracle.com' or cr.release LIKE '7.0p21') and 
#  (cr.release LIKE '7.0p21')
#
#set Etc =
#  order by category, sub_category, ${ID_}
#
#doMeta genQuery cr pipe esc+
