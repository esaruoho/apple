# apple-completion.bash — tab completion for `applelist` / `apple.sh`.
# (The `apple` alias is reserved for `cd ~/work/apple; claude`.)
#
# Install: add this line to ~/.bash_profile (or ~/.zshrc with bashcompinit):
#   source ~/work/apple/bin/apple-completion.bash
#
# Reload cache after adding scripts:
#   applelist --reload

_apple_complete() {
  local cur cache
  cur="${COMP_WORDS[COMP_CWORD]}"
  cache="$HOME/work/apple/bin/.apple-names.cache"
  [ -f "$cache" ] || "$HOME/work/apple/bin/apple.sh" --reload >/dev/null 2>&1
  # Read the cache once into the completion list (no subshell per keystroke
  # other than compgen itself — file-read is the entire roundtrip).
  COMPREPLY=( $(compgen -W "$(cat "$cache")" -- "$cur") )
}

complete -F _apple_complete applelist apple.sh
