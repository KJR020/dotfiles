#!/usr/bin/env bats

setup() {
  export REPO_ROOT
  REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  export TEST_HOME="$BATS_TEST_TMPDIR/home"
  export TEST_BIN="$BATS_TEST_TMPDIR/bin"
  export ZDOTDIR="$BATS_TEST_TMPDIR/zdotdir"
  export RESULT_FILE="$BATS_TEST_TMPDIR/result.txt"
  export OP_LOG="$BATS_TEST_TMPDIR/op.log"
  mkdir -p "$TEST_HOME" "$TEST_BIN" "$ZDOTDIR"
  : > "$OP_LOG"
}

write_mock_claude() {
  cat > "$TEST_BIN/claude" <<'EOF'
#!/bin/sh
printf 'args:%s\n' "$*" > "$RESULT_FILE"
printf 'anthropic:%s\n' "${ANTHROPIC_API_KEY:-}" >> "$RESULT_FILE"
EOF
  chmod +x "$TEST_BIN/claude"
}

write_mock_codex() {
  cat > "$TEST_BIN/codex" <<'EOF'
#!/bin/sh
printf 'args:%s\n' "$*" > "$RESULT_FILE"
printf 'github:%s\n' "${GITHUB_TOKEN:-}" >> "$RESULT_FILE"
EOF
  chmod +x "$TEST_BIN/codex"
}

write_mock_op_signed_out() {
  cat > "$TEST_BIN/op" <<'EOF'
#!/bin/sh
printf '%s\n' "$*" >> "$OP_LOG"
if [ "$1" = "whoami" ]; then
  exit 1
fi
if [ "$1" = "read" ]; then
  echo "unexpected op read" >&2
  exit 9
fi
exit 0
EOF
  chmod +x "$TEST_BIN/op"
}

wrapper_snippet_command() {
  printf "%s" "source <(sed -n '/^run_with_op_env()/,/^# Claude Code with English Coach mode/p' \"\$REPO_ROOT/home/dot_zsh_config.zsh\")"
}

@test "Given op is signed out, when claude runs, then it falls back without reading op secrets" {
  write_mock_claude
  write_mock_op_signed_out
  cat > "$TEST_HOME/.env.op" <<'EOF'
ANTHROPIC_API_KEY=op://Development/Anthropic/credential
EOF

  run env \
    HOME="$TEST_HOME" \
    PATH="$TEST_BIN:$PATH" \
    RESULT_FILE="$RESULT_FILE" \
    OP_LOG="$OP_LOG" \
    REPO_ROOT="$REPO_ROOT" \
    zsh -fc "$(wrapper_snippet_command); claude hello world"

  [ "$status" -eq 0 ]
  grep -q '^args:hello world$' "$RESULT_FILE"
  grep -q '^anthropic:$' "$RESULT_FILE"
  grep -q '^whoami$' "$OP_LOG"
  ! grep -q '^read ' "$OP_LOG"
}

@test "Given op is signed out, when codex runs, then it falls back without reading op secrets" {
  write_mock_codex
  write_mock_op_signed_out
  cat > "$TEST_HOME/.env.op" <<'EOF'
GITHUB_TOKEN=op://Development/GitHub-PAT/credential
EOF

  run env \
    HOME="$TEST_HOME" \
    PATH="$TEST_BIN:$PATH" \
    RESULT_FILE="$RESULT_FILE" \
    OP_LOG="$OP_LOG" \
    REPO_ROOT="$REPO_ROOT" \
    zsh -fc "$(wrapper_snippet_command); codex exec --help"

  [ "$status" -eq 0 ]
  grep -q '^args:exec --help$' "$RESULT_FILE"
  grep -q '^github:$' "$RESULT_FILE"
  grep -q '^whoami$' "$OP_LOG"
  ! grep -q '^read ' "$OP_LOG"
}

@test "Given op is signed out, when an interactive shell loads the wrapper, then it prints a fallback warning" {
  write_mock_op_signed_out
  cat > "$TEST_HOME/.env.op" <<'EOF'
ANTHROPIC_API_KEY=op://Development/Anthropic/credential
EOF
  : > "$ZDOTDIR/.zshrc"

  run env \
    HOME="$TEST_HOME" \
    ZDOTDIR="$ZDOTDIR" \
    PATH="$TEST_BIN:$PATH" \
    OP_LOG="$OP_LOG" \
    REPO_ROOT="$REPO_ROOT" \
    zsh -ic "$(wrapper_snippet_command)"

  [ "$status" -eq 0 ]
  [[ "$output" == *"1Password"* ]]
  [[ "$output" == *"fallback"* ]]
  grep -q '^whoami$' "$OP_LOG"
}
