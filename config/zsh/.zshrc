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

source $ZSH/oh-my-zsh.sh

# ----------------------------
# パス設定
# ----------------------------
# Homebrewのパス
export PATH="/opt/homebrew/bin:$PATH"
export PATH="/opt/homebrew/sbin:$PATH"

# Goのパス
export GOPATH="$HOME/go"
export PATH="$GOPATH/bin:$PATH"

# Python関連
export PATH="$HOME/.local/bin:$PATH"
# uvを使用してPythonパッケージを管理
export UV_SYSTEM_PYTHON=1

# Node.js (Volta)
export VOLTA_HOME="$HOME/.volta"
export PATH="$VOLTA_HOME/bin:$PATH"

# ----------------------------
# エイリアスとカスタム関数
# ----------------------------
# エイリアスの読み込み
[ -f ~/.aliases.zsh ] && source ~/.aliases.zsh

# ----------------------------
# ツール設定
# ----------------------------
# fzf
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
export FZF_DEFAULT_OPTS='--height 40% --reverse --border'

# zoxide
eval "$(zoxide init zsh)"

# ----------------------------
# 補完設定
# ----------------------------
# 大文字小文字を区別しない
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

# 補完候補をカラー表示
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}

# 補完候補を詰めて表示
setopt list_packed

# ----------------------------
# 履歴設定
# ----------------------------
# 履歴ファイルの保存先
export HISTFILE=${HOME}/.zsh_history

# メモリに保存される履歴の件数
export HISTSIZE=10000

# 履歴ファイルに保存される履歴の件数
export SAVEHIST=100000

# 重複を記録しない
setopt hist_ignore_dups

# 開始と終了を記録
setopt EXTENDED_HISTORY

# ----------------------------
# その他のオプション
# ----------------------------
# ディレクトリ名だけでcdする
setopt auto_cd

# ビープ音を無効化
setopt no_beep

# コマンドのスペルを訂正する
setopt correct

# バックグラウンドジョブの状態変化を即時報告
setopt notify

# プロンプトカスタマイズ
# パスの省略表示を有効化
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

# pnpm
export PNPM_HOME="/Users/kojiro/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

# Added by Windsurf
export PATH="/Users/kjr020/.codeium/windsurf/bin:$PATH"

autoload -U +X bashcompinit && bashcompinit
complete -o nospace -C /opt/homebrew/bin/terraform terraform
