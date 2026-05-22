#!/bin/bash
# mail-select-mailbox.sh <mailbox-name>
#
# Activate Mail.app and select the named row in the sidebar outline by walking
# the System Events tree. Mail's AppleScript dict can't set smart mailboxes as
# selected (-10006) and `every mailbox` errors (-1728) on Sequoia, so this is
# the only reliable path.
#
# Each sidebar row has UI element 1 containing either a `static text` (folders,
# inboxes, VIPs, Flagged) or a `text field` (smart mailboxes). Both expose the
# row label as `value`, so we check both.
#
# Smart mailboxes (Human Only, Free Energy) live under a collapsible
# "Smart Mailboxes" header — when collapsed, their rows are NOT in the AX
# tree. Pre-expand every disclosure row before iterating so nested rows
# are reachable. Top-level rows like VIPs aren't affected.

set -u
NAME="${1:-}"
[[ -z "$NAME" ]] && { echo "usage: $0 <mailbox-name>" >&2; exit 2; }

/usr/bin/osascript <<APPLESCRIPT
tell application "Mail" to activate
delay 0.4
tell application "System Events"
  tell process "Mail"
    -- Pass 1: expand every disclosure row so nested rows (smart mailboxes
    -- under the "Smart Mailboxes" header, accounts under their roots) are
    -- present in the AX tree. Iterator proxy is fine here — we don't
    -- select inside this loop.
    set ol to outline 1 of scroll area 1 of splitter group 1 of window 1
    repeat with r in rows of ol
      try
        if value of attribute "AXDisclosing" of r is false then
          set value of attribute "AXDisclosing" of r to true
        end if
      end try
    end repeat
    delay 0.25  -- let the AX tree repopulate after the expansions

    -- Pass 2: index-walk to find the target's row number. Iterator
    -- proxies (\`repeat with r in rows of ol\`) go stale after the
    -- disclosure expansions on Sequoia and \`select\`-ing through them
    -- triggers a -1728 reference resolution error. Indices stay valid.
    set ol to outline 1 of scroll area 1 of splitter group 1 of window 1
    set tgtIdx to 0
    set n to count of rows of ol
    repeat with i from 1 to n
      try
        set u to UI element 1 of row i of ol
        set label_ to ""
        try
          set label_ to value of text field 1 of u
        on error
          try
            set label_ to value of static text 1 of u
          end try
        end try
        if label_ is "$NAME" then
          set tgtIdx to i
          exit repeat
        end if
      end try
    end repeat
    if tgtIdx is 0 then return "not-found"

    -- Pass 3: re-resolve the outline + select by index. Selecting via the
    -- fresh path keeps the entire reference chain valid through Mail's
    -- viewer repaint that the selection itself triggers.
    set ol to outline 1 of scroll area 1 of splitter group 1 of window 1
    select row tgtIdx of ol
    return "ok"
  end tell
end tell
APPLESCRIPT
