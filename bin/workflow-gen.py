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
        ("duplicate-selected", "Duplicate the selected Finder items", '''\
tell application "Finder"
    set sel to selection
    if sel is {} then
        display notification "Nothing selected" with title "Finder"
        return
    end if
    repeat with f in sel
        duplicate f
    end repeat
    display notification "Duplicated " & (count of sel) & " item(s)" with title "Finder"
end tell
'''),
        ("compress-selected", "Compress selected Finder items into a zip", '''\
tell application "Finder"
    set sel to selection
    if sel is {} then
        display notification "Nothing selected" with title "Finder"
        return
    end if
    set firstItem to item 1 of sel as alias
    set p to POSIX path of firstItem
    do shell script "cd " & quoted form of (do shell script "dirname " & quoted form of p) & " && zip -r " & quoted form of (do shell script "basename " & quoted form of p) & ".zip " & quoted form of (do shell script "basename " & quoted form of p)
    display notification "Compressed " & name of item 1 of sel with title "Finder"
end tell
'''),
        ("move-to-trash", "Move selected Finder items to Trash", '''\
tell application "Finder"
    set sel to selection
    if sel is {} then
        display notification "Nothing selected" with title "Finder"
        return
    end if
    repeat with f in sel
        move f to trash
    end repeat
    display notification "Trashed " & (count of sel) & " item(s)" with title "Finder"
end tell
'''),
        ("count-items", "Count items in the frontmost Finder window", '''\
tell application "Finder"
    if (count of Finder windows) > 0 then
        set c to count of items of target of front Finder window
        set p to name of target of front Finder window
        display notification (c as text) & " items in " & p with title "Finder"
    else
        display notification "No Finder windows open" with title "Finder"
    end if
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
        ("toggle-repeat", "Cycle repeat mode: off → all → one → off", '''\
tell application "Music"
    if song repeat is off then
        set song repeat to all
        display notification "Repeat ALL" with title "Music"
    else if song repeat is all then
        set song repeat to one
        display notification "Repeat ONE" with title "Music"
    else
        set song repeat to off
        display notification "Repeat OFF" with title "Music"
    end if
end tell
'''),
        ("rating-0-stars", "Clear rating of current track", '''\
tell application "Music"
    set rating of current track to 0
    display notification "Rating cleared: " & name of current track with title "Music"
end tell
'''),
        ("rating-1-star", "Rate the current track 1 star", '''\
tell application "Music"
    set rating of current track to 20
    display notification "Rated 1 star: " & name of current track with title "Music"
end tell
'''),
        ("rating-2-stars", "Rate the current track 2 stars", '''\
tell application "Music"
    set rating of current track to 40
    display notification "Rated 2 stars: " & name of current track with title "Music"
end tell
'''),
        ("rating-3-stars", "Rate the current track 3 stars", '''\
tell application "Music"
    set rating of current track to 60
    display notification "Rated 3 stars: " & name of current track with title "Music"
end tell
'''),
        ("rating-4-stars", "Rate the current track 4 stars", '''\
tell application "Music"
    set rating of current track to 80
    display notification "Rated 4 stars: " & name of current track with title "Music"
end tell
'''),
        ("get-lyrics", "Show lyrics of current track", '''\
tell application "Music"
    set t to current track
    set l to lyrics of t
    if l is "" then
        display dialog "No lyrics found for: " & name of t with title "Music" buttons {"OK"} default button "OK"
    else
        display dialog l with title (name of t & " — Lyrics") buttons {"OK"} default button "OK"
    end if
end tell
'''),
        ("track-info-detail", "Show detailed info about current track", '''\
tell application "Music"
    set t to current track
    set info to "Track: " & name of t & return
    set info to info & "Artist: " & artist of t & return
    set info to info & "Album: " & album of t & return
    set info to info & "Genre: " & genre of t & return
    set info to info & "Year: " & (year of t as text) & return
    set info to info & "Duration: " & time of t & return
    set info to info & "Plays: " & (played count of t as text) & return
    set info to info & "BPM: " & (bpm of t as text) & return
    set info to info & "Bit Rate: " & (bit rate of t as text) & " kbps"
    display dialog info with title "Track Info" buttons {"Copy", "OK"} default button "OK"
    if button returned of result is "Copy" then
        set the clipboard to info
    end if
end tell
'''),
        ("toggle-eq", "Toggle equalizer on/off", '''\
tell application "Music"
    set EQ enabled to not EQ enabled
    if EQ enabled then
        display notification "EQ ON" with title "Music"
    else
        display notification "EQ OFF" with title "Music"
    end if
end tell
'''),
        ("set-eq-preset", "Choose an EQ preset from list", '''\
tell application "Music"
    set presetNames to name of every EQ preset
    set chosen to choose from list presetNames with title "Music EQ" with prompt "Choose EQ preset:"
    if chosen is not false then
        set EQ enabled to true
        set current EQ preset to EQ preset (item 1 of chosen)
        display notification "EQ: " & (item 1 of chosen) with title "Music"
    end if
end tell
'''),
        ("toggle-visuals", "Toggle visual effects on/off", '''\
tell application "Music"
    set visuals enabled to not visuals enabled
end tell
'''),
        ("play-playlist", "Choose a playlist to play", '''\
tell application "Music"
    set pNames to name of every user playlist
    set chosen to choose from list pNames with title "Music" with prompt "Choose playlist:"
    if chosen is not false then
        play user playlist (item 1 of chosen)
        display notification "Playing: " & (item 1 of chosen) with title "Music"
    end if
end tell
'''),
        ("reveal-current", "Reveal current track in Music library", '''\
tell application "Music"
    reveal current track
    activate
end tell
'''),
        ("count-library", "Show total track count in library", '''\
tell application "Music"
    set c to count of tracks of library playlist 1
    display notification (c as text) & " tracks in library" with title "Music"
end tell
'''),
        ("played-count-current", "Show how many times current track was played", '''\
tell application "Music"
    set t to current track
    display notification "Played " & (played count of t as text) & " times" with title (name of t)
end tell
'''),
        ("toggle-fullscreen", "Toggle Music fullscreen mode", '''\
tell application "Music"
    set full screen to not full screen
end tell
'''),
        ("seek-forward-30", "Jump forward 30 seconds", '''\
tell application "Music"
    set player position to (player position + 30)
end tell
'''),
        ("seek-backward-30", "Jump backward 30 seconds", '''\
tell application "Music"
    set p to player position
    if p > 30 then
        set player position to (p - 30)
    else
        set player position to 0
    end if
end tell
'''),
        ("list-playlists", "Show all user playlists as notification", '''\
tell application "Music"
    set pNames to name of every user playlist
    set output to ""
    repeat with p in pNames
        set output to output & p & ", "
    end repeat
    display dialog output with title "Your Playlists" buttons {"OK"} default button "OK"
end tell
'''),
        ("create-playlist", "Create a new empty playlist", '''\
tell application "Music"
    set pName to text returned of (display dialog "New playlist name:" default answer "My Playlist")
    make new user playlist with properties {name:pName}
    display notification "Created: " & pName with title "Music"
end tell
'''),
        ("airplay-list", "Show available AirPlay devices", '''\
tell application "Music"
    set devNames to name of every AirPlay device
    set output to ""
    repeat with d in devNames
        set output to output & d & return
    end repeat
    if output is "" then
        display dialog "No AirPlay devices found" with title "AirPlay" buttons {"OK"} default button "OK"
    else
        display dialog output with title "AirPlay Devices" buttons {"OK"} default button "OK"
    end if
end tell
'''),
        ("current-stream-info", "Show stream title and URL if streaming", '''\
tell application "Music"
    set t to current stream title
    set u to current stream URL
    if t is "" and u is "" then
        display notification "Not streaming" with title "Music"
    else
        display notification u with title t
    end if
end tell
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
        ("delete-junk", "Delete all junk mail", '''\
tell application "Mail"
    set junkMsgs to every message of junk mailbox
    set c to count of junkMsgs
    repeat with m in junkMsgs
        delete m
    end repeat
    display notification "Deleted " & (c as text) & " junk messages" with title "Mail"
end tell
'''),
        ("list-accounts", "List all mail accounts", '''\
tell application "Mail"
    set acctNames to name of every account
    set output to ""
    repeat with a in acctNames
        set output to output & a & return
    end repeat
    display dialog output with title "Mail Accounts" buttons {"OK"} default button "OK"
end tell
'''),
        ("archive-selected", "Move selected messages to Archive", '''\
tell application "Mail"
    set sel to selection
    if (count of sel) > 0 then
        repeat with m in sel
            set acct to account of mailbox of m
            try
                move m to mailbox "Archive" of acct
            on error
                move m to mailbox "All Mail" of acct
            end try
        end repeat
        display notification "Archived " & (count of sel) & " message(s)" with title "Mail"
    end if
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
        ("show-bookmarks", "Show Safari bookmarks", '''\
tell application "Safari"
    activate
    show bookmarks
end tell
'''),
        ("reload-tab", "Reload the current Safari tab", '''\
tell application "Safari"
    set URL of current tab of front window to URL of current tab of front window
    display notification "Reloaded" with title "Safari"
end tell
'''),
        ("show-privacy-report", "Show Safari Privacy Report", '''\
tell application "Safari"
    activate
    show privacy report
end tell
'''),
        ("tab-count", "Show number of open tabs across all windows", '''\
tell application "Safari"
    set total to 0
    repeat with w in every window
        set total to total + (count of tabs of w)
    end repeat
    display notification (total as text) & " tabs open" with title "Safari"
end tell
'''),
        ("close-other-tabs", "Close all tabs except the current one", '''\
tell application "Safari"
    tell front window
        set currentIndex to index of current tab
        repeat with t in (reverse of (every tab whose index is not currentIndex))
            close t
        end repeat
    end tell
    display notification "Closed other tabs" with title "Safari"
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
        ("list-folders", "List all Notes folders", '''\
tell application "Notes"
    set folderNames to name of every folder of account "iCloud"
    set output to ""
    repeat with f in folderNames
        set output to output & f & return
    end repeat
    display dialog output with title "Notes Folders" buttons {"OK"} default button "OK"
end tell
'''),
        ("append-to-note", "Append text to an existing note", '''\
tell application "Notes"
    set q to text returned of (display dialog "Note name to append to:" default answer "")
    set results to every note of account "iCloud" whose name contains q
    if (count of results) is 0 then
        display notification "No note matching: " & q with title "Notes"
        return
    end if
    set n to item 1 of results
    set newText to text returned of (display dialog "Text to append:" default answer "")
    set body of n to (body of n) & "<br>" & newText
    display notification "Appended to: " & name of n with title "Notes"
end tell
'''),
        ("show-recent-note", "Open the most recently modified note", '''\
tell application "Notes"
    set n to note 1
    show n
    activate
    display notification "Opened: " & name of n with title "Notes"
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
        ("list-lists", "Show all reminder lists", '''\
tell application "Reminders"
    set listNames to name of every list
    set output to ""
    repeat with l in listNames
        set output to output & l & return
    end repeat
    display dialog output with title "Reminder Lists" buttons {"OK"} default button "OK"
end tell
'''),
        ("count-incomplete", "Count incomplete reminders", '''\
tell application "Reminders"
    set incomplete to every reminder whose completed is false
    display notification (count of incomplete) & " incomplete reminders" with title "Reminders"
end tell
'''),
        ("reminder-with-priority", "Create a high-priority reminder", '''\
tell application "Reminders"
    set t to text returned of (display dialog "High priority reminder:" default answer "")
    tell default list
        make new reminder with properties {name:t, priority:1}
    end tell
    display notification "HIGH: " & t with title "Reminders"
end tell
'''),
        ("flagged-reminders", "Show all flagged reminders", '''\
tell application "Reminders"
    set flagged to every reminder whose flagged is true and completed is false
    set output to ""
    repeat with r in flagged
        set output to output & name of r & return
    end repeat
    if output is "" then
        display notification "No flagged reminders" with title "Reminders"
    else
        display dialog output with title "Flagged Reminders" buttons {"OK"} default button "OK"
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
        ("list-calendars", "List all calendar names", '''\
tell application "Calendar"
    set calNames to name of every calendar
    set output to ""
    repeat with c in calNames
        set output to output & c & return
    end repeat
    display dialog output with title "Calendars" buttons {"OK"} default button "OK"
end tell
'''),
        ("count-events-today", "Count events happening today", '''\
tell application "Calendar"
    set today to current date
    set time of today to 0
    set tomorrow to today + (1 * days)
    set eventCount to 0
    repeat with cal in every calendar
        set evts to (every event of cal whose start date >= today and start date < tomorrow)
        set eventCount to eventCount + (count of evts)
    end repeat
    display notification (eventCount as text) & " events today" with title "Calendar"
end tell
'''),
        ("event-at-time", "Create an event at a specific time today", '''\
tell application "Calendar"
    set t to text returned of (display dialog "Event title:" default answer "")
    set h to text returned of (display dialog "Hour (0-23):" default answer "14")
    set startDate to current date
    set hours of startDate to (h as integer)
    set minutes of startDate to 0
    set seconds of startDate to 0
    set endDate to startDate + (1 * hours)
    tell calendar "Home"
        make new event with properties {summary:t, start date:startDate, end date:endDate}
    end tell
    display notification t & " at " & h & ":00" with title "Calendar"
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
        ("stop-slideshow", "Stop the currently playing slideshow", '''\
tell application "Photos"
    stop slideshow
end tell
'''),
        ("count-photos", "Show total photo count in library", '''\
tell application "Photos"
    set c to count of every media item
    display notification (c as text) & " photos in library" with title "Photos"
end tell
'''),
        ("list-albums", "List all album names", '''\
tell application "Photos"
    set albumNames to name of every album
    set output to ""
    repeat with a in albumNames
        set output to output & a & return
    end repeat
    set the clipboard to output
    display notification "Copied " & (count of albumNames) & " album names" with title "Photos"
end tell
'''),
        ("create-album", "Create a new empty album", '''\
tell application "Photos"
    set aName to text returned of (display dialog "New album name:" default answer "My Album")
    make new album named aName
    display notification "Created: " & aName with title "Photos"
end tell
'''),
        ("favorite-selected", "Favorite the selected photos", '''\
tell application "Photos"
    set sel to selection
    if sel is {} then
        display notification "No photos selected" with title "Photos"
        return
    end if
    repeat with p in sel
        set favorite of p to true
    end repeat
    display notification "Favorited " & (count of sel) & " photo(s)" with title "Photos"
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
        ("clear-scrollback", "Clear scrollback in the front Terminal tab", '''\
tell application "Terminal"
    set contents of selected tab of front window to ""
end tell
'''),
        ("set-title", "Set a custom title for the front Terminal tab", '''\
tell application "Terminal"
    set t to text returned of (display dialog "Tab title:" default answer "")
    tell selected tab of front window
        set custom title to t
        set title displays custom title to true
    end tell
end tell
'''),
        ("ssh-connect", "Open an SSH connection in a new tab", '''\
tell application "Terminal"
    activate
    set h to text returned of (display dialog "SSH host (user@host):" default answer "")
    do script "ssh " & h
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
        ("send-clipboard", "Send clipboard contents as an iMessage", '''\
set clipText to the clipboard as text
tell application "Messages"
    set targetBuddy to text returned of (display dialog "Send clipboard to (phone/email):" default answer "")
    set targetService to 1st account whose service type = iMessage
    set targetParticipant to participant targetBuddy of targetService
    send clipText to targetParticipant
    display notification "Sent clipboard to " & targetBuddy with title "Messages"
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
        ("count-contacts", "Show total number of contacts", '''\
tell application "Contacts"
    set c to count of every person
    display notification (c as text) & " contacts" with title "Contacts"
end tell
'''),
        ("new-contact", "Create a new contact", '''\
tell application "Contacts"
    set fn to text returned of (display dialog "First name:" default answer "")
    set ln to text returned of (display dialog "Last name:" default answer "")
    set p to make new person with properties {first name:fn, last name:ln}
    save
    display notification "Created: " & fn & " " & ln with title "Contacts"
end tell
'''),
        ("list-groups", "List all contact groups", '''\
tell application "Contacts"
    set groupNames to name of every group
    set output to ""
    repeat with g in groupNames
        set output to output & g & return
    end repeat
    if output is "" then
        display notification "No groups" with title "Contacts"
    else
        display dialog output with title "Contact Groups" buttons {"OK"} default button "OK"
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
        ("battery-status", "Show battery percentage and charging state", '''\
set battPct to do shell script "pmset -g batt | grep -o '[0-9]*%' | head -1"
set battSrc to do shell script "pmset -g ps | head -1"
display notification battSrc with title "Battery: " & battPct
'''),
        ("disk-usage", "Show disk space usage for the main drive", '''\
set diskInfo to do shell script "df -h / | tail -1 | awk '{print $3, \"/\", $2, $5}'"
display notification diskInfo with title "Disk Usage"
'''),
        ("uptime", "Show system uptime", '''\
set uptimeStr to do shell script "uptime | sed 's/.*up //' | sed 's/,.*//' | xargs"
display notification uptimeStr with title "Uptime"
'''),
        ("ip-address", "Show current IP addresses (local and external)", '''\
set localIP to do shell script "ipconfig getifaddr en0 2>/dev/null || echo 'No Wi-Fi'"
set extIP to do shell script "curl -s ifconfig.me 2>/dev/null || echo 'No internet'"
display dialog "Local: " & localIP & return & "External: " & extIP with title "IP Address" buttons {"Copy Local", "Copy External", "OK"} default button "OK"
if button returned of result is "Copy Local" then
    set the clipboard to localIP
else if button returned of result is "Copy External" then
    set the clipboard to extIP
end if
'''),
        ("bluetooth-toggle", "Toggle Bluetooth on/off", '''\
set status to do shell script "defaults read /Library/Preferences/com.apple.Bluetooth ControllerPowerState 2>/dev/null || echo 0"
if status is "1" then
    do shell script "blueutil --power 0"
    display notification "Bluetooth OFF" with title "System"
else
    do shell script "blueutil --power 1"
    display notification "Bluetooth ON" with title "System"
end if
'''),
        ("screen-lock", "Lock the screen immediately", '''\
do shell script "/System/Library/CoreServices/Menu\\\\ Extras/User.menu/Contents/Resources/CGSession -suspend"
'''),
        ("empty-clipboard", "Clear the clipboard", '''\
set the clipboard to ""
display notification "Clipboard cleared" with title "System"
'''),
        ("trash-size", "Show the size of the Trash", '''\
set sz to do shell script "du -sh ~/.Trash 2>/dev/null | awk '{print $1}'"
display notification sz with title "Trash Size"
'''),
        ("notification-count", "Show pending notification count", '''\
set c to do shell script "sqlite3 $(getconf DARWIN_USER_DIR)com.apple.notificationcenter/db2/db 'SELECT COUNT(*) FROM record WHERE presented=1' 2>/dev/null || echo '?'"
display notification c & " notifications" with title "Notification Center"
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
        ("search-shortcuts", "Search for a Shortcut by name and run it", '''\
set allShortcuts to do shell script "shortcuts list"
set q to text returned of (display dialog "Search shortcuts:" default answer "")
set matches to do shell script "echo " & quoted form of allShortcuts & " | grep -i " & quoted form of q & " || echo ''"
if matches is "" then
    display notification "No shortcuts matching: " & q with title "Shortcuts"
else
    set chosen to choose from list (paragraphs of matches) with title "Shortcuts" with prompt "Run which shortcut?"
    if chosen is not false then
        do shell script "shortcuts run " & quoted form of (item 1 of chosen)
        display notification "Ran: " & (item 1 of chosen) with title "Shortcuts"
    end if
end if
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
        ("new-document", "Create a new blank TextEdit document", '''\
tell application "TextEdit"
    activate
    make new document
end tell
'''),
        ("save-as-txt", "Save frontmost TextEdit document as plain text to Desktop", '''\
tell application "TextEdit"
    set d to front document
    set n to name of d
    set savePath to (POSIX path of (path to desktop)) & n & ".txt"
    save d as "public.plain-text" in POSIX file savePath
    display notification "Saved: " & n & ".txt" with title "TextEdit"
end tell
'''),
        ("char-count", "Count characters in frontmost TextEdit document", '''\
tell application "TextEdit"
    set t to text of front document
    set cc to count of characters of t
    set wc to count of words of t
    display notification (cc as text) & " chars, " & (wc as text) & " words" with title "TextEdit"
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
        ("play-frontmost", "Play the frontmost QuickTime document", '''\
tell application "QuickTime Player"
    if (count of documents) > 0 then
        play front document
    else
        display notification "No documents open" with title "QuickTime"
    end if
end tell
'''),
        ("pause-frontmost", "Pause the frontmost QuickTime document", '''\
tell application "QuickTime Player"
    if (count of documents) > 0 then
        pause front document
    else
        display notification "No documents open" with title "QuickTime"
    end if
end tell
'''),
        ("present-fullscreen", "Present the frontmost document in fullscreen", '''\
tell application "QuickTime Player"
    if (count of documents) > 0 then
        present front document
    else
        display notification "No documents open" with title "QuickTime"
    end if
end tell
'''),
    ],

    # ═══════════════════════════════════════════════════════════════════════════
    # HOMEPOD — sensor data via Shortcuts CLI
    # ═══════════════════════════════════════════════════════════════════════════
    "homepod": [
        ("climate-reading", "Read HomePod temperature and humidity", '''\
set reading to do shell script "shortcuts run 'HomePod Sensors'"
if reading is "" then
    display notification "No response from HomePod" with title "HomePod"
    return
end if
set humidity to do shell script "echo " & quoted form of reading & " | sed 's/,.*//'"
set temperature to do shell script "echo " & quoted form of reading & " | sed 's/^[^,]*, //' | tr -d '°C' | tr ',' '.'"
display notification "Temp: " & temperature & "°C | Humidity: " & humidity & "%" with title "HomePod Climate"
'''),
        ("climate-log", "Take a climate reading and log it", '''\
set repoDir to do shell script "cd -- \\"$(dirname $(dirname $(dirname \\\"$0\\\")))\\\" 2>/dev/null && pwd || echo $HOME/work/apple"
do shell script "bash " & quoted form of (repoDir & "/homepod/homepod-climate.sh") & " --nograph"
display notification "Climate reading logged" with title "HomePod"
'''),
        ("climate-dashboard", "Open the HomePod climate dashboard", '''\
set repoDir to do shell script "echo $HOME/work/apple"
do shell script "cd " & quoted form of (repoDir & "/homepod") & " && if ! lsof -i :3007 >/dev/null 2>&1; then nohup python3 climate-server.py >/dev/null 2>&1 & sleep 0.5; fi"
do shell script "open http://localhost:3007/climate-graph.html"
'''),
        ("climate-summary", "Show today's climate summary", '''\
set repoDir to do shell script "echo $HOME/work/apple"
set summary to do shell script "bash " & quoted form of (repoDir & "/homepod/climate-summary.sh")
display dialog summary with title "Climate Summary" buttons {"OK"} default button "OK"
'''),
    ],
    # ═══════════════════════════════════════════════════════════════════════════
    # TV — 29 commands, video playback and library management
    # ═══════════════════════════════════════════════════════════════════════════
    "tv": [
        ("playpause", "Toggle play/pause", '''\
tell application "TV" to playpause
'''),
        ("next-track", "Skip to next track", '''\
tell application "TV" to next track
'''),
        ("previous-track", "Go to previous track", '''\
tell application "TV" to previous track
'''),
        ("now-playing", "Show current track as notification", '''\
tell application "TV"
    try
        set t to name of current track
        set s to show of current track
        display notification s with title t
    on error
        display notification "Nothing playing" with title "TV"
    end try
end tell
'''),
        ("list-playlists", "List playlists in a dialog", '''\
tell application "TV"
    set pNames to name of every playlist
    set AppleScript's text item delimiters to linefeed
    set pList to pNames as text
    set AppleScript's text item delimiters to ""
    display dialog pList with title "TV Playlists" buttons {"OK"} default button "OK"
end tell
'''),
        ("search-library", "Search TV library by name", '''\
tell application "TV"
    set q to text returned of (display dialog "Search TV:" default answer "")
    set results to search library playlist 1 for q
    if (count of results) is 0 then
        display notification "No results for: " & q with title "TV"
    else
        set t to item 1 of results
        play t
        display notification "Playing: " & name of t with title "TV"
    end if
end tell
'''),
        ("mute-toggle", "Toggle TV mute", '''\
tell application "TV"
    set mute to not mute
end tell
'''),
        ("volume-up", "Increase TV volume by 10", '''\
tell application "TV"
    set v to sound volume
    if v + 10 > 100 then
        set sound volume to 100
    else
        set sound volume to v + 10
    end if
end tell
'''),
        ("volume-down", "Decrease TV volume by 10", '''\
tell application "TV"
    set v to sound volume
    if v - 10 < 0 then
        set sound volume to 0
    else
        set sound volume to v - 10
    end if
end tell
'''),
        ("reveal-current", "Reveal current track in library", '''\
tell application "TV"
    try
        reveal current track
        activate
    on error
        display notification "Nothing playing to reveal" with title "TV"
    end try
end tell
'''),
    ],
    # ═══════════════════════════════════════════════════════════════════════════
    # KEYNOTE — 28 commands, presentation creation and playback
    # ═══════════════════════════════════════════════════════════════════════════
    "keynote": [
        ("new-presentation", "Create a new Keynote presentation", '''\
tell application "Keynote"
    activate
    make new document
end tell
'''),
        ("start-slideshow", "Start slideshow from the beginning", '''\
tell application "Keynote"
    try
        start front document
    on error
        display notification "No presentation open" with title "Keynote"
    end try
end tell
'''),
        ("stop-slideshow", "Stop the current slideshow", '''\
tell application "Keynote"
    try
        stop front document
    on error
        display notification "No slideshow running" with title "Keynote"
    end try
end tell
'''),
        ("next-slide", "Advance to the next slide", '''\
tell application "Keynote"
    try
        show next
    on error
        display notification "No slideshow running" with title "Keynote"
    end try
end tell
'''),
        ("previous-slide", "Go to the previous slide", '''\
tell application "Keynote"
    try
        show previous
    on error
        display notification "No slideshow running" with title "Keynote"
    end try
end tell
'''),
        ("slide-count", "Show slide count of front document", '''\
tell application "Keynote"
    try
        set n to count of slides of front document
        display notification (n as text) & " slides" with title "Keynote"
    on error
        display notification "No presentation open" with title "Keynote"
    end try
end tell
'''),
        ("export-pdf", "Export front presentation as PDF to Desktop", '''\
tell application "Keynote"
    try
        set docName to name of front document
        if docName ends with ".key" then set docName to text 1 thru -5 of docName
        set exportPath to (((path to desktop) as text) & docName & ".pdf")
        export front document to file exportPath as PDF
        display notification "Exported: " & docName & ".pdf" with title "Keynote"
    on error errMsg
        display notification errMsg with title "Keynote Export Error"
    end try
end tell
'''),
        ("current-slide", "Show current slide number", '''\
tell application "Keynote"
    try
        set n to slide number of current slide of front document
        set total to count of slides of front document
        display notification "Slide " & n & " of " & total with title "Keynote"
    on error
        display notification "No presentation open" with title "Keynote"
    end try
end tell
'''),
        ("list-slides", "List slide titles in a dialog", '''\
tell application "Keynote"
    try
        set slideInfo to {}
        set allSlides to slides of front document
        repeat with s in allSlides
            try
                set t to object text of default title item of s as text
            on error
                set t to "(untitled)"
            end try
            set end of slideInfo to (slide number of s as text) & ". " & t
        end repeat
        set AppleScript's text item delimiters to linefeed
        set slideList to slideInfo as text
        set AppleScript's text item delimiters to ""
        display dialog slideList with title "Keynote Slides" buttons {"OK"} default button "OK"
    on error errMsg
        display notification errMsg with title "Keynote"
    end try
end tell
'''),
        ("presenter-notes", "Show presenter notes for current slide", '''\
tell application "Keynote"
    try
        set n to presenter notes of current slide of front document as text
        if n is "" then
            display notification "No presenter notes on this slide" with title "Keynote"
        else
            display dialog n with title "Presenter Notes" buttons {"OK"} default button "OK"
        end if
    on error
        display notification "No presentation open" with title "Keynote"
    end try
end tell
'''),
    ],
    # ═══════════════════════════════════════════════════════════════════════════
    # PAGES — 11 commands, word processing and document export
    # ═══════════════════════════════════════════════════════════════════════════
    "pages": [
        ("new-document", "Create a new blank Pages document", '''\
tell application "Pages"
    activate
    make new document
end tell
'''),
        ("word-count", "Show word count of front document", '''\
tell application "Pages"
    try
        set n to count of words of body text of front document
        display notification (n as text) & " words" with title "Pages"
    on error
        display notification "No document open" with title "Pages"
    end try
end tell
'''),
        ("export-pdf", "Export front document as PDF to Desktop", '''\
tell application "Pages"
    try
        set docName to name of front document
        if docName ends with ".pages" then set docName to text 1 thru -7 of docName
        set exportPath to (((path to desktop) as text) & docName & ".pdf")
        export front document to file exportPath as PDF
        display notification "Exported: " & docName & ".pdf" with title "Pages"
    on error errMsg
        display notification errMsg with title "Pages Export Error"
    end try
end tell
'''),
        ("character-count", "Show character count of front document", '''\
tell application "Pages"
    try
        set n to count of characters of body text of front document
        display notification (n as text) & " characters" with title "Pages"
    on error
        display notification "No document open" with title "Pages"
    end try
end tell
'''),
        ("page-count", "Show page count of front document", '''\
tell application "Pages"
    try
        set n to count of pages of front document
        display notification (n as text) & " pages" with title "Pages"
    on error
        display notification "No document open" with title "Pages"
    end try
end tell
'''),
        ("list-documents", "List all open Pages documents", '''\
tell application "Pages"
    try
        set docNames to name of every document
        set AppleScript's text item delimiters to linefeed
        set docList to docNames as text
        set AppleScript's text item delimiters to ""
        display dialog docList with title "Open Documents" buttons {"OK"} default button "OK"
    on error
        display notification "No documents open" with title "Pages"
    end try
end tell
'''),
    ],
    # ═══════════════════════════════════════════════════════════════════════════
    # NUMBERS — 16 commands, spreadsheet management and export
    # ═══════════════════════════════════════════════════════════════════════════
    "numbers": [
        ("new-spreadsheet", "Create a new blank Numbers spreadsheet", '''\
tell application "Numbers"
    activate
    make new document
end tell
'''),
        ("export-csv", "Export front document as CSV to Desktop", '''\
tell application "Numbers"
    try
        set docName to name of front document
        if docName ends with ".numbers" then set docName to text 1 thru -9 of docName
        set exportPath to (((path to desktop) as text) & docName & ".csv")
        export front document to file exportPath as CSV
        display notification "Exported: " & docName & ".csv" with title "Numbers"
    on error errMsg
        display notification errMsg with title "Numbers Export Error"
    end try
end tell
'''),
        ("sheet-count", "Show sheet count of front document", '''\
tell application "Numbers"
    try
        set n to count of sheets of front document
        display notification (n as text) & " sheets" with title "Numbers"
    on error
        display notification "No spreadsheet open" with title "Numbers"
    end try
end tell
'''),
        ("table-count", "Show table count in active sheet", '''\
tell application "Numbers"
    try
        set n to count of tables of active sheet of front document
        display notification (n as text) & " tables" with title "Numbers"
    on error
        display notification "No spreadsheet open" with title "Numbers"
    end try
end tell
'''),
        ("list-sheets", "List sheet names in a dialog", '''\
tell application "Numbers"
    try
        set sheetNames to name of every sheet of front document
        set AppleScript's text item delimiters to linefeed
        set sheetList to sheetNames as text
        set AppleScript's text item delimiters to ""
        display dialog sheetList with title "Numbers Sheets" buttons {"OK"} default button "OK"
    on error
        display notification "No spreadsheet open" with title "Numbers"
    end try
end tell
'''),
        ("export-pdf", "Export front document as PDF to Desktop", '''\
tell application "Numbers"
    try
        set docName to name of front document
        if docName ends with ".numbers" then set docName to text 1 thru -9 of docName
        set exportPath to (((path to desktop) as text) & docName & ".pdf")
        export front document to file exportPath as PDF
        display notification "Exported: " & docName & ".pdf" with title "Numbers"
    on error errMsg
        display notification errMsg with title "Numbers Export Error"
    end try
end tell
'''),
    ],

    # ═══════════════════════════════════════════════════════════════════════════
    # AUTOMATOR — workflow automation tool (16 commands, 17 classes)
    # ═══════════════════════════════════════════════════════════════════════════
    "automator": [
        ("new-workflow", "Create a new Automator workflow document", '''\
tell application "Automator"
    activate
    make new document
end tell
'''),
        ("run-workflow", "Run an Automator workflow file by path", '''\
set workflowPath to choose file with prompt "Choose an Automator workflow to run:" of type {"com.apple.automator-workflow"}
tell application "Automator"
    activate
    open workflowPath
    set theDoc to front document
    set theWorkflow to workflow of theDoc
    try
        execute theWorkflow
        set theResult to execution result of theWorkflow
        if theResult is not missing value then
            display notification (theResult as text) with title "Automator"
        else
            display notification "Workflow completed" with title "Automator"
        end if
    on error errMsg
        display dialog "Workflow error: " & errMsg with title "Automator" buttons {"OK"} default button "OK" with icon stop
    end try
end tell
'''),
        ("list-actions", "List available Automator actions and copy to clipboard", '''\
tell application "Automator"
    activate
    make new document
    set actionNames to name of every Automator action
    set actionCount to count of actionNames
    set actionList to ""
    repeat with anAction in actionNames
        set actionList to actionList & anAction & linefeed
    end repeat
    set the clipboard to actionList
    display notification (actionCount as text) & " actions copied to clipboard" with title "Automator"
end tell
'''),
        ("save-as-app", "Save the front Automator workflow as an application", '''\
tell application "Automator"
    activate
    if (count of documents) is 0 then
        display notification "No workflow open" with title "Automator"
        return
    end if
    set savePath to choose file name with prompt "Save workflow as application:" default name "My Workflow.app"
    save front document as "application" in savePath
    display notification "Saved as application" with title "Automator"
end tell
'''),
        ("get-result", "Get the execution result of the front workflow", '''\
tell application "Automator"
    activate
    if (count of documents) is 0 then
        display notification "No workflow open" with title "Automator"
        return
    end if
    set theDoc to front document
    set theWorkflow to workflow of theDoc
    set theResult to execution result of theWorkflow
    set errMsg to execution error message of theWorkflow
    if errMsg is not "" and errMsg is not missing value then
        display dialog "Error: " & errMsg with title "Automator Result" buttons {"OK"} default button "OK" with icon stop
    else if theResult is not missing value then
        display dialog "Result: " & (theResult as text) with title "Automator Result" buttons {"Copy", "OK"} default button "OK"
        if button returned of result is "Copy" then
            set the clipboard to (theResult as text)
        end if
    else
        display notification "No result available (run a workflow first)" with title "Automator"
    end if
end tell
'''),
    ],

    # ═══════════════════════════════════════════════════════════════════════════
    # SCRIPT EDITOR — AppleScript IDE (16 commands, 16 classes)
    # ═══════════════════════════════════════════════════════════════════════════
    "script-editor": [
        ("compile", "Compile the front Script Editor document", '''\
tell application "Script Editor"
    activate
    if (count of documents) is 0 then
        display notification "No document open" with title "Script Editor"
        return
    end if
    try
        set compileResult to compile front document
        if compileResult then
            display notification "Compiled successfully" with title "Script Editor"
        else
            display notification "Compilation failed" with title "Script Editor"
        end if
    on error errMsg
        display dialog "Compile error: " & errMsg with title "Script Editor" buttons {"OK"} default button "OK" with icon stop
    end try
end tell
'''),
        ("run", "Run the front Script Editor document", '''\
tell application "Script Editor"
    activate
    if (count of documents) is 0 then
        display notification "No document open" with title "Script Editor"
        return
    end if
    try
        compile front document
        tell front document
            execute
        end tell
        display notification "Script executed" with title "Script Editor"
    on error errMsg
        display dialog "Run error: " & errMsg with title "Script Editor" buttons {"OK"} default button "OK" with icon stop
    end try
end tell
'''),
        ("new-script", "Create a new Script Editor document with a template", '''\
tell application "Script Editor"
    activate
    set newDoc to make new document
    set contents of newDoc to "-- New AppleScript" & linefeed & "-- Created: " & (current date) as text & linefeed & linefeed & "tell application \\"Finder\\"" & linefeed & "    activate" & linefeed & "end tell" & linefeed
end tell
'''),
        ("get-result", "Get the result of the last script run", '''\
tell application "Script Editor"
    activate
    if (count of documents) is 0 then
        display notification "No document open" with title "Script Editor"
        return
    end if
    set theResult to contents of result of front document
    if theResult is "" or theResult is missing value then
        display notification "No result available" with title "Script Editor"
    else
        display dialog theResult with title "Script Result" buttons {"Copy", "OK"} default button "OK"
        if button returned of result is "Copy" then
            set the clipboard to theResult
        end if
    end if
end tell
'''),
        ("open-dictionary", "Open the scripting dictionary browser", '''\
tell application "Script Editor"
    activate
end tell
tell application "System Events"
    tell process "Script Editor"
        click menu item "Open Dictionary…" of menu "File" of menu bar 1
    end tell
end tell
'''),
    ],

    # ═══════════════════════════════════════════════════════════════════════════
    # IMAGE EVENTS — headless image processing (13 commands, 16 classes)
    # ═══════════════════════════════════════════════════════════════════════════
    "image-events": [
        ("resize", "Resize an image file to specified dimensions", '''\
set imagePath to choose file with prompt "Choose an image to resize:" of type {"public.image"}
set newWidth to text returned of (display dialog "Enter new width in pixels:" default answer "800" with title "Resize Image")
tell application "Image Events"
    set theImage to open imagePath
    set {origW, origH} to dimensions of theImage
    set scaleFactor to (newWidth as number) / origW
    scale theImage by factor scaleFactor
    save theImage
    close theImage
end tell
display notification "Resized to " & newWidth & "px wide" with title "Image Events"
'''),
        ("rotate", "Rotate an image 90 degrees clockwise", '''\
set imagePath to choose file with prompt "Choose an image to rotate:" of type {"public.image"}
tell application "Image Events"
    set theImage to open imagePath
    rotate theImage to angle 90
    save theImage
    close theImage
end tell
display notification "Rotated 90 degrees clockwise" with title "Image Events"
'''),
        ("flip", "Flip an image horizontally", '''\
set imagePath to choose file with prompt "Choose an image to flip:" of type {"public.image"}
tell application "Image Events"
    set theImage to open imagePath
    flip theImage horizontal
    save theImage
    close theImage
end tell
display notification "Flipped horizontally" with title "Image Events"
'''),
        ("get-dimensions", "Show width and height of an image", '''\
set imagePath to choose file with prompt "Choose an image:" of type {"public.image"}
tell application "Image Events"
    set theImage to open imagePath
    set {imgWidth, imgHeight} to dimensions of theImage
    set imgSpace to color space of theImage
    close theImage
end tell
display dialog "Width: " & imgWidth & " px" & linefeed & "Height: " & imgHeight & " px" & linefeed & "Color space: " & imgSpace with title "Image Info" buttons {"Copy", "OK"} default button "OK"
if button returned of result is "Copy" then
    set the clipboard to (imgWidth as text) & "x" & (imgHeight as text)
end if
'''),
        ("convert-format", "Convert an image to JPEG, PNG, or TIFF", '''\
set imagePath to choose file with prompt "Choose an image to convert:" of type {"public.image"}
set formatChoice to choose from list {"JPEG", "PNG", "TIFF"} with prompt "Choose output format:" with title "Convert Image" default items {"JPEG"}
if formatChoice is false then return
set outputFormat to item 1 of formatChoice
tell application "Image Events"
    set theImage to open imagePath
    if outputFormat is "JPEG" then
        save theImage as JPEG
    else if outputFormat is "PNG" then
        save theImage as PNG
    else if outputFormat is "TIFF" then
        save theImage as TIFF
    end if
    close theImage
end tell
display notification "Converted to " & outputFormat with title "Image Events"
'''),
    ],

    # ═══════════════════════════════════════════════════════════════════════════
    # IMOVIE — video editing (Standard Suite only, limited scripting)
    # ═══════════════════════════════════════════════════════════════════════════
    "imovie": [
        ("new-project", "Create a new iMovie document", '''\
tell application "iMovie"
    activate
    make new document
end tell
'''),
        ("list-projects", "List open iMovie projects", '''\
tell application "iMovie"
    activate
    set docCount to count of documents
    if docCount is 0 then
        display notification "No projects open" with title "iMovie"
        return
    end if
    set docNames to {}
    repeat with i from 1 to docCount
        set end of docNames to name of document i
    end repeat
    choose from list docNames with prompt "Open iMovie projects:" with title "iMovie Projects"
end tell
'''),
    ],

    # ═══════════════════════════════════════════════════════════════════════════
    # SYSTEM INFORMATION — hardware/software profiling via system_profiler CLI
    # ═══════════════════════════════════════════════════════════════════════════
    "system-information": [
        ("hardware", "Show hardware overview", '''\
set hwInfo to do shell script "system_profiler SPHardwareDataType"
display dialog hwInfo with title "Hardware Overview" buttons {"Copy", "OK"} default button "OK"
if button returned of result is "Copy" then
    set the clipboard to hwInfo
end if
'''),
        ("software", "Show software overview", '''\
set swInfo to do shell script "system_profiler SPSoftwareDataType"
display dialog swInfo with title "Software Overview" buttons {"Copy", "OK"} default button "OK"
if button returned of result is "Copy" then
    set the clipboard to swInfo
end if
'''),
        ("network", "Show network configuration info", '''\
set netInfo to do shell script "system_profiler SPNetworkDataType"
display dialog netInfo with title "Network Info" buttons {"Copy", "OK"} default button "OK"
if button returned of result is "Copy" then
    set the clipboard to netInfo
end if
'''),
        ("storage", "Show storage and disk info", '''\
set storageInfo to do shell script "system_profiler SPStorageDataType"
display dialog storageInfo with title "Storage Info" buttons {"Copy", "OK"} default button "OK"
if button returned of result is "Copy" then
    set the clipboard to storageInfo
end if
'''),
    ],

    # ═══════════════════════════════════════════════════════════════════════════
    # PREVIEW — UI scripting + CLI (no useful sdef)
    # ═══════════════════════════════════════════════════════════════════════════
    "preview": [
        ("open-file", "Open a file in Preview via choose dialog", '''\
set f to choose file with prompt "Choose a file to open in Preview:" of type {"public.image", "com.adobe.pdf"}
tell application "Preview"
    activate
    open f
end tell
'''),
        ("zoom-in", "Zoom in on current Preview document", '''\
tell application "Preview" to activate
tell application "System Events"
    tell process "Preview"
        keystroke "+" using command down
    end tell
end tell
'''),
        ("zoom-out", "Zoom out on current Preview document", '''\
tell application "Preview" to activate
tell application "System Events"
    tell process "Preview"
        keystroke "-" using command down
    end tell
end tell
'''),
        ("rotate-left", "Rotate current Preview document left", '''\
tell application "Preview" to activate
tell application "System Events"
    tell process "Preview"
        keystroke "L" using command down
    end tell
end tell
'''),
    ],

    # ═══════════════════════════════════════════════════════════════════════════
    # SYSTEM SETTINGS — URL scheme navigation (3 sdef commands)
    # ═══════════════════════════════════════════════════════════════════════════
    "system-settings": [
        ("wifi", "Open Wi-Fi settings pane", '''\
do shell script "open 'x-apple.systempreferences:com.apple.wifi-settings-extension'"
'''),
        ("bluetooth", "Open Bluetooth settings pane", '''\
do shell script "open 'x-apple.systempreferences:com.apple.BluetoothSettings'"
'''),
        ("sound", "Open Sound settings pane", '''\
do shell script "open 'x-apple.systempreferences:com.apple.Sound-Settings.extension'"
'''),
        ("displays", "Open Displays settings pane", '''\
do shell script "open 'x-apple.systempreferences:com.apple.Displays-Settings.extension'"
'''),
        ("battery", "Open Battery settings pane", '''\
do shell script "open 'x-apple.systempreferences:com.apple.settings.battery'"
'''),
        ("notifications", "Open Notifications settings pane", '''\
do shell script "open 'x-apple.systempreferences:com.apple.Notifications-Settings.extension'"
'''),
        ("privacy", "Open Privacy and Security settings pane", '''\
do shell script "open 'x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension'"
'''),
        ("general", "Open General settings pane", '''\
do shell script "open 'x-apple.systempreferences:com.apple.systempreferences.GeneralSettings'"
'''),
    ],

    # ═══════════════════════════════════════════════════════════════════════════
    # DISK UTILITY — CLI wrapper via diskutil
    # ═══════════════════════════════════════════════════════════════════════════
    "disk-utility": [
        ("list-disks", "List all disks via diskutil", '''\
set output to do shell script "diskutil list"
display dialog output with title "Disk List" buttons {"OK"} default button "OK"
'''),
        ("disk-info", "Show info for main disk via diskutil", '''\
set output to do shell script "diskutil info /"
display dialog output with title "Disk Info" buttons {"OK"} default button "OK"
'''),
        ("apfs-list", "List APFS containers via diskutil", '''\
set output to do shell script "diskutil apfs list"
display dialog output with title "APFS Containers" buttons {"OK"} default button "OK"
'''),
    ],

    # ═══════════════════════════════════════════════════════════════════════════
    # SCREENSHOT — CLI wrapper via screencapture
    # ═══════════════════════════════════════════════════════════════════════════
    "screenshot": [
        ("fullscreen", "Capture full screen to Desktop", '''\
set ts to do shell script "date '+%Y-%m-%d_%H%M%S'"
set f to (POSIX path of (path to desktop)) & "Screenshot-" & ts & ".png"
do shell script "screencapture " & quoted form of f
display notification "Saved to Desktop" with title "Screenshot"
'''),
        ("area", "Capture selected area to Desktop", '''\
set ts to do shell script "date '+%Y-%m-%d_%H%M%S'"
set f to (POSIX path of (path to desktop)) & "Screenshot-" & ts & ".png"
do shell script "screencapture -i " & quoted form of f
display notification "Saved to Desktop" with title "Screenshot"
'''),
        ("window", "Capture front window to Desktop", '''\
set ts to do shell script "date '+%Y-%m-%d_%H%M%S'"
set f to (POSIX path of (path to desktop)) & "Screenshot-" & ts & ".png"
do shell script "screencapture -w " & quoted form of f
display notification "Saved to Desktop" with title "Screenshot"
'''),
        ("clipboard", "Capture selected area to clipboard", '''\
do shell script "screencapture -ic"
display notification "Screenshot copied to clipboard" with title "Screenshot"
'''),
    ],

    # ═══════════════════════════════════════════════════════════════════════════
    # CONSOLE — CLI wrapper via log command
    # ═══════════════════════════════════════════════════════════════════════════
    "console": [
        ("recent-errors", "Show recent system errors from last 5 minutes", '''\
set output to do shell script "log show --last 5m --predicate 'messageType == error' --style compact 2>&1 | tail -50"
display dialog output with title "Recent Errors (last 5m)" buttons {"OK"} default button "OK"
'''),
        ("app-log", "Show recent log entries for a specific app", '''\
set appName to text returned of (display dialog "App name to filter:" default answer "Finder")
set output to do shell script "log show --last 10m --predicate 'process == \\"" & appName & "\\"' --style compact 2>&1 | tail -50"
display dialog output with title (appName & " Log") buttons {"OK"} default button "OK"
'''),
        ("system-log", "Show recent system messages", '''\
set output to do shell script "log show --last 5m --style compact 2>&1 | tail -50"
display dialog output with title "System Log (last 5m)" buttons {"OK"} default button "OK"
'''),
    ],

    # ═══════════════════════════════════════════════════════════════════════════
    # TIME MACHINE — CLI wrapper via tmutil
    # ═══════════════════════════════════════════════════════════════════════════
    "time-machine": [
        ("status", "Show Time Machine backup status", '''\
set output to do shell script "tmutil status 2>&1"
display dialog output with title "Time Machine Status" buttons {"OK"} default button "OK"
'''),
        ("list-backups", "List recent Time Machine backups", '''\
set output to do shell script "tmutil listbackups 2>&1 | tail -10"
display dialog output with title "Recent Backups" buttons {"OK"} default button "OK"
'''),
        ("start-backup", "Start a Time Machine backup", '''\
do shell script "tmutil startbackup" with administrator privileges
display notification "Backup started" with title "Time Machine"
'''),
        ("latest-backup", "Show latest Time Machine backup timestamp", '''\
set output to do shell script "tmutil latestbackup 2>&1"
display dialog output with title "Latest Backup" buttons {"OK"} default button "OK"
'''),
    ],
}


# ─── Generator ────────────────────────────────────────────────────────────────

def extract_teaching_comments(code):
    """Extract teaching comments explaining AppleScript concepts used in the code."""
    comments = []
    seen = set()

    teachings = [
        ('tell application', 'tell application ... end tell',
         'Sends Apple Events to an app. The app must have a scripting dictionary (sdef).'),
        ('try', 'try ... on error ... end try',
         'Error handling. Catches runtime errors so the script doesn\'t crash.'),
        ('display notification', 'display notification "text" with title "title"',
         'Shows a macOS notification banner. Disappears after a few seconds.'),
        ('display dialog', 'display dialog "text"',
         'Shows a modal dialog. Can include text fields (default answer), buttons, and icons.'),
        ('choose from list', 'choose from list myList',
         'Shows a scrollable list picker. Returns false if cancelled, otherwise a list.'),
        ('set the clipboard', 'set the clipboard to "text"',
         'Copies text to the system clipboard, same as Cmd+C.'),
        ('do shell script', 'do shell script "command"',
         'Runs a shell command from AppleScript and returns stdout as text.'),
        ('repeat with', 'repeat with item in list',
         'Loops over each item in a list, like a for-each loop.'),
        ('if ', 'if condition then ... else ... end if',
         'Conditional branching. AppleScript uses English-like "is", "is not", "contains".'),
        ('keystroke', 'keystroke "key" using {command down}',
         'Simulates keyboard input via System Events. Needs accessibility permission.'),
        ('current date', 'current date',
         'Returns the current date and time as an AppleScript date object.'),
        ('quoted form of', 'quoted form of variable',
         'Safely escapes a string for shell commands. Prevents injection.'),
        ('POSIX path', 'POSIX path of alias',
         'Converts a Mac alias/HFS path to a Unix-style /path/to/file.'),
        ('with administrator privileges', 'do shell script "cmd" with administrator privileges',
         'Prompts for admin password. Required for system-level changes.'),
        ('as alias', 'file "path" as alias',
         'Converts a file reference to an alias. Aliases track files even if moved.'),
    ]

    code_lower = code.lower()
    for trigger, syntax, explanation in teachings:
        if trigger.lower() in code_lower and trigger not in seen:
            seen.add(trigger)
            comments.append(f'-- Concept: {syntax}')
            comments.append(f'--   {explanation}')

    return '\n'.join(comments)


def generate_script(app_name, suffix, description, code):
    """Write a single .applescript file."""
    slug = app_name.lower().replace(' ', '-')
    app_dir = SCRIPTS_DIR / slug
    app_dir.mkdir(parents=True, exist_ok=True)

    filename = f"{slug}-{suffix}.applescript"
    filepath = app_dir / filename

    teaching = extract_teaching_comments(code)
    teaching_block = f'\n{teaching}\n' if teaching else ''

    header = f'''\
-- {description}
-- App: {app_name}
-- Usage: osascript scripts/workflows/{slug}/{filename}
-- Generated by workflow-gen.py
{teaching_block}
'''
    filepath.write_text(header + code)
    return filepath


def generate_catalog(generated):
    """Generate/update scripts.md catalog from recipes and launcher scripts."""
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
        lines.append("| Script | Description | Run |")
        lines.append("|--------|-------------|-----|")
        for filepath, description in scripts:
            rel = filepath.relative_to(Path(__file__).parent.parent / "scripts")
            osacmd = f"`osascript scripts/{rel}`"
            lines.append(f"| `{rel}` | {description} | {osacmd} |")
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

    # --catalog: standalone mode — generate scripts.md from RECIPES + launchers + any extra dirs
    if catalog_only:
        all_generated = {}
        for app_slug, recipes in sorted(RECIPES.items()):
            slug = app_slug.lower().replace(' ', '-')
            all_generated[slug] = []
            for suffix, description, _code in recipes:
                filename = f"{slug}-{suffix}.applescript"
                filepath = SCRIPTS_DIR / slug / filename
                all_generated[slug].append((filepath, description))

        # Pick up workflow directories that exist on disk but aren't in RECIPES
        if SCRIPTS_DIR.exists():
            for app_dir in sorted(SCRIPTS_DIR.iterdir()):
                if app_dir.is_dir() and app_dir.name not in all_generated:
                    scripts = []
                    for f in sorted(app_dir.glob("*.applescript")):
                        first_line = f.read_text().split('\n')[0]
                        desc = first_line.replace('-- ', '') if first_line.startswith('-- ') else f.stem
                        scripts.append((f, desc))
                    if scripts:
                        all_generated[app_dir.name] = scripts

        catalog = generate_catalog(all_generated)
        CATALOG_PATH.write_text(catalog)

        total_workflows = sum(len(v) for v in all_generated.values())
        launchers_dir = Path(__file__).parent.parent / "scripts" / "launchers"
        total_launchers = len(list(launchers_dir.glob("*.applescript"))) if launchers_dir.exists() else 0
        print(f"Catalog written: {CATALOG_PATH}")
        print(f"  {total_launchers} launchers + {total_workflows} workflows = {total_launchers + total_workflows} scripts")
        return

    # Filter apps if specified
    if args:
        apps = {k: v for k, v in RECIPES.items() if k in args}
        if not apps:
            print(f"Unknown app(s): {args}")
            print(f"Available: {', '.join(sorted(RECIPES.keys()))}")
            sys.exit(1)
    else:
        apps = RECIPES

    SCRIPTS_DIR.mkdir(parents=True, exist_ok=True)

    print("═══ Apple Workflow Generator ═══")
    print(f"Output: {SCRIPTS_DIR}")
    print(f"Apps: {len(apps)}")
    print()

    generated = {}

    for app_slug, recipes in sorted(apps.items()):
        app_display = app_slug.replace("-", " ").title()
        print(f"  {app_display}:")

        generated[app_slug] = []
        for suffix, description, code in recipes:
            filepath = generate_script(app_display, suffix, description, code)
            generated[app_slug].append((filepath, description))
            print(f"    {filepath.name}")

    total = sum(len(v) for v in generated.values())
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
