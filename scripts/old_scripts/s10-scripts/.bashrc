#!/usr/bin/bash -x
# -<colour codes>--------------------------------
if [ `/usr/xpg4/bin/id -u` -eq 0 ]; then
        # - color of root user
        COLNORM="\[\033[0;1;31m\]" # RED (bold)
else
        # - color of normal user
        #COLNORM="\[\033[0;1;32m\]" # GREEN (bold)
        COLNORM="\[\033[0;1;30m\]" # BLACK (bold)
fi
# - reset all color settings
COLRESE="\[\033[0;1;22m\]"
# - color of the path
#COLPATH="\[\033[0;1;38m\]"
COLPATH="\[\033[0;1;30m\]"
# -</colour codes>-------------------------------

# -<uname release>-------------------------------
# set a fancy osrelease (blue)
#UNAMER='[\[\033[0;1;34m\]'$UNAME'\[\033[0;1;38m\]] '
# -</uname release>------------------------------

# -<set the prompt>------------------------------
case $TERM in
        xterm*|Eterm|rxvt)
                # this command is run before PS1 is shown.
                # currently used to set the xterm title.
                PROMPT_COMMAND='echo -ne "\033]0;${USER}@${HOSTNAME}";\
                        echo -ne " :: ${PWD} :: ['$UNAME']\007"'
                # avoid the osrelease to be shown in an xterm
                unset UNAMER
                ;;
        *)
                # do nothing.
                ;;
esac
# set the promt (PS1)
# \u is the username
# \h is the hostname
# \w is the working directory
# \$ is $ as normal user and # as root user.
PS1="${UNAMER}$COLNORM\u$COLRESE@$COLNORM\h$COLRESE:$COLPATH\w$COLRESE\\$ "
# -</set the prompt>-----------------------------

# -<clean up variables>--------------------------
unset UNAME UNAMER COLPATH COLRESE COLNORM COLROOT
# -</clean up variables>-------------------------
export PATH=$PATH:/tools/ns-arch/ns/bin:/usr/dist/pkgs/devpro/5.x-sparc/bin:/usr/dist/exe/:/opt/csw/bin:/space/ath/tle/bin:.
export CVSROOT=:pserver:abakhru@jescvs.sfbay.sun.com:/m/src
export CLASSPATH=/export/workspace/junit3.8.1/junit.jar:/space/imsrc/junit/imnet.jar:/space/imsrc/junit/:.
export JDK_HOME=/usr/jdk/latest
export TERM=vt100
export JAVA_HOME=$JDK_HOME
export LD_LIBRARY_PATH=/usr/lib:/usr/share/lib:/usr/sfw/lib:/usr/dist/share/socks/lib:/space/brightmail/symantec/sbas/Scanner/lib:/opt/csw/lib:.
export CLASSPATH=/space/trunk/junit/imnet.jar:/space/trunk/junit/:/space/trunk/dist/SunOS5.10_DBG.OBJ/built/lib/imservice.jar:/share/builds/components/log4j/1.2.8/./lib/log4j-1.2.8.jar:.
export ATHROOT=/space/ath/tle
alias viconf='vi /opt/sun/comms/im/config/iim.conf'
alias cl='javaws "http://`hostname`.sfbay.sun.com:8080/im/en/im.jnlp"'
alias webstart='/var/opt/SUNWwbsvr7/https-`hostname`.sfbay.sun.com/bin/startserv;/var/opt/SUNWwbsvr7/admin-server/bin/startserv'
alias webstop='/var/opt/SUNWwbsvr7/https-`hostname`.sfbay.sun.com/bin/stopserv;/var/opt/SUNWwbsvr7/admin-server/bin/stopserv'
alias appstart='/opt/glassfishv3/bin/asadmin start-domain'
alias appstop='/opt/glassfishv3/bin/asadmin stop-domain; rm -rf /opt/glassfishv3/glassfish/domains/domain1/logs/* /var/opt/sun/comms/iwc/logs/*'
alias studio='/space/netbeans-5/bin/netbeans --jdkhome `$JDK_HOME` &'
alias cdlogs='cd /var/opt/sun/comms/im/default/log'
alias ls='ls -lhrt'
alias ssh='ssh -CX -l uadmin'
alias calstop='/opt/sun/comms/calendar/SUNWics5/cal/sbin/stop-cal'
alias calstart='/opt/sun/comms/calendar/SUNWics5/cal/sbin/start-cal'
alias dsstop='/opt/sun/dsee7/bin/dsadm stop /var/opt/SUNWdsee/dsins1'
alias dsstart='/opt/sun/dsee7/bin/dsadm start /var/opt/SUNWdsee/dsins1'
alias imstop='/opt/sun/comms/im/sbin/imadmin stop'
alias imstatus='/opt/sun/comms/im/sbin/imadmin status'
alias imstart='/opt/sun/comms/im/sbin/imadmin start'
alias imrefresh='/opt/sun/comms/im/sbin/imadmin refresh'
alias log='tail -f /var/opt/sun/comms/im/default/log/xmppd.log'
alias wlog='tail -f /var/opt/sun/comms/im/default/log/httpbind.log'
alias mlog='tail -f /var/opt/sun/comms/im/default/log/mux.log'
alias fdgrep='find . |xargs grep'
#Mail server aliases
#####################
msg_dir=/opt/sun/comms/messaging64
alias imsimta='$msg_dir/sbin/imsimta'
alias configutil='$msg_dir/sbin/configutil'
alias stop='$msg_dir/sbin/stop-msg; rm -rf /var/$msg_dir/log/*' 
alias start='$msg_dir/sbin/start-msg'
alias mslog='cd $msg_dir/log'
alias hgup='hg pull -u'
alias cvsup='cvs up -d -P 2>/dev/null'
alias cnbuild='$msg_dir/sbin/imsimta cnbuild'
alias version='$msg_dir/sbin/imsimta version'
#alias refresh='$msg_dir/sbin/stop-msg;$msg_dir/sbin/imsimta cnbuild; $msg_dir/sbin/start-msg'
alias refresh='stop; cnbuild; start'
alias pp='/usr/bin/ps -eo "user s pri pid ppid pcpu pmem vsz rss stime time nlwp psr args"'
alias runtle='/usr/bin/perl $ATHROOT/bin/tle -f $ATHROOT/workload -vt'
alias debugtle='/usr/bin/perl -d $ATHROOT/bin/tle -f $ATHROOT/workload -vt'
alias le='less +F'
alias hgst='hg st .'
export http_proxy="http://www-proxy.us.oracle.com:80"
export ftp_proxy="http://www-proxy.us.oracle.com:80"
alias de='(cd /; cd /space/src/results/ && less +F `find .|grep detaillog|grep -v SUPPORT| tail -1`)'
