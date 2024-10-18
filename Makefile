# 色設定
COLOR_BLUE := \033[0;34m
COLOR_GREEN := \033[0;32m
COLOR_RESET := \033[0m

# すべてのターゲットを実行
all: setup brew

setup:

  # symlinkを作成
	@echo "$(COLOR_BLUE)Creating symlinks$(COLOR_RESET)"
  ## .zshrcのsymlinkを作成
	@echo "$(COLOR_BLUE)Creating zshrc symlinks$(COLOR_RESET)"
  ### zshrcがすでに存在するかチェック
	@if [ ! -e "$$HOME/.zshrc" ]; then \
		ln -s "$(PWD)/.zshrc" "$$HOME/.zshrc"; \
		echo "$(COLOR_GREEN)Added symlink to zshrc at $$HOME/.zshrc$(COLOR_RESET)"; \
	else \
		echo "$$HOME/.zshrc already exists... Skipping."; \
	fi
  ## .vimrcのsymlinkを作成
	@echo "$(COLOR_BLUE)Creating vim symlinks$(COLOR_RESET)"
  ### .vimrcがすでに存在するかチェック
	@if [ ! -e "$$HOME/.vimrc" ]; then \
		ln -s "$(PWD)/.vimrc" "$$HOME/.vimrc"; \
		echo "$(COLOR_GREEN)Added symlink to vimrc at $$HOME/.vimrc$(COLOR_RESET)"; \
	else \
		echo "$$HOME/.vimrc already exists... Skipping."; \
	fi

  # Homebrewの設定
	@echo "$(COLOR_BLUE)Setting up Homebrew$(COLOR_RESET)"
  ## Homebrewのinstall
	@sudo apt update
	@sudo apt install -y build-essential
	@if ! command -v brew > /dev/null; then \
		echo "$(COLOR_BLUE)Homebrew not installed. Installing.$(COLOR_RESET)"; \
		/bin/bash -c "$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"; \
	fi
	@echo "$(COLOR_GREEN)Setup complete.$(COLOR_RESET)"

# Install macOS applications.
brew:
	@echo "$(COLOR_BLUE)Run brew.sh$(COLOR_RESET)"
	.bin/brew.sh
	@echo "$(COLOR_GREEN)Done.$(COLOR_RESET)"