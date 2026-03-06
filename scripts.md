# AppleScript Catalog

> All scripts in this repo, organized by type.
> Last updated: 2026-03-06

## Launchers

Single-purpose app activation scripts in `scripts/launchers/`.
Each one brings an app to the foreground — ideal for hardware buttons.

| Script | App |
|--------|-----|
| `launchers/activate-activity-monitor.applescript` | Activity Monitor |
| `launchers/activate-airport-utility.applescript` | Airport Utility |
| `launchers/activate-app-store.applescript` | App Store |
| `launchers/activate-audio-midi-setup.applescript` | Audio Midi Setup |
| `launchers/activate-automator.applescript` | Automator |
| `launchers/activate-bluetooth-file-exchange.applescript` | Bluetooth File Exchange |
| `launchers/activate-books.applescript` | Books |
| `launchers/activate-calculator.applescript` | Calculator |
| `launchers/activate-calendar.applescript` | Calendar |
| `launchers/activate-chess.applescript` | Chess |
| `launchers/activate-clock.applescript` | Clock |
| `launchers/activate-colorsync-utility.applescript` | Colorsync Utility |
| `launchers/activate-console.applescript` | Console |
| `launchers/activate-contacts.applescript` | Contacts |
| `launchers/activate-dictionary.applescript` | Dictionary |
| `launchers/activate-digital-color-meter.applescript` | Digital Color Meter |
| `launchers/activate-disk-utility.applescript` | Disk Utility |
| `launchers/activate-facetime.applescript` | Facetime |
| `launchers/activate-final-cut-pro.applescript` | Final Cut Pro |
| `launchers/activate-find-my.applescript` | Find My |
| `launchers/activate-finder.applescript` | Finder |
| `launchers/activate-font-book.applescript` | Font Book |
| `launchers/activate-freeform.applescript` | Freeform |
| `launchers/activate-grapher.applescript` | Grapher |
| `launchers/activate-home.applescript` | Home |
| `launchers/activate-image-capture.applescript` | Image Capture |
| `launchers/activate-imovie.applescript` | Imovie |
| `launchers/activate-keynote.applescript` | Keynote |
| `launchers/activate-launchpad.applescript` | Launchpad |
| `launchers/activate-logic-pro.applescript` | Logic Pro |
| `launchers/activate-mail.applescript` | Mail |
| `launchers/activate-maps.applescript` | Maps |
| `launchers/activate-messages.applescript` | Messages |
| `launchers/activate-migration-assistant.applescript` | Migration Assistant |
| `launchers/activate-mission-control.applescript` | Mission Control |
| `launchers/activate-music.applescript` | Music |
| `launchers/activate-news.applescript` | News |
| `launchers/activate-notes.applescript` | Notes |
| `launchers/activate-numbers.applescript` | Numbers |
| `launchers/activate-pages.applescript` | Pages |
| `launchers/activate-passwords.applescript` | Passwords |
| `launchers/activate-photo-booth.applescript` | Photo Booth |
| `launchers/activate-photos.applescript` | Photos |
| `launchers/activate-podcasts.applescript` | Podcasts |
| `launchers/activate-preview.applescript` | Preview |
| `launchers/activate-quicktime-player.applescript` | Quicktime Player |
| `launchers/activate-reminders.applescript` | Reminders |
| `launchers/activate-safari.applescript` | Safari |
| `launchers/activate-screen-sharing.applescript` | Screen Sharing |
| `launchers/activate-screenshot.applescript` | Screenshot |
| `launchers/activate-script-editor.applescript` | Script Editor |
| `launchers/activate-shortcuts.applescript` | Shortcuts |
| `launchers/activate-stickies.applescript` | Stickies |
| `launchers/activate-stocks.applescript` | Stocks |
| `launchers/activate-system-information.applescript` | System Information |
| `launchers/activate-system-settings.applescript` | System Settings |
| `launchers/activate-terminal.applescript` | Terminal |
| `launchers/activate-textedit.applescript` | Textedit |
| `launchers/activate-time-machine.applescript` | Time Machine |
| `launchers/activate-tips.applescript` | Tips |
| `launchers/activate-tv.applescript` | Tv |
| `launchers/activate-voice-memos.applescript` | Voice Memos |
| `launchers/activate-voiceover-utility.applescript` | Voiceover Utility |
| `launchers/activate-weather.applescript` | Weather |

## Workflows

Real automation scripts in `scripts/workflows/` — these DO things, not just open apps.
One button = one action = one result (Sal's rule).

### Calendar

| Script | Description |
|--------|-------------|
| `workflows/calendar/calendar-quick-event.applescript` | Create a quick calendar event |
| `workflows/calendar/calendar-show-today.applescript` | Switch Calendar to today view |
| `workflows/calendar/calendar-show-week.applescript` | Switch Calendar to week view |
| `workflows/calendar/calendar-show-month.applescript` | Switch Calendar to month view |
| `workflows/calendar/calendar-reload.applescript` | Reload all calendars |
| `workflows/calendar/calendar-next-event.applescript` | Show the next upcoming calendar event |
| `workflows/calendar/calendar-list-calendars.applescript` | List all calendar names |
| `workflows/calendar/calendar-count-events-today.applescript` | Count events happening today |
| `workflows/calendar/calendar-event-at-time.applescript` | Create an event at a specific time today |

### Contacts

| Script | Description |
|--------|-------------|
| `workflows/contacts/contacts-search-contact.applescript` | Search for a contact and show their info |
| `workflows/contacts/contacts-count-contacts.applescript` | Show total number of contacts |
| `workflows/contacts/contacts-new-contact.applescript` | Create a new contact |
| `workflows/contacts/contacts-list-groups.applescript` | List all contact groups |

### Finder

| Script | Description |
|--------|-------------|
| `workflows/finder/finder-new-window.applescript` | Open a new Finder window at home folder |
| `workflows/finder/finder-new-window-desktop.applescript` | Open a new Finder window at Desktop |
| `workflows/finder/finder-new-window-downloads.applescript` | Open a new Finder window at Downloads |
| `workflows/finder/finder-get-selection.applescript` | Get names of selected Finder items |
| `workflows/finder/finder-copy-path.applescript` | Copy path of selected Finder item to clipboard |
| `workflows/finder/finder-reveal-downloads.applescript` | Reveal Downloads folder in Finder |
| `workflows/finder/finder-empty-trash.applescript` | Empty the Trash (no confirmation) |
| `workflows/finder/finder-empty-trash-confirm.applescript` | Empty the Trash with confirmation dialog |
| `workflows/finder/finder-tag-red.applescript` | Tag selected Finder items red |
| `workflows/finder/finder-tag-orange.applescript` | Tag selected Finder items orange |
| `workflows/finder/finder-tag-clear.applescript` | Clear tags from selected Finder items |
| `workflows/finder/finder-duplicate-selected.applescript` | Duplicate the selected Finder items |
| `workflows/finder/finder-compress-selected.applescript` | Compress selected Finder items into a zip |
| `workflows/finder/finder-move-to-trash.applescript` | Move selected Finder items to Trash |
| `workflows/finder/finder-count-items.applescript` | Count items in the frontmost Finder window |
| `workflows/finder/finder-toggle-hidden-files.applescript` | Toggle visibility of hidden files in Finder |
| `workflows/finder/finder-new-folder.applescript` | Create a new folder in the frontmost Finder window |
| `workflows/finder/finder-get-window-path.applescript` | Get POSIX path of the frontmost Finder window |
| `workflows/finder/finder-close-all-windows.applescript` | Close all Finder windows |
| `workflows/finder/finder-eject-all.applescript` | Eject all mounted external volumes |
| `workflows/finder/finder-sort-by-name.applescript` | Sort the frontmost Finder window by name |
| `workflows/finder/finder-file-info.applescript` | Display info about the selected file |
| `workflows/finder/finder-restart-finder.applescript` | Restart Finder (kf) |
| `workflows/finder/finder-hide-desktop-icons.applescript` | Hide all desktop icons |
| `workflows/finder/finder-show-desktop-icons.applescript` | Show all desktop icons |
| `workflows/finder/finder-open-current-dir.applescript` | Open current working directory in Finder |
| `workflows/finder/finder-set-wallpaper.applescript` | Set desktop wallpaper from a file path |
| `workflows/finder/finder-airdrop-reveal.applescript` | Reveal a file in Finder for AirDrop sharing |

### Homepod

| Script | Description |
|--------|-------------|
| `workflows/homepod/homepod-climate-reading.applescript` | Read HomePod temperature and humidity |
| `workflows/homepod/homepod-climate-log.applescript` | Take a climate reading and log it |
| `workflows/homepod/homepod-climate-dashboard.applescript` | Open the HomePod climate dashboard |
| `workflows/homepod/homepod-climate-summary.applescript` | Show today's climate summary |

### Mail

| Script | Description |
|--------|-------------|
| `workflows/mail/mail-check-mail.applescript` | Check for new mail |
| `workflows/mail/mail-compose.applescript` | Open a new blank compose window |
| `workflows/mail/mail-compose-to.applescript` | Compose a new message to a specific address |
| `workflows/mail/mail-unread-count.applescript` | Show unread mail count as notification |
| `workflows/mail/mail-read-latest-subject.applescript` | Get the subject of the latest message in inbox |
| `workflows/mail/mail-reply-to-selected.applescript` | Reply to the selected message |
| `workflows/mail/mail-forward-selected.applescript` | Forward the selected message |
| `workflows/mail/mail-flag-selected.applescript` | Flag the selected message |
| `workflows/mail/mail-mark-all-read.applescript` | Mark all inbox messages as read |
| `workflows/mail/mail-delete-junk.applescript` | Delete all junk mail |
| `workflows/mail/mail-list-accounts.applescript` | List all mail accounts |
| `workflows/mail/mail-archive-selected.applescript` | Move selected messages to Archive |
| `workflows/mail/mail-send-quick.applescript` | Send a quick email (dialog prompts for to/subject/body) |

### Messages

| Script | Description |
|--------|-------------|
| `workflows/messages/messages-send-message.applescript` | Send an iMessage to a contact |
| `workflows/messages/messages-list-chats.applescript` | List recent chat names |
| `workflows/messages/messages-send-clipboard.applescript` | Send clipboard contents as an iMessage |

### Music

| Script | Description |
|--------|-------------|
| `workflows/music/music-playpause.applescript` | Toggle play/pause |
| `workflows/music/music-next-track.applescript` | Skip to next track |
| `workflows/music/music-previous-track.applescript` | Go to previous track |
| `workflows/music/music-now-playing.applescript` | Show current track as notification |
| `workflows/music/music-now-playing-clipboard.applescript` | Copy current track info to clipboard |
| `workflows/music/music-volume-up.applescript` | Increase Music volume by 10 |
| `workflows/music/music-volume-down.applescript` | Decrease Music volume by 10 |
| `workflows/music/music-mute-toggle.applescript` | Toggle Music mute |
| `workflows/music/music-toggle-shuffle.applescript` | Toggle shuffle mode |
| `workflows/music/music-love-current.applescript` | Favorite the current track |
| `workflows/music/music-dislike-current.applescript` | Dislike the current track and skip |
| `workflows/music/music-add-to-playlist.applescript` | Add current track to a playlist by name |
| `workflows/music/music-search-library.applescript` | Search the music library |
| `workflows/music/music-rating-5-stars.applescript` | Rate the current track 5 stars |
| `workflows/music/music-stop.applescript` | Stop playback |
| `workflows/music/music-toggle-repeat.applescript` | Cycle repeat mode: off → all → one → off |
| `workflows/music/music-rating-0-stars.applescript` | Clear rating of current track |
| `workflows/music/music-rating-1-star.applescript` | Rate the current track 1 star |
| `workflows/music/music-rating-2-stars.applescript` | Rate the current track 2 stars |
| `workflows/music/music-rating-3-stars.applescript` | Rate the current track 3 stars |
| `workflows/music/music-rating-4-stars.applescript` | Rate the current track 4 stars |
| `workflows/music/music-get-lyrics.applescript` | Show lyrics of current track |
| `workflows/music/music-track-info-detail.applescript` | Show detailed info about current track |
| `workflows/music/music-toggle-eq.applescript` | Toggle equalizer on/off |
| `workflows/music/music-set-eq-preset.applescript` | Choose an EQ preset from list |
| `workflows/music/music-toggle-visuals.applescript` | Toggle visual effects on/off |
| `workflows/music/music-play-playlist.applescript` | Choose a playlist to play |
| `workflows/music/music-reveal-current.applescript` | Reveal current track in Music library |
| `workflows/music/music-count-library.applescript` | Show total track count in library |
| `workflows/music/music-played-count-current.applescript` | Show how many times current track was played |
| `workflows/music/music-toggle-fullscreen.applescript` | Toggle Music fullscreen mode |
| `workflows/music/music-seek-forward-30.applescript` | Jump forward 30 seconds |
| `workflows/music/music-seek-backward-30.applescript` | Jump backward 30 seconds |
| `workflows/music/music-list-playlists.applescript` | Show all user playlists as notification |
| `workflows/music/music-create-playlist.applescript` | Create a new empty playlist |
| `workflows/music/music-airplay-list.applescript` | Show available AirPlay devices |
| `workflows/music/music-current-stream-info.applescript` | Show stream title and URL if streaming |

### Notes

| Script | Description |
|--------|-------------|
| `workflows/notes/notes-new-note.applescript` | Create a new note with title and body |
| `workflows/notes/notes-new-note-from-clipboard.applescript` | Create a new note from clipboard contents |
| `workflows/notes/notes-list-notes.applescript` | List names of recent notes |
| `workflows/notes/notes-search-notes.applescript` | Search notes by name |
| `workflows/notes/notes-count-notes.applescript` | Show total note count |
| `workflows/notes/notes-list-folders.applescript` | List all Notes folders |
| `workflows/notes/notes-append-to-note.applescript` | Append text to an existing note |
| `workflows/notes/notes-show-recent-note.applescript` | Open the most recently modified note |

### Photos

| Script | Description |
|--------|-------------|
| `workflows/photos/photos-search.applescript` | Search Photos library |
| `workflows/photos/photos-export-selected.applescript` | Export selected photos to Desktop |
| `workflows/photos/photos-favorites-count.applescript` | Count favorited photos |
| `workflows/photos/photos-start-slideshow.applescript` | Start a slideshow of selected photos |
| `workflows/photos/photos-stop-slideshow.applescript` | Stop the currently playing slideshow |
| `workflows/photos/photos-count-photos.applescript` | Show total photo count in library |
| `workflows/photos/photos-list-albums.applescript` | List all album names |
| `workflows/photos/photos-create-album.applescript` | Create a new empty album |
| `workflows/photos/photos-favorite-selected.applescript` | Favorite the selected photos |

### Quicktime

| Script | Description |
|--------|-------------|
| `workflows/quicktime/quicktime-new-screen-recording.applescript` | Start a new screen recording |
| `workflows/quicktime/quicktime-new-audio-recording.applescript` | Start a new audio recording |
| `workflows/quicktime/quicktime-new-movie-recording.applescript` | Start a new movie recording |
| `workflows/quicktime/quicktime-play-frontmost.applescript` | Play the frontmost QuickTime document |
| `workflows/quicktime/quicktime-pause-frontmost.applescript` | Pause the frontmost QuickTime document |
| `workflows/quicktime/quicktime-present-fullscreen.applescript` | Present the frontmost document in fullscreen |

### Reminders

| Script | Description |
|--------|-------------|
| `workflows/reminders/reminders-quick-reminder.applescript` | Create a quick reminder |
| `workflows/reminders/reminders-reminder-due-today.applescript` | Create a reminder due today |
| `workflows/reminders/reminders-reminder-from-clipboard.applescript` | Create a reminder from clipboard text |
| `workflows/reminders/reminders-show-today.applescript` | Show reminders due today |
| `workflows/reminders/reminders-complete-latest.applescript` | Mark the most recent incomplete reminder as done |
| `workflows/reminders/reminders-list-lists.applescript` | Show all reminder lists |
| `workflows/reminders/reminders-count-incomplete.applescript` | Count incomplete reminders |
| `workflows/reminders/reminders-reminder-with-priority.applescript` | Create a high-priority reminder |
| `workflows/reminders/reminders-flagged-reminders.applescript` | Show all flagged reminders |

### Safari

| Script | Description |
|--------|-------------|
| `workflows/safari/safari-current-url.applescript` | Copy the URL of the current Safari tab to clipboard |
| `workflows/safari/safari-current-title.applescript` | Copy the title of the current Safari tab to clipboard |
| `workflows/safari/safari-current-url-and-title.applescript` | Copy URL and title as markdown link |
| `workflows/safari/safari-open-url.applescript` | Open a URL in a new Safari tab |
| `workflows/safari/safari-search-web.applescript` | Search the web using Safari |
| `workflows/safari/safari-add-reading-list.applescript` | Add the current page to Reading List |
| `workflows/safari/safari-close-all-tabs.applescript` | Close all tabs in the front Safari window |
| `workflows/safari/safari-list-all-tabs.applescript` | List all open Safari tab URLs |
| `workflows/safari/safari-page-source.applescript` | Copy page source of current tab to clipboard |
| `workflows/safari/safari-do-javascript.applescript` | Run JavaScript in the current Safari tab |
| `workflows/safari/safari-show-bookmarks.applescript` | Show Safari bookmarks |
| `workflows/safari/safari-reload-tab.applescript` | Reload the current Safari tab |
| `workflows/safari/safari-show-privacy-report.applescript` | Show Safari Privacy Report |
| `workflows/safari/safari-tab-count.applescript` | Show number of open tabs across all windows |
| `workflows/safari/safari-close-other-tabs.applescript` | Close all tabs except the current one |

### Shortcuts

| Script | Description |
|--------|-------------|
| `workflows/shortcuts/shortcuts-run-shortcut.applescript` | Run a named Shortcut |
| `workflows/shortcuts/shortcuts-list-shortcuts.applescript` | List all available Shortcuts |
| `workflows/shortcuts/shortcuts-run-shortcut-with-input.applescript` | Run a Shortcut with text input |
| `workflows/shortcuts/shortcuts-search-shortcuts.applescript` | Search for a Shortcut by name and run it |

### System Events

| Script | Description |
|--------|-------------|
| `workflows/system-events/system-events-dark-mode-toggle.applescript` | Toggle macOS Dark Mode |
| `workflows/system-events/system-events-screenshot-area.applescript` | Take a screenshot of a selected area |
| `workflows/system-events/system-events-screenshot-window.applescript` | Take a screenshot of the frontmost window |
| `workflows/system-events/system-events-get-frontmost-app.applescript` | Get the name of the frontmost application |
| `workflows/system-events/system-events-list-running-apps.applescript` | List all running applications |
| `workflows/system-events/system-events-spotlight-status.applescript` | Check Spotlight indexing status |
| `workflows/system-events/system-events-wifi-toggle.applescript` | Toggle Wi-Fi on/off |
| `workflows/system-events/system-events-volume-set.applescript` | Set system volume to a specific level |
| `workflows/system-events/system-events-do-not-disturb.applescript` | Toggle Do Not Disturb (Focus) |
| `workflows/system-events/system-events-type-text.applescript` | Type text via System Events (paste alternative) |
| `workflows/system-events/system-events-hide-dock.applescript` | Hide the Dock (autohide on) |
| `workflows/system-events/system-events-show-dock.applescript` | Show the Dock (autohide off) |
| `workflows/system-events/system-events-dock-add-spacer.applescript` | Add a spacer tile to the Dock |
| `workflows/system-events/system-events-dock-add-recent-apps.applescript` | Add Recent Apps stack to the Dock |
| `workflows/system-events/system-events-restart-menu-bar.applescript` | Restart the macOS menu bar (topbar) |
| `workflows/system-events/system-events-reset-apple-events.applescript` | Reset Apple Events daemon (fixes -1712 errors) |
| `workflows/system-events/system-events-key-shortcut.applescript` | Send a keyboard shortcut to the frontmost app |
| `workflows/system-events/system-events-battery-status.applescript` | Show battery percentage and charging state |
| `workflows/system-events/system-events-disk-usage.applescript` | Show disk space usage for the main drive |
| `workflows/system-events/system-events-uptime.applescript` | Show system uptime |
| `workflows/system-events/system-events-ip-address.applescript` | Show current IP addresses (local and external) |
| `workflows/system-events/system-events-bluetooth-toggle.applescript` | Toggle Bluetooth on/off |
| `workflows/system-events/system-events-screen-lock.applescript` | Lock the screen immediately |
| `workflows/system-events/system-events-empty-clipboard.applescript` | Clear the clipboard |
| `workflows/system-events/system-events-trash-size.applescript` | Show the size of the Trash |
| `workflows/system-events/system-events-notification-count.applescript` | Show pending notification count |

### Terminal

| Script | Description |
|--------|-------------|
| `workflows/terminal/terminal-new-tab.applescript` | Open a new Terminal tab |
| `workflows/terminal/terminal-new-tab-at-path.applescript` | Open Terminal tab at a specific directory |
| `workflows/terminal/terminal-run-command.applescript` | Run a command in a new Terminal tab |
| `workflows/terminal/terminal-clear-scrollback.applescript` | Clear scrollback in the front Terminal tab |
| `workflows/terminal/terminal-set-title.applescript` | Set a custom title for the front Terminal tab |
| `workflows/terminal/terminal-ssh-connect.applescript` | Open an SSH connection in a new tab |

### Textedit

| Script | Description |
|--------|-------------|
| `workflows/textedit/textedit-new-from-clipboard.applescript` | Open TextEdit with clipboard contents |
| `workflows/textedit/textedit-word-count.applescript` | Count words in frontmost TextEdit document |
| `workflows/textedit/textedit-new-document.applescript` | Create a new blank TextEdit document |
| `workflows/textedit/textedit-save-as-txt.applescript` | Save frontmost TextEdit document as plain text to Desktop |
| `workflows/textedit/textedit-char-count.applescript` | Count characters in frontmost TextEdit document |

---

**Total: 64 launchers + 186 workflows = 250 scripts**
