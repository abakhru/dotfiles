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
alias gtar="git status -s|awk '{print \$2}'|xargs tar cvzf ~/tmp/t.tgz"

alias vi='vim'
alias pp='/bin/ps -eo "user s pri pid ppid pcpu pmem vsz rss stime time nlwp psr args" |grep amit|grep -v grep|grep -v ps'
alias le='less +F'
alias de='(cd ./o && less +F `find .|grep $1|xargs ls -arth|tail -1`)'
alias tcpdump='tcpdump -qns 0 -X -r'
alias ngrep='ngrep -q -I'
alias fdgrep='find . -type f |xargs grep'
alias pygrep="find . -type f -name '*.py'|xargs grep"
alias s='screen -X screen'
alias vncport='ps ww $(vncserver -list |tail -n +5 | sed -e s/^\\S\\+\\s\\+//) | tail -n +2 | sed -e s/^.*-rfbport\ // -e s/\\s.*$//'
alias clean_pycs='find . -name "*.pyc" -exec rm {} \;'
alias bld='make -r -j$CORES -f all.make'
alias rabbitlog='less +F ~/src/rabbitmq_server-3.3.4/var/log/rabbitmq/rabbit@usxxbakhram1.log'
alias mongolog='less +F /usr/local/var/log/mongodb/mongo.log'
alias knose="ps -ef|grep nosetests|grep -v grep|awk '{print \$2}'|xargs kill -9"
alias krabbit="ps -ef|grep rabbit|grep -v grep|awk '{print \$2}'|xargs kill -9"
alias launchesa='`find o |grep esaserver/cmd |tail -1 |xargs more`'

# ------------------------------------
# Docker alias and function
# https://kartar.net/2014/03/useful-docker-bash-functions-and-aliases/
# ------------------------------------

alias d='docker'

# Get latest container ID
alias dl="docker ps -l -q"

# Get container process
alias dps="docker ps"

# Get process included stop container
alias dpa="docker ps -a"

# Get images
alias di="docker images"

# Get container IP
alias dip="docker inspect --format '{{ .NetworkSettings.IPAddress }}'"

# Run deamonized container, e.g., $dkd base /bin/echo hello
alias dkd="docker run -d -P"

# Run interactive container, e.g., $dki base /bin/bash
alias dki="docker run -i -t -P"

# Execute interactive container, e.g., $dex base /bin/bash
alias dex="docker exec -i -t"

# Stop all containers
dstop() { docker stop $(docker ps -a -q); }

# Remove all containers
#drm() { docker rm $(docker ps -a -q); }

# Stop and Remove all containers
alias drmf='docker stop $(docker ps -a -q) && docker rm $(docker ps -a -q)'

# Remove all images
dri() { docker rmi $(docker images -q); }

# Dockerfile build, e.g., $dbu tcnksm/test 
#dbu() { docker build -t=$1 .; }

# Show all alias related docker
dalias() { alias | grep 'docker' | sed "s/^\([^=]*\)=\(.*\)/\1 => \2/"| sed "s/['|\']//g" | sort; }

# Bash into running container
#dbash() { docker exec -it $(docker ps -aqf "name=$1") bash; }
dbash() { docker exec -it $1 bash; }
kbash() { kubectl exec -it $1 bash; }

# Modern CLI alternatives
alias ping='prettyping --nolegend'
alias cat='bat'
alias top='glances'
alias du="ncdu --color dark -rr -x --exclude .git --exclude node_modules"
alias l='eza --long --git -g -a -s modified'
alias k='kubecolor'
alias kubectl="kubecolor"

# Navigation aliases
alias zc='z -c'      # restrict matches to subdirs of $PWD
alias zz='z -i'      # cd with interactive selection
alias zf='z -I'      # use to select in multiple matches
alias zb='z -b'      # quickly cd to the parent directory

# Configuration aliases
alias zconf="vim ${HOME}/.zshrc"
alias reload=". ${HOME}/.zshrc"

# Bulk update aliases
alias gall="for i in \$(find ${HOME}/src -type d -execdir test -d {}/.git \; -prune -print); do (echo \"==== Updating \$i ====\"; cd \$i; git stash && g p && gfa && git stash pop; cd -); done"
alias pipall="for i in \$(pip list -o --format columns|awk '{print \$1}') ; do pip install -U \$i; done"
alias dall="docker images --format \"{{.Repository}}:{{.Tag}}\" | grep ':latest' | xargs -L1 docker pull"

# Cargo aliases
alias c='cargo'
alias cb='cargo build'
alias cr='cargo run'
alias cw='cargo watch'
alias ct='cargo test'

# Utility aliases
alias cloc="tokei"
alias calc="insect"
alias myip="ip -json route get 8.8.8.8 | jq -r '.[].prefsrc'"

# OSX specific aliases
if [ "$(uname)" = "Darwin" ]; then
    # Airport/WiFi control
    alias wifi='/usr/libexec/airportd'
    alias vnc='open vnc://billyjack.silvertailsystems.com:5901'
fi
#alias kcpod='function _kcpod() { if [[ -z $NAMESPACE ]]; then echo "Error: NAMESPACE environment variable is not set"; return 1; fi; local pod=$(kubectl get pods -n $NAMESPACE | grep -m 1 "$1" | awk "{print \$1}"); if [[ -z $pod ]]; then echo "Error: No pod found matching \"$1\" in namespace $NAMESPACE"; return 1; fi; kubectl exec -it $pod -n $NAMESPACE -- /bin/bash; }; _kcpod'
alias kcpod='function _kcpod() { if [[ -z $NAMESPACE ]]; then echo "Error: NAMESPACE environment variable is not set"; return 1; fi; local pod=$(kubectl get pods -n $NAMESPACE | grep -m 1 "$1" | awk "{print \$1}"); if [[ -z $pod ]]; then echo "Error: No pod found matching \"$1\" in namespace $NAMESPACE"; return 1; fi; if [[ -n $2 ]]; then kubectl exec -it $pod -n $NAMESPACE -c "$2" -- /bin/bash; else kubectl exec -it $pod -n $NAMESPACE -- /bin/bash; fi; }; _kcpod'
alias j=just
