# Git関連のエイリアス
alias grh='git reset HEAD^'

# Docker関連のエイリアス
alias docker-clear-dangling='docker rmi -f $(docker images -f \"dangling=true\" -q)'

# Python関連
alias python='python3'

# その他
alias c='clear'
alias h='history'
alias grep='grep --color=auto'
alias mkdir='mkdir -p'
alias df='df -h'
alias du='du -h'

# ghq + fzf
alias gr='cd $(ghq root)/$(ghq list | fzf)'
