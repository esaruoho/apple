#!/usr/bin/env bash
# Run AFTER bin/dictation-commands-install.sh — compile all loupedeck-button .applescript
# sources into .scpt now that the DC-* libraries are in ~/Library/Script Libraries/.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DIR="$ROOT/scripts/sal/dictation-commands/loupedeck-buttons"
ok=0
fail=0
for src in "$DIR"/*.applescript; do
  [[ -f "$src" ]] || continue
  out="${src%.applescript}.scpt"
  if osacompile -o "$out" "$src" 2>/dev/null; then
    ok=$((ok+1))
  else
    fail=$((fail+1))
    echo "FAIL: $src" >&2
  fi
done
echo "Compiled: $ok"
echo "Failed:   $fail"
