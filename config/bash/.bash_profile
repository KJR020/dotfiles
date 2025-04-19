if [ -f ~/.bashrc ]; then
    . ~/.bashrc
fi
export PATH="/usr/local/opt/postgresql@13>/bin:$PATH"

complete -C /opt/homebrew/bin/terraform terraform
