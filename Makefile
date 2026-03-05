# 変数設定
DOTFILES_DIR := $(HOME)/dotfiles
HOME_DIR := $(DOTFILES_DIR)/home
DEVTOOLS_DIR := $(CURDIR)/devtools
BREW_PROFILE ?= profile1
BREWFILE := $(DEVTOOLS_DIR)/brew/$(BREW_PROFILE).Brewfile
VOLTA_PACKAGES_FILE := $(DEVTOOLS_DIR)/volta/packages.txt
UV_TOOLS_FILE := $(DEVTOOLS_DIR)/uv/tools.txt

.PHONY: init apply update diff test install install-homebrew install-oh-my-zsh \
	update-brew check-brew cleanup-brew \
	brew-sync brew-dump brew-check brew-cleanup \
	volta-sync uv-sync

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

brew-sync: ## Homebrewを定義ファイルに合わせて適用 (例: make brew-sync BREW_PROFILE=profile2)
	@[ -f "$(BREWFILE)" ] || (echo "Brewfile not found: $(BREWFILE)" && exit 1)
	@brew bundle --file "$(BREWFILE)"

brew-dump: ## 現在環境をBrewfileへ反映 (例: make brew-dump BREW_PROFILE=profile2)
	@[ -f "$(BREWFILE)" ] || (echo "Brewfile not found: $(BREWFILE)" && exit 1)
	@brew bundle dump --file "$(BREWFILE)" --force

brew-check: ## Brewfileとインストール済みパッケージの整合性を確認
	@[ -f "$(BREWFILE)" ] || (echo "Brewfile not found: $(BREWFILE)" && exit 1)
	@brew bundle check --file "$(BREWFILE)"

brew-cleanup: ## BrewfileにないHomebrewパッケージをクリーンアップ
	@[ -f "$(BREWFILE)" ] || (echo "Brewfile not found: $(BREWFILE)" && exit 1)
	@brew bundle cleanup --file "$(BREWFILE)" --force

volta-sync: ## devtools/volta/packages.txt のCLIをVoltaで同期
	@[ -f "$(VOLTA_PACKAGES_FILE)" ] || (echo "Volta packages file not found: $(VOLTA_PACKAGES_FILE)" && exit 1)
	@grep -Ev '^\s*(#|$$)' "$(VOLTA_PACKAGES_FILE)" | while read -r pkg; do \
		echo "volta install $$pkg"; \
		volta install "$$pkg"; \
	done

uv-sync: ## devtools/uv/tools.txt のCLIをuv toolで同期
	@[ -f "$(UV_TOOLS_FILE)" ] || (echo "uv tools file not found: $(UV_TOOLS_FILE)" && exit 1)
	@grep -Ev '^\s*(#|$$)' "$(UV_TOOLS_FILE)" | while read -r tool; do \
		echo "uv tool install $$tool"; \
		uv tool install "$$tool"; \
	done

update-brew: brew-dump ## 互換: 現在インストールされているパッケージでBrewfileを更新
check-brew: brew-check ## 互換: brewfileとインストール済みパッケージの整合性を確認
cleanup-brew: brew-cleanup ## 互換: Homebrewのクリーンアップ
