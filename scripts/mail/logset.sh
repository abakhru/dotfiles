msg_pkg=`pkginfo |grep SUNWmessaging |cut -f2 -d" "`
msg_dir=`pkginfo -l $msg_pkg|grep BASEDIR |cut -f2 -d":"`
cd $msg_dir/sbin
./configutil -o logfile.admin.loglevel -v Debug
./configutil -o logfile.default.loglevel -v Debug
./configutil -o logfile.http.loglevel -v Debug
./configutil -o logfile.imap.loglevel -v Debug
./configutil -o logfile.imta.loglevel -v Debug
./configutil -o logfile.pop.loglevel -v Debug
./configutil -o local.service.http.showunreadcounts -v yes
./configutil -o local.ldaptrace -v 1
cp $msg_dir/config/option.dat $msg_dir/config/option.dat.ORIG
cp $msg_dir/config/imta.cnf $msg_dir/config/imta.cnf.ORIG
cp $msg_dir/config/mappings $msg_dir/config/mappings.ORIG
echo "!
LOG_MESSAGE_ID=1
LOG_FILTER=1
LOG_MESSAGES_SYSLOG=20
LOG_CONNECTION=3
!LOG_HEADER=1
LOG_FILENAME=1
LOG_USERNAME=1
LOG_SNDOPR=1
LOG_REASON=1
DEQUEUE_DEBUG=1
!
MM_DEBUG=10
OS_DEBUG=1
MAX_NOTIFYS = 2
! Log to syslog
SEPARATE_CONNECTION_LOG=1
!
ENABLE_SIEVE_BODY=1
!SPAMFILTER1_CONFIG_FILE=/opt/sun/comms/messaging64/config/bmiconfig.xml
!SPAMFILTER1_LIBRARY=/opt/sun/comms/messaging64/lib/libbmiclient.so
!SPAMFILTER1_OPTIONAL=1
!SPAMFILTER1_STRING_ACTION=data:,$M
!SPAMFILTER1_STRING_ACTION=data:,require ["addheader", "editheader", "reject"];if header :contains "subject" ["Test Mail", "spam"] { discard; }
" >> ../config/option.dat
echo "debug=10" >> ../config/job_controller.cnf
sed -e 's/defaults/defaults logging/' \
-e '/ims-ms defragment/ s/$/ master_debug slave_debug/' \
-e '/tcp_local smtp/ s/$/ master_debug slave_debug/' \
-e '/tcp_intranet smtp/ s/$/ master_debug slave_debug/' \
-e '/tcp_submit submit/ s/$/ master_debug slave_debug/' \
-e '/tcp_auth smtp/ s/$/ master_debug slave_debug/' ../config/imta.cnf > t1; mv t1 ../config/imta.cnf
#-e '80,$ s/conversion /conversion master_debug slave_debug/' imta.cnf > t1
#./imsimta cnbuild; ./stop-msg; ./start-msg
cd -
