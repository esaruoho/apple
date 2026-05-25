#!/bin/bash
# apple.sh — zero-roundtrip launcher for the 304 workflows under scripts/workflows/.
#
# Usage:
#   applelist                       — list every script name (one per line)
#   applelist tv                    — list scripts whose name starts with "tv"
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
  --help|-h) sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
esac

q="${1:-}"

# No arg → full list
if [ -z "$q" ]; then
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
