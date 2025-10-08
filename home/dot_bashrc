#!/bin/bash

if OSTYPE="Darwin"; then
  eval "$(fzf --bash)"
  eval "$(zoxide init bash)"

  alias python="python3" 
  alias pip="pip3" 

elif OSTYPE="msys"; then
  alias tree="pwd;find . | sort | sed '1d;s/^\.//;s/\/\([^/]*\)$/|--\1/;s/\/[^/|]*/| /g'"
  
fi
[ -f ~/.fzf.bash ] && source ~/.fzf.bash
