# Define color variables
COLOR_BLUE := \033[0;34m
COLOR_GREEN := \033[0;32m
COLOR_RESET := \033[0m

# Do everything.
all: init link defaults brew

# Set initial preference.
init:
	@echo "$(COLOR_BLUE)Run init.sh$(COLOR_RESET)"
	.bin/mac/install.sh all
	@echo "$(COLOR_BLUE)Done.$(COLOR_RESET)"

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

