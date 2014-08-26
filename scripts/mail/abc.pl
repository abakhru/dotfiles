#!/usr/bin/perl

sub _system
{
        use IPC::Open3;
        my (@cmd) = @_;
        print "Running: \"@cmd\"\n";
        my $pid = open3(\*WRITER, \*READER, \*ERROR, @cmd);
        #if \*ERROR is 0, stderr goes to stdout
        my @output, @error;
        while( my $output = <READER> ) {
                print "OUTPUT -> $output";
                push(@OutputContents,$output);
        }
        while( my $errout = <ERROR> ) {
                print "ERROR -> $errout";
                push(@ErrorContents,$errout);
        }
        waitpid( $pid, 0 ) or die "$!\n";
        $retval = $?;
        $SysResult = $? >> 8;
        if( $SysResult == 0 ) {
                $SysResult = 1;
        } else {
                print "\"@cmd\" command FAILED: return code $SysResult\n";
                $SysResult = 0;
        }
        return ($SysResult, $retval, \@OutputContents, \@ErrorContents);
}

_system("/opt/sun/comms/messaging64/sbin/mboxutil -c \"user/quotauser3\@quotaByFolder.com/folder1\"");
_system("/opt/sun/comms/messaging64/sbin/readership -s \"user/quotauser3\@quotaByFolder.com/folder1\" anyone lrwscidpa");
#_system("perl /export/amit/msg_next/msg/test/tle/mailBoxPurge/smail.pl sc11e0405.us.oracle.com quotauser0 quotauser3+folder1\@quotaByFolder.com 5 f:/export/amit/msg_next/msg/test/tle/quotaByFolder/395KB_file");
