# 変数設定
DOTFILES_DIR := $(HOME)/dotfiles
HOME_DIR := $(DOTFILES_DIR)/home


.PHONY: init apply update diff test install install-homebrew install-oh-my-zsh update-brew cleanup-brew 

# ----------------------------
# Chezmoi Commands
# ----------------------------

init: ## chezmoiを初期化
	@chezmoi init --source=$(HOME_DIR)

apply: ## chezmoiでdotfilesを適用
	@chezmoi apply -v

update: ## chezmoiでdotfilesを更新
	@chezmoi update -v

diff: ## chezmoiで差分を確認
	@chezmoi diff

test: ## Batsでテストを実行
	@bats $(DOTFILES_DIR)/tests/*.bats

# ----------------------------
# Installation Commands
# ----------------------------

install: ## 全てのインストールを実行 (Homebrew + Oh My Zsh + chezmoi apply)
	@bash $(DOTFILES_DIR)/install/install-all.sh
	@$(MAKE) init
	@$(MAKE) apply

install-homebrew: ## Homebrewとパッケージをインストール
	@bash $(DOTFILES_DIR)/install/install-homebrew.sh

install-oh-my-zsh: ## Oh My Zshとプラグインをインストール
	@bash $(DOTFILES_DIR)/install/install-oh-my-zsh.sh

# ----------------------------
# Other Commands
# ----------------------------

update-brew: ## 現在インストールされているパッケージでBrewfileを更新
	@brew bundle dump --force

check-brew: ## brewfileとインストール済みパッケージの整合性を確認
	$(call print_info,Checking Homebrew packages against Brewfile)
	@brew bundle check

cleanup-brew: ## Homebrewのクリーンアップ
	@brew bundle --cleanup
