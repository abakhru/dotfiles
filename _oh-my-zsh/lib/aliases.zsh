# Push and pop directories on directory stack
alias pu='pushd'
alias po='popd'

# Basic directory operations
alias ...='cd ../..'
alias -- -='cd -'

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
alias s='open -a 'Sublime Text''

# Color LS
#for osx
#colorflag='-G'
#for linux
#colorflag='--color=tty'

# List direcory contents
alias lsa='ls -lah'
alias l='ls -larth'
alias ll='ls -lh'
alias la='ls -lAh'
alias lsd='ls -lF | grep '^d'' # only directories
alias ls='ls -larth'

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
alias cs='/usr/local/bin/cscope'

# Git 
# You must install Git first - ''
alias gs='git status'
alias ga='git add .'
alias gc='git commit -m' # requires you to type a commit message
alias gp='git push'
alias gitbackout='git ls -m|xargs git co HEAD'
alias cloneana='git clone git@github.silvertailsystems.com:ana/main3.git'
alias gtar='git st|awk '{print $2}'|xargs tar cvf ~/tmp/t.tar'

alias vi='vim'
alias pp='/bin/ps -eo 'user s pri pid ppid pcpu pmem vsz rss stime time nlwp psr args' |grep bakhra|grep -v grep|grep -v ps'
alias le='less -rXF'
#alias de='(cd ./o && less +F `find .|grep $1|xargs ls -arth|tail -1`)'
alias tcpdump='tcpdump -qns 0 -X -r'
alias ngrep='ngrep -q -I'
alias findpy='cd 5-qa/python/stqa && find . -maxdepth 4 -type f|grep '\.py'|xargs grep'
alias fdgrep='find . |xargs grep'
alias pygrep="find . -type f -name '*.py'|xargs grep"
alias top='top -c d'
alias knose='pkill -9 -u bakhra nosetests'
alias ksilver='pkill -9 -u bakhra -f silver'
alias sshs1='ssh -AXYp 2772 mecha.silvertailsystems.com'
alias sshs2='ssh -AXYp 2772 billyjack.silvertailsystems.com'
alias ssh='ssh -AXYp 2772 -l bakhra'
alias s='screen -X screen'
alias vncport='ps ww $(vncserver -list |tail -n +5 | sed -e s/^\\S\\+\\s\\+//) | tail -n +2 | sed -e s/^.*-rfbport\ // -e s/\\s.*$//'
alias nosetests="nosetests -e '^Modify' -svm"
alias clean_pycs="find . -name '*.pyc' -exec rm {} \;"
