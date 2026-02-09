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
# プラグイン (Homebrew)
# ----------------------------
source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# ----------------------------
# ツール設定
# ----------------------------
source <(fzf --zsh)
export FZF_DEFAULT_OPTS='--height 40% --reverse --border'

eval "$(zoxide init zsh)"

# Claude Code with English Coach mode
claude-en() {
  claude --append-system-prompt "$(cat ~/.claude/prompts/en-coach.txt)" "$@"
}

# Claude Code Agent Teams (tmux split-pane mode)
alias cc-team='claude --teammate-mode tmux'

