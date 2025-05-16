#!/usr/bin/env bash

# Add error handling and logging
set -euo pipefail
LOG_FILE="${HOME}/install.log"

function log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" | tee -a "${LOG_FILE}"
}

function ensure_zsh() {
    if ! command -v zsh >/dev/null 2>&1; then
        log "zsh not found. Installing..."
        if [ "$(uname)" = "Darwin" ]; then
            brew install zsh
        else
            sudo apt-get update && sudo apt-get install -y zsh
        fi
    fi

    ZSH_PATH=$(command -v zsh)
    log "zsh path: $ZSH_PATH"

    # Add zsh to valid login shells if not already present
    if ! grep -q "$ZSH_PATH" /etc/shells; then
        log "Adding zsh to /etc/shells..."
        echo "$ZSH_PATH" | sudo tee -a /etc/shells
    fi

    # Change default shell to zsh if not already
    if [ "$SHELL" != "$ZSH_PATH" ]; then
        log "Changing default shell to zsh..."
        chsh -s "$ZSH_PATH"
        export SHELL="$ZSH_PATH"
    fi

    # Switch to zsh for the rest of the script
    if [ -z "${ZSH_VERSION:-}" ]; then
        log "Not running in zsh. Current shell: $SHELL. Restarting script with zsh..."
        exec "$ZSH_PATH" "$0" "$@"
    fi
}

# Run zsh setup before anything else
ensure_zsh
log "Running in zsh version: $ZSH_VERSION"

function link_file() {
    local source="${PWD}/$1"
    local target="${HOME}/${1/_/.}"

    if [ ! -e "${source}" ]; then
        log "Error: Source file ${source} does not exist"
        return 1
    fi

    if [ -L "${target}" ]; then
        unlink "$target"
    elif [ -e "${target}" ]; then
        mv "$target" "$target.df.bak"
    fi
    ln -sf "${source}" "${target}"
    log "Linked ${source} to ${target}"
}

function unlink_file() {
    local source="${PWD}/$1"
    local target="${HOME}/${1/_/.}"
    if [ -e "${target}.df.bak" ] && [ -L "${target}" ]; then
        unlink "${target}"
        mv "$target.df.bak" "${target}"
    fi
}

function setup_home_files() {
    for i in _*; do
        link_file "$i"
    done
}

function os_packages_install() {
    log "Starting package installation"
    mkdir -p "${HOME}"/{src,.ssh}

    if [ ! -f "${HOME}/.ssh/known_hosts" ]; then
        ssh-keyscan github.com >> "${HOME}"/.ssh/known_hosts
    fi

    if [ "$(uname -s)" = "Darwin" ]; then
        if ! command -v brew &> /dev/null; then
            log "Installing Homebrew"
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        fi

        local brew_packages=(
            npm zsh tmux git vim htop ruby node wget fzf maven openjdk
            awscli docker-compose go lazydocker cloudflared k9s stern helm
            docker-credential-helper docker-credential-helper-ecr kubecolor sniffnet
            numi lens spotify firefox beekeeper-studio figma dbeaver-community the-unarchiver appcleaner
        )
        local brew_casks=(aerial notion)

        /opt/homebrew/bin/brew install "${brew_packages[@]}"
        /opt/homebrew/bin/brew install --cask "${brew_casks[@]}"
    elif [ "$(awk -F= '/^NAME/{print $2}' /etc/os-release)" = "\"Ubuntu\"" ]; then
        log "Installing Ubuntu packages"
        sudo apt-get update && sudo apt-get full-upgrade -y
        sudo apt-get install -y htop vim tmux zsh ruby git npm curl net-tools \
            openssl pkg-config rbenv python3 python3-venv
    fi

    if [ ! -d "${HOME}/src/ohmyzsh" ]; then
        git clone https://github.com/ohmyzsh/ohmyzsh.git "${HOME}/src/ohmyzsh"
    fi

    ln -sf "${HOME}/src/ohmyzsh" "${HOME}/.oh-my-zsh"

    if [ ! -f antigen.zsh ]; then
        curl -L git.io/antigen > antigen.zsh
    fi

    if ! command -v dockly &> /dev/null; then
        sudo npm install -g dockly
    fi
}

function rust_install() {
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
  source "${HOME}"/.cargo/env
  (cargo install starship bat ripgrep bat exa procs fd-find topgrade grex cargo-update git-delta)
}

function tmux_install() {
    log "Setting up tmux configuration..."

    # Install tmux if not present
    if ! command -v tmux >/dev/null 2>&1; then
        if [ "$(uname)" = "Darwin" ]; then
            brew install tmux
        else
            sudo apt-get update && sudo apt-get install -y tmux
        fi
    fi

    # Setup tmux configuration
    (cd "${HOME}" && git clone https://github.com/gpakosz/.tmux.git)
    gem install tmuxinator
    rm -rf "${HOME}"/.tmux/.tmux.conf*
    ln -sf "${HOME}"/src/dotfiles/_tmux.conf "${HOME}"/.tmux/.tmux.conf
    ln -sf "${HOME}"/src/dotfiles/_tmux.conf.local "${HOME}"/.tmux/.tmux.conf.local

    # Ensure tmux is using zsh
    tmux_shell=$(command -v zsh)
    log "Setting tmux default shell to: $tmux_shell"
    tmux set-option -g default-shell "$tmux_shell"

    (cd "${HOME}/.tmux" && git clone https://github.com/jonmosco/kube-tmux)
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
  sudo wget https://github.com/bcicen/ctop/releases/download/v0.7.5/ctop-0.7.5-linux-amd64 -O /usr/local/bin/ctop && sudo chmod +x /usr/local/bin/ctop
}

function setup_zsh() {
    # Add zsh to valid login shells
    if ! grep -q "$(which zsh)" /etc/shells; then
        echo "$(which zsh)" | sudo tee -a /etc/shells
    fi

    # Change default shell to zsh
    if [ "$SHELL" != "$(which zsh)" ]; then
        chsh -s "$(which zsh)"
        log "Changed default shell to zsh. Please log out and back in for changes to take effect."
    fi
}

function all() {
    log "Starting full installation"
    os_packages_install
    setup_zsh
    install_docker
    rust_install
    tmux_install
    setup_git_repo
    log "Installation complete"
    log "Please log out and back in to start using zsh"
}

function help() {
  typeset -f | awk '/ \(\) $/ && !/^main / {print $1}'
}

# Main execution
if [ $# -eq 0 ]; then
    help
else
    "$@"
fi
