#!/usr/bin/env bash
# One-command Sal Demo library installer.
#
# Builds all .shortcut files, opens them for batch import, then runs the
# folder organizer to put them in a "Sal Demo" folder in Shortcuts.app.
#
# Pre-req: bin/dictation-commands-install.sh has been run (Sal libraries
# at ~/Library/Script Libraries/, helpers at ~/Applications/).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

echo "═══ Sal Demo Library Installer ═══"
echo ""
echo "Step 1/4: Build granular Shortcuts (~30 of them)"
python3 "$ROOT/bin/build-sal-demo-shortcuts.py" 2>&1 | tail -5
echo ""

echo "Step 2/4: Build master orchestrator (Sal Vacation Demo)"
python3 "$ROOT/bin/build-sal-vacation-demo.py" 2>&1
echo ""

echo "Step 3/4: Build Take My Picture (native AVFoundation)"
python3 "$ROOT/bin/build-take-my-picture-shortcut.py" 2>&1
echo ""

echo "Step 4/4: Open all .shortcut files for import"
echo "  → Click 'Add Shortcut' for each dialog that appears."
echo "  → If a Shortcut already exists, click 'Replace'."
echo ""
read -r -p "Ready to start opening import dialogs? (will open ~32 files) [Y/n] " ans
if [[ "$ans" != "n" && "$ans" != "N" ]]; then
  for f in "$ROOT/shortcuts/sal-dictation"/*.shortcut; do
    open "$f"
    sleep 0.4
  done
  echo ""
  echo "All import dialogs opened. Click Add/Replace on each."
  echo ""
  read -r -p "Press Enter once you've imported them all to organize into 'Sal Demo' folder..."
  osascript "$ROOT/bin/organize-sal-shortcuts-into-folder.applescript"
fi

echo ""
echo "═══ Done ═══"
echo ""
echo "Next:"
echo "  1. Bind 'Hey Sal' as a Vocal Shortcut:"
echo "     System Settings → Accessibility → Speech → Vocal Shortcuts → +"
echo "     Phrase: Hey Sal   →  train 3x  →  Run Shortcut → Hey Sal"
echo ""
echo "  2. Run it: say 'Hey Sal' then 'Run Sal Demo' to play the WWDC 717 arc."
