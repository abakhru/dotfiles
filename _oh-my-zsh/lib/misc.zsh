## smart urls
autoload -U url-quote-magic
zle -N self-insert url-quote-magic

## file rename magick
bindkey "^[m" copy-prev-shell-word

## jobs
setopt long_list_jobs

## pager
export PAGER="less"
export LESS="-R"

export LC_CTYPE=$LANG
# Make vim the default editor
export EDITOR="vim"

# Larger bash history (allow 32³ entries; default is 500)
export HISTSIZE=32768
export HISTFILESIZE=$HISTSIZE
export HISTCONTROL=ignoredups
# Make some commands not show up in history
export HISTIGNORE="ls:cd:cd -:pwd:exit:date:* --help"

# Prefer US English and use UTF-8
export LANG="en_US"
export LC_ALL="en_US.UTF-8"

# Highlight section titles in manual pages
export LESS_TERMCAP_mb=$'\E[01;31m'
export LESS_TERMCAP_md=$'\E[01;37m'
export LESS_TERMCAP_me=$'\E[0m'
export LESS_TERMCAP_se=$'\E[0m'
export LESS_TERMCAP_so=$'\E[01;44;33m'
export LESS_TERMCAP_ue=$'\E[0m'
export LESS_TERMCAP_us=$'\E[01;32m'

# Don’t clear the screen after quitting a manual page
export MANPAGER="less -X"

# Always enable colored `grep` output
export GREP_OPTIONS="--color=auto"

# Link Homebrew casks in `/Applications` rather than `~/Applications`
#export HOMEBREW_CASK_OPTS="--appdir=/Applications"
export DISPLAY=:1
export PATH=$PATH:/usr/local/homebrew/bin:/sbin:/bin:~/source/sts/tools
export PYTHONPATH=$PYTHONPATH:/home/bakhra/source/us3238/5-qa/python/rpmtest/wui
export WUI_DEV_DIR='build/us3252-risk-indicator-response-code-v6/apps'
export JAVA_HOME=$(/usr/libexec/java_home)
export JDK_HOME=$JAVA_HOME
