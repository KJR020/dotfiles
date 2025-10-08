#!/usr/bin/env bash

set -euo pipefail

# スクリプトのディレクトリを取得
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# カラー出力用
readonly COLOR_BLUE="\033[0;34m"
readonly COLOR_GREEN="\033[0;32m"
readonly COLOR_YELLOW="\033[0;33m"
readonly COLOR_RESET="\033[0m"

print_info() {
    echo -e "${COLOR_BLUE}▶ $1${COLOR_RESET}"
}

print_success() {
    echo -e "${COLOR_GREEN}✓ $1${COLOR_RESET}"
}

print_warning() {
    echo -e "${COLOR_YELLOW}⚠ $1${COLOR_RESET}"
}

# メイン処理
main() {
    print_info "Starting dotfiles installation"

    # 1. Homebrewとパッケージのインストール
    if [[ -f "$SCRIPT_DIR/install-homebrew.sh" ]]; then
        bash "$SCRIPT_DIR/install-homebrew.sh"
    else
        print_warning "install-homebrew.sh not found, skipping"
    fi

    # 2. Oh My Zshとプラグインのインストール
    if [[ -f "$SCRIPT_DIR/install-oh-my-zsh.sh" ]]; then
        bash "$SCRIPT_DIR/install-oh-my-zsh.sh"
    else
        print_warning "install-oh-my-zsh.sh not found, skipping"
    fi

    # 3. VS Codeのセットアップ
    if [[ -f "$SCRIPT_DIR/install-vscode.sh" ]]; then
        bash "$SCRIPT_DIR/install-vscode.sh"
    else
        print_warning "install-vscode.sh not found, skipping"
    fi

    print_success "All installations completed!"
    echo ""
    print_info "Next steps:"
    echo "  1. Install chezmoi: brew install chezmoi"
    echo "  2. Initialize chezmoi: chezmoi init --source ~/dotfiles/home"
    echo "  3. Apply dotfiles: chezmoi apply"
}

main "$@"
