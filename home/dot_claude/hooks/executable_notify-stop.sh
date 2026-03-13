#!/bin/bash
# notify-stop.sh - Notify when Claude Code finishes responding
# Triggers terminal bell + macOS notification

# Terminal bell (makes tmux tab flash)
printf '\a' > /dev/tty 2>/dev/null || true

# macOS notification via terminal-notifier
if command -v terminal-notifier &>/dev/null; then
  SESSION_NAME=""
  PANE_ID=""
  if [ -n "$TMUX" ]; then
    SESSION_NAME=$(tmux display-message -p '#S' 2>/dev/null)
    PANE_ID=$(tmux display-message -p '#D' 2>/dev/null)
  fi

  terminal-notifier \
    -title "Claude Code" \
    -message "応答が完了しました${SESSION_NAME:+ [$SESSION_NAME]}" \
    -group "claude-code-${SESSION_NAME:-default}" \
    -sound default \
    &>/dev/null &
fi

exit 0
