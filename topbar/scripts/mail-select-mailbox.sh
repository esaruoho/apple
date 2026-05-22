#!/bin/bash
# mail-select-mailbox.sh <mailbox-name>
#
# Activate Mail.app and select the named row in the sidebar outline by walking
# the System Events tree. Original VIPs-only-working version, restored after
# 2026-05-22 session where I tried to extend it to Human Only / Free Energy
# and ended up flooding the system with keystrokes. Smart-mailbox navigation
# is parked pending a safer approach (e.g. dedicated CGEventPost helper that
# doesn't go through `keystroke`, or driving Mail via the Apple-events
# mailbox-favorites menu).

set -u
NAME="${1:-}"
[[ -z "$NAME" ]] && { echo "usage: $0 <mailbox-name>" >&2; exit 2; }

/usr/bin/osascript <<APPLESCRIPT
tell application "Mail" to activate
delay 0.3
tell application "System Events"
  tell process "Mail"
    set ol to outline 1 of scroll area 1 of splitter group 1 of window 1
    repeat with r in rows of ol
      try
        set u to UI element 1 of r
        set label_ to ""
        try
          set label_ to value of text field 1 of u
        on error
          try
            set label_ to value of static text 1 of u
          end try
        end try
        if label_ is "$NAME" then
          select r
          return "ok"
        end if
      end try
    end repeat
    return "not-found"
  end tell
end tell
APPLESCRIPT
