#!/usr/bin/env bash
# Phase 3 Path A — Install Sal's CitrusPeel libraries + helpers on current macOS.
#
# DEPRECATED-IN-PART (2026-05-07): macOS 15 (Sequoia) removed the Enhanced
# Dictation Commands runtime that read Custom Commands.plist. The library and
# helper installation steps remain useful as the substrate for Phase 3.5 (the
# Vocal Shortcuts importer) — but Step 3 (install Custom Commands.plist) is a
# no-op on Sequoia because no daemon reads that path anymore.
#
# Use this script to install the engine. Use bin/dictation-commands-to-shortcuts.py
# + bin/dictation-commands-vocal-shortcuts-import.py to wire the trigger surface.
# See analysis/sal/macos-sequoia-dictation-runtime-removal.md for details.
#
# Replaces the manual UI flow Sal shipped (1) Install Automation Tools.app with a
# scriptable installer. Safe to re-run any time. Logs everything.
#
# What this does:
#   1. Copies 18 .scptd AppleScriptObjC libraries to ~/Library/Script Libraries/
#   2. Copies 5 helper apps to ~/Library/Application Support/Dictation Commands/
#   3. Installs Custom Commands.plist into the macOS speech recognition prefs
#   4. Prints TCC consent reminders (Accessibility, Speech, Photos, Camera)
#
# What this does NOT do (cannot be scripted on Sequoia):
#   - Grant TCC consent (must be done manually in System Settings)
#   - Enable "Voice Control" toggle (System Settings → Accessibility → Voice Control)
#   - Resign apps for Gatekeeper (run `codesign --force --sign - <app>` if launches blocked)
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CITRUSPEEL="$REPO_ROOT/scripts/sal/dictation-commands/citruspeel-extracted/CitrusPeel"
DRY_RUN="${DRY_RUN:-0}"

if [[ ! -d "$CITRUSPEEL" ]]; then
  echo "ERROR: CitrusPeel not extracted. Run:"
  echo "  unzip -q sources/sal/macosxautomation.com/dictationcommands/CitrusPeel255.zip -d scripts/sal/dictation-commands/citruspeel-extracted/"
  exit 1
fi

LIB_DST="$HOME/Library/Script Libraries"
HELPER_DST="$HOME/Applications/Dictation Helper Apps"
PREF_DST="$HOME/Library/Preferences/com.apple.speech.recognition.AppleSpeechRecognition.CustomCommands.plist"

run() {
  if [[ "$DRY_RUN" == "1" ]]; then
    echo "DRY: $*"
  else
    echo "→ $*"
    "$@"
  fi
}

echo "== Phase 3 Path A — Sal Dictation Commands installer =="
echo "Repo: $REPO_ROOT"
echo "Libraries → $LIB_DST"
echo "Helpers   → $HELPER_DST"
echo "Prefs     → $PREF_DST"
echo "Dry run:  $DRY_RUN"
echo ""

run mkdir -p "$LIB_DST" "$HELPER_DST"

echo "Step 1: install 18 .scptd libraries"
for lib in "$CITRUSPEEL/Installation Items/Script Libraries/"*.scptd; do
  base=$(basename "$lib")
  run cp -R "$lib" "$LIB_DST/$base"
done

echo ""
echo "Step 2: install 5 helper apps"
for helper in "$CITRUSPEEL/Installation Items/Helper Apps/"*.app; do
  base=$(basename "$helper")
  run cp -R "$helper" "$HELPER_DST/$base"
done

echo ""
echo "Step 3: install Custom Commands.plist (DEPRECATED on macOS 15+)"
macos_major=$(sw_vers -productVersion | cut -d. -f1)
if [[ "$macos_major" -ge 15 ]]; then
  echo "  ⚠  macOS $macos_major detected. The Enhanced Dictation Commands runtime"
  echo "     that read this plist was removed in Sequoia. Skipping Step 3."
  echo "     Use bin/dictation-commands-vocal-shortcuts-import.py for the trigger surface."
  echo "     See analysis/sal/macos-sequoia-dictation-runtime-removal.md."
else
  if [[ -f "$PREF_DST" ]]; then
    ts=$(date +%Y%m%d-%H%M%S)
    run cp "$PREF_DST" "$PREF_DST.backup-$ts"
  fi
  run cp "$CITRUSPEEL/Custom Commands.plist" "$PREF_DST"
fi

echo ""
echo "Step 4: TCC consent reminders"
echo ""
echo "After install, you MUST manually grant these in System Settings → Privacy & Security:"
echo "  - Accessibility:    Helper apps need Accessibility for UI scripting"
echo "  - Automation:       Each app pair (Photos→Keynote, Numbers→Keynote, etc.) needs explicit consent"
echo "  - Photos:           DC-Photos needs Photos library access"
echo "  - Camera:           PictureTaker Helper needs Camera access for 'Take my picture'"
echo "  - Voice Control:    System Settings → Accessibility → Voice Control → ON"
echo "                      Then Commands… → import the new commands"
echo ""
echo "If a helper app refuses to launch, ad-hoc resign it:"
echo "  codesign --force --sign - '$HELPER_DST/<helper>.app'"
echo ""
echo "Done. Try a command: open Voice Control, say 'Take my picture'"
