# apple-do-completion.sh — Tab-complete + CYCLE the apple-do capabilities.
# Source this from your shell rc:   source ~/work/apple/bin/apple-do-completion.sh
# Then `apple-do <Tab>` cycles through home/now/fleet/spotlight/search/ocr…

if [ -n "${ZSH_VERSION:-}" ]; then
  _APPLE_DO_DIR="${${(%):-%x}:A:h}"
  _apple_do() {
    if (( CURRENT == 2 )); then
      local -a caps
      caps=(${(f)"$("$_APPLE_DO_DIR/apple-do" --complete)"})
      compadd -- $caps
    fi
  }
  compdef _apple_do apple-do
  # cycle through matches on repeated Tab (menu completion)
  zstyle ':completion:*' menu select
  setopt MENU_COMPLETE 2>/dev/null

elif [ -n "${BASH_VERSION:-}" ]; then
  _APPLE_DO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  _apple_do() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    if [ "$COMP_CWORD" -eq 1 ]; then
      COMPREPLY=( $(compgen -W "$("$_APPLE_DO_DIR/apple-do" --complete)" -- "$cur") )
    fi
  }
  complete -F _apple_do apple-do
  # make Tab cycle through matches instead of just listing them
  bind 'set show-all-if-ambiguous on' 2>/dev/null
  bind 'set menu-complete-display-prefix on' 2>/dev/null
  bind 'TAB:menu-complete' 2>/dev/null
  bind '"\e[Z":menu-complete-backward' 2>/dev/null   # Shift-Tab = cycle backward
fi
