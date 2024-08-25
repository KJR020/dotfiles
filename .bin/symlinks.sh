#!/bin/bash
DOTFILES="$(pwd)"
COLOR_BLUE="\033[1;34m"
COLOR_NONE="\033[0m"

info() {
    echo -e "${COLOR_BLUE}Info: ${COLOR_NONE}$1"
}

setup_symlinks() {
    info "Creating zshrc symlinks"
    zshrc=$DOTFILES/.zshrc
    if [ ! -e "$HOME/.zshrc" ]; then
        info "Adding symlink to zshrc at $HOME/.zshrc"
        ln -s "$zshrc" ~/.zshrc
    else
        info "$HOME/.zshrc already exists... Skipping."
    fi
    
    info "Creating vim symlinks"
    vimrc=$DOTFILES/.vimrc
    if [ ! -e "$HOME/.vimrc" ]; then
        info "Adding symlink to vimrc at $HOME/.vimrc"
        ln -s "$vimrc" ~/.vimrc
    else
        info "~/.vimrc already exists... Skipping."
    fi
}

setup_symlinks