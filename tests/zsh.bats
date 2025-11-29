#!/usr/bin/env bats

# Zsh configuration tests

@test "Given zsh is configured, then ~/.zshrc exists" {
  [ -f "$HOME/.zshrc" ]
}

@test "Given zsh is configured, then ~/.zprofile exists" {
  [ -f "$HOME/.zprofile" ]
}

@test "Given .zshrc exists, then Oh My Zsh is configured" {
  grep -q 'ZSH=' "$HOME/.zshrc"
}

@test "Given .zshrc exists, then PATH is configured" {
  grep -q 'PATH=' "$HOME/.zshrc"
}

@test "Given .zshrc exists, then fzf is configured" {
  grep -q 'fzf' "$HOME/.zshrc"
}

@test "Given .zshrc exists, then zoxide is configured" {
  grep -q 'zoxide' "$HOME/.zshrc"
}
