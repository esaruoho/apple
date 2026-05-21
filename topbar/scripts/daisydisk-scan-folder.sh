#!/bin/bash
# UI-script DaisyDisk to scan a specific folder, bypassing its CLI's
# volume-reduction behavior. When `open -a DaisyDisk <folder>` is used,
# DaisyDisk reduces the path to the containing volume root — on APFS
# /Users/esaruoho firmlinks to /System/Volumes/Data so the scan target
# collapses to "Data". The Sal/Esa fix: drive the GUI directly via
# System Events. Action → Scan Folder… opens a standard NSOpenPanel, then
# Cmd+Shift+G ("Go to folder") accepts a literal path string.
#
# Usage: daisydisk-scan-folder.sh [absolute-path]   (defaults to $HOME)
set -e

target="${1:-$HOME}"

# Dynamic-button behavior: if DaisyDisk is already running, just bring
# it to focus — don't open a new scan dialog on top of an existing scan
# the user is reading. Fresh scan only happens on a cold launch.
if pgrep -x "DaisyDisk" > /dev/null; then
    osascript -e 'tell application "DaisyDisk" to activate'
    exit 0
fi

osascript <<EOF
tell application "DaisyDisk" to activate
delay 0.6

tell application "System Events"
    tell process "DaisyDisk"
        -- Cmd+O = "Scan Folder…" in DaisyDisk (Esa-confirmed shortcut).
        keystroke "o" using {command down}
    end tell

    -- Wait for the open panel sheet.
    repeat 30 times
        if exists window 1 of process "DaisyDisk" then
            if exists sheet 1 of window 1 of process "DaisyDisk" then exit repeat
        end if
        delay 0.1
    end repeat
    delay 0.2

    tell process "DaisyDisk"
        -- Go-to-folder dialog inside the open panel.
        keystroke "g" using {command down, shift down}
        delay 0.4
        -- Type the literal path. keystroke is fine for ASCII paths.
        keystroke "$target"
        delay 0.2
        keystroke return
        delay 0.5
        -- Confirm the selection (Open / Scan button).
        keystroke return
    end tell
end tell
EOF
