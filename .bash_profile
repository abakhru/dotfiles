### Prompt Colors 
# Modified version of @gf3’s Sexy Bash Prompt 
# (https://github.com/gf3/dotfiles)
if [[ $COLORTERM = gnome-* && $TERM = xterm ]] && infocmp gnome-256color >/dev/null 2>&1; then
	export TERM=gnome-256color
elif infocmp xterm-256color >/dev/null 2>&1; then
	export TERM=xterm-256color
fi

if tput setaf 1 &> /dev/null; then
	tput sgr0
	if [[ $(tput colors) -ge 256 ]] 2>/dev/null; then
		BLACK=$(tput setaf 190)
		MAGENTA=$(tput setaf 9)
		ORANGE=$(tput setaf 172)
		GREEN=$(tput setaf 190)
		PURPLE=$(tput setaf 141)
		WHITE=$(tput setaf 0)
	else
		BLACK=$(tput setaf 190)
		MAGENTA=$(tput setaf 5)
		ORANGE=$(tput setaf 4)
		GREEN=$(tput setaf 2)
		PURPLE=$(tput setaf 1)
		WHITE=$(tput setaf 7)
	fi
	BOLD=$(tput bold)
	RESET=$(tput sgr0)
else
	BLACK="\033[01;30m"
	MAGENTA="\033[1;31m"
	ORANGE="\033[1;33m"
	GREEN="\033[1;32m"
	#PURPLE="\033[1;35m"
	PURPLE="\033[1;63m"
	WHITE="\033[1;37m"
	BOLD=""
	RESET="\033[m"
fi

export BLACK
export MAGENTA
export ORANGE
export GREEN
export PURPLE
export WHITE
export BOLD
export RESET

# Git branch details
function parse_git_dirty() {
	[[ $(git status 2> /dev/null | tail -n1) != *"working directory clean"* ]] && echo "*"
}
function parse_git_branch() {
	git branch --no-color 2> /dev/null | sed -e '/^[^*]/d' -e "s/* \(.*\)/\1$(parse_git_dirty)/"
}

# Change this symbol to something sweet. 
# (http://en.wikipedia.org/wiki/Unicode_symbols)
#symbol="⚡ "
symbol="⚡ "

source ~/.bash/git-prompt
source ~/.bash/git-completion

export PS1="\[${BOLD}${MAGENTA}\]\u\[$WHITE\]@\[$PURPLE\]\h \[$ORANGE\]in \[$GREEN\]\w\[$ORANGE\]\$([[ -n \$(git branch 2> /dev/null) ]] && echo \" on\")\[$PURPLE\]\$(parse_git_branch)\[$ORANGE\] $symbol\[$RESET\]"
#export PS2="\[$ORANGE\]→ \[$RESET\]"
#export PS1='[\[\e[36;1m\]\u@\[\e[32;1m\]\h \[\e[31;1m\]\w $(parse_git_branch_or_tag)]# \[\e[0m\]'
#blue=36
#green=32
#red=31
#export PS1='\[\e[31;1m\]\u \[\e[32;1m\]\w \[\e[36;1m\]$(parse_git_branch_or_tag)]# \[\e[0m\]'


### Misc

# Only show the current directory's name in the tab 
export PROMPT_COMMAND='echo -ne "\033]0;${PWD##*/}\007"'
export PYTHONPATH=../..:../../../../python

# init z! (https://github.com/rupa/z)
. ~/dotfiles/z.sh

# Load the shell dotfiles, and then some:
# * ~/.path can be used to extend `$PATH`.
# * ~/.extra can be used for other settings you don’t want to commit.
for file in ~/dotfiles/.{path,bash_prompt,vimrc,exports,aliases,functions,extra}; do
    [ -r "$file" ] && [ -f "$file" ] && source "$file"
done
unset file

# Append to the Bash history file, rather than overwriting it
shopt -s histappend

# Autocorrect typos in path names when using `cd`
shopt -s cdspell

# Enable some Bash 4 features when possible:
# * `autocd`, e.g. `**/qux` will enter `./foo/bar/baz/qux`
# * Recursive globbing, e.g. `echo **/*.txt`
for option in autocd globstar; do
    shopt -s "$option" 2> /dev/null
done
#alias sshfs='sshfs bakhra@billyjack.silvertailsystems.com:/home/bakhra/source/ /Users/bakhra/sshfs/'
#git lsmod |xargs tar cvf ~/tmp/t.tar
#nosetests -svm "^test_" test/basic_test.py

#time/date on top-right corner of terminal for full screen mode
#while sleep 1;do tput sc;tput cup 0 $(($(tput cols)-29));date;tput rc;done &

#Show numerical values for each of the 256 colors in bash
#for i in {0..255}; do echo -e "\e[38;05;${i}m${i}"; done | column -c 80 -s '  '; echo -e "\e[m"

#Send command to all terminals in a screen session
#<ctrl+a>:at "#" stuff "echo hello world^M"
