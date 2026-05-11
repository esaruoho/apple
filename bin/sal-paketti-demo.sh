#!/usr/bin/env bash
# sal-paketti-demo.sh — 60-second live demo of the Hey Sal × Paketti chain.
#
# Designed for showing the work to a friend (e.g. Josh) without giving a
# lecture. Narrates each step via `say`, fires the verbs through hey-sal
# (the same router voice and Spotlight use), and pauses for laughs.
#
# Safe to run: only toggles dialog-style verbs (Groovebox, Gater) and the
# Paketti Preferences window. Does NOT change BPM, mute tracks, or alter
# the loaded song. Toggling means the dialog opens on first fire and
# closes on the second — leaves Renoise's state unchanged.
#
# Usage:
#   bash ~/work/apple/bin/sal-paketti-demo.sh
#   bash ~/work/apple/bin/sal-paketti-demo.sh --silent   # no `say` narration
#   bash ~/work/apple/bin/sal-paketti-demo.sh --fast     # no pauses

set -euo pipefail

SILENT=0
FAST=0
for arg in "$@"; do
  case "$arg" in
    --silent) SILENT=1 ;;
    --fast)   FAST=1 ;;
  esac
done

HEY_SAL="$HOME/work/apple/bin/hey-sal"
REGISTRY="$HOME/work/apple/analysis/sal/paketti-verbs.json"

bold() { printf '\033[1m%s\033[0m\n' "$*"; }
say_it() {
  local text="$1"
  bold "→ $text"
  [ "$SILENT" -eq 0 ] && /usr/bin/say "$text" 2>/dev/null || true
}
pause() {
  [ "$FAST" -eq 0 ] && sleep "${1:-2}"
}
verb() {
  local phrase="$1"
  echo "    \$ hey-sal \"$phrase\""
  "$HEY_SAL" "$phrase" 2>&1 | grep -E "Paketti verb|Keyboard shortcut|wrapper|sent key|ERROR" | head -4 || true
  pause 2
}

# ---------------------------------------------------------------- prechecks ---
if ! pgrep -f "Renoise.app/Contents/MacOS/Renoise" >/dev/null; then
  echo "Renoise is not running. Start it, then re-run this demo."
  [ "$SILENT" -eq 0 ] && /usr/bin/say "Renoise is not running. Please start it first."
  exit 2
fi
if [ ! -x "$HEY_SAL" ]; then
  echo "hey-sal router missing at $HEY_SAL. Run bootstrap-hey-sal.sh first."
  exit 2
fi
if [ ! -f "$REGISTRY" ]; then
  echo "Paketti verb registry missing at $REGISTRY. Run bootstrap-hey-sal.sh."
  exit 2
fi

VERB_COUNT=$(/usr/bin/python3 -c "import json; print(json.load(open('$REGISTRY'))['count'])")

clear
bold "═══════════════════════════════════════════════════════════════════"
bold "  Hey Sal × Paketti — live demo"
bold "═══════════════════════════════════════════════════════════════════"
echo
pause 1

# ---------------------------------------------------------------- act 1 ---
say_it "Paketti is the open-source workflow suite I built for Renoise. Today it has $VERB_COUNT voice-callable commands."
pause 3

say_it "Watch. I'll open Paketti's Groovebox by saying its name."
pause 1
verb "groovebox"

say_it "Now the Paketti Gater."
pause 1
verb "gater"

say_it "Now Pattern Mute Toggle."
pause 1
verb "pattern mute toggle" || true

# ---------------------------------------------------------------- act 2 ---
echo
bold "─── closing the dialogs (toggle back) ───"
pause 1
verb "groovebox"
verb "gater"

# ---------------------------------------------------------------- act 3 ---
echo
bold "─── the scope ───"
echo
echo "  Voice-callable Paketti commands: $VERB_COUNT"
echo "  Source: Renoise's exported KeyBindings.xml"
echo "  Router: ~/work/apple/bin/hey-sal"
echo "  Entry points: Hey Sal Vocal Shortcut, Spotlight 'Hey Sal' app,"
echo "                 menu-bar Shortcuts pin, or any shell"
echo
pause 2

say_it "This is Sal Soghoian's WWDC 2016 vision, running on a 2026 Mac, with Paketti talking to it through the same router. The voice path, the Spotlight path, the menu bar, and the shell — all four hit the same wrappers. $VERB_COUNT verbs, no Claude, no daemon, no roundtrip."

echo
bold "─── demo complete ───"
