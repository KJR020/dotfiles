# 変数設定
DOTFILES_DIR := $(HOME)/dotfiles
HOME_DIR := $(DOTFILES_DIR)/home

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

.PHONY: init apply update diff test install install-homebrew install-oh-my-zsh update-brew cleanup-brew help

.DEFAULT_GOAL := help

help: ## ヘルプメッセージを表示
	@echo "Available targets:"
	@echo ""
	@echo "  Chezmoi Commands:"
	@grep -E '^(init|apply|update|diff|test):.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "    \033[36m%-20s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo "  Installation Commands:"
	@grep -E '^(install|install-homebrew|install-oh-my-zsh):.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "    \033[36m%-20s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo "  Other Commands:"
	@grep -E '^(update-brew|cleanup-brew):.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "    \033[36m%-20s\033[0m %s\n", $$1, $$2}'

# ----------------------------
# Chezmoi Commands
# ----------------------------

init: ## chezmoiを初期化
	$(call print_info,Initializing chezmoi)
	@chezmoi init --source=$(HOME_DIR)
	$(call print_success,Chezmoi initialized)

apply: ## chezmoiでdotfilesを適用
	$(call print_info,Applying dotfiles with chezmoi)
	@chezmoi apply -v
	$(call print_success,Dotfiles applied)

update: ## chezmoiでdotfilesを更新
	$(call print_info,Updating dotfiles with chezmoi)
	@chezmoi update -v
	$(call print_success,Dotfiles updated)

diff: ## chezmoiで差分を確認
	@chezmoi diff

test: ## Batsでテストを実行
	$(call print_info,Running tests with Bats)
	@bats $(DOTFILES_DIR)/tests/*.bats
	$(call print_success,Tests passed)

# ----------------------------
# Installation Commands
# ----------------------------

install: ## 全てのインストールを実行 (Homebrew + Oh My Zsh + chezmoi apply)
	$(call print_info,Running full installation)
	@bash $(DOTFILES_DIR)/install/install-all.sh
	@$(MAKE) init
	@$(MAKE) apply
	$(call print_success,Installation completed)

install-homebrew: ## Homebrewとパッケージをインストール
	@bash $(DOTFILES_DIR)/install/install-homebrew.sh

install-oh-my-zsh: ## Oh My Zshとプラグインをインストール
	@bash $(DOTFILES_DIR)/install/install-oh-my-zsh.sh

# ----------------------------
# Other Commands
# ----------------------------

update-brew: ## 現在インストールされているパッケージでBrewfileを更新
	$(call print_info,Updating Brewfile)
	@brew bundle dump --force
	$(call print_success,Brewfile updated)

cleanup-brew: ## Homebrewのクリーンアップ
	$(call print_info,Cleaning up Homebrew)
	@brew bundle --cleanup
	$(call print_success,Homebrew cleanup completed)
