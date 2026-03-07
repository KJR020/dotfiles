#!/usr/bin/env bats

# Claude Code security settings tests

SETTINGS_FILE="$HOME/.claude/settings.json"

setup() {
  if ! command -v jq &>/dev/null; then
    skip "jq is not installed"
  fi
}

@test "Given Claude Code is configured, then settings.json exists" {
  [ -f "$SETTINGS_FILE" ]
}

@test "Given settings.json exists, then it is valid JSON" {
  jq . "$SETTINGS_FILE" >/dev/null 2>&1
}

@test "Given settings.json exists, then enableAllProjectMcpServers is false" {
  result=$(jq '.enableAllProjectMcpServers' "$SETTINGS_FILE")
  [ "$result" = "false" ]
}

@test "Given settings.json exists, then deny list is not empty" {
  result=$(jq '.permissions.deny | length' "$SETTINGS_FILE")
  [ "$result" -gt 0 ]
}

@test "Given settings.json exists, then deny list contains network commands (curl)" {
  jq -e '.permissions.deny[] | select(test("curl"))' "$SETTINGS_FILE" >/dev/null
}

@test "Given settings.json exists, then deny list contains destructive commands (rm -rf)" {
  jq -e '.permissions.deny[] | select(test("rm -rf"))' "$SETTINGS_FILE" >/dev/null
}

@test "Given settings.json exists, then deny list contains privilege escalation (sudo)" {
  jq -e '.permissions.deny[] | select(test("sudo"))' "$SETTINGS_FILE" >/dev/null
}

@test "Given settings.json exists, then deny list contains dotfiles protection (Edit ~/.zshrc)" {
  jq -e '.permissions.deny[] | select(test("Edit.*zshrc"))' "$SETTINGS_FILE" >/dev/null
}

@test "Given settings.json exists, then deny list contains credential file protection (Read ~/.gnupg)" {
  jq -e '.permissions.deny[] | select(test("Read.*gnupg"))' "$SETTINGS_FILE" >/dev/null
}

@test "Given settings.json exists, then deny list contains macOS credential protection (Keychains)" {
  jq -e '.permissions.deny[] | select(test("Keychains"))' "$SETTINGS_FILE" >/dev/null
}

# managed-settings.json tests

MANAGED_SETTINGS="/Library/Application Support/ClaudeCode/managed-settings.json"

@test "Given managed-settings.json exists, then it is valid JSON" {
  if [ ! -f "$MANAGED_SETTINGS" ]; then
    skip "managed-settings.json not found (requires manual setup with sudo)"
  fi
  jq . "$MANAGED_SETTINGS" >/dev/null 2>&1
}

@test "Given managed-settings.json exists, then disableBypassPermissionsMode is disable" {
  if [ ! -f "$MANAGED_SETTINGS" ]; then
    skip "managed-settings.json not found (requires manual setup with sudo)"
  fi
  result=$(jq -r '.permissions.disableBypassPermissionsMode' "$MANAGED_SETTINGS")
  [ "$result" = "disable" ]
}
