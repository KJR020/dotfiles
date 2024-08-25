#!/bin/bash
COLOR_BLUE="\033[1;34m"
COLOR_NONE="\033[0m"

info() {
    echo -e "${COLOR_BLUE}Info: ${COLOR_NONE}$1"
}

setup_git() {
    info "Setting up Git"

    # ユーザー名とメールの設定
    defaultName=$(git config user.name)
    defaultEmail=$(git config user.email)

    read -rp "Name [$defaultName] " name
    read -rp "Email [$defaultEmail] " email

    git config --global user.name "${name:-$defaultName}"
    git config --global user.email "${email:-$defaultEmail}"

    # 認証情報の保存方法の設定
    read -rp "Save user and password to an unencrypted file to avoid writing? [y/N] " save
    if [ "$save" = "y" ]; then
        git config --global credential.helper "store"
    else
        git config --global credential.helper "cache --timeout 3600"
    fi

    # 改行コードの設定
    os_type=$(uname -s)
    if [[ "$os_type" == "Darwin" ]]; then
        info "Setting Git to handle line endings for macOS"
        git config --global core.autocrlf input
    elif [[ "$os_type" == "Linux" ]]; then
        info "Setting Git to handle line endings for Linux"
        git config --global core.autocrlf input
    elif [[ "$os_type" == "CYGWIN"* || "$os_type" == "MINGW"* ]]; then
        info "Setting Git to handle line endings for Windows"
        git config --global core.autocrlf true
    else
        info "Unknown OS type. No specific Git settings applied for line endings."
    fi
}

# Gitのセットアップを実行
setup_git