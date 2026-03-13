# 変数設定
DOTFILES_DIR := $(CURDIR)
HOME_DIR := $(DOTFILES_DIR)/home
DEVTOOLS_DIR := $(CURDIR)/devtools
BREW_PROFILE ?= profile1
BREWFILE := $(DEVTOOLS_DIR)/brew/$(BREW_PROFILE).Brewfile
VOLTA_PACKAGES_FILE := $(DEVTOOLS_DIR)/volta/packages.txt
UV_TOOLS_FILE := $(DEVTOOLS_DIR)/uv/tools.txt
DMG_PACKAGES_FILE := $(DEVTOOLS_DIR)/dmg/packages.txt

# 非ログインシェルでもHomebrewコマンドを解決できるようにする（macOS）
ifeq ($(shell uname -s),Darwin)
PATH := /opt/homebrew/bin:/opt/homebrew/sbin:$(PATH)
endif

.PHONY: init apply update diff test install help \
	update-brew check-brew cleanup-brew \
	brew-sync brew-dump brew-check brew-cleanup \
	volta-sync uv-sync dmg-sync

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

install: ## 初期セットアップ（chezmoi init/apply）
	@$(MAKE) init
	@$(MAKE) apply

help: ## ターゲット一覧を表示
	@awk 'BEGIN {FS = ":.*## "; printf "\nUsage:\n  make <target>\n\nTargets:\n"} /^[a-zA-Z0-9_-]+:.*## / {printf "  %-16s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

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

dmg-sync: ## DMGアプリをインストール（未インストールのみ）
	@[ -f "$(DMG_PACKAGES_FILE)" ] || (echo "DMG packages file not found: $(DMG_PACKAGES_FILE)" && exit 1)
	@grep -Ev '^\s*(#|$$)' "$(DMG_PACKAGES_FILE)" | while IFS='|' read -r name app_dir arm64_url x64_url; do \
		if [ -d "/Applications/$$app_dir" ]; then \
			echo "✓ $$name already installed"; \
		else \
			echo "Installing $$name..."; \
			if [ "$$(uname -m)" = "arm64" ]; then url="$$arm64_url"; else url="$$x64_url"; fi; \
			tmpfile=$$(mktemp /tmp/dmg-XXXXXX.dmg); \
			curl -fsSL -o "$$tmpfile" "$$url" && \
			volume=$$(hdiutil attach "$$tmpfile" -nobrowse | tail -1 | awk -F'\t' '{print $$NF}') && \
			cp -R "$$volume"/*.app /Applications/ && \
			hdiutil detach "$$volume" -quiet && \
			rm -f "$$tmpfile" && \
			echo "✓ $$name installed" || \
			echo "✗ $$name installation failed"; \
		fi; \
	done

notebooklm-sync: ## Python版 notebooklm-mcp をクローン＆セットアップ
	@NLMCP_DIR="$(HOME)/.local/share/notebooklm-mcp"; \
	if [ ! -d "$$NLMCP_DIR" ]; then \
		echo "Cloning notebooklm-mcp..."; \
		git clone https://github.com/wangjing0/notebooklm-mcp "$$NLMCP_DIR"; \
	else \
		echo "Updating notebooklm-mcp..."; \
		cd "$$NLMCP_DIR" && git pull; \
	fi; \
	cd "$$NLMCP_DIR" && uv sync && uv run playwright install chromium

update-brew: brew-dump ## 互換: 現在インストールされているパッケージでBrewfileを更新
check-brew: brew-check ## 互換: brewfileとインストール済みパッケージの整合性を確認
cleanup-brew: brew-cleanup ## 互換: Homebrewのクリーンアップ
