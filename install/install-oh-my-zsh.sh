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

# Oh My Zshのインストール
install_oh_my_zsh() {
    print_info "Checking Oh My Zsh installation"

    if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
        print_info "Installing Oh My Zsh"
        sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
        print_success "Oh My Zsh installed"
    else
        print_success "Oh My Zsh already installed"
    fi
}

# Zshプラグインのインストール
install_zsh_plugins() {
    local zsh_custom="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

    # zsh-autosuggestions
    if [[ ! -d "$zsh_custom/plugins/zsh-autosuggestions" ]]; then
        print_info "Installing zsh-autosuggestions"
        git clone https://github.com/zsh-users/zsh-autosuggestions "$zsh_custom/plugins/zsh-autosuggestions"
        print_success "zsh-autosuggestions installed"
    else
        print_success "zsh-autosuggestions already installed"
    fi

    # zsh-syntax-highlighting
    if [[ ! -d "$zsh_custom/plugins/zsh-syntax-highlighting" ]]; then
        print_info "Installing zsh-syntax-highlighting"
        git clone https://github.com/zsh-users/zsh-syntax-highlighting "$zsh_custom/plugins/zsh-syntax-highlighting"
        print_success "zsh-syntax-highlighting installed"
    else
        print_success "zsh-syntax-highlighting already installed"
    fi

    # zsh-completions
    if [[ ! -d "$zsh_custom/plugins/zsh-completions" ]]; then
        print_info "Installing zsh-completions"
        git clone https://github.com/zsh-users/zsh-completions "$zsh_custom/plugins/zsh-completions"
        print_success "zsh-completions installed"
    else
        print_success "zsh-completions already installed"
    fi
}

# fzfのインストール
install_fzf() {
    if [[ ! -f "$HOME/.fzf.zsh" ]]; then
        print_info "Installing fzf"
        if command -v brew &> /dev/null; then
            "$(brew --prefix)/opt/fzf/install" --all
            print_success "fzf installed"
        else
            echo "Homebrew not found. Please install Homebrew first."
            exit 1
        fi
    else
        print_success "fzf already installed"
    fi
}

# メイン処理
main() {
    install_oh_my_zsh
    install_zsh_plugins
    install_fzf
}

main "$@"
