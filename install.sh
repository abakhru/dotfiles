#!/usr/bin/env bash

# cd ..; git clone https://github.com/robbyrussell/oh-my-zsh.git; cd -

function link_file {
    source="${PWD}/$1"
    target="${HOME}/${1/_/.}"
    if [ -L "${target}" ]; then
        unlink $target
    fi

    if [ -e "${target}" ] && [ ! -L "${target}" ]; then
        mv $target $target.df.bak
    fi

    ln -sf ${source} ${target}
}

function unlink_file {
    source="${PWD}/$1"
    target="${HOME}/${1/_/.}"

    if [ -e "${target}.df.bak" ] && [ -L "${target}" ]; then
        unlink ${target}
        mv $target.df.bak $target
    fi
}

if [ "$1" = "restore" ]; then
    for i in _*
    do
        unlink_file $i
    done
    exit
else
    for i in _*
    do
        link_file $i
    done
fi

/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
brew install npm zsh tmux git vim screen
brew cask install chef java
npm install -g diff-so-fancy
