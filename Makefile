# 色設定
COLOR_BLUE := \033[0;34m
COLOR_GREEN := \033[0;32m
COLOR_RESET := \033[0m
COLOR_YELLOW := \033[0;33m

# 変数設定
DOTFILES_DIR := $(HOME)/dotfiles
CONFIG_DIR := $(DOTFILES_DIR)/config

.PHONY: all brew ln-git ln-zsh ln-bash ln-vim ln-code-mcp ln-claude-mcp ln-windsurf-mcp plugins brew-setup update-brew install

# すべてのターゲットを実行
all: brew ln-git ln-zsh ln-bash ln-vim ln-code-mcp ln-claude-mcp ln-windsurf-mcp plugins

# シンボリックリンクの作成 - Git設定
ln-git:
	@echo "$(COLOR_BLUE)🔗 Creating Git symbolic links...$(COLOR_RESET)"
	@ln -sf "$(CONFIG_DIR)/git/.gitconfig" "$(HOME)/.gitconfig"
	@ln -sf "$(CONFIG_DIR)/git/.gitignore_global" "$(HOME)/.gitignore_global"
	@ln -sf "$(CONFIG_DIR)/git/.gitmessage" "$(HOME)/.gitmessage"
	@echo "$(COLOR_GREEN)Git symbolic links created successfully.$(COLOR_RESET)"

# シンボリックリンクの作成 - Zsh設定
ln-zsh:
	@echo "$(COLOR_BLUE)🔗 Creating Zsh symbolic links...$(COLOR_RESET)"
	@ln -sf "$(CONFIG_DIR)/zsh/.zprofile" "$(HOME)/.zprofile"
	@ln -sf "$(CONFIG_DIR)/zsh/.zshrc" "$(HOME)/.zshrc"
	@mkdir -p "$(HOME)/.config/zsh"
	@ln -sf "$(CONFIG_DIR)/zsh/aliases.zsh" "$(HOME)/.config/zsh/aliases.zsh"
	@echo "$(COLOR_GREEN)Zsh symbolic links created successfully.$(COLOR_RESET)"

# シンボリックリンクの作成 - Bash設定
ln-bash:
	@echo "$(COLOR_BLUE)🔗 Creating Bash symbolic links...$(COLOR_RESET)"
	@ln -sf "$(CONFIG_DIR)/bash/.bash_profile" "$(HOME)/.bash_profile"
	@ln -sf "$(CONFIG_DIR)/bash/.bashrc" "$(HOME)/.bashrc"
	@echo "$(COLOR_GREEN)Bash symbolic links created successfully.$(COLOR_RESET)"

# シンボリックリンクの作成 - Vim設定
ln-vim:
	@echo "$(COLOR_BLUE)🔗 Creating Vim symbolic links...$(COLOR_RESET)"
	@ln -sf "$(CONFIG_DIR)/vim/.vimrc" "$(HOME)/.vimrc"
	@echo "$(COLOR_GREEN)Vim symbolic links created successfully.$(COLOR_RESET)"

# シンボリックリンクの作成 - MCP設定
ln-code-mcp:
	@ln -sf "$(CONFIG_DIR)/mcp/secrets.jsonnet.template" "$(HOME)/Library/Application Support/Code/User/settings.json"
	@mkdir -p "$(HOME)/Library/Application Support/Code/User/globalStorage/rooveterinaryinc.roo-cline/settings/mcp_settings.json"
	@ln -sf "$(CONFIG_DIR)/mcp/mcp_settings.json" "$(HOME)/Library/Application Support/Code/User/globalStorage/rooveterinaryinc.roo-cline/settings/mcp_settings.json"

ln-claude-mcp:
	@mkdir -p "$(HOME)/Library/Application Support/Claude"
	@ln -sf "$(CONFIG_DIR)/mcp/claude.json" "$(HOME)/Library/Application Support/Claude/claude_desktop_config.json"

ln-windsurf-mcp:
	@mkdir -p "$(HOME)/.codeium/windsurf"
	@ln -sf "$(CONFIG_DIR)/mcp/windsurf.json" "$(HOME)/.codeium/windsurf/mcp_config.json"

# すべてのシンボリックリンクを作成
symlinks: ln-git ln-zsh ln-bash ln-vim ln-code-mcp ln-claude-mcp ln-windsurf-mcp
	@echo "$(COLOR_GREEN)All symbolic links created successfully.$(COLOR_RESET)"


# Homebrewのインストール
brew-setup:
	@echo "$(COLOR_BLUE)📦 Setting up Homebrew$(COLOR_RESET)"
	@if ! command -v brew > /dev/null; then \
		echo "$(COLOR_BLUE)Homebrew not installed. Installing.$(COLOR_RESET)"; \
		/bin/bash -c "$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; \
		echo 'eval "$$/opt/homebrew/bin/brew shellenv"' >> "$(HOME)/.zprofile"; \
		eval "$$/opt/homebrew/bin/brew shellenv"; \
	else \
		echo "$(COLOR_GREEN)✅ Homebrew is already installed$(COLOR_RESET)"; \
	fi

# Homebrewパッケージのインストール
brew: brew-setup
	@echo "$(COLOR_BLUE)📦 Installing packages from Brewfile...$(COLOR_RESET)"
	@brew bundle --file="$(DOTFILES_DIR)/Brewfile"
	@echo "$(COLOR_GREEN)Brew packages installed successfully.$(COLOR_RESET)"

# Brewfileの更新
update-brew:
	@echo "$(COLOR_BLUE)Updating Brewfile$(COLOR_RESET)"
	@brew bundle dump --force
	@echo "$(COLOR_GREEN)Brewfile updated.$(COLOR_RESET)"

cleanup-brew:
	@echo "$(COLOR_BLUE)Cleaning up Homebrew$(COLOR_RESET)"
	@brew bundle --cleanup
	@echo "$(COLOR_GREEN)Homebrew cleanup completed.$(COLOR_RESET)"

# Oh My Zshとプラグインのインストール
plugins:
	@if [ ! -d "$(HOME)/.oh-my-zsh" ]; then \
		echo "$(COLOR_BLUE)🔧 Installing Oh My Zsh...$(COLOR_RESET)"; \
		sh -c "$$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended; \
	else \
		echo "$(COLOR_GREEN)✅ Oh My Zsh is already installed$(COLOR_RESET)"; \
	fi

	@if [ ! -d "$${ZSH_CUSTOM:-$(HOME)/.oh-my-zsh/custom}/plugins/zsh-autosuggestions" ]; then \
		echo "$(COLOR_BLUE)🔌 Installing zsh-autosuggestions...$(COLOR_RESET)"; \
		git clone https://github.com/zsh-users/zsh-autosuggestions $${ZSH_CUSTOM:-$(HOME)/.oh-my-zsh/custom}/plugins/zsh-autosuggestions; \
	fi

	@if [ ! -d "$${ZSH_CUSTOM:-$(HOME)/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting" ]; then \
		echo "$(COLOR_BLUE)🔌 Installing zsh-syntax-highlighting...$(COLOR_RESET)"; \
		git clone https://github.com/zsh-users/zsh-syntax-highlighting $${ZSH_CUSTOM:-$(HOME)/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting; \
	fi

	@if [ ! -f "$(HOME)/.fzf.zsh" ]; then \
		echo "$(COLOR_BLUE)🔍 Installing fzf...$(COLOR_RESET)"; \
		$$(brew --prefix)/opt/fzf/install --all; \
	fi
	@echo "$(COLOR_GREEN)Plugins installed successfully.$(COLOR_RESET)"
