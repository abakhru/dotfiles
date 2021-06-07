#!/usr/bin/env bash


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
  (mkdir -p "${HOME}"/src "${HOME}"/.ssh || true)
  ssh-keyscan github.com >>"${HOME}"/.ssh/known_hosts

  if [ "$(uname -s)" = "Darwin" ]; then
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
    brew install npm zsh tmux git vim htop ruby node
    brew cask install chef java
  elif [ "$(awk -F= '/^NAME/{print $2}' /etc/os-release)" = "\"Ubuntu\"" ]; then
    sudo -- sh -c "apt update && \
    apt full-upgrade -y && \
    apt install -y htop vim tmux zsh ruby git npm curl net-tools openssl pkg-config rbenv \
    python3 python3-venv"
  fi
  if [ ! -d "${HOME}/src/ohmyzsh" ]; then
    (cd "${HOME}"/src && git clone https://github.com/ohmyzsh/ohmyzsh.git)
  fi
  #  ln -sf "${HOME}"/src/ohmyzsh "${PWD}"/_oh-my-zsh
  ln -sf "${HOME}"/src/ohmyzsh "${HOME}"/.oh-my-zsh
  curl -L git.io/antigen >antigen.zsh
  sudo npm install -g dockly
}

function rust_install() {
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
  source "${HOME}"/.cargo/env
  (cargo install starship bat ripgrep bat exa procs fd-find topgrade grex cargo-update git-delta)
}

function tmux_install() {
  (cd "${HOME}" && git clone https://github.com/gpakosz/.tmux.git)
  gem install tmuxinator
  rm -rf "${HOME}"/.tmux/.tmux.conf*
  ln -s "${HOME}"/src/dotfiles/_tmux.conf "${HOME}"/.tmux/.tmux.conf
  ln -s "${HOME}"/src/dotfiles/_tmux.conf.local "${HOME}"/.tmux/.tmux.conf.local
}

function sudo_access() {
  echo "${USER} ALL=(ALL) NOPASSWD: ALL" >>/etc/sudoers
}

function setup_git_repo() {
  cd "${HOME}" && mkdir -p src && cd "${HOME}"/src
  git clone https://github.com/abakhru/dotfiles.git
  cd "${HOME}"/src/dotfiles
  setup_home_files
}

function install_docker() {
  sudo apt-get remove -y docker docker-engine docker.io containerd runc
  sudo apt-get update
  sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
  echo \
    "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
  sudo apt-get update
  sudo apt-get install -y docker-ce docker-ce-cli containerd.io
  sudo adduser "${USER}" docker
}

function all() {
  os_packages_install
  install_docker
  rust_install
  tmux_install
  setup_git_repo
  zsh
}

function help() {
  typeset -f | awk '/ \(\) $/ && !/^main / {print $1}'
}

if [ "_$1" = "_" ]; then
  help
else
  "$@"
fi
