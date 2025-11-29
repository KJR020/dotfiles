#!/usr/bin/env bats

# Git configuration tests

@test "Given git is configured, then ~/.gitconfig exists" {
  [ -f "$HOME/.gitconfig" ]
}

@test "Given git is configured, then ~/.gitignore_global exists" {
  [ -f "$HOME/.gitignore_global" ]
}

@test "Given git is configured, then ~/.gitmessage exists" {
  [ -f "$HOME/.gitmessage" ]
}

@test "Given .gitconfig exists, then user name is configured" {
  grep -q "name = " "$HOME/.gitconfig"
}

@test "Given .gitconfig exists, then email is configured" {
  grep -q "email = " "$HOME/.gitconfig"
}

@test "Given .gitconfig exists, then excludesfile is configured" {
  grep -q "excludesfile = ~/.gitignore_global" "$HOME/.gitconfig"
}

@test "Given .gitconfig exists, then ghq root is configured" {
  grep -q "root = " "$HOME/.gitconfig"
}
