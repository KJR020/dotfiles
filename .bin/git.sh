#!/bin/bash
COLOR_BLUE="\033[1;34m"
COLOR_NONE="\033[0m"

info() {
    echo -e "${COLOR_BLUE}Info: ${COLOR_NONE}$1"
}

setup_git() {
    info "Setting up Git"
    defaultName=$(git config user.name)
    defaultEmail=$(git config user.email)

    read -rp "Name [$defaultName] " name
    read -rp "Email [$defaultEmail] " email

    git config --global user.name "${name:-$defaultName}"
    git config --global user.email "${email:-$defaultEmail}"

    read -rp "Save user and password to an unencrypted file to avoid writing? [y/N] " save
    if [ "$save" = "y" ]; then
        git config --global credential.helper "store"
    else
        git config --global credential.helper "cache --timeout 3600"
    fi
}

setup_git