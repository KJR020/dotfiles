#!/usr/bin/env bats

# Zsh configuration tests

@test "Given zsh is configured, then ~/.zshrc exists" {
  [ -f "$HOME/.zshrc" ]
}

@test "Given zsh is configured, then ~/.zprofile exists" {
  [ -f "$HOME/.zprofile" ]
}

@test "Given zsh is configured, then ~/.zshenv exists" {
  [ -f "$HOME/.zshenv" ]
}

@test "Given zsh is configured, then ~/.env.op exists" {
  [ -f "$HOME/.env.op" ]
}

@test "Given zsh is configured, then ~/.zsh_config.zsh exists" {
  [ -f "$HOME/.zsh_config.zsh" ]
}

@test "Given .zshrc exists, then PATH is configured" {
  grep -q 'PATH=' "$HOME/.zshrc"
}

@test "Given .zshrc exists, then zsh_config is sourced" {
  grep -q 'source ~/.zsh_config.zsh' "$HOME/.zshrc"
}

@test "Given .zshenv exists, then op read is guarded" {
  ! grep -q 'export REDMINE_API_KEY=$(op read' "$HOME/.zshenv"
}

@test "Given .zsh_config.zsh exists, then AI commands load op references before launch" {
  grep -q 'run_with_op_env' "$HOME/.zsh_config.zsh"
  grep -q '^claude() {' "$HOME/.zsh_config.zsh"
  grep -q '^codex() {' "$HOME/.zsh_config.zsh"
  grep -q 'op read --no-newline' "$HOME/.zsh_config.zsh"
}

@test "Given .env.op exists, then REDMINE_API_KEY is configured as an op reference" {
  grep -q '^REDMINE_API_KEY=op://' "$HOME/.env.op"
}

@test "Given .zsh_config.zsh exists, then Oh My Zsh is not referenced" {
  ! grep -Eq 'oh-my-zsh|^export ZSH=' "$HOME/.zsh_config.zsh"
}

@test "Given .zsh_config.zsh exists, then zsh plugins are configured via Homebrew" {
  grep -q 'zsh-autosuggestions' "$HOME/.zsh_config.zsh"
  grep -q 'zsh-syntax-highlighting' "$HOME/.zsh_config.zsh"
}

@test "Given .zsh_config.zsh exists, then fzf is configured" {
  grep -q 'fzf' "$HOME/.zsh_config.zsh"
}

@test "Given .zsh_config.zsh exists, then zoxide is configured" {
  grep -q 'zoxide' "$HOME/.zsh_config.zsh"
}
