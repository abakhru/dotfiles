.PHONY: all install uninstall clean help zsh docker rust tmux git

# Default target
all: help

# Colors for output
YELLOW := \033[1;33m
NC := \033[0m

# Installation paths
HOME_DIR := $(HOME)
DOTFILES_DIR := $(HOME)/src/dotfiles
LOG_FILE := $(HOME)/install.log

help:
	@echo "$(YELLOW)Available targets:$(NC)"
	@echo "  install    - Install all components and configurations"
	@echo "  uninstall  - Remove all installed components"
	@echo "  clean      - Clean up temporary files"
	@echo "  zsh        - Install and configure zsh only"
	@echo "  docker     - Install and configure docker only"
	@echo "  rust       - Install and configure rust only"
	@echo "  tmux       - Install and configure tmux only"
	@echo "  git        - Configure git settings only"

install: zsh docker rust tmux git
	@echo "$(YELLOW)Full installation complete. Please restart your terminal.$(NC)"

zsh:
	@echo "$(YELLOW)Installing and configuring zsh...$(NC)"
	./install.sh ensure_zsh
	./install.sh setup_home_files

docker:
	@echo "$(YELLOW)Installing and configuring docker...$(NC)"
	./install.sh install_docker

rust:
	@echo "$(YELLOW)Installing and configuring rust...$(NC)"
	./install.sh rust_install

tmux:
	@echo "$(YELLOW)Installing and configuring tmux...$(NC)"
	./install.sh tmux_install

git:
	@echo "$(YELLOW)Setting up git configuration...$(NC)"
	./install.sh setup_git_repo

uninstall:
	@echo "$(YELLOW)Uninstalling configurations...$(NC)"
	@for file in $(DOTFILES_DIR)/_*; do \
		./install.sh unlink_file "$$(basename $$file)"; \
	done
	@echo "$(YELLOW)Uninstall complete. Some components may need manual removal.$(NC)"

clean:
	@echo "$(YELLOW)Cleaning up...$(NC)"
	@rm -f $(LOG_FILE)
	@find . -name "*.log" -delete
	@find . -name "*.bak" -delete
	@echo "$(YELLOW)Cleanup complete$(NC)"

# Check for required commands
check-requirements:
	@command -v git >/dev/null 2>&1 || { echo "git is required but not installed. Aborting." >&2; exit 1; }
	@command -v curl >/dev/null 2>&1 || { echo "curl is required but not installed. Aborting." >&2; exit 1; }

# Initialize the environment
init: check-requirements
	@mkdir -p $(HOME_DIR)/src
	@mkdir -p $(HOME_DIR)/.ssh
	@touch $(LOG_FILE)
