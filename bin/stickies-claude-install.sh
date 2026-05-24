#!/bin/bash
# stickies-claude-install — install/uninstall the stickies → claude watcher
# as a LaunchAgent. Safe to re-run.
#
# Usage:
#   stickies-claude-install.sh           # install + load
#   stickies-claude-install.sh status    # show whether it's loaded
#   stickies-claude-install.sh run       # one-shot run (no LaunchAgent)
#   stickies-claude-install.sh uninstall # unload + remove plist
#   stickies-claude-install.sh tail      # tail the activity log

set -u
LABEL="com.esa.stickies-claude"
SRC_PLIST="/Users/esaruoho/work/apple/bin/${LABEL}.plist"
DST_PLIST="$HOME/Library/LaunchAgents/${LABEL}.plist"
WATCHER="/Users/esaruoho/work/apple/bin/stickies-claude-watcher"
LOG="$HOME/work/comms/queue/stickies-claude.log"

cmd=${1:-install}

case "$cmd" in
install)
    chmod +x "$WATCHER"
    mkdir -p "$(dirname "$DST_PLIST")"
    # If already loaded, unload first so the refreshed plist takes effect.
    launchctl unload "$DST_PLIST" 2>/dev/null || true
    cp "$SRC_PLIST" "$DST_PLIST"
    launchctl load "$DST_PLIST"
    echo "installed and loaded: $LABEL"
    echo "edit tag map: /Users/esaruoho/work/apple/etc/stickies-claude-tagmap.txt"
    echo "activity log: $LOG"
    ;;
uninstall)
    launchctl unload "$DST_PLIST" 2>/dev/null || true
    rm -f "$DST_PLIST"
    echo "uninstalled: $LABEL"
    ;;
status)
    if launchctl list | grep -q "$LABEL"; then
        launchctl list | grep "$LABEL"
    else
        echo "not loaded"
    fi
    ;;
run)
    exec "$WATCHER"
    ;;
tail)
    touch "$LOG"
    exec tail -f "$LOG"
    ;;
*)
    echo "usage: $(basename "$0") [install|uninstall|status|run|tail]"
    exit 2
    ;;
esac
