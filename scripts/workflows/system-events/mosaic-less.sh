#!/bin/bash
# Mosaic Less: show one fewer window of the frontmost app, tiled.
# Loupedeck knob turn LEFT. Pair with mosaic-more.sh for knob turn RIGHT.
# Loupedeck: /Users/esaruoho/work/apple/scripts/workflows/system-events/mosaic-less.sh

STATE_FILE="/tmp/mosaic-knob-state"

# Read current state (default high so first left-turn shows all-minus-one)
if [ -f "$STATE_FILE" ]; then
    SHOW=$(cat "$STATE_FILE")
else
    SHOW=999
fi

# Decrement (floor at 1)
SHOW=$((SHOW - 1))
if [ "$SHOW" -lt 1 ]; then SHOW=1; fi

# Save state
echo "$SHOW" > "$STATE_FILE"

osascript - "$SHOW" <<'APPLESCRIPT'
use framework "AppKit"

on run argv
    set showCount to (item 1 of argv) as integer

    set mainScreen to current application's NSScreen's mainScreen()
    set screenFrame to mainScreen's visibleFrame()
    set sX to (item 1 of item 1 of screenFrame) as integer
    set sY to (item 2 of item 1 of screenFrame) as integer
    set sW to (item 1 of item 2 of screenFrame) as integer
    set sH to (item 2 of item 2 of screenFrame) as integer
    set mainFrame to mainScreen's frame()
    set totalH to (item 2 of item 2 of mainFrame) as integer
    set menuBarH to totalH - sH - sY

    tell application "System Events"
        set fp to first process whose frontmost is true
        set appName to name of fp
        set winCount to count of windows of fp
    end tell

    if winCount is 0 then return "No windows"

    -- Cap at window count
    if showCount > winCount then set showCount to winCount
    if showCount < 1 then set showCount to 1

    -- Calculate best grid
    set bestCols to 1
    set bestRows to showCount
    set bestRatio to 999
    repeat with c from 1 to showCount
        set r to ((showCount + c - 1) div c)
        set cellW2 to sW / c
        set cellH2 to sH / r
        set ratio to cellW2 / cellH2
        set diff to (ratio - 1.6)
        if diff < 0 then set diff to diff * -1
        if diff < bestRatio then
            set bestRatio to diff
            set bestCols to c
            set bestRows to r
        end if
    end repeat

    set cellW to sW div bestCols
    set cellH to sH div bestRows

    tell application "System Events"
        repeat with i from 1 to showCount
            set idx to i - 1
            set c to idx mod bestCols
            set r to idx div bestCols
            set winX to sX + (c * cellW)
            set winY to menuBarH + (r * cellH)
            try
                set position of window i of fp to {winX, winY}
                set size of window i of fp to {cellW, cellH}
            end try
        end repeat

        repeat with i from (showCount + 1) to winCount
            try
                click (first button of window i of fp whose subrole is "AXMinimizeButton")
            end try
        end repeat
    end tell

    return appName & ": " & showCount & "/" & winCount
end run
APPLESCRIPT
