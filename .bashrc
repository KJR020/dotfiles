#!/bin/bash

# simulating the `tree` command for Windows GitBash 
# alias tree="pwd;find . | sort | sed '1d;s/^\.//;s/\/\([^/]*\)$/|--\1/;s/\/[^/|]*/| /g'"

# Set up fzf key bindings and fuzzy completion
eval "$(fzf --bash)"
eval "$(zoxide init bash)"

alias python="python3" 
alias pip="pip3" 
