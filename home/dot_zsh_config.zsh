# ----------------------------
# 基本設定
# ----------------------------
export LANG=ja_JP.UTF-8
export EDITOR='nvim'
export VISUAL='nvim'
export PAGER='less'

# ----------------------------
# Oh My Zsh Configuration
# ----------------------------
export ZSH="$HOME/.oh-my-zsh"

# テーマ設定
ZSH_THEME="robbyrussell"

# Oh My Zsh設定
DISABLE_AUTO_UPDATE="true"
ENABLE_CORRECTION="true"
COMPLETION_WAITING_DOTS="true"
HIST_STAMPS="yyyy-mm-dd"

# プラグイン
plugins=(
  git
  zsh-autosuggestions
  zsh-syntax-highlighting
  docker
  docker-compose
  npm
  python
  pip
  golang
)

# Oh My Zshの読み込み（存在確認付き）
if [[ -f "$ZSH/oh-my-zsh.sh" ]]; then
  source $ZSH/oh-my-zsh.sh
else
  echo "Warning: Oh My Zsh not found. Please install it first:"
  echo "sh -c \"\$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)\""
fi

# ----------------------------
# プロンプトカスタマイズ
# ----------------------------
setopt prompt_subst

function prompt_pwd() {
    local pwd="${PWD/#$HOME/~}"
    if [[ "$pwd" == (#m)[/~] ]]; then
        print "$MATCH"
    else
        print "${${${${(@j:/:M)${(@s:/:)pwd}##.#?}:h}%/}//\%/%%}/${${pwd:t}//\%/%%}"
    fi
}

PROMPT='%F{cyan}$(prompt_pwd)%f %F{green}$(git_prompt_info)%f$ '

# ----------------------------
# 補完設定
# ----------------------------
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
setopt list_packed

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
setopt correct
setopt notify

# ----------------------------
# ツール設定
# ----------------------------
# fzf
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
export FZF_DEFAULT_OPTS='--height 40% --reverse --border'

# zoxide
eval "$(zoxide init zsh)"
