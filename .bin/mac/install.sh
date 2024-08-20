#!/bin/bash

DOTFILES="$(pwd)"
COLOR_GRAY="\033[1;38;5;243m"
COLOR_BLUE="\033[1;34m"
COLOR_GREEN="\033[1;32m"
#COLOR_RED="\033[1;31m"
COLOR_PURPLE="\033[1;35m"
#COLOR_YELLOW="\033[1;33m"
COLOR_NONE="\033[0m"

title() {
    echo "${COLOR_PURPLE}$1${COLOR_NONE}"
    echo "${COLOR_GRAY}==============================${COLOR_NONE}"
}

#error() {
#    echo -e "${COLOR_RED}Error: ${COLOR_NONE}$1"
#    exit 1
#}

#warning() {
#    echo -e "${COLOR_YELLOW}Warning: ${COLOR_NONE}$1"
#}

info() {
    echo "${COLOR_BLUE}Info: ${COLOR_NONE}$1"
}

success() {
    echo "${COLOR_GREEN}$1${COLOR_NONE}"
}

setup_symlinks() {
   title "Creating symlinks"
   
   info "Creating zshrc symlinks"
   zshrc=$DOTFILES/.zshrc
   if [ ! -e "$HOME/.zshrc" ]; then
       info "Adding symlink to zshrc at $HOME/.zshrc"
       ln -s "$zshrc" ~/.zshrc
   else
       info "~/.zshrc already exists... Skipping."
   fi
   
   info "installing to ~/.zsh"
   if [ ! -d "$HOME/.zsh" ]; then
       info "Creating ~/.zsh"
       mkdir -p "$HOME/.zsh"
   fi
   
   zsh_files=$(find "$DOTFILES/zsh" -maxdepth 1 -name '*.zsh')
   for zsh in $zsh_files; do
       target="$HOME/.zsh/$(basename "$zsh")"
       if [ -e "$target" ]; then
           info "~${target#$HOME} already exists... Skipping."
       else
           info "Creating symlink for $zsh"
           ln -s "$zsh" "$target"
       fi
   done
   
   info "Creating vim symlinks"
   vimrc=$DOTFILES/.vimrc
   if [ ! -e "$HOME/.vimrc" ]; then
       info "Adding symlink to vimrc at $HOME/.vimrc"
       ln -s "$vimrc" ~/.vimrc
   else
       info "~/.vimrc already exists... Skipping."
   fi
}

setup_homebrew() {
    title "Setting up Homebrew"

    # wsl2 ubuntu omajinai
    sudo apt update
    sudo apt install build-essential
    #sudo apt install clang

    if test ! "$(command -v brew)"; then
        info "Homebrew not installed. Installing."
        # Run as a login shell (non-interactive) so that the script doesn't pause for user input
        curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh | bash --login
    fi

    if [ "$(uname)" = "Linux" ]; then
        test -d ~/.linuxbrew && eval "$(~/.linuxbrew/bin/brew shellenv)"
        test -d /home/linuxbrew/.linuxbrew && eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
        test -r ~/.bash_profile && echo "eval \$($(brew --prefix)/bin/brew shellenv)" >>~/.bash_profile
        echo "eval \$($(brew --prefix)/bin/brew shellenv)" >>~/.profile
    fi

    # install brew dependencies from Brewfile
    brew bundle
}

setup_shell() {
    title "Configuring shell"

    [ -n "$(command -v brew)" ] && zsh_path="$(brew --prefix)/bin/zsh" || zsh_path="$(which zsh)"
    if ! grep "$zsh_path" /etc/shells; then
        info "adding $zsh_path to /etc/shells"
        echo "$zsh_path" | sudo tee -a /etc/shells
    fi

    if [ "$SHELL" != "$zsh_path" ]; then
        chsh -s "$zsh_path"
        info "default shell changed to $zsh_path"
    fi
}

setup_git() {
    title "Setting up Git"

    defaultName=$(git config user.name)
    defaultEmail=$(git config user.email)

    read -rp "Name [$defaultName] " name
    read -rp "Email [$defaultEmail] " email

    git config --global user.name "${name:-$defaultName}"
    git config --global user.email "${email:-$defaultEmail}"

    read -rp "Save user and password to an unencrypted file to avoid writing? [y/N] " save
    if [ $save = y ]; then
        git config --global credential.helper "store"
    else
        git config --global credential.helper "cache --timeout 3600"
    fi
}

case "$1" in
    link)
        setup_symlinks
        ;;
    git)
        setup_git
        ;;
    homebrew)
        setup_homebrew
        ;;
    shell)
        setup_shell
        ;;
    all)
        setup_symlinks
        setup_homebrew
        setup_shell
        setup_git
        ;;
    *)
        echo -e $"\nUsage: $(basename "$0") {link|git|homebrew|shell|all}\n"
        exit 1
        ;;
esac

success "Done."
