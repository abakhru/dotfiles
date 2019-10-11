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
alias gtar="git st|awk '{print \$2}'|xargs tar cvzf ~/tmp/t.tgz"

alias vi='vim'
alias pp='/bin/ps -eo "user s pri pid ppid pcpu pmem vsz rss stime time nlwp psr args" |grep amit|grep -v grep|grep -v ps'
alias le='less +F'
alias de='(cd ./o && less +F `find .|grep $1|xargs ls -arth|tail -1`)'
alias tcpdump='tcpdump -qns 0 -X -r'
alias ngrep='ngrep -q -I'
alias fdgrep='find . -type f |xargs grep'
alias pygrep="find . -type f -name '*.py'|xargs grep"
alias ssh='ssh -AXYp 22 -l amit'
alias s='screen -X screen'
alias vncport='ps ww $(vncserver -list |tail -n +5 | sed -e s/^\\S\\+\\s\\+//) | tail -n +2 | sed -e s/^.*-rfbport\ // -e s/\\s.*$//'
alias clean_pycs='find . -name "*.pyc" -exec rm {} \;'
alias bld='make -r -j$CORES -f all.make'
alias rabbitlog='less +F ~/source/rabbitmq_server-3.3.4/var/log/rabbitmq/rabbit@usxxbakhram1.log'
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
drm() { docker rm $(docker ps -a -q); }

# Stop and Remove all containers
alias drmf='docker stop $(docker ps -a -q) && docker rm $(docker ps -a -q)'

# Remove all images
dri() { docker rmi $(docker images -q); }

# Dockerfile build, e.g., $dbu tcnksm/test 
dbu() { docker build -t=$1 .; }

# Show all alias related docker
dalias() { alias | grep 'docker' | sed "s/^\([^=]*\)=\(.*\)/\1 => \2/"| sed "s/['|\']//g" | sort; }

# Bash into running container
#dbash() { docker exec -it $(docker ps -aqf "name=$1") bash; }
dbash() { docker exec -it $1 bash; }
kbash() { kubectl exec -it $1 bash; }

#!/usr/bin/env zsh

####################
## blackbox stuff ##
####################

function blackbox-customer-info() {
  # Arguments:
  #   - $1 = Area 1 Blackbox customer name, requires quotes for names with spaces
  local customer=$1 
  curl -s https://portalservices.production.area1security.com/customers/ \
  | jq ".data[] | select(.customer_name | contains(\"$customer\"))"
}

function blackbox-customer-id() {
  # Arguments:
  #   - $1 = Area 1 Blackbox customer name
  blackbox-customer-info $1 | jq '.customer_id'
}

##################
## caliber docker stuff ##
##################

GCR_PROJECT="${GCR_PROJECT:-us.gcr.io/valiant-arcana-573}"
function a1s-docker-pull() {
  # Arguments:
  #   - $1 = shorthand of docker image (without us.gcr.io/...)
  docker pull "${GCR_PROJECT}/$1"
}

function start-caliber-docker() {
  # Arguments:
  #   - $1 = area 1 project / repo
  project="$1"

  # associative array of "area 1 project -> caliber docker image name"
  typeset -A repo2docker
  # assoc=(key1 value1 key2 value2 ...)
  repo2docker=(
    blackbox jenkins-slave-node:caliber-bb
    indicators jenkins-slave-node:caliber-ims
    icarus/papillon jenkins-slave-node:caliber-pap
    icarus/kubrick jenkins-slave-node:caliber-kub
    shaggy jenkins-slave-node:caliber-shag
    marshall jenkins-slave-node:caliber-marshall
    mailsearch jenkins-slave-node:caliber-mailsearch
  )

  docker_image="${repo2docker[$project]}"
  if [[ "${docker_image}" == "" ]]; then
    echo "... no matching docker image for project '${project}'"
    echo "... if you wanted IMS, use project name 'indicators'"
    echo "... checking if you meant an icarus subproject"
    docker_image="${repo2docker[icarus/$project]}"
    if [[ "${docker_image}" == "" ]]; then
      echo "... no matching docker image for 'icarus/${project}'"
      return
    fi
    project="icarus/${project}"
  fi

  #GIT_DIR="${GIT_DIR:-$HOME/git/a1s}"
  #temp_dir_for_repos="${GIT_DIR}/caliber-temp"
  #if [[ ! -d "${temp_dir_for_repos}/${project}" ]]; then
  #  if [[ "${project}" =~ "icarus" ]]; then
  #    git clone "git@github.area1security.com:engineering/icarus" "${temp_dir_for_repos}/icarus"
  #  else
  #    git clone "git@github.area1security.com:engineering/${project}" "${temp_dir_for_repos}/${project}"
  #  fi
  #fi

 # pushd "${temp_dir_for_repos}/${project}"
 # echo "... you're here right now: $(pwd)"

  echo "... pulling latest caliber docker image: ${docker_image}"
  a1s-docker-pull "${docker_image}"

  echo "... starting bash in caliber docker container using image: ${docker_image}"
  docker run -it --rm \
    -v $HOME/.ssh:/home/jenkins/.ssh \
    -v $HOME/.aws:/home/jenkins/.aws \
    -v $(pwd):/data/jenkins/ \
    -P \
    -exec -e WORKSPACE=/data/jenkins/ -P "${GCR_PROJECT}/${docker_image}" bash

  popd
}

# Remove python compiled byte-code and mypy cache in either current directory or in a
# list of specified directories
function pyclean() {
    for i in "*.py[co]" "[.]*cache" "*.egg*" "build" "dist*" "*test-reports" "[.]coverage*" "coverage*" "o" "__pycache__";
    do find . -name "${i}" -exec rm -rv {} + ; done
}
