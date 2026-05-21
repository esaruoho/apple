#!/bin/bash
# UI-script GrandPerspective to scan a specific folder. The App Store build
# of GrandPerspective is sandboxed (only com.apple.security.files.user-selected.
# read-write), so paths passed via `open -a GrandPerspective <folder>` are
# silently ignored — GP falls back to whatever it can read (often its own
# container). To grant it access to a real path, the path must come through
# its File → Scan Folder… NSOpenPanel, which counts as user-selected and
# gets a security-scoped bookmark.
#
# Usage: grandperspective-scan-folder.sh [absolute-path]   (defaults to $HOME)
set -e

target="${1:-$HOME}"

# Dynamic-button behavior: if GrandPerspective is already running, just
# bring it to focus — don't open a new scan dialog on top of an existing
# scan the user is reading. Fresh scan only happens on a cold launch.
if pgrep -x "GrandPerspective" > /dev/null; then
    osascript -e 'tell application "GrandPerspective" to activate'
    exit 0
fi

osascript <<EOF
tell application "GrandPerspective" to activate
delay 0.5

tell application "System Events"
    tell process "GrandPerspective"
        click menu item "Scan Folder..." of menu "File" of menu bar 1
        delay 0.8
        -- Cmd+Shift+G = Go to folder dialog in any NSOpenPanel.
        keystroke "g" using {command down, shift down}
        delay 0.4
        keystroke "$target"
        delay 0.2
        keystroke return
        delay 0.5
        -- Confirm selection (Scan button).
        keystroke return
    end tell
end tell
EOF
