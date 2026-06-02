#!/usr/bin/env bash
# build.sh — generate + compile the companion boot-app from panes.conf.
# Produces Companion-Boot.app (gitignored). Set it as a Login Item on the
# companion so all your service panes open after login.
#
# Usage:
#   build.sh            generate main.applescript + compile Companion-Boot.app
#   build.sh --check    generate + syntax-check only, do not build the .app
#   build.sh --print    print the generated AppleScript to stdout and stop

set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
conf="$here/panes.conf"
src="$here/main.applescript"     # generated, gitignored
app="$here/Companion-Boot.app"   # generated, gitignored

[ -f "$conf" ] || { echo "no panes.conf — copy panes.conf.example → panes.conf" >&2; exit 1; }

gen="$(/usr/bin/python3 "$here/gen-boot-app.py" "$conf")"

if [ "${1:-}" = "--print" ]; then
  printf '%s\n' "$gen"; exit 0
fi

printf '%s\n' "$gen" > "$src"
echo "wrote $src"

# Syntax-check via osacompile to a throwaway target.
tmp="$(mktemp -d)/check.scpt"
if osacompile -o "$tmp" "$src" 2>/tmp/companion-boot-check.err; then
  echo "syntax OK"
else
  echo "syntax error:"; cat /tmp/companion-boot-check.err >&2; exit 1
fi

[ "${1:-}" = "--check" ] && { echo "check-only — not building .app"; exit 0; }

# Snapshot any prior app, then build fresh.
[ -d "$app" ] && cp -R "$app" "$here/Companion-Boot.app.bak.$(date +%s)" 2>/dev/null || true
rm -rf "$app"
osacompile -o "$app" "$src"
echo "built $app"
echo "→ set it as a Login Item on the companion (System Settings ▸ General ▸ Login Items)."
