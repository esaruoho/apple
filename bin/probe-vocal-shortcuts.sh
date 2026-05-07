#!/usr/bin/env bash
# Probe where Vocal Shortcuts stores its phrase→Shortcut mappings.
#
# Apple has not documented the storage location of Vocal Shortcuts (introduced
# macOS 15, Apple Silicon only). This script discovers it empirically by:
#   1. Looking at every plist domain whose name contains shortcut/vocal/speech/assistant
#   2. Looking at file-system locations Apple typically uses for such state
#   3. Detecting which file changes when you add/remove a Vocal Shortcut entry
#
# Run BEFORE adding a Vocal Shortcut, then run AFTER. Diff the two outputs.
# Pass run number as first arg (1 = before, 2 = after) to label the snapshot.
#
# Usage:
#   bash bin/probe-vocal-shortcuts.sh 1 > /tmp/vs-before.txt
#   <add a Vocal Shortcut in System Settings>
#   bash bin/probe-vocal-shortcuts.sh 2 > /tmp/vs-after.txt
#   diff /tmp/vs-before.txt /tmp/vs-after.txt
#
# Output is plain text. Send it to me.
set -uo pipefail
run="${1:-1}"

echo "=== run $run @ $(date -u +%Y-%m-%dT%H:%M:%SZ) ==="
echo "host: $(sw_vers -productName) $(sw_vers -productVersion) $(sw_vers -buildVersion)"
echo "arch: $(uname -m)"
echo ""

echo "=== plist domains matching shortcut/vocal/speech/assistant/accessibility ==="
defaults domains | tr ',' '\n' | sed 's/^ *//' | grep -iE "shortcut|vocal|speech|assistant|accessibility|siri" | sort -u
echo ""

echo "=== file-system candidates ==="
for d in \
  "$HOME/Library/Preferences" \
  "$HOME/Library/Application Support" \
  "$HOME/Library/Containers/com.apple.shortcuts" \
  "$HOME/Library/Group Containers" \
  "$HOME/Library/Mobile Documents/iCloud~is~workflow~my~workflows"
do
  if [[ -d "$d" ]]; then
    find "$d" -maxdepth 4 \( -iname "*vocal*" -o -iname "*shortcut*" -o -iname "*assistant*" -o -iname "*custom*command*" -o -iname "*WorkflowDB*" \) 2>/dev/null | head -20
  fi
done
echo ""

echo "=== sizes/mtimes of high-probability files (we'll diff these between runs) ==="
for f in \
  "$HOME/Library/Preferences/com.apple.Accessibility.plist" \
  "$HOME/Library/Preferences/com.apple.AssistantSettings.plist" \
  "$HOME/Library/Preferences/com.apple.SpeechRecognitionCore.plist" \
  "$HOME/Library/Preferences/com.apple.speech.recognition.AppleSpeechRecognition.prefs.plist" \
  "$HOME/Library/Application Support/com.apple.shortcuts" \
  "$HOME/Library/Group Containers/group.com.apple.shortcuts"
do
  if [[ -e "$f" ]]; then
    if [[ -f "$f" ]]; then
      stat -f "%z bytes  %Sm  %N" -t "%Y-%m-%dT%H:%M:%S" "$f"
    else
      du -sk "$f" 2>/dev/null | awk -v p="$f" '{printf "%s KB  (dir)  %s\n", $1, p}'
    fi
  fi
done
echo ""

echo "=== plist contents — top-level keys only ==="
for d in com.apple.Accessibility com.apple.AssistantSettings com.apple.SpeechRecognitionCore; do
  echo "--- $d ---"
  defaults read "$d" 2>/dev/null | head -40
  echo ""
done

echo "=== Shortcuts.app database files (if present) ==="
find "$HOME/Library/Group Containers" -name "WorkflowDB*" 2>/dev/null | while read f; do
  echo "  $(stat -f '%z bytes  %Sm' -t '%Y-%m-%dT%H:%M:%S' "$f")  $f"
done
echo ""

echo "=== TCC (does the Accessibility consent we need exist?) ==="
sqlite3 "$HOME/Library/Application Support/com.apple.TCC/TCC.db" \
  "SELECT service, client FROM access WHERE service IN ('kTCCServiceAccessibility','kTCCServiceListenEvent','kTCCServicePostEvent','kTCCServiceMicrophone','kTCCServiceSpeechRecognition') ORDER BY service, client;" \
  2>&1 | head -30
echo ""
echo "=== end run $run ==="
