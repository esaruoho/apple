#!/bin/bash
# Launch AppleToolbox in --live mode (always-on-top floating viewport with
# hot-reload). If a live instance is already running, raise it instead.
#
# Safe to re-run.

set -e
TOPBAR="$(cd "$(dirname "$0")/.." && pwd)"
BIN="$TOPBAR/AppleToolbox.app/Contents/MacOS/AppleToolbox"

if [ ! -x "$BIN" ]; then
    echo "==> Building AppleToolbox first..."
    bash "$TOPBAR/build.sh"
fi

if pgrep -f "AppleToolbox --live" > /dev/null; then
    osascript -e 'tell application "System Events" to tell (first process whose name is "AppleToolbox") to set frontmost to true' 2>/dev/null || true
    echo "AppleToolbox --live already running; raised."
    exit 0
fi

nohup "$BIN" --live > /tmp/appletoolbox-live.log 2>&1 &
echo "Launched AppleToolbox --live (PID $!). Log: /tmp/appletoolbox-live.log"
