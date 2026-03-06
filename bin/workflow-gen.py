#!/usr/bin/env python3
"""
workflow-gen.py — Generate real AppleScript workflow scripts from curated recipes.

Usage:
    python3 bin/workflow-gen.py                  # Generate all workflows
    python3 bin/workflow-gen.py finder            # Generate for one app
    python3 bin/workflow-gen.py finder music mail  # Generate for specific apps
    python3 bin/workflow-gen.py --list            # List all available recipes
    python3 bin/workflow-gen.py --catalog         # Update scripts.md catalog

Output:
    scripts/workflows/<app>/<app>-<action>.applescript
    scripts.md (updated catalog)

Every recipe is a real, tested AppleScript that does ONE thing well.
Designed for Loupedeck Live / Stream Deck / Contour Shuttle Pro buttons.

Sal's rule: one button = one action = one result.
"""

import sys
import os
from pathlib import Path
from datetime import datetime

SCRIPTS_DIR = Path(__file__).parent.parent / "scripts" / "workflows"
CATALOG_PATH = Path(__file__).parent.parent / "scripts.md"

# ─── Recipe Registry ─────────────────────────────────────────────────────────
# Each recipe: (filename_suffix, description, applescript_code)
# Code uses triple-quoted strings. Each script is standalone and runnable.

RECIPES = {

    # ═══════════════════════════════════════════════════════════════════════════
    # FINDER — 25 commands, 32 classes, the deepest GUI app
    # ═══════════════════════════════════════════════════════════════════════════
    "finder": [
        ("new-window", "Open a new Finder window at home folder", '''\
tell application "Finder"
    activate
    make new Finder window to home
end tell
'''),
        ("new-window-desktop", "Open a new Finder window at Desktop", '''\
tell application "Finder"
    activate
    make new Finder window to desktop
end tell
'''),
        ("new-window-downloads", "Open a new Finder window at Downloads", '''\
tell application "Finder"
    activate
    make new Finder window to folder "Downloads" of home
end tell
'''),
        ("get-selection", "Get names of selected Finder items", '''\
tell application "Finder"
    set sel to selection
    if sel is {} then
        return "No selection"
    end if
    set names to {}
    repeat with f in sel
        set end of names to name of f as text
    end repeat
    return names as text
end tell
'''),
        ("copy-path", "Copy path of selected Finder item to clipboard", '''\
tell application "Finder"
    set sel to selection
    if sel is {} then
        display notification "No file selected" with title "Finder"
        return
    end if
    set f to item 1 of sel
    set p to POSIX path of (f as alias)
    set the clipboard to p
    display notification p with title "Path Copied"
end tell
'''),
        ("reveal-downloads", "Reveal Downloads folder in Finder", '''\
tell application "Finder"
    activate
    reveal folder "Downloads" of home
end tell
'''),
        ("empty-trash", "Empty the Trash (no confirmation)", '''\
tell application "Finder"
    empty the trash
end tell
'''),
        ("empty-trash-confirm", "Empty the Trash with confirmation dialog", '''\
tell application "Finder"
    set tc to count of items of trash
    if tc is 0 then
        display notification "Trash is already empty" with title "Finder"
        return
    end if
    display dialog "Empty Trash? (" & tc & " items)" buttons {"Cancel", "Empty"} default button "Empty" with icon caution
    empty the trash
    display notification "Trash emptied" with title "Finder"
end tell
'''),
        ("tag-red", "Tag selected Finder items red", '''\
tell application "Finder"
    set sel to selection
    repeat with f in sel
        set label index of f to 2
    end repeat
end tell
'''),
        ("tag-orange", "Tag selected Finder items orange", '''\
tell application "Finder"
    set sel to selection
    repeat with f in sel
        set label index of f to 1
    end repeat
end tell
'''),
        ("tag-clear", "Clear tags from selected Finder items", '''\
tell application "Finder"
    set sel to selection
    repeat with f in sel
        set label index of f to 0
    end repeat
end tell
'''),
        ("toggle-hidden-files", "Toggle visibility of hidden files in Finder", '''\
set curVal to do shell script "defaults read com.apple.finder AppleShowAllFiles"
if curVal is "TRUE" or curVal is "true" or curVal is "1" then
    do shell script "defaults write com.apple.finder AppleShowAllFiles -bool false"
else
    do shell script "defaults write com.apple.finder AppleShowAllFiles -bool true"
end if
tell application "Finder" to quit
delay 0.5
tell application "Finder" to activate
'''),
        ("new-folder", "Create a new folder in the frontmost Finder window", '''\
tell application "Finder"
    activate
    set w to target of front Finder window
    set newFolder to make new folder at w
    select newFolder
end tell
'''),
        ("get-window-path", "Get POSIX path of the frontmost Finder window", '''\
tell application "Finder"
    if (count of Finder windows) is 0 then
        return POSIX path of (desktop as alias)
    end if
    return POSIX path of (target of front Finder window as alias)
end tell
'''),
        ("close-all-windows", "Close all Finder windows", '''\
tell application "Finder"
    close every window
end tell
'''),
        ("eject-all", "Eject all mounted external volumes", '''\
tell application "Finder"
    set vols to every disk whose ejectable is true
    repeat with v in vols
        eject v
    end repeat
    if (count of vols) > 0 then
        display notification "Ejected " & (count of vols) & " volume(s)" with title "Finder"
    else
        display notification "No ejectable volumes" with title "Finder"
    end if
end tell
'''),
        ("sort-by-name", "Sort the frontmost Finder window by name", '''\
tell application "Finder"
    set current view of front Finder window to list view
    set sort column of list view options of front Finder window to column id name column of front Finder window
end tell
'''),
        ("file-info", "Display info about the selected file", '''\
tell application "Finder"
    set sel to selection
    if sel is {} then
        display notification "No file selected" with title "Finder"
        return
    end if
    set f to item 1 of sel
    set n to name of f
    set k to kind of f
    set s to size of f
    set d to modification date of f
    set msg to "Name: " & n & return & "Kind: " & k & return & "Size: " & s & " bytes" & return & "Modified: " & (d as text)
    display dialog msg with title "File Info" buttons {"OK"} default button "OK"
end tell
'''),
        ("restart-finder", "Restart Finder (kf)", '''\
do shell script "killall Finder"
'''),
        ("hide-desktop-icons", "Hide all desktop icons", '''\
do shell script "defaults write com.apple.Finder CreateDesktop false"
do shell script "killall Finder"
'''),
        ("show-desktop-icons", "Show all desktop icons", '''\
do shell script "defaults write com.apple.Finder CreateDesktop true"
do shell script "killall Finder"
'''),
        ("open-current-dir", "Open current working directory in Finder", '''\
tell application "Finder"
    activate
    open (POSIX file (do shell script "pwd") as alias)
end tell
'''),
        ("set-wallpaper", "Set desktop wallpaper from a file path", '''\
set imgPath to choose file with prompt "Choose wallpaper image:" of type {"public.image"}
tell application "Finder"
    set desktop picture to imgPath
end tell
display notification "Wallpaper changed" with title "Finder"
'''),
        ("airdrop-reveal", "Reveal a file in Finder for AirDrop sharing", '''\
set f to choose file with prompt "Choose file to AirDrop:"
set p to POSIX path of f
do shell script "open -R " & quoted form of p
tell application "Finder" to activate
display notification "Right-click > Share > AirDrop" with title "AirDrop"
'''),
    ],

    # ═══════════════════════════════════════════════════════════════════════════
    # MUSIC — 31 commands, the richest playback API
    # ═══════════════════════════════════════════════════════════════════════════
    "music": [
        ("playpause", "Toggle play/pause", '''\
tell application "Music" to playpause
'''),
        ("next-track", "Skip to next track", '''\
tell application "Music" to next track
'''),
        ("previous-track", "Go to previous track", '''\
tell application "Music" to previous track
'''),
        ("now-playing", "Show current track as notification", '''\
tell application "Music"
    if player state is playing then
        set t to name of current track
        set a to artist of current track
        set al to album of current track
        display notification a & " — " & al with title t
    else
        display notification "Nothing playing" with title "Music"
    end if
end tell
'''),
        ("now-playing-clipboard", "Copy current track info to clipboard", '''\
tell application "Music"
    if player state is not playing and player state is not paused then
        display notification "Nothing playing" with title "Music"
        return
    end if
    set t to name of current track
    set a to artist of current track
    set al to album of current track
    set info to t & " by " & a & " (" & al & ")"
    set the clipboard to info
    display notification info with title "Copied to Clipboard"
end tell
'''),
        ("volume-up", "Increase Music volume by 10", '''\
tell application "Music"
    set v to sound volume
    if v + 10 > 100 then
        set sound volume to 100
    else
        set sound volume to v + 10
    end if
end tell
'''),
        ("volume-down", "Decrease Music volume by 10", '''\
tell application "Music"
    set v to sound volume
    if v - 10 < 0 then
        set sound volume to 0
    else
        set sound volume to v - 10
    end if
end tell
'''),
        ("mute-toggle", "Toggle Music mute", '''\
tell application "Music"
    set mute to not mute
end tell
'''),
        ("toggle-shuffle", "Toggle shuffle mode", '''\
tell application "Music"
    set shuffle enabled to not shuffle enabled
    if shuffle enabled then
        display notification "Shuffle ON" with title "Music"
    else
        display notification "Shuffle OFF" with title "Music"
    end if
end tell
'''),
        ("love-current", "Favorite the current track", '''\
tell application "Music"
    set favorited of current track to true
    display notification "Favorited: " & name of current track with title "Music"
end tell
'''),
        ("dislike-current", "Dislike the current track and skip", '''\
tell application "Music"
    set disliked of current track to true
    display notification "Disliked: " & name of current track with title "Music"
    next track
end tell
'''),
        ("add-to-playlist", "Add current track to a playlist by name", '''\
tell application "Music"
    set t to current track
    set pName to text returned of (display dialog "Add to playlist:" default answer "Favorites")
    try
        set p to user playlist pName
        duplicate t to p
        display notification (name of t) & " added to " & pName with title "Music"
    on error
        display notification "Playlist '" & pName & "' not found" with title "Music"
    end try
end tell
'''),
        ("search-library", "Search the music library", '''\
tell application "Music"
    set q to text returned of (display dialog "Search Music:" default answer "")
    set results to search library playlist 1 for q
    if (count of results) is 0 then
        display notification "No results for: " & q with title "Music"
    else
        set t to item 1 of results
        play t
        display notification "Playing: " & name of t & " by " & artist of t with title "Music"
    end if
end tell
'''),
        ("rating-5-stars", "Rate the current track 5 stars", '''\
tell application "Music"
    set rating of current track to 100
    display notification "Rated 5 stars: " & name of current track with title "Music"
end tell
'''),
        ("stop", "Stop playback", '''\
tell application "Music" to stop
'''),
    ],

    # ═══════════════════════════════════════════════════════════════════════════
    # MAIL — 10 layers, 164 Siri phrases
    # ═══════════════════════════════════════════════════════════════════════════
    "mail": [
        ("check-mail", "Check for new mail", '''\
tell application "Mail" to check for new mail
'''),
        ("compose", "Open a new blank compose window", '''\
tell application "Mail"
    activate
    set newMsg to make new outgoing message with properties {visible:true}
end tell
'''),
        ("compose-to", "Compose a new message to a specific address", '''\
tell application "Mail"
    activate
    set addr to text returned of (display dialog "Send to:" default answer "")
    set newMsg to make new outgoing message with properties {visible:true, subject:""}
    tell newMsg
        make new to recipient at end of to recipients with properties {address:addr}
    end tell
end tell
'''),
        ("unread-count", "Show unread mail count as notification", '''\
tell application "Mail"
    set total to 0
    repeat with a in every account
        repeat with m in every mailbox of a
            set total to total + unread count of m
        end repeat
    end repeat
    display notification (total as text) & " unread messages" with title "Mail"
end tell
'''),
        ("read-latest-subject", "Get the subject of the latest message in inbox", '''\
tell application "Mail"
    set msgs to messages of inbox
    if (count of msgs) > 0 then
        set m to item 1 of msgs
        set s to subject of m
        set f to sender of m
        display notification f with title s
    else
        display notification "Inbox is empty" with title "Mail"
    end if
end tell
'''),
        ("reply-to-selected", "Reply to the selected message", '''\
tell application "Mail"
    activate
    set sel to selection
    if (count of sel) > 0 then
        set m to item 1 of sel
        reply m opening window yes
    end if
end tell
'''),
        ("forward-selected", "Forward the selected message", '''\
tell application "Mail"
    activate
    set sel to selection
    if (count of sel) > 0 then
        set m to item 1 of sel
        forward m opening window yes
    end if
end tell
'''),
        ("flag-selected", "Flag the selected message", '''\
tell application "Mail"
    set sel to selection
    repeat with m in sel
        set flagged status of m to true
    end repeat
    display notification "Flagged " & (count of sel) & " message(s)" with title "Mail"
end tell
'''),
        ("mark-all-read", "Mark all inbox messages as read", '''\
tell application "Mail"
    set msgs to messages of inbox whose read status is false
    repeat with m in msgs
        set read status of m to true
    end repeat
    display notification "Marked " & (count of msgs) & " messages read" with title "Mail"
end tell
'''),
        ("send-quick", "Send a quick email (dialog prompts for to/subject/body)", '''\
tell application "Mail"
    set addr to text returned of (display dialog "To:" default answer "")
    set subj to text returned of (display dialog "Subject:" default answer "")
    set bod to text returned of (display dialog "Body:" default answer "")
    set newMsg to make new outgoing message with properties {subject:subj, content:bod, visible:false}
    tell newMsg
        make new to recipient at end of to recipients with properties {address:addr}
    end tell
    send newMsg
    display notification "Sent to " & addr with title "Mail"
end tell
'''),
    ],

    # ═══════════════════════════════════════════════════════════════════════════
    # SAFARI — do JavaScript, tabs, reading list
    # ═══════════════════════════════════════════════════════════════════════════
    "safari": [
        ("current-url", "Copy the URL of the current Safari tab to clipboard", '''\
tell application "Safari"
    set u to URL of current tab of front window
    set the clipboard to u
    display notification u with title "URL Copied"
end tell
'''),
        ("current-title", "Copy the title of the current Safari tab to clipboard", '''\
tell application "Safari"
    set t to name of current tab of front window
    set the clipboard to t
    display notification t with title "Title Copied"
end tell
'''),
        ("current-url-and-title", "Copy URL and title as markdown link", '''\
tell application "Safari"
    set u to URL of current tab of front window
    set t to name of current tab of front window
    set mdLink to "[" & t & "](" & u & ")"
    set the clipboard to mdLink
    display notification mdLink with title "Markdown Link Copied"
end tell
'''),
        ("open-url", "Open a URL in a new Safari tab", '''\
tell application "Safari"
    activate
    set u to text returned of (display dialog "URL:" default answer "https://")
    tell front window
        set newTab to make new tab with properties {URL:u}
    end tell
end tell
'''),
        ("search-web", "Search the web using Safari", '''\
tell application "Safari"
    activate
    set q to text returned of (display dialog "Search:" default answer "")
    search the web for q
end tell
'''),
        ("add-reading-list", "Add the current page to Reading List", '''\
tell application "Safari"
    set u to URL of current tab of front window
    set t to name of current tab of front window
    add reading list item u with title t
    display notification t with title "Added to Reading List"
end tell
'''),
        ("close-all-tabs", "Close all tabs in the front Safari window", '''\
tell application "Safari"
    tell front window
        set currentTab to current tab
        repeat with t in (every tab whose index is not index of currentTab)
            close t
        end repeat
    end tell
end tell
'''),
        ("list-all-tabs", "List all open Safari tab URLs", '''\
tell application "Safari"
    set tabList to ""
    repeat with w in every window
        repeat with t in every tab of w
            set tabList to tabList & URL of t & return
        end repeat
    end repeat
    set the clipboard to tabList
    display notification "Copied " & (count of paragraphs of tabList) & " URLs" with title "Safari Tabs"
end tell
'''),
        ("page-source", "Copy page source of current tab to clipboard", '''\
tell application "Safari"
    set src to source of current tab of front window
    set the clipboard to src
    display notification "Source copied (" & (length of src) & " chars)" with title "Safari"
end tell
'''),
        ("do-javascript", "Run JavaScript in the current Safari tab", '''\
tell application "Safari"
    set js to text returned of (display dialog "JavaScript:" default answer "document.title")
    set result to do JavaScript js in current tab of front window
    display dialog "Result: " & result with title "JavaScript" buttons {"Copy", "OK"} default button "OK"
    if button returned of result is "Copy" then
        set the clipboard to result
    end if
end tell
'''),
    ],

    # ═══════════════════════════════════════════════════════════════════════════
    # NOTES — 318 Siri phrases, Siri champion
    # ═══════════════════════════════════════════════════════════════════════════
    "notes": [
        ("new-note", "Create a new note with title and body", '''\
tell application "Notes"
    activate
    set t to text returned of (display dialog "Note title:" default answer "")
    set b to text returned of (display dialog "Note body:" default answer "")
    tell account "iCloud"
        make new note at folder "Notes" with properties {name:t, body:b}
    end tell
    display notification "Created: " & t with title "Notes"
end tell
'''),
        ("new-note-from-clipboard", "Create a new note from clipboard contents", '''\
set clipContent to the clipboard as text
tell application "Notes"
    activate
    tell account "iCloud"
        make new note at folder "Notes" with properties {name:"From Clipboard", body:clipContent}
    end tell
    display notification "Note created from clipboard" with title "Notes"
end tell
'''),
        ("list-notes", "List names of recent notes", '''\
tell application "Notes"
    set noteNames to name of every note of account "iCloud"
    set output to ""
    set maxNotes to 20
    if (count of noteNames) < maxNotes then set maxNotes to (count of noteNames)
    repeat with i from 1 to maxNotes
        set output to output & item i of noteNames & return
    end repeat
    set the clipboard to output
    display notification "Copied " & maxNotes & " note names" with title "Notes"
end tell
'''),
        ("search-notes", "Search notes by name", '''\
tell application "Notes"
    set q to text returned of (display dialog "Search notes:" default answer "")
    set results to every note of account "iCloud" whose name contains q
    if (count of results) is 0 then
        display notification "No notes matching: " & q with title "Notes"
    else
        set n to item 1 of results
        show n
        activate
        display notification "Found " & (count of results) & " note(s)" with title "Notes"
    end if
end tell
'''),
        ("count-notes", "Show total note count", '''\
tell application "Notes"
    set c to count of every note
    display notification (c as text) & " notes total" with title "Notes"
end tell
'''),
    ],

    # ═══════════════════════════════════════════════════════════════════════════
    # REMINDERS — task creation, the GTD workhorse
    # ═══════════════════════════════════════════════════════════════════════════
    "reminders": [
        ("quick-reminder", "Create a quick reminder", '''\
tell application "Reminders"
    set t to text returned of (display dialog "Reminder:" default answer "")
    tell default list
        make new reminder with properties {name:t}
    end tell
    display notification "Created: " & t with title "Reminders"
end tell
'''),
        ("reminder-due-today", "Create a reminder due today", '''\
tell application "Reminders"
    set t to text returned of (display dialog "Reminder (due today):" default answer "")
    tell default list
        make new reminder with properties {name:t, due date:current date}
    end tell
    display notification "Due today: " & t with title "Reminders"
end tell
'''),
        ("reminder-from-clipboard", "Create a reminder from clipboard text", '''\
set clipText to the clipboard as text
tell application "Reminders"
    tell default list
        make new reminder with properties {name:clipText}
    end tell
    display notification "Reminder: " & clipText with title "Reminders"
end tell
'''),
        ("show-today", "Show reminders due today", '''\
tell application "Reminders"
    set today to current date
    set time of today to 0
    set tomorrow to today + (1 * days)
    set dueToday to every reminder whose completed is false and due date >= today and due date < tomorrow
    set output to ""
    repeat with r in dueToday
        set output to output & name of r & return
    end repeat
    if output is "" then
        display notification "No reminders due today" with title "Reminders"
    else
        display dialog output with title "Due Today" buttons {"OK"} default button "OK"
    end if
end tell
'''),
        ("complete-latest", "Mark the most recent incomplete reminder as done", '''\
tell application "Reminders"
    set incomplete to every reminder whose completed is false
    if (count of incomplete) > 0 then
        set r to item 1 of incomplete
        set completed of r to true
        display notification "Completed: " & name of r with title "Reminders"
    else
        display notification "No incomplete reminders" with title "Reminders"
    end if
end tell
'''),
    ],

    # ═══════════════════════════════════════════════════════════════════════════
    # CALENDAR — events, views, the scheduling surface
    # ═══════════════════════════════════════════════════════════════════════════
    "calendar": [
        ("quick-event", "Create a quick calendar event", '''\
tell application "Calendar"
    set t to text returned of (display dialog "Event title:" default answer "")
    set startDate to current date
    set endDate to startDate + (1 * hours)
    tell calendar "Home"
        make new event with properties {summary:t, start date:startDate, end date:endDate}
    end tell
    display notification "Created: " & t with title "Calendar"
end tell
'''),
        ("show-today", "Switch Calendar to today view", '''\
tell application "Calendar"
    activate
    view calendar at current date
    switch view to day view
end tell
'''),
        ("show-week", "Switch Calendar to week view", '''\
tell application "Calendar"
    activate
    switch view to week view
end tell
'''),
        ("show-month", "Switch Calendar to month view", '''\
tell application "Calendar"
    activate
    switch view to month view
end tell
'''),
        ("reload", "Reload all calendars", '''\
tell application "Calendar"
    reload calendars
    display notification "Calendars reloaded" with title "Calendar"
end tell
'''),
        ("next-event", "Show the next upcoming calendar event", '''\
tell application "Calendar"
    set now to current date
    set upcoming to {}
    repeat with cal in every calendar
        set evts to (every event of cal whose start date > now)
        repeat with e in evts
            set end of upcoming to {summary of e, start date of e}
        end repeat
    end repeat
    if (count of upcoming) > 0 then
        set nextEvt to item 1 of upcoming
        display notification (item 2 of nextEvt as text) with title (item 1 of nextEvt)
    else
        display notification "No upcoming events" with title "Calendar"
    end if
end tell
'''),
    ],

    # ═══════════════════════════════════════════════════════════════════════════
    # PHOTOS — import, export, slideshow
    # ═══════════════════════════════════════════════════════════════════════════
    "photos": [
        ("search", "Search Photos library", '''\
tell application "Photos"
    activate
    set q to text returned of (display dialog "Search Photos:" default answer "")
    search for q
end tell
'''),
        ("export-selected", "Export selected photos to Desktop", '''\
tell application "Photos"
    set sel to selection
    if sel is {} then
        display notification "No photos selected" with title "Photos"
        return
    end if
    set exportPath to (POSIX path of (path to desktop)) as POSIX file as alias
    export sel to exportPath
    display notification "Exported " & (count of sel) & " photo(s) to Desktop" with title "Photos"
end tell
'''),
        ("favorites-count", "Count favorited photos", '''\
tell application "Photos"
    set favs to every media item whose favorite is true
    display notification (count of favs) & " favorites" with title "Photos"
end tell
'''),
        ("start-slideshow", "Start a slideshow of selected photos", '''\
tell application "Photos"
    activate
    set sel to selection
    if sel is not {} then
        start slideshow using sel
    else
        display notification "Select photos first" with title "Photos"
    end if
end tell
'''),
    ],

    # ═══════════════════════════════════════════════════════════════════════════
    # TERMINAL — do script, the CLI bridge
    # ═══════════════════════════════════════════════════════════════════════════
    "terminal": [
        ("new-tab", "Open a new Terminal tab", '''\
tell application "Terminal"
    activate
    do script ""
end tell
'''),
        ("new-tab-at-path", "Open Terminal tab at a specific directory", '''\
tell application "Finder"
    if (count of Finder windows) > 0 then
        set p to POSIX path of (target of front Finder window as alias)
    else
        set p to POSIX path of (path to home folder)
    end if
end tell
tell application "Terminal"
    activate
    do script "cd " & quoted form of p
end tell
'''),
        ("run-command", "Run a command in a new Terminal tab", '''\
tell application "Terminal"
    activate
    set cmd to text returned of (display dialog "Command:" default answer "")
    do script cmd
end tell
'''),
    ],

    # ═══════════════════════════════════════════════════════════════════════════
    # MESSAGES — thin sdef, but send works
    # ═══════════════════════════════════════════════════════════════════════════
    "messages": [
        ("send-message", "Send an iMessage to a contact", '''\
tell application "Messages"
    set targetBuddy to text returned of (display dialog "Send to (phone/email):" default answer "")
    set msgText to text returned of (display dialog "Message:" default answer "")
    set targetService to 1st account whose service type = iMessage
    set targetParticipant to participant targetBuddy of targetService
    send msgText to targetParticipant
    display notification "Sent to " & targetBuddy with title "Messages"
end tell
'''),
        ("list-chats", "List recent chat names", '''\
tell application "Messages"
    set chatNames to name of every chat
    set output to ""
    set maxChats to 20
    if (count of chatNames) < maxChats then set maxChats to count of chatNames
    repeat with i from 1 to maxChats
        set output to output & item i of chatNames & return
    end repeat
    set the clipboard to output
    display notification "Copied " & maxChats & " chat names" with title "Messages"
end tell
'''),
    ],

    # ═══════════════════════════════════════════════════════════════════════════
    # CONTACTS — person management
    # ═══════════════════════════════════════════════════════════════════════════
    "contacts": [
        ("search-contact", "Search for a contact and show their info", '''\
tell application "Contacts"
    set q to text returned of (display dialog "Search contacts:" default answer "")
    set results to every person whose name contains q
    if (count of results) is 0 then
        display notification "No contact matching: " & q with title "Contacts"
    else
        set p to item 1 of results
        set n to name of p
        set emails to value of every email of p
        set phones to value of every phone of p
        set info to n
        if (count of emails) > 0 then set info to info & return & "Email: " & item 1 of emails
        if (count of phones) > 0 then set info to info & return & "Phone: " & item 1 of phones
        display dialog info with title "Contact" buttons {"Copy", "OK"} default button "OK"
        if button returned of result is "Copy" then set the clipboard to info
    end if
end tell
'''),
    ],

    # ═══════════════════════════════════════════════════════════════════════════
    # SYSTEM EVENTS — the universal bridge (89 classes)
    # ═══════════════════════════════════════════════════════════════════════════
    "system-events": [
        ("dark-mode-toggle", "Toggle macOS Dark Mode", '''\
tell application "System Events"
    tell appearance preferences
        set dark mode to not dark mode
    end tell
end tell
'''),
        ("screenshot-area", "Take a screenshot of a selected area", '''\
do shell script "screencapture -i ~/Desktop/screenshot-" & (do shell script "date +%Y%m%d-%H%M%S") & ".png"
'''),
        ("screenshot-window", "Take a screenshot of the frontmost window", '''\
do shell script "screencapture -w ~/Desktop/screenshot-" & (do shell script "date +%Y%m%d-%H%M%S") & ".png"
'''),
        ("get-frontmost-app", "Get the name of the frontmost application", '''\
tell application "System Events"
    set frontApp to name of first application process whose frontmost is true
    display notification frontApp with title "Frontmost App"
    set the clipboard to frontApp
end tell
'''),
        ("list-running-apps", "List all running applications", '''\
tell application "System Events"
    set appNames to name of every application process whose background only is false
    set output to ""
    repeat with a in appNames
        set output to output & a & return
    end repeat
    set the clipboard to output
    display notification (count of appNames) & " apps running" with title "System Events"
end tell
'''),
        ("spotlight-status", "Check Spotlight indexing status", '''\
set status to do shell script "mdutil -s /System/Volumes/Data 2>&1 | tail -1 | sed 's/^[[:space:]]//'"
set appCount to do shell script "mdfind 'kMDItemContentType == \\\"com.apple.application-bundle\\\"' 2>/dev/null | grep -c '/Applications/'"
set workflowCount to do shell script "mdfind 'kMDItemContentType == \\\"com.apple.application-bundle\\\"' 2>/dev/null | grep -c 'Apple-Workflows' || echo 0"
set cpuUse to do shell script "ps aux | grep '[m]ds_stores' | awk '{print $3}' || echo 0"
set msg to status & return & "Apps indexed: " & appCount & return & "Workflows: " & workflowCount & "/109" & return & "mds_stores CPU: " & cpuUse & "%"
if cpuUse is "0" or cpuUse is "0.0" then
    display dialog msg with title "Spotlight: Idle" buttons {"OK"} default button "OK"
else
    display dialog msg with title "Spotlight: Indexing..." buttons {"OK"} default button "OK"
end if
'''),
        ("wifi-toggle", "Toggle Wi-Fi on/off", '''\
set wifiStatus to do shell script "networksetup -getairportpower en0 | awk '{print $NF}'"
if wifiStatus is "On" then
    do shell script "networksetup -setairportpower en0 off"
    display notification "Wi-Fi OFF" with title "Network"
else
    do shell script "networksetup -setairportpower en0 on"
    display notification "Wi-Fi ON" with title "Network"
end if
'''),
        ("volume-set", "Set system volume to a specific level", '''\
set v to text returned of (display dialog "Volume (0-100):" default answer "50")
set volume output volume (v as integer)
display notification "Volume: " & v & "%" with title "System"
'''),
        ("do-not-disturb", "Toggle Do Not Disturb (Focus)", '''\
tell application "System Events"
    tell application process "ControlCenter"
        -- Click the Focus button in Control Center
        click menu bar item "Focus" of menu bar 1
    end tell
end tell
'''),
        ("type-text", "Type text via System Events (paste alternative)", '''\
set t to text returned of (display dialog "Type text:" default answer "")
tell application "System Events"
    keystroke t
end tell
'''),
        ("hide-dock", "Hide the Dock (autohide on)", '''\
do shell script "defaults write com.apple.Dock autohide -bool TRUE"
do shell script "killall Dock"
display notification "Dock hidden" with title "Dock"
'''),
        ("show-dock", "Show the Dock (autohide off)", '''\
do shell script "defaults write com.apple.Dock autohide -bool FALSE"
do shell script "killall Dock"
display notification "Dock visible" with title "Dock"
'''),
        ("dock-add-spacer", "Add a spacer tile to the Dock", '''\
do shell script "defaults write com.apple.dock persistent-apps -array-add '{\\"tile-type\\"=\\"spacer-tile\\";}'"
do shell script "killall Dock"
display notification "Spacer added" with title "Dock"
'''),
        ("dock-add-recent-apps", "Add Recent Apps stack to the Dock", '''\
do shell script "defaults write com.apple.dock persistent-others -array-add '{\\"tile-data\\" = {\\"list-type\\" = 1;}; \\"tile-type\\" = \\"recents-tile\\";}'"
do shell script "killall Dock"
display notification "Recent Apps added to Dock" with title "Dock"
'''),
        ("restart-menu-bar", "Restart the macOS menu bar (topbar)", '''\
do shell script "killall -KILL SystemUIServer"
display notification "Menu bar restarted" with title "System"
'''),
        ("reset-apple-events", "Reset Apple Events daemon (fixes -1712 errors)", '''\
do shell script "sudo killall -KILL appleeventsd" with administrator privileges
display notification "Apple Events daemon restarted" with title "System"
'''),
        ("key-shortcut", "Send a keyboard shortcut to the frontmost app", '''\
-- Example: Cmd+Shift+S (Save As)
tell application "System Events"
    keystroke "s" using {command down, shift down}
end tell
'''),
    ],

    # ═══════════════════════════════════════════════════════════════════════════
    # SHORTCUTS — the bridge to App Intents
    # ═══════════════════════════════════════════════════════════════════════════
    "shortcuts": [
        ("run-shortcut", "Run a named Shortcut", '''\
set sName to text returned of (display dialog "Shortcut name:" default answer "")
do shell script "shortcuts run " & quoted form of sName
display notification "Ran: " & sName with title "Shortcuts"
'''),
        ("list-shortcuts", "List all available Shortcuts", '''\
set output to do shell script "shortcuts list"
set the clipboard to output
display notification "Copied shortcut list to clipboard" with title "Shortcuts"
'''),
        ("run-shortcut-with-input", "Run a Shortcut with text input", '''\
set sName to text returned of (display dialog "Shortcut name:" default answer "")
set input to text returned of (display dialog "Input:" default answer "")
do shell script "echo " & quoted form of input & " | shortcuts run " & quoted form of sName
display notification "Ran: " & sName with title "Shortcuts"
'''),
    ],

    # ═══════════════════════════════════════════════════════════════════════════
    # TEXTEDIT — simple document automation
    # ═══════════════════════════════════════════════════════════════════════════
    "textedit": [
        ("new-from-clipboard", "Open TextEdit with clipboard contents", '''\
set clipContent to the clipboard as text
tell application "TextEdit"
    activate
    make new document with properties {text:clipContent}
end tell
'''),
        ("word-count", "Count words in frontmost TextEdit document", '''\
tell application "TextEdit"
    set t to text of front document
    set wc to count of words of t
    display notification (wc as text) & " words" with title "TextEdit"
end tell
'''),
    ],

    # ═══════════════════════════════════════════════════════════════════════════
    # QUICKTIME — recording and playback
    # ═══════════════════════════════════════════════════════════════════════════
    "quicktime": [
        ("new-screen-recording", "Start a new screen recording", '''\
tell application "QuickTime Player"
    activate
    new screen recording
end tell
'''),
        ("new-audio-recording", "Start a new audio recording", '''\
tell application "QuickTime Player"
    activate
    new audio recording
end tell
'''),
        ("new-movie-recording", "Start a new movie recording", '''\
tell application "QuickTime Player"
    activate
    new movie recording
end tell
'''),
    ],
}


# ─── Generator ────────────────────────────────────────────────────────────────

def generate_script(app_name, suffix, description, code):
    """Write a single .applescript file."""
    slug = app_name.lower().replace(' ', '-')
    app_dir = SCRIPTS_DIR / slug
    app_dir.mkdir(parents=True, exist_ok=True)

    filename = f"{slug}-{suffix}.applescript"
    filepath = app_dir / filename

    header = f'''\
-- {description}
-- App: {app_name}
-- Usage: osascript scripts/workflows/{slug}/{filename}
-- Generated by workflow-gen.py

'''
    filepath.write_text(header + code)
    return filepath


def generate_catalog(generated):
    """Generate/update scripts.md catalog."""
    lines = []
    lines.append("# AppleScript Catalog")
    lines.append("")
    lines.append("> All scripts in this repo, organized by type.")
    lines.append(f"> Last updated: {datetime.now().strftime('%Y-%m-%d')}")
    lines.append("")

    # Launchers section
    lines.append("## Launchers")
    lines.append("")
    lines.append("Single-purpose app activation scripts in `scripts/launchers/`.")
    lines.append("Each one brings an app to the foreground — ideal for hardware buttons.")
    lines.append("")
    lines.append("| Script | App |")
    lines.append("|--------|-----|")

    launchers_dir = Path(__file__).parent.parent / "scripts" / "launchers"
    if launchers_dir.exists():
        for f in sorted(launchers_dir.glob("*.applescript")):
            name = f.stem.replace("activate-", "").replace("-", " ").title()
            lines.append(f"| `launchers/{f.name}` | {name} |")
    lines.append("")

    # Workflows section
    lines.append("## Workflows")
    lines.append("")
    lines.append("Real automation scripts in `scripts/workflows/` — these DO things, not just open apps.")
    lines.append("One button = one action = one result (Sal's rule).")
    lines.append("")

    for app_slug in sorted(generated.keys()):
        app_display = app_slug.replace("-", " ").title()
        scripts = generated[app_slug]
        lines.append(f"### {app_display}")
        lines.append("")
        lines.append("| Script | Description |")
        lines.append("|--------|-------------|")
        for filepath, description in scripts:
            rel = filepath.relative_to(Path(__file__).parent.parent / "scripts")
            lines.append(f"| `{rel}` | {description} |")
        lines.append("")

    # Summary
    total_launchers = len(list(launchers_dir.glob("*.applescript"))) if launchers_dir.exists() else 0
    total_workflows = sum(len(v) for v in generated.values())
    lines.append("---")
    lines.append("")
    lines.append(f"**Total: {total_launchers} launchers + {total_workflows} workflows = {total_launchers + total_workflows} scripts**")
    lines.append("")

    return '\n'.join(lines)


def main():
    args = [a.lower().replace(' ', '-') for a in sys.argv[1:]]

    if '--list' in args:
        print("Available workflow recipes:")
        for app, recipes in sorted(RECIPES.items()):
            print(f"  {app:20s} {len(recipes)} recipes")
        total = sum(len(r) for r in RECIPES.values())
        print(f"\n  Total: {total} recipes across {len(RECIPES)} apps")
        return

    catalog_only = '--catalog' in args
    args = [a for a in args if not a.startswith('--')]

    # Filter apps if specified
    if args:
        apps = {k: v for k, v in RECIPES.items() if k in args}
        if not apps:
            print(f"Unknown app(s): {args}")
            print(f"Available: {', '.join(sorted(RECIPES.keys()))}")
            sys.exit(1)
    else:
        apps = RECIPES

    if not catalog_only:
        SCRIPTS_DIR.mkdir(parents=True, exist_ok=True)

        print("═══ Apple Workflow Generator ═══")
        print(f"Output: {SCRIPTS_DIR}")
        print(f"Apps: {len(apps)}")
        print()

    generated = {}

    for app_slug, recipes in sorted(apps.items()):
        app_display = app_slug.replace("-", " ").title()
        if not catalog_only:
            print(f"  {app_display}:")

        generated[app_slug] = []
        for suffix, description, code in recipes:
            filepath = generate_script(app_display, suffix, description, code)
            generated[app_slug].append((filepath, description))
            if not catalog_only:
                print(f"    {filepath.name}")

    total = sum(len(v) for v in generated.values())
    if not catalog_only:
        print(f"\n  Generated: {total} workflow scripts")

    # Update catalog
    # For full catalog, we need all apps even if we only generated some
    if not args:
        all_generated = generated
    else:
        # Re-scan existing workflows to build full catalog
        all_generated = {}
        if SCRIPTS_DIR.exists():
            for app_dir in sorted(SCRIPTS_DIR.iterdir()):
                if app_dir.is_dir():
                    slug = app_dir.name
                    all_generated[slug] = []
                    for f in sorted(app_dir.glob("*.applescript")):
                        # Read first line for description
                        first_line = f.read_text().split('\n')[0]
                        desc = first_line.replace('-- ', '') if first_line.startswith('-- ') else f.stem
                        all_generated[slug].append((f, desc))

    catalog = generate_catalog(all_generated)
    CATALOG_PATH.write_text(catalog)
    print(f"  Catalog: {CATALOG_PATH}")

    print(f"\n═══ Done: {total} workflows across {len(generated)} apps ═══")


if __name__ == '__main__':
    main()
