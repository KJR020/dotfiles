# Check if the script is running on Windows (Git Bash)
if [[ "$(uname -o)" == "Msys" ]]; then
  # Simulating the `tree` command for Windows Git Bash 
  alias tree="pwd; find . | sort | sed '1d;s/^\.//;s/\/\([^/]*\)$/|--\1/;s/\/[^/|]*/| /g'"
fi

# Set up fzf key bindings and fuzzy completion
eval "$(fzf --bash)"
eval "$(zoxide init bash)"

alias python="python3" 
alias pip="pip3" 
