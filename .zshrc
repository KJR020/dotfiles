# ----------------------------
# Oh My Zsh Configuration
# ----------------------------

# Oh My Zsh installation path
export ZSH="$HOME/.oh-my-zsh"

# Theme and update reminder
ZSH_THEME="robbyrussell"
zstyle ':omz:update' mode reminder  # Just remind me to update when it's time

# Enable command auto-correction and display waiting dots during completion
ENABLE_CORRECTION="true"
COMPLETION_WAITING_DOTS="true"

# Load Oh My Zsh plugins
plugins=(
  git
  zsh-autosuggestions
  zsh-syntax-highlighting
)

# Source Oh My Zsh
source $ZSH/oh-my-zsh.sh

# ----------------------------
# User-specific Configuration
# ----------------------------

# Prompt configuration
PROMPT='%~ %F{green}$(git_prompt_info)%f:%# '

# Set preferred editor based on connection type
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='vim'
else
  export EDITOR='nvim'
fi

# Set up fzf key bindings and fuzzy completion
eval "$(fzf --zsh)"
eval "$(zoxide init zsh)"

# Custom Python aliases
alias python="/usr/local/opt/python@3.12/bin/python3"
alias pip="/usr/local/opt/python@3.12/bin/pip3"
