# ----------------------------
# 基本設定
# ----------------------------
export LANG=ja_JP.UTF-8
export EDITOR='nvim'
export VISUAL='nvim'
export PAGER='less'

# ----------------------------
# 補完設定
# ----------------------------
autoload -Uz compinit
compinit

zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
setopt list_packed

# zsh-completions (Homebrew)
if type brew &>/dev/null; then
  FPATH="$(brew --prefix)/share/zsh-completions:$FPATH"
fi

# ----------------------------
# 履歴設定
# ----------------------------
export HISTFILE=${HOME}/.zsh_history
export HISTSIZE=10000
export SAVEHIST=100000
setopt hist_ignore_dups
setopt EXTENDED_HISTORY

# ----------------------------
# その他のオプション
# ----------------------------
setopt auto_cd
setopt no_beep
setopt notify
setopt prompt_subst

# ----------------------------
# Git prompt
# ----------------------------
function git_prompt_info() {
  local branch
  branch=$(git symbolic-ref --short HEAD 2>/dev/null) || return

  local status_color="%F{green}"
  if [[ -n $(git status --porcelain 2>/dev/null) ]]; then
    status_color="%F{yellow}"
  fi

  echo "${status_color}(${branch})%f"
}

# ----------------------------
# プロンプト設定
# ----------------------------
PROMPT='%F{cyan}%~%f $(git_prompt_info)$ '

# ----------------------------
# プラグイン
# ----------------------------
if command -v brew >/dev/null 2>&1; then
  BREW_PREFIX="$(brew --prefix)"

  if [ -f "$BREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]; then
    source "$BREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
  fi

  if [ -f "$BREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]; then
    source "$BREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
  fi
fi

# ----------------------------
# ツール設定
# ----------------------------
if command -v fzf >/dev/null 2>&1; then
  source <(fzf --zsh)
fi
export FZF_DEFAULT_OPTS='--height 40% --reverse --border'

if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
fi

# pet (snippet manager)
function pet-select() {
  BUFFER=$(pet search --query "$LBUFFER")
  CURSOR=$#BUFFER
  zle redisplay
}
zle -N pet-select
stty -ixon
bindkey '^s' pet-select

run_with_op_env() {
  emulate -L zsh
  local executable="$1"
  local env_file="$HOME/.env.op"
  local -a env_args
  local line key value resolved_value
  local needs_op=0
  local op_ready=0
  shift

  if [ -z "$executable" ]; then
    return 127
  fi

  if [ -f "$env_file" ]; then
    if ai_op_env_has_reference && ai_op_session_ready; then
      op_ready=1
    fi

    while IFS= read -r line || [ -n "$line" ]; do
      case "$line" in
        ''|'#'*) continue ;;
      esac

      if [[ "$line" != *=* ]]; then
        print -u2 "Invalid line in $env_file: $line"
        return 1
      fi

      key="${line%%=*}"
      value="${line#*=}"

      if [[ "$value" == op://* ]]; then
        needs_op=1
        if (( op_ready )); then
          resolved_value="$(op read --no-newline "$value")" || return $?
          env_args+=("$key=$resolved_value")
          continue
        fi
      else
        env_args+=("$key=$value")
      fi
    done < "$env_file"

    if (( needs_op )) && ! (( op_ready )); then
      warn_ai_op_fallback_once
    fi

    if (( ${#env_args[@]} > 0 )); then
      env "${env_args[@]}" "$executable" "$@"
      return
    fi
  fi

  "$executable" "$@"
}

ai_op_session_ready() {
  command -v op >/dev/null 2>&1 && op whoami >/dev/null 2>&1
}

ai_op_env_has_reference() {
  emulate -L zsh
  local env_file="$HOME/.env.op"
  local line value

  [ -f "$env_file" ] || return 1

  while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in
      ''|'#'*) continue ;;
    esac

    [[ "$line" == *=* ]] || continue
    value="${line#*=}"
    [[ "$value" == op://* ]] && return 0
  done < "$env_file"

  return 1
}

typeset -gi AI_OP_FALLBACK_WARNING_EMITTED=0

warn_ai_op_fallback_once() {
  (( AI_OP_FALLBACK_WARNING_EMITTED )) && return 0
  AI_OP_FALLBACK_WARNING_EMITTED=1
  print -u2 "Warning: 1Password is unavailable; claude/codex will fallback to direct launch without ~/.env.op secrets."
}

warn_ai_op_fallback_on_startup() {
  [[ -o interactive ]] || return 0
  ai_op_env_has_reference || return 0
  ai_op_session_ready && return 0
  warn_ai_op_fallback_once
}

claude() {
  run_with_op_env "$(whence -p claude)" "$@"
}

codex() {
  run_with_op_env "$(whence -p codex)" "$@"
}

warn_ai_op_fallback_on_startup

# Claude Code with English Coach mode
claude-en() {
  claude --append-system-prompt "$(cat ~/.claude/prompts/en-coach.txt)" "$@"
}

# Claude Code Agent Teams (tmux split-pane mode)
alias cc-team='claude --teammate-mode tmux'
