# Git関連のエイリアス
alias g='git'
alias gst='git status'
alias gl='git pull'
alias gp='git push'
alias gd='git diff'
alias gc='git commit'
alias gco='git checkout'
alias gb='git branch'
alias ga='git add'
alias grh='git reset HEAD'

# Docker関連のエイリアス
alias d='docker'
alias dc='docker-compose'
alias dps='docker ps'
alias dex='docker exec -it'
alias dl='docker logs'

# ナビゲーション
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias ll='ls -la'
alias la='ls -A'
alias l='ls -CF'

# Python関連
alias python='python3'
alias pip='uv pip'
alias py='python3'
alias pyvenv='python3 -m venv'
alias uvp='uv pip'
alias uvi='uv install'
alias uvr='uv requirements'

# npm関連
alias ni='npm install'
alias nr='npm run'
alias nrd='npm run dev'
alias nrb='npm run build'

# その他
alias c='clear'
alias h='history'
alias grep='grep --color=auto'
alias mkdir='mkdir -p'
alias df='df -h'
alias du='du -h'

# ghq + fzf
alias gr='cd $(ghq root)/$(ghq list | fzf)'
