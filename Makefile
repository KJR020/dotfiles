# Define color variables
COLOR_BLUE := \033[0;34m
COLOR_GREEN := \033[0;32m
COLOR_RESET := \033[0m

# Do everything.
all: init link defaults brew setup

# Set initial preference.
init:
	@echo "$(COLOR_BLUE)Run init.sh$(COLOR_RESET)"
	.bin/mac/install.sh all
	@echo "$(COLOR_GREEN)Done.$(COLOR_RESET)"

# Link dotfiles.
link:
	@echo "$(COLOR_BLUE)Run link.sh$(COLOR_RESET)"
	.bin/mac/install.sh link
	@echo "$(COLOR_GREEN)Done.$(COLOR_RESET)"

# Install macOS applications.
brew:
	@echo "$(COLOR_BLUE)Run brew.sh$(COLOR_RESET)"
	.bin/brew.sh
	@echo "$(COLOR_GREEN)Done.$(COLOR_RESET)"

# Set executable permissions and run setup process.
setup:
	@echo "$(COLOR_BLUE)Setting executable permissions and running setup.sh$(COLOR_RESET)"
	chmod +x symlinks.sh homebrew.sh shell.sh git.sh
	@echo "$(COLOR_BLUE)Creating symlinks$(COLOR_RESET)"
	@echo "$(COLOR_BLUE)Creating zshrc symlinks$(COLOR_RESET)"
	@if [ ! -e "$$HOME/.zshrc" ]; then \
		ln -s "$(PWD)/.zshrc" "$$HOME/.zshrc"; \
		echo "$(COLOR_GREEN)Added symlink to zshrc at $$HOME/.zshrc$(COLOR_RESET)"; \
	else \
		echo "$$HOME/.zshrc already exists... Skipping."; \
	fi
	@echo "$(COLOR_BLUE)Creating vim symlinks$(COLOR_RESET)"
	@if [ ! -e "$$HOME/.vimrc" ]; then \
		ln -s "$(PWD)/.vimrc" "$$HOME/.vimrc"; \
		echo "$(COLOR_GREEN)Added symlink to vimrc at $$HOME/.vimrc$(COLOR_RESET)"; \
	else \
		echo "$$HOME/.vimrc already exists... Skipping."; \
	fi

	@echo "$(COLOR_BLUE)Setting up Homebrew$(COLOR_RESET)"
	@sudo apt update
	@sudo apt install -y build-essential
	@if ! command -v brew > /dev/null; then \
		echo "$(COLOR_BLUE)Homebrew not installed. Installing.$(COLOR_RESET)"; \
		/bin/bash -c "$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"; \
	fi
	@echo "$(COLOR_GREEN)Setup complete.$(COLOR_RESET)"