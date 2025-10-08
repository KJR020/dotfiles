# 変数設定
DOTFILES_DIR := $(HOME)/dotfiles
CONFIG_DIR := $(DOTFILES_DIR)/config

# メッセージ表示関数
define print_info
	@echo "\033[0;34m▶ $(1)\033[0m"
endef

define print_success
	@echo "\033[0;32m✓ $(1)\033[0m"
endef

define print_warning
	@echo "\033[0;33m⚠ $(1)\033[0m"
endef

.PHONY: all brew ln-git ln-zsh ln-bash ln-vim ln-code-mcp ln-claude-mcp ln-windsurf-mcp plugins brew-setup update-brew install help

.DEFAULT_GOAL := help

help: ## ヘルプメッセージを表示
	@echo "Available targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

all: brew ln-git ln-zsh ln-bash ln-vim ln-code-mcp ln-claude-mcp ln-windsurf-mcp plugins ## 全てのセットアップタスクを実行

ln-git: ## Git設定のセットアップ
	$(call print_info,Creating Git symbolic links)
	@ln -sf "$(CONFIG_DIR)/git/.gitconfig" "$(HOME)/.gitconfig"
	@ln -sf "$(CONFIG_DIR)/git/.gitignore_global" "$(HOME)/.gitignore_global"
	@ln -sf "$(CONFIG_DIR)/git/.gitmessage" "$(HOME)/.gitmessage"
	$(call print_success,Git configured)

ln-zsh: ## Zsh設定のセットアップ
	$(call print_info,Creating Zsh symbolic links)
	@ln -sf "$(CONFIG_DIR)/zsh/.zprofile" "$(HOME)/.zprofile"
	@ln -sf "$(CONFIG_DIR)/zsh/.zshrc" "$(HOME)/.zshrc"
	@mkdir -p "$(HOME)/.config/zsh"
	@ln -sf "$(CONFIG_DIR)/zsh/aliases.zsh" "$(HOME)/.config/zsh/aliases.zsh"
	$(call print_success,Zsh configured)

ln-bash: ## Bash設定のセットアップ
	$(call print_info,Creating Bash symbolic links)
	@ln -sf "$(CONFIG_DIR)/bash/.bash_profile" "$(HOME)/.bash_profile"
	@ln -sf "$(CONFIG_DIR)/bash/.bashrc" "$(HOME)/.bashrc"
	$(call print_success,Bash configured)

ln-vim: ## Vim設定のセットアップ
	$(call print_info,Creating Vim symbolic links)
	@ln -sf "$(CONFIG_DIR)/vim/.vimrc" "$(HOME)/.vimrc"
	$(call print_success,Vim configured)

ln-code-mcp: ## VSCode MCP設定のセットアップ
	$(call print_info,Creating VSCode MCP symbolic links)
	@ln -sf "$(CONFIG_DIR)/mcp/secrets.jsonnet.template" "$(HOME)/Library/Application Support/Code/User/settings.json"
	@mkdir -p "$(HOME)/Library/Application Support/Code/User/globalStorage/rooveterinaryinc.roo-cline/settings/mcp_settings.json"
	@ln -sf "$(CONFIG_DIR)/mcp/mcp_settings.json" "$(HOME)/Library/Application Support/Code/User/globalStorage/rooveterinaryinc.roo-cline/settings/mcp_settings.json"
	$(call print_success,VSCode MCP configured)

ln-claude-mcp: ## Claude MCP設定のセットアップ
	$(call print_info,Creating Claude MCP symbolic links)
	@mkdir -p "$(HOME)/Library/Application Support/Claude"
	@ln -sf "$(CONFIG_DIR)/mcp/mcp_settings.json" "$(HOME)/Library/Application Support/Claude/claude_desktop_config.json"
	$(call print_success,Claude MCP configured)

ln-windsurf-mcp: ## Windsurf MCP設定のセットアップ
	$(call print_info,Creating Windsurf MCP symbolic links)
	@mkdir -p "$(HOME)/.codeium/windsurf"
	@ln -sf "$(CONFIG_DIR)/mcp/windsurf.json" "$(HOME)/.codeium/windsurf/mcp_config.json"
	$(call print_success,Windsurf MCP configured)

symlinks: ln-git ln-zsh ln-bash ln-vim ln-code-mcp ln-claude-mcp ln-windsurf-mcp ## 全てのシンボリックリンクを作成
	$(call print_success,All symbolic links created)


brew-setup: ## Homebrewをインストール(未インストールの場合)
	$(call print_info,Checking Homebrew installation)
	@if ! command -v brew > /dev/null; then \
		$(call print_info,Installing Homebrew); \
		/bin/bash -c "$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; \
		echo 'eval "$$/opt/homebrew/bin/brew shellenv"' >> "$(HOME)/.zprofile"; \
		eval "$$/opt/homebrew/bin/brew shellenv"; \
		$(call print_success,Homebrew installed); \
	else \
		$(call print_success,Homebrew already installed); \
	fi

brew: brew-setup ## Brewfileからパッケージをインストール
	$(call print_info,Installing packages from Brewfile)
	@brew bundle --file="$(DOTFILES_DIR)/Brewfile"
	$(call print_success,Packages installed)

update-brew: ## 現在インストールされているパッケージでBrewfileを更新
	$(call print_info,Updating Brewfile)
	@brew bundle dump --force
	$(call print_success,Brewfile updated)

cleanup-brew: ## Homebrewのクリーンアップ
	$(call print_info,Cleaning up Homebrew)
	@brew bundle --cleanup
	$(call print_success,Homebrew cleanup completed)

plugins: ## Oh My Zshとシェルプラグインをインストール
	$(call print_info,Checking Oh My Zsh installation)
	@if [ ! -d "$(HOME)/.oh-my-zsh" ]; then \
		$(call print_info,Installing Oh My Zsh); \
		sh -c "$$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended; \
		$(call print_success,Oh My Zsh installed); \
	else \
		$(call print_success,Oh My Zsh already installed); \
	fi

	@if [ ! -d "$${ZSH_CUSTOM:-$(HOME)/.oh-my-zsh/custom}/plugins/zsh-autosuggestions" ]; then \
		$(call print_info,Installing zsh-autosuggestions); \
		git clone https://github.com/zsh-users/zsh-autosuggestions $${ZSH_CUSTOM:-$(HOME)/.oh-my-zsh/custom}/plugins/zsh-autosuggestions; \
	fi

	@if [ ! -d "$${ZSH_CUSTOM:-$(HOME)/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting" ]; then \
		$(call print_info,Installing zsh-syntax-highlighting); \
		git clone https://github.com/zsh-users/zsh-syntax-highlighting $${ZSH_CUSTOM:-$(HOME)/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting; \
	fi

	@if [ ! -f "$(HOME)/.fzf.zsh" ]; then \
		$(call print_info,Installing fzf); \
		$$(brew --prefix)/opt/fzf/install --all; \
	fi
	$(call print_success,Plugins installed)
