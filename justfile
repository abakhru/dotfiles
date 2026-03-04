#!/usr/bin/env just --justfile

# Configuration - works on both macOS and Linux
dotfiles_dir := env_var_or_default("DOTFILES_DIR", home_dir() / "src" / "dotfiles")
log_file := home_dir() / "install.log"

# Detect OS for informational purposes
[private]
detect-os:
    @if [ "$(uname -s)" = "Darwin" ]; then \
        echo "macOS detected"; \
    else \
        echo "Linux detected"; \
    fi

# Show available recipes
default:
    @just --list

# Install all components and configurations
install: check-requirements brew-deps zsh docker rust tmux git
    @echo "Full installation complete. Please restart your terminal."

# Install Homebrew and Brewfile packages (macOS only)
brew-deps:
    #!/usr/bin/env bash
    if [ "$(uname -s)" = "Darwin" ]; then
      echo "Installing Homebrew packages from Brewfile..."
      if ! command -v brew &>/dev/null; then
        echo "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
      fi
      brew bundle install --file="{{dotfiles_dir}}/Brewfile"
    else
      echo "Skipping Brewfile (macOS only)"
    fi

# Install and configure zsh only (macOS Homebrew / Linux apt)
zsh:
    @echo "Installing and configuring zsh..."
    ./install.sh ensure_zsh
    ./install.sh setup_home_files

# Install and configure docker only (Linux-specific, skipped on macOS)
docker:
    @echo "Installing and configuring docker for linux..."
    @if [ "$(uname -s)" != "Darwin" ]; then \
        ./install.sh install_docker; \
    else \
        echo "Docker installation is for Linux"; \
    fi

# Install and configure rust only (cross-platform)
rust:
    @echo "Installing and configuring rust..."
    ./install.sh rust_install

# Install and configure tmux only (macOS Homebrew / Linux apt)
tmux:
    @echo "Installing and configuring tmux..."
    ./install.sh tmux_install

# Configure git settings only (cross-platform)
git:
    @echo "Setting up git configuration..."
    ./install.sh setup_git_repo

# Remove all installed configurations (cross-platform)
uninstall:
    #!/usr/bin/env bash
    for file in "{{dotfiles_dir}}"/_*; do
      if [ -e "$file" ]; then
        ./install.sh unlink_file "$(basename "$file")"
      fi
    done
    echo "Uninstall complete. Some components may need manual removal."

# Clean up temporary files (macOS and Linux compatible)
clean:
    @echo "Cleaning up..."
    rm -f "{{log_file}}"
    find . -name "*.log" -delete
    find . -name "*.bak" -delete
    @echo "Cleanup complete"

# Check for required commands (both platforms)
check-requirements:
    @command -v git >/dev/null 2>&1 || { echo "git is required but not installed. Aborting." >&2; exit 1; }
    @command -v curl >/dev/null 2>&1 || { echo "curl is required but not installed. Aborting." >&2; exit 1; }

# Initialize the environment (cross-platform)
init: check-requirements
    mkdir -p "{{home_dir()}}/src"
    mkdir -p "{{home_dir()}}/.ssh"
    touch "{{log_file}}"
    @echo "Environment initialized"

# Full setup: init + install all components
setup: init install
    @echo "Setup complete!"
