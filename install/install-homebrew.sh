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

# Homebrewのインストール
install_homebrew() {
    print_info "Checking Homebrew installation"

    if ! command -v brew &> /dev/null; then
        print_info "Installing Homebrew"
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

        # シェル環境変数の設定
        if [[ "$OSTYPE" == "darwin"* ]]; then
            echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$HOME/.zprofile"
            eval "$(/opt/homebrew/bin/brew shellenv)"
        else
            echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> "$HOME/.profile"
            eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
        fi

        print_success "Homebrew installed"
    else
        print_success "Homebrew already installed"
    fi
}

# Brewfileからパッケージをインストール
install_packages() {
    local brewfile="${1:-$HOME/dotfiles/Brewfile}"

    if [[ -f "$brewfile" ]]; then
        print_info "Installing packages from Brewfile"
        brew bundle --file="$brewfile"
        print_success "Packages installed"
    else
        echo "Brewfile not found at $brewfile"
        exit 1
    fi
}

# メイン処理
main() {
    install_homebrew
    install_packages "$@"
}

main "$@"
