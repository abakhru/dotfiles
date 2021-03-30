#!/usr/bin/env bash

curl -L git.io/antigen >antigen.zsh

function link_file() {
  source="${PWD}/$1"
  target="${HOME}/${1/_/.}"
  if [ -L "${target}" ]; then unlink "$target"; fi
  if [ -e "${target}" ] && [ ! -L "${target}" ]; then mv "$target" "$target.df.bak"; fi
  ln -sf "${source}" "${target}"
}

function unlink_file() {
  source="${PWD}/$1"
  target="${HOME}/${1/_/.}"
  if [ -e "${target}.df.bak" ] && [ -L "${target}" ]; then
    unlink "${target}"
    mv "$target.df.bak" "${target}"
  fi
}

function setup_home_files() {
  #  if [ "$1" = "restore" ]; then
  #      for i in _*; do unlink_file "$i"; done
  #      exit
  #  else
  for i in _*; do link_file "$i"; done
  #  fi
}

function os_packages_install() {
  if [ "$(uname -s)" = "Darwin" ]; then
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
    brew install npm zsh tmux git vim htop ruby node
    brew cask install chef java
  elif [ "$(uname -s)" = "Linux" ]; then
    sudo -- sh -c "apt update && apt full-upgrade -y &&
     apt install -y htop  vim tmux zsh node ruby git npm curl net-tools "
  fi
  (mkdir -p "${HOME}"/src || true)
  if [ ! -d "${HOME}/src/ohmyzsh" ]; then
    (cd ~/src && git clone https://github.com/ohmyzsh/ohmyzsh.git)
  fi
  ln -sf ~/src/ohmyzsh "${PWD}"/_oh-my-zsh
  ln -sf ~/src/ohmyzsh "${HOME}"/.oh-my-zsh
  npm install -g diff-so-fancy dockly
}

function rust_install() {
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
  (cargo install starship rustup bat ripgrep fzf prettyping bat ncdu exa procs fd-find topgrade grex cargo-update)
}

function tmux_install() {
  (cd "${HOME}" && git clone https://github.com/gpakosz/.tmux.git)
  gem install tmuxinator
  ln -sf _tmux.conf "${HOME}"/.tmux/.tmux.conf
  ln -sf _tmux.conf.local "${HOME}"/.tmux/.tmux.conf.local
}

function sudo_access() {
  echo "${USER} ALL=(ALL) NOPASSWD: ALL" >>/etc/sudoers
}

function setup_git_repo() {
    cd "${HOME}" && mkdir -p src && cd "${HOME}"/src
    git clone git@github.com:abakhru/dotfiles.git
    cd "${HOME}"/src/dotfiles
}

setup_git_repo
os_packages_install
rust_install
tmux_install
setup_home_files
antigen
