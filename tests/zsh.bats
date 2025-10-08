#!/usr/bin/env bats

# Zsh設定のテスト

@test "~/.zshrc が存在する" {
  [ -f "$HOME/.zshrc" ]
}

@test "~/.zprofile が存在する" {
  [ -f "$HOME/.zprofile" ]
}

@test ".zshrc に Oh My Zsh の設定が含まれている" {
  grep -q 'ZSH=' "$HOME/.zshrc"
}

@test ".zshrc にパス設定が含まれている" {
  grep -q 'PATH=' "$HOME/.zshrc"
}

@test ".zshrc にfzfの設定が含まれている" {
  grep -q 'fzf' "$HOME/.zshrc"
}

@test ".zshrc にzoxideの設定が含まれている" {
  grep -q 'zoxide' "$HOME/.zshrc"
}
