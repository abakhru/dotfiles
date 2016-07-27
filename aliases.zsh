# Push and pop directories on directory stack
alias pu='pushd'
alias po='popd'

# Basic directory operations
alias ...='cd ../..'
#alias --='cd -'

# Super user
alias _='sudo'
alias please='sudo'

#alias g='grep -in'

# Show history
if [ '$HIST_STAMPS' = 'mm/dd/yyyy' ]
then
    alias history='fc -fl 1'
elif [ '$HIST_STAMPS' = 'dd.mm.yyyy' ]
then
    alias history='fc -El 1'
elif [ '$HIST_STAMPS' = 'yyyy-mm-dd' ]
then
    alias history='fc -il 1'
else
    alias history='fc -l 1'
fi

alias afind='ack-grep -il'

### Aliases

# Open specified files in Sublime Text
# 's .' will open the current directory in Sublime
alias s='open -a "Sublime Text"'

# Color LS
#for osx
colorflag='-G'
#for linux
#colorflag='--color=tty'

# List direcory contents
alias lsa='ls -lah ${colorflag}'
alias l='ls -larth ${colorflag}'
alias ll='ls -lh ${colorflag}'
alias la='ls -lAh ${colorflag}'
alias lsd='ls -lF | grep '^d'' # only directories
alias ls='ls -larth ${colorflag}'

# Quicker navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias ......='cd ../../../../..'

# Shortcuts to my Code folder in my home directory
alias code='cd ~/source'
alias sites='cd ~/Code/sites'

# Colored up cat!
# You must install Pygments first - 'sudo easy_install Pygments'
alias c='pygmentize -O style=monokai -f console256 -g'

# Git 
# You must install Git first - ''
alias gs='git status'
alias ga='git add .'
alias gc='git commit -m' # requires you to type a commit message
alias gp='git push'
alias gitbackout='git ls -m|xargs git co HEAD'
alias clonests='git clone git@github.silvertailsystems.com:sts/main3.git'
alias gtar='git st|awk "{print $2}"|xargs tar cvf ~/tmp/t.tar'

alias vi='vim'
alias pp='/bin/ps -eo "user s pri pid ppid pcpu pmem vsz rss stime time nlwp psr args" |grep bakhra|grep -v grep|grep -v ps'
alias le='less +F'
alias de='(cd ./o && less +F `find .|grep $1|xargs ls -arth|tail -1`)'
alias tcpdump='tcpdump -qns 0 -X -r'
alias ngrep='ngrep -q -I'
alias fdgrep='find . -type f |xargs grep'
alias pygrep="find . -type f -name '*.py'|xargs grep"
alias ssh='ssh -AXYp 22 -l bakhra'
alias s='screen -X screen'
alias vncport='ps ww $(vncserver -list |tail -n +5 | sed -e s/^\\S\\+\\s\\+//) | tail -n +2 | sed -e s/^.*-rfbport\ // -e s/\\s.*$//'
alias clean_pycs='find . -name "*.pyc" -exec rm {} \;'
alias bld='make -r -j$CORES -f all.make'
alias rabbitlog='less +F ~/source/rabbitmq_server-3.3.4/var/log/rabbitmq/rabbit@usxxbakhram1.log'
alias mongolog='less +F /usr/local/var/log/mongodb/mongo.log'
alias knose='pkill -9 -u bakhra nosetests'
alias krabbit="ps -ef|grep rabbit|awk '{print $2}'|xargs kill -9"
alias kjava='pkill -9 -u bakhra java'
alias ksilver='pkill -9 -u bakhra -f silver'
alias launchesa='`find o |grep esaserver/cmd |tail -1 |xargs more`'
alias esalog='find o |grep esaserver/stdout |tail -1 |xargs less +F'
alias eclog='find o |grep esaclient/esaclient.log |tail -1 |xargs less +F'
