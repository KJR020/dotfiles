#!/usr/bin/env bats

# Git設定のテスト

@test "~/.gitconfig が存在する" {
  [ -f "$HOME/.gitconfig" ]
}

@test "~/.gitignore_global が存在する" {
  [ -f "$HOME/.gitignore_global" ]
}

@test "~/.gitmessage が存在する" {
  [ -f "$HOME/.gitmessage" ]
}

@test ".gitconfig にユーザー名が設定されている" {
  grep -q "name = " "$HOME/.gitconfig"
}

@test ".gitconfig にメールアドレスが設定されている" {
  grep -q "email = " "$HOME/.gitconfig"
}

@test ".gitconfig に excludesfile が設定されている" {
  grep -q "excludesfile = ~/.gitignore_global" "$HOME/.gitconfig"
}

@test ".gitconfig に ghq root が設定されている" {
  grep -q "root = " "$HOME/.gitconfig"
}
