#!/usr/bin/env bash
# Phase 6 — Install Sal's Siri-on-Mac router files into the user library.
#
# Copies the intent catalog, system prompt, and dispatcher AppleScript to
# ~/Library/Application Support/Sal-Siri/ so the "Sal's Siri" Shortcut can find
# them at runtime.
#
# Pre-requisite: bin/dictation-commands-install.sh has been run (the 18 .scptd
# libraries must be in ~/Library/Script Libraries/).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DST="$HOME/Library/Application Support/Sal-Siri"
mkdir -p "$DST"
cp "$ROOT/scripts/sal/dictation-commands/sal-siri-intents.json"          "$DST/intents.json"
cp "$ROOT/scripts/sal/dictation-commands/sal-siri-system-prompt.txt"     "$DST/system-prompt.txt"
cp "$ROOT/scripts/sal/dictation-commands/sal-siri-dispatch.applescript"  "$DST/dispatch.applescript"
echo "Installed Sal's Siri runtime at: $DST"
echo ""
echo "Next steps:"
echo "  1. Import the Shortcut spec at:"
echo "     scripts/sal/dictation-commands/sal-siri-shortcut-spec.yaml"
echo "     into Shortcuts.app (use bin/shortcut-gen.py once it supports use_model action)"
echo "  2. Add a Vocal Shortcut entry: System Settings → Accessibility → Speech →"
echo "     Vocal Shortcuts → + → phrase: \"Hey Sal\" → action: Run Shortcut → Sal's Siri"
echo "  3. Test: say \"Hey Sal\" then \"give me a wide gradient presentation\""
