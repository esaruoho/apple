#!/usr/bin/env bash
# Install the voicebox-worker LaunchAgent so it starts at login + restarts on failure.
# Safe to re-run.

set -euo pipefail

PLIST_SRC="/Users/esaruoho/work/apple/bin/com.esa.voicebox-worker.plist"
PLIST_DEST="$HOME/Library/LaunchAgents/com.esa.voicebox-worker.plist"
LABEL="com.esa.voicebox-worker"

echo "=> Checking Voicebox is up on :17493 ..."
if ! curl -m 2 -fsS http://127.0.0.1:17493/health >/dev/null 2>&1; then
  echo "  WARNING: Voicebox is not responding. Worker will install but fail until you launch Voicebox.app."
fi

echo "=> Copying plist ..."
mkdir -p "$HOME/Library/LaunchAgents"
cp -v "$PLIST_SRC" "$PLIST_DEST"

echo "=> Booting out any previous instance ..."
launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || true

echo "=> Bootstrapping ..."
launchctl bootstrap "gui/$(id -u)" "$PLIST_DEST"

echo "=> Kickstart ..."
launchctl kickstart -k "gui/$(id -u)/$LABEL"

echo "=> Waiting 3s for first poll ..."
sleep 3

echo "=> Status:"
launchctl print "gui/$(id -u)/$LABEL" 2>&1 | grep -E "state|pid|last exit" | head -5 || true

echo
echo "✓ bootstrapped: $LABEL"
echo "tail logs:  tail -F ~/work/comms/queue/voicebox-worker.stdout"
echo "results:    ls -lt ~/work/comms/queue/voicebox-results/ | head -5"
echo
echo "(close this Terminal window when done)"
