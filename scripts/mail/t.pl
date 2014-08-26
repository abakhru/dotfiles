#!/usr/bin/perl

@messages = qw(mail1 mail2 mail3 mail4);

@threadMessages = qw(thread/mail1 thread/mail2 thread/mail3 thread/mail4 thread/mail5 thread/mail6 thread/mail7 thread/mail8 thread/mail9 thread/mail10 thread/mail11 thread/mail12 thread/mail13 thread/mail14 thread/mail15 thread/mail16 thread/mail17 thread/mail18 thread/mail19 thread/mail20 thread/mail21 thread/mail22 thread/mail23 thread/mail24 thread/mail25);

@threadNoSubjMessages = qw(threadNoSubj/1.msg threadNoSubj/2.msg threadNoSubj/3.msg threadNoSubj/4.msg threadNoSubj/5.msg threadNoSubj/6.msg threadNoSubj/7.msg threadNoSubj/8.msg threadNoSubj/9.msg threadNoSubj/10.msg threadNoSubj/11.msg threadNoSubj/12.msg threadNoSubj/13.msg threadNoSubj/14.msg threadNoSubj/15.msg threadNoSubj/16.msg threadNoSubj/17.msg threadNoSubj/18.msg threadNoSubj/19.msg threadNoSubj/20.msg threadNoSubj/21.msg threadNoSubj/22.msg threadNoSubj/23.msg threadNoSubj/24.msg threadNoSubj/25.msg threadNoSubj/26.msg threadNoSubj/27.msg threadNoSubj/28.msg threadNoSubj/29.msg threadNoSubj/30.msg threadNoSubj/31.msg threadNoSubj/32.msg threadNoSubj/33.msg threadNoSubj/34.msg threadNoSubj/35.msg threadNoSubj/36.msg threadNoSubj/37.msg threadNoSubj/38.msg threadNoSubj/39.msg threadNoSubj/40.msg threadNoSubj/41.msg threadNoSubj/42.msg threadNoSubj/43.msg threadNoSubj/44.msg threadNoSubj/45.msg threadNoSubj/46.msg threadNoSubj/47.msg threadNoSubj/48.msg threadNoSubj/49.msg threadNoSubj/50.msg threadNoSubj/51.msg threadNoSubj/52.msg threadNoSubj/53.msg threadNoSubj/54.msg threadNoSubj/55.msg threadNoSubj/56.msg threadNoSubj/57.msg threadNoSubj/58.msg threadNoSubj/59.msg threadNoSubj/60.msg threadNoSubj/61.msg threadNoSubj/62.msg threadNoSubj/63.msg threadNoSubj/64.msg threadNoSubj/65.msg threadNoSubj/66.msg threadNoSubj/67.msg threadNoSubj/68.msg threadNoSubj/69.msg threadNoSubj/70.msg threadNoSubj/71.msg threadNoSubj/72.msg threadNoSubj/73.msg threadNoSubj/74.msg threadNoSubj/75.msg threadNoSubj/76.msg threadNoSubj/77.msg threadNoSubj/78.msg threadNoSubj/79.msg threadNoSubj/80.msg threadNoSubj/81.msg threadNoSubj/82.msg threadNoSubj/83.msg threadNoSubj/84.msg threadNoSubj/85.msg threadNoSubj/86.msg threadNoSubj/87.msg threadNoSubj/88.msg threadNoSubj/89.msg threadNoSubj/90.msg threadNoSubj/91.msg threadNoSubj/92.msg threadNoSubj/93.msg threadNoSubj/94.msg threadNoSubj/95.msg threadNoSubj/96.msg threadNoSubj/97.msg threadNoSubj/98.msg threadNoSubj/99.msg threadNoSubj/100.msg threadNoSubj/101.msg threadNoSubj/102.msg threadNoSubj/103.msg threadNoSubj/104.msg threadNoSubj/105.msg threadNoSubj/106.msg threadNoSubj/107.msg threadNoSubj/108.msg threadNoSubj/109.msg threadNoSubj/110.msg);

$TLE_ModuleSourceDir = "/space/src/msg_next/msg/test/tle/imap_condstore";

sub deliverMessages {
    my $mailboxUser = $_[0];
    my @mailMsgs = @{$_[1]};
    foreach $msg (@mailMsgs) {
        system("/opt/sun/comms/messaging64/bin/deliver -c $mailboxUser < $TLE_ModuleSourceDir/$msg");
        print "Sent mail $msg\n";
    }
    return 1;
}

$user = "neo3";
deliverMessages("$user", \@messages);
deliverMessages("$user", \@messages);
deliverMessages("$user", \@messages);
deliverMessages("$user", \@messages);
deliverMessages("$user", \@messages);
deliverMessages("$user", \@messages);
deliverMessages("$user", \@threadMessages);
deliverMessages("$user", \@threadNoSubjMessages);
