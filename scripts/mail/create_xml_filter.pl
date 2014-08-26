#!/usr/bin/perl

sub create_xml_filter{

        my ($path, $mmp_file) = @_;

        unless( open (FH, "$path/$mmp_file") ) {
                print "Unable to open file $path/$mmp_file\n";
                close(FH);
                return 0;
        }
        @FileContents = <FH>; close(FH);

        foreach $Line (@FileContents) {
		if($Line =~ /\\/){
			$Line =~ s/\\/\\\\\\/;
		}
                $Line =~ s/"/\\"/g;
        }

        unless( open(OP, ">$TLE_ModuleDirectory/$mmp_file.rcp") ) {
                print "Unable to open file $mmp_file.rcp\n";
                close(OP);
                return 0;
        }
        print OP "filter1 = \"";
        print OP @FileContents;
        print OP "\"\;\n";
        print OP "set_option\(\"systemfilter\"\,filter1\)\;";
        close(OP);

        system("chmod -R 777 $TLE_ModuleDirectory/$mmp_file.rcp");
        system("more $TLE_ModuleDirectory/$mmp_file.rcp");
        return 1;
}

create_xml_filter("/export/amit/msg75/msg/test/tle/mta_option","imta.filter");
