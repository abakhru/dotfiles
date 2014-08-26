#
# /.profile   sh/ksh startup file for root, to be executed after standard system supplied /etc/profile
#
export PATH TERM EDITOR PS1
umask 022

#  System search path (local executables only):
#
PATH=/usr/sbin:/sbin:/usr/bin:/usr/ccs/bin:/usr/dt/bin:/usr/X/bin:/usr/ucb/cc

#  TERM setup for dialup (wy50 and tvi925 OK as well):
#
DUPTERM=vt100
if [ "$TERM" = "dialup" -o "$TERM" = "unknown" ]; then
        TERM=$DUPTERM;  /usr/bin/tput init;  /usr/bin/tabs -8
fi

#  We don't want to use ed, do we:
#
EDITOR=/usr/bin/vi

#
# MANPATH
#
MANPATH=/usr/man:/usr/dt/man:/usr/X/man


#  Default root prompt:

#
alias nets="/usr/dt/appconfig/SUNWns/netscape &"
alias start="/net/tornedo/orion_builds/orion2/m2/b10_nightly/sparc/Solaris_sparc/installer"
alias silent="/net/tornedo/orion_builds/orion2/m2/b10_nightly/sparc/Solaris_sparc/installer -nodisplay -noconsole -state"
alias starts="/net/tornedo/orion_builds/orion2/m2/b10_nightly/sparc/Solaris_sparc/installer -no -saveState"
alias startd="/net/tornedo/orion_builds/orion2/m2/b10_nightly/sparc/Solaris_sparc/installer -debug -debugWbAll |tee"
alias startc="/net/tornedo/orion_builds/orion2/m2/b10_nightly/sparc/Solaris_sparc/installer -nodisplay |tee"
alias stops="/var/sadm/prod/entsys/uninstall -no -saveState"
alias silents="/var/sadm/prod/entsys/uninstall -nodisplay -noconsole -state" 
#PS1="root[(k)sh]@`/usr/bin/uname -n`# "
alias c="clear"
alias stopc="/Individuals/arvind/Common/stopc"
alias stopp="/Individuals/arvind/Common/stopp" 
alias com="sh /Helpers_Sparc/Complete_Clean/Final_Clean1"
alias par="sh /Helpers_Sparc/Partial_Clean/Final_Clean1"
alias d0="/var/opt/mps/serverroot/slapd-tornedo/start-slapd"
alias d1="/var/opt/mps/serverroot/slapd-tornedo/stop-slapd"

alias apps0="/Individuals/arvind/AP/IStartap"
alias apps1="/Individuals/arvind/AP/MStartap"
alias webs0="/Individuals/arvind/WS/IStartap"
alias webs1="/Individuals/arvind/WS/MStartap"
alias cs="sh /Individuals/arvind/Common/CO"
alias arvind="cd /Individuals/arvind"
alias admin="/Individuals/arvind/Common/admin"
alias g0="/opt/SUNWps/bin/gateway start"
alias g1="/opt/SUNWps/bin/gateway stop"
PS1="root[(k)sh]@or002# "
alias Nets="/usr/dist/exe/netscape &" 
