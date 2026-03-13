#!/bin/bash
# cleanup-mcp.sh - Kill orphaned MCP server processes on SessionEnd
# SessionEnd hook: finds the parent Claude process and kills its notebooklm-mcp children

LOGFILE="$HOME/.claude/mcp-cleanup.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Walk up process tree to find the Claude Code process
find_claude_pid() {
  local pid=$1
  local max_depth=5
  local i=0
  while [ "$pid" -gt 1 ] && [ $i -lt $max_depth ]; do
    local cmd=$(ps -o comm= -p "$pid" 2>/dev/null)
    if [[ "$cmd" == *"claude"* ]]; then
      echo "$pid"
      return
    fi
    pid=$(ps -o ppid= -p "$pid" 2>/dev/null | tr -d ' ')
    i=$((i + 1))
  done
}

CLAUDE_PID=$(find_claude_pid $$)

if [ -n "$CLAUDE_PID" ]; then
  # Kill notebooklm-mcp processes that are children of this Claude session
  PIDS=$(pgrep -P "$CLAUDE_PID" -f "notebooklm-mcp" 2>/dev/null)
  if [ -n "$PIDS" ]; then
    echo "[$TIMESTAMP] Killing notebooklm-mcp (claude=$CLAUDE_PID): $PIDS" >> "$LOGFILE"
    echo "$PIDS" | xargs kill 2>/dev/null || true
  else
    echo "[$TIMESTAMP] No notebooklm-mcp children of claude=$CLAUDE_PID" >> "$LOGFILE"
  fi
else
  echo "[$TIMESTAMP] Could not find parent Claude process, skipping" >> "$LOGFILE"
fi

exit 0
