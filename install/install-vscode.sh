#!/usr/bin/env bash

set -euo pipefail

# カラー出力用
readonly COLOR_BLUE="\033[0;34m"
readonly COLOR_GREEN="\033[0;32m"
readonly COLOR_RESET="\033[0m"

print_info() {
    echo -e "${COLOR_BLUE}▶ $1${COLOR_RESET}"
}

print_success() {
    echo -e "${COLOR_GREEN}✓ $1${COLOR_RESET}"
}

# VS Code設定のセットアップ
setup_vscode() {
    if ! command -v code &> /dev/null; then
        echo "VS Code is not installed. Skipping."
        return 0
    fi

    # macOSの場合、キーリピート設定を変更
    if [[ "$OSTYPE" == "darwin"* ]]; then
        print_info "Configuring VS Code for macOS"
        defaults write com.microsoft.VSCode ApplePressAndHoldEnabled -bool false
        print_success "macOS settings applied"
    fi

    # 拡張機能のインストール
    print_info "Installing VS Code extensions"

    local extensions=(
        "ms-python.python"
        "ms-vscode.cpptools"
        "esbenp.prettier-vscode"
    )

    for ext in "${extensions[@]}"; do
        if code --list-extensions | grep -q "^${ext}$"; then
            print_success "$ext already installed"
        else
            print_info "Installing $ext"
            code --install-extension "$ext"
            print_success "$ext installed"
        fi
    done
}

# メイン処理
main() {
    setup_vscode
}

main "$@"
