#!/bin/bash
# apple.sh — zero-roundtrip launcher for the 304 workflows under scripts/workflows/.
#
# Usage:
#   applelist                       — interactive picker: Apple-native
#                                     choose-from-list dialog with
#                                     type-ahead. Enter runs the script.
#                                     Falls back to dumping the cache
#                                     when stdout isn't a TTY (pipes).
#   applelist --list                — always dump every script name
#                                     (one per line), even on a TTY
#   applelist tv                    — list scripts matching "tv"
#   applelist tv-playpause          — run that script
#   applelist tv-playpause arg1 ... — pass args to the script
#   applelist --reload              — regenerate the tab-completion cache
#   applelist --cache               — print the cache path
#
# Tab completion: source ~/work/apple/bin/apple-completion.bash from your shell rc.

set -euo pipefail

WORKFLOWS="$HOME/work/apple/scripts/workflows"
CACHE="$HOME/work/apple/bin/.apple-names.cache"

regen_cache() {
  find "$WORKFLOWS" -type f \( -name '*.applescript' -o -name '*.sh' \) \
    -exec basename {} \; \
    | sed -E 's/\.(applescript|sh)$//' \
    | sort -u > "$CACHE"
}

# Build cache if missing OR older than the workflows dir
if [ ! -f "$CACHE" ] || [ "$WORKFLOWS" -nt "$CACHE" ]; then
  regen_cache
fi

case "${1:-}" in
  --reload) regen_cache; echo "rebuilt: $CACHE ($(wc -l <"$CACHE" | tr -d ' ') names)"; exit 0 ;;
  --cache)  echo "$CACHE"; exit 0 ;;
  --list)   cat "$CACHE"; exit 0 ;;
  --help|-h) sed -n '2,16p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
esac

q="${1:-}"

# No arg → interactive picker on TTY, dump otherwise.
if [ -z "$q" ]; then
  if [ -t 1 ]; then
    # `choose from list` is Apple-native, opens a real macOS list dialog
    # with type-to-jump, scrolling, and a default "OK" button. Returns
    # "false" on cancel; otherwise the selected name.
    selected=$(osascript <<APPLESCRIPT
tell me to activate
set listText to (do shell script "cat " & quoted form of "$CACHE")
set scriptList to paragraphs of listText
tell application "System Events"
    set chosen to choose from list scriptList with title "Apple Workflows" with prompt "Pick a script (type to filter):" default items {item 1 of scriptList} OK button name "Run" cancel button name "Cancel"
end tell
if chosen is false then
    return ""
else
    return item 1 of chosen
end if
APPLESCRIPT
)
    [ -z "$selected" ] && exit 0
    exec "$0" "$selected"
  fi
  cat "$CACHE"
  exit 0
fi

# Exact match → run it
match=$(find "$WORKFLOWS" -type f \( -name "$q.applescript" -o -name "$q.sh" \) | head -1)
if [ -n "$match" ]; then
  shift
  case "$match" in
    *.applescript) exec osascript "$match" "$@" ;;
    *.sh)          exec bash      "$match" "$@" ;;
  esac
fi

# Prefix / substring match → list options
prefix=$(grep "^$q" "$CACHE" || true)
if [ -n "$prefix" ]; then
  echo "$prefix"
  exit 0
fi
substr=$(grep -i "$q" "$CACHE" || true)
if [ -n "$substr" ]; then
  echo "$substr"
  exit 0
fi

echo "apple: no script matches '$q'" >&2
exit 1
