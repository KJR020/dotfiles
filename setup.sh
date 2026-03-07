#!/usr/bin/env bash

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

# ----------------------------
# Claude Code managed-settings.json
# ----------------------------
# Claude Code の "bypass permissions mode" を無効化し、deny リストの
# 迂回を防止する。この設定は ~/.claude/settings.json では効かず、
# macOS の managed settings パスへの配置が必要（sudo 必須）。
# 初回のみ実行。変更頻度は極めて低い。
# See: docs/adr/0002-claude-code-security-settings.md

MANAGED_DIR="/Library/Application Support/ClaudeCode"
MANAGED_FILE="$MANAGED_DIR/managed-settings.json"

if [ ! -f "$MANAGED_FILE" ]; then
    echo "==> Setting up Claude Code managed-settings.json (requires sudo)"
    sudo mkdir -p "$MANAGED_DIR"
    sudo tee "$MANAGED_FILE" > /dev/null <<'JSON'
{
  "permissions": {
    "disableBypassPermissionsMode": "disable"
  }
}
JSON
    echo "==> managed-settings.json created at $MANAGED_FILE"
else
    echo "==> managed-settings.json already exists, skipping"
fi
