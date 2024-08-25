#!/bin/bash
COLOR_BLUE="\033[1;34m"
COLOR_NONE="\033[0m"

info() {
    echo -e "${COLOR_BLUE}Info: ${COLOR_NONE}$1"
}

setup_homebrew() {
    info "Setting up Homebrew"
    sudo apt update
    sudo apt install build-essential

    if test ! "$(command -v brew)"; then
        info "Homebrew not installed. Installing."
        curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh | bash --login
    fi

    brew bundle
}

setup_homebrew