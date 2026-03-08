# AppleScript Catalog

> All scripts in this repo, organized by type.
> Last updated: 2026-03-08

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

### Accessibility

| Script | Description | Run |
|--------|-------------|-----|
| `workflows/accessibility/ax-system-settings-battery.applescript` | Open System Settings Battery pane via Accessibility API | `osascript scripts/workflows/accessibility/ax-system-settings-battery.applescript` |
| `workflows/accessibility/ax-system-settings-bluetooth.applescript` | Open System Settings Bluetooth pane via Accessibility API | `osascript scripts/workflows/accessibility/ax-system-settings-bluetooth.applescript` |
| `workflows/accessibility/ax-system-settings-displays.applescript` | Open System Settings Displays pane via Accessibility API | `osascript scripts/workflows/accessibility/ax-system-settings-displays.applescript` |
| `workflows/accessibility/ax-system-settings-keyboard.applescript` | Open System Settings Keyboard pane via Accessibility API | `osascript scripts/workflows/accessibility/ax-system-settings-keyboard.applescript` |
| `workflows/accessibility/ax-system-settings-notifications.applescript` | Open System Settings Notifications pane via Accessibility API | `osascript scripts/workflows/accessibility/ax-system-settings-notifications.applescript` |
| `workflows/accessibility/ax-system-settings-privacy.applescript` | Open System Settings Privacy & Security pane via Accessibility API | `osascript scripts/workflows/accessibility/ax-system-settings-privacy.applescript` |
| `workflows/accessibility/ax-system-settings-sound.applescript` | Open System Settings Sound pane via Accessibility API | `osascript scripts/workflows/accessibility/ax-system-settings-sound.applescript` |
| `workflows/accessibility/ax-system-settings-wifi.applescript` | Open System Settings Wi-Fi pane via Accessibility API | `osascript scripts/workflows/accessibility/ax-system-settings-wifi.applescript` |

### Automator

| Script | Description | Run |
|--------|-------------|-----|
| `workflows/automator/automator-new-workflow.applescript` | Create a new Automator workflow document | `osascript scripts/workflows/automator/automator-new-workflow.applescript` |
| `workflows/automator/automator-run-workflow.applescript` | Run an Automator workflow file by path | `osascript scripts/workflows/automator/automator-run-workflow.applescript` |
| `workflows/automator/automator-list-actions.applescript` | List available Automator actions and copy to clipboard | `osascript scripts/workflows/automator/automator-list-actions.applescript` |
| `workflows/automator/automator-save-as-app.applescript` | Save the front Automator workflow as an application | `osascript scripts/workflows/automator/automator-save-as-app.applescript` |
| `workflows/automator/automator-get-result.applescript` | Get the execution result of the front workflow | `osascript scripts/workflows/automator/automator-get-result.applescript` |

### Calendar

| Script | Description | Run |
|--------|-------------|-----|
| `workflows/calendar/calendar-quick-event.applescript` | Create a quick calendar event | `osascript scripts/workflows/calendar/calendar-quick-event.applescript` |
| `workflows/calendar/calendar-show-today.applescript` | Switch Calendar to today view | `osascript scripts/workflows/calendar/calendar-show-today.applescript` |
| `workflows/calendar/calendar-show-week.applescript` | Switch Calendar to week view | `osascript scripts/workflows/calendar/calendar-show-week.applescript` |
| `workflows/calendar/calendar-show-month.applescript` | Switch Calendar to month view | `osascript scripts/workflows/calendar/calendar-show-month.applescript` |
| `workflows/calendar/calendar-reload.applescript` | Reload all calendars | `osascript scripts/workflows/calendar/calendar-reload.applescript` |
| `workflows/calendar/calendar-next-event.applescript` | Show the next upcoming calendar event | `osascript scripts/workflows/calendar/calendar-next-event.applescript` |
| `workflows/calendar/calendar-list-calendars.applescript` | List all calendar names | `osascript scripts/workflows/calendar/calendar-list-calendars.applescript` |
| `workflows/calendar/calendar-count-events-today.applescript` | Count events happening today | `osascript scripts/workflows/calendar/calendar-count-events-today.applescript` |
| `workflows/calendar/calendar-event-at-time.applescript` | Create an event at a specific time today | `osascript scripts/workflows/calendar/calendar-event-at-time.applescript` |

### Console

| Script | Description | Run |
|--------|-------------|-----|
| `workflows/console/console-recent-errors.applescript` | Show recent system errors from last 5 minutes | `osascript scripts/workflows/console/console-recent-errors.applescript` |
| `workflows/console/console-app-log.applescript` | Show recent log entries for a specific app | `osascript scripts/workflows/console/console-app-log.applescript` |
| `workflows/console/console-system-log.applescript` | Show recent system messages | `osascript scripts/workflows/console/console-system-log.applescript` |

### Contacts

| Script | Description | Run |
|--------|-------------|-----|
| `workflows/contacts/contacts-search-contact.applescript` | Search for a contact and show their info | `osascript scripts/workflows/contacts/contacts-search-contact.applescript` |
| `workflows/contacts/contacts-count-contacts.applescript` | Show total number of contacts | `osascript scripts/workflows/contacts/contacts-count-contacts.applescript` |
| `workflows/contacts/contacts-new-contact.applescript` | Create a new contact | `osascript scripts/workflows/contacts/contacts-new-contact.applescript` |
| `workflows/contacts/contacts-list-groups.applescript` | List all contact groups | `osascript scripts/workflows/contacts/contacts-list-groups.applescript` |

### Disk Utility

| Script | Description | Run |
|--------|-------------|-----|
| `workflows/disk-utility/disk-utility-list-disks.applescript` | List all disks via diskutil | `osascript scripts/workflows/disk-utility/disk-utility-list-disks.applescript` |
| `workflows/disk-utility/disk-utility-disk-info.applescript` | Show info for main disk via diskutil | `osascript scripts/workflows/disk-utility/disk-utility-disk-info.applescript` |
| `workflows/disk-utility/disk-utility-apfs-list.applescript` | List APFS containers via diskutil | `osascript scripts/workflows/disk-utility/disk-utility-apfs-list.applescript` |

### Finder

| Script | Description | Run |
|--------|-------------|-----|
| `workflows/finder/finder-new-window.applescript` | Open a new Finder window at home folder | `osascript scripts/workflows/finder/finder-new-window.applescript` |
| `workflows/finder/finder-new-window-desktop.applescript` | Open a new Finder window at Desktop | `osascript scripts/workflows/finder/finder-new-window-desktop.applescript` |
| `workflows/finder/finder-new-window-downloads.applescript` | Open a new Finder window at Downloads | `osascript scripts/workflows/finder/finder-new-window-downloads.applescript` |
| `workflows/finder/finder-get-selection.applescript` | Get names of selected Finder items | `osascript scripts/workflows/finder/finder-get-selection.applescript` |
| `workflows/finder/finder-copy-path.applescript` | Copy path of selected Finder item to clipboard | `osascript scripts/workflows/finder/finder-copy-path.applescript` |
| `workflows/finder/finder-reveal-downloads.applescript` | Reveal Downloads folder in Finder | `osascript scripts/workflows/finder/finder-reveal-downloads.applescript` |
| `workflows/finder/finder-empty-trash.applescript` | Empty the Trash (no confirmation) | `osascript scripts/workflows/finder/finder-empty-trash.applescript` |
| `workflows/finder/finder-empty-trash-confirm.applescript` | Empty the Trash with confirmation dialog | `osascript scripts/workflows/finder/finder-empty-trash-confirm.applescript` |
| `workflows/finder/finder-tag-red.applescript` | Tag selected Finder items red | `osascript scripts/workflows/finder/finder-tag-red.applescript` |
| `workflows/finder/finder-tag-orange.applescript` | Tag selected Finder items orange | `osascript scripts/workflows/finder/finder-tag-orange.applescript` |
| `workflows/finder/finder-tag-clear.applescript` | Clear tags from selected Finder items | `osascript scripts/workflows/finder/finder-tag-clear.applescript` |
| `workflows/finder/finder-duplicate-selected.applescript` | Duplicate the selected Finder items | `osascript scripts/workflows/finder/finder-duplicate-selected.applescript` |
| `workflows/finder/finder-compress-selected.applescript` | Compress selected Finder items into a zip | `osascript scripts/workflows/finder/finder-compress-selected.applescript` |
| `workflows/finder/finder-move-to-trash.applescript` | Move selected Finder items to Trash | `osascript scripts/workflows/finder/finder-move-to-trash.applescript` |
| `workflows/finder/finder-count-items.applescript` | Count items in the frontmost Finder window | `osascript scripts/workflows/finder/finder-count-items.applescript` |
| `workflows/finder/finder-toggle-hidden-files.applescript` | Toggle visibility of hidden files in Finder | `osascript scripts/workflows/finder/finder-toggle-hidden-files.applescript` |
| `workflows/finder/finder-new-folder.applescript` | Create a new folder in the frontmost Finder window | `osascript scripts/workflows/finder/finder-new-folder.applescript` |
| `workflows/finder/finder-get-window-path.applescript` | Get POSIX path of the frontmost Finder window | `osascript scripts/workflows/finder/finder-get-window-path.applescript` |
| `workflows/finder/finder-close-all-windows.applescript` | Close all Finder windows | `osascript scripts/workflows/finder/finder-close-all-windows.applescript` |
| `workflows/finder/finder-eject-all.applescript` | Eject all mounted external volumes | `osascript scripts/workflows/finder/finder-eject-all.applescript` |
| `workflows/finder/finder-sort-by-name.applescript` | Sort the frontmost Finder window by name | `osascript scripts/workflows/finder/finder-sort-by-name.applescript` |
| `workflows/finder/finder-file-info.applescript` | Display info about the selected file | `osascript scripts/workflows/finder/finder-file-info.applescript` |
| `workflows/finder/finder-restart-finder.applescript` | Restart Finder (kf) | `osascript scripts/workflows/finder/finder-restart-finder.applescript` |
| `workflows/finder/finder-hide-desktop-icons.applescript` | Hide all desktop icons | `osascript scripts/workflows/finder/finder-hide-desktop-icons.applescript` |
| `workflows/finder/finder-show-desktop-icons.applescript` | Show all desktop icons | `osascript scripts/workflows/finder/finder-show-desktop-icons.applescript` |
| `workflows/finder/finder-open-current-dir.applescript` | Open current working directory in Finder | `osascript scripts/workflows/finder/finder-open-current-dir.applescript` |
| `workflows/finder/finder-set-wallpaper.applescript` | Set desktop wallpaper from a file path | `osascript scripts/workflows/finder/finder-set-wallpaper.applescript` |
| `workflows/finder/finder-airdrop-reveal.applescript` | Reveal a file in Finder for AirDrop sharing | `osascript scripts/workflows/finder/finder-airdrop-reveal.applescript` |

### Hardware

| Script | Description | Run |
|--------|-------------|-----|
| `workflows/hardware/hardware-audio-devices.applescript` | List audio input and output devices | `osascript scripts/workflows/hardware/hardware-audio-devices.applescript` |
| `workflows/hardware/hardware-battery-status.applescript` | Full battery status via IOKit (ioreg) | `osascript scripts/workflows/hardware/hardware-battery-status.applescript` |
| `workflows/hardware/hardware-bluetooth-devices.applescript` | List Bluetooth devices and connection status | `osascript scripts/workflows/hardware/hardware-bluetooth-devices.applescript` |
| `workflows/hardware/hardware-cpu-info.applescript` | Show CPU model, core count, and current load | `osascript scripts/workflows/hardware/hardware-cpu-info.applescript` |
| `workflows/hardware/hardware-disk-usage.applescript` | Show disk usage for the startup volume | `osascript scripts/workflows/hardware/hardware-disk-usage.applescript` |
| `workflows/hardware/hardware-display-brightness.applescript` | Display current screen brightness level | `osascript scripts/workflows/hardware/hardware-display-brightness.applescript` |
| `workflows/hardware/hardware-memory-pressure.applescript` | Show memory pressure and usage statistics | `osascript scripts/workflows/hardware/hardware-memory-pressure.applescript` |
| `workflows/hardware/hardware-usb-devices.applescript` | List connected USB devices | `osascript scripts/workflows/hardware/hardware-usb-devices.applescript` |

### Homepod

| Script | Description | Run |
|--------|-------------|-----|
| `workflows/homepod/homepod-climate-reading.applescript` | Read HomePod temperature and humidity | `osascript scripts/workflows/homepod/homepod-climate-reading.applescript` |
| `workflows/homepod/homepod-climate-log.applescript` | Take a climate reading and log it | `osascript scripts/workflows/homepod/homepod-climate-log.applescript` |
| `workflows/homepod/homepod-climate-dashboard.applescript` | Open the HomePod climate dashboard | `osascript scripts/workflows/homepod/homepod-climate-dashboard.applescript` |
| `workflows/homepod/homepod-climate-summary.applescript` | Show today's climate summary | `osascript scripts/workflows/homepod/homepod-climate-summary.applescript` |

### Image Events

| Script | Description | Run |
|--------|-------------|-----|
| `workflows/image-events/image-events-resize.applescript` | Resize an image file to specified dimensions | `osascript scripts/workflows/image-events/image-events-resize.applescript` |
| `workflows/image-events/image-events-rotate.applescript` | Rotate an image 90 degrees clockwise | `osascript scripts/workflows/image-events/image-events-rotate.applescript` |
| `workflows/image-events/image-events-flip.applescript` | Flip an image horizontally | `osascript scripts/workflows/image-events/image-events-flip.applescript` |
| `workflows/image-events/image-events-get-dimensions.applescript` | Show width and height of an image | `osascript scripts/workflows/image-events/image-events-get-dimensions.applescript` |
| `workflows/image-events/image-events-convert-format.applescript` | Convert an image to JPEG, PNG, or TIFF | `osascript scripts/workflows/image-events/image-events-convert-format.applescript` |

### Imovie

| Script | Description | Run |
|--------|-------------|-----|
| `workflows/imovie/imovie-new-project.applescript` | Create a new iMovie document | `osascript scripts/workflows/imovie/imovie-new-project.applescript` |
| `workflows/imovie/imovie-list-projects.applescript` | List open iMovie projects | `osascript scripts/workflows/imovie/imovie-list-projects.applescript` |

### Keynote

| Script | Description | Run |
|--------|-------------|-----|
| `workflows/keynote/keynote-new-presentation.applescript` | Create a new Keynote presentation | `osascript scripts/workflows/keynote/keynote-new-presentation.applescript` |
| `workflows/keynote/keynote-start-slideshow.applescript` | Start slideshow from the beginning | `osascript scripts/workflows/keynote/keynote-start-slideshow.applescript` |
| `workflows/keynote/keynote-stop-slideshow.applescript` | Stop the current slideshow | `osascript scripts/workflows/keynote/keynote-stop-slideshow.applescript` |
| `workflows/keynote/keynote-next-slide.applescript` | Advance to the next slide | `osascript scripts/workflows/keynote/keynote-next-slide.applescript` |
| `workflows/keynote/keynote-previous-slide.applescript` | Go to the previous slide | `osascript scripts/workflows/keynote/keynote-previous-slide.applescript` |
| `workflows/keynote/keynote-slide-count.applescript` | Show slide count of front document | `osascript scripts/workflows/keynote/keynote-slide-count.applescript` |
| `workflows/keynote/keynote-export-pdf.applescript` | Export front presentation as PDF to Desktop | `osascript scripts/workflows/keynote/keynote-export-pdf.applescript` |
| `workflows/keynote/keynote-current-slide.applescript` | Show current slide number | `osascript scripts/workflows/keynote/keynote-current-slide.applescript` |
| `workflows/keynote/keynote-list-slides.applescript` | List slide titles in a dialog | `osascript scripts/workflows/keynote/keynote-list-slides.applescript` |
| `workflows/keynote/keynote-presenter-notes.applescript` | Show presenter notes for current slide | `osascript scripts/workflows/keynote/keynote-presenter-notes.applescript` |

### Mail

| Script | Description | Run |
|--------|-------------|-----|
| `workflows/mail/mail-check-mail.applescript` | Check for new mail | `osascript scripts/workflows/mail/mail-check-mail.applescript` |
| `workflows/mail/mail-compose.applescript` | Open a new blank compose window | `osascript scripts/workflows/mail/mail-compose.applescript` |
| `workflows/mail/mail-compose-to.applescript` | Compose a new message to a specific address | `osascript scripts/workflows/mail/mail-compose-to.applescript` |
| `workflows/mail/mail-unread-count.applescript` | Show unread mail count as notification | `osascript scripts/workflows/mail/mail-unread-count.applescript` |
| `workflows/mail/mail-read-latest-subject.applescript` | Get the subject of the latest message in inbox | `osascript scripts/workflows/mail/mail-read-latest-subject.applescript` |
| `workflows/mail/mail-reply-to-selected.applescript` | Reply to the selected message | `osascript scripts/workflows/mail/mail-reply-to-selected.applescript` |
| `workflows/mail/mail-forward-selected.applescript` | Forward the selected message | `osascript scripts/workflows/mail/mail-forward-selected.applescript` |
| `workflows/mail/mail-flag-selected.applescript` | Flag the selected message | `osascript scripts/workflows/mail/mail-flag-selected.applescript` |
| `workflows/mail/mail-mark-all-read.applescript` | Mark all inbox messages as read | `osascript scripts/workflows/mail/mail-mark-all-read.applescript` |
| `workflows/mail/mail-delete-junk.applescript` | Delete all junk mail | `osascript scripts/workflows/mail/mail-delete-junk.applescript` |
| `workflows/mail/mail-list-accounts.applescript` | List all mail accounts | `osascript scripts/workflows/mail/mail-list-accounts.applescript` |
| `workflows/mail/mail-archive-selected.applescript` | Move selected messages to Archive | `osascript scripts/workflows/mail/mail-archive-selected.applescript` |
| `workflows/mail/mail-send-quick.applescript` | Send a quick email (dialog prompts for to/subject/body) | `osascript scripts/workflows/mail/mail-send-quick.applescript` |

### Messages

| Script | Description | Run |
|--------|-------------|-----|
| `workflows/messages/messages-send-message.applescript` | Send an iMessage to a contact | `osascript scripts/workflows/messages/messages-send-message.applescript` |
| `workflows/messages/messages-list-chats.applescript` | List recent chat names | `osascript scripts/workflows/messages/messages-list-chats.applescript` |
| `workflows/messages/messages-send-clipboard.applescript` | Send clipboard contents as an iMessage | `osascript scripts/workflows/messages/messages-send-clipboard.applescript` |

### Music

| Script | Description | Run |
|--------|-------------|-----|
| `workflows/music/music-playpause.applescript` | Toggle play/pause | `osascript scripts/workflows/music/music-playpause.applescript` |
| `workflows/music/music-next-track.applescript` | Skip to next track | `osascript scripts/workflows/music/music-next-track.applescript` |
| `workflows/music/music-previous-track.applescript` | Go to previous track | `osascript scripts/workflows/music/music-previous-track.applescript` |
| `workflows/music/music-now-playing.applescript` | Show current track as notification | `osascript scripts/workflows/music/music-now-playing.applescript` |
| `workflows/music/music-now-playing-clipboard.applescript` | Copy current track info to clipboard | `osascript scripts/workflows/music/music-now-playing-clipboard.applescript` |
| `workflows/music/music-volume-up.applescript` | Increase Music volume by 10 | `osascript scripts/workflows/music/music-volume-up.applescript` |
| `workflows/music/music-volume-down.applescript` | Decrease Music volume by 10 | `osascript scripts/workflows/music/music-volume-down.applescript` |
| `workflows/music/music-mute-toggle.applescript` | Toggle Music mute | `osascript scripts/workflows/music/music-mute-toggle.applescript` |
| `workflows/music/music-toggle-shuffle.applescript` | Toggle shuffle mode | `osascript scripts/workflows/music/music-toggle-shuffle.applescript` |
| `workflows/music/music-love-current.applescript` | Favorite the current track | `osascript scripts/workflows/music/music-love-current.applescript` |
| `workflows/music/music-dislike-current.applescript` | Dislike the current track and skip | `osascript scripts/workflows/music/music-dislike-current.applescript` |
| `workflows/music/music-add-to-playlist.applescript` | Add current track to a playlist by name | `osascript scripts/workflows/music/music-add-to-playlist.applescript` |
| `workflows/music/music-search-library.applescript` | Search the music library | `osascript scripts/workflows/music/music-search-library.applescript` |
| `workflows/music/music-rating-5-stars.applescript` | Rate the current track 5 stars | `osascript scripts/workflows/music/music-rating-5-stars.applescript` |
| `workflows/music/music-stop.applescript` | Stop playback | `osascript scripts/workflows/music/music-stop.applescript` |
| `workflows/music/music-toggle-repeat.applescript` | Cycle repeat mode: off → all → one → off | `osascript scripts/workflows/music/music-toggle-repeat.applescript` |
| `workflows/music/music-rating-0-stars.applescript` | Clear rating of current track | `osascript scripts/workflows/music/music-rating-0-stars.applescript` |
| `workflows/music/music-rating-1-star.applescript` | Rate the current track 1 star | `osascript scripts/workflows/music/music-rating-1-star.applescript` |
| `workflows/music/music-rating-2-stars.applescript` | Rate the current track 2 stars | `osascript scripts/workflows/music/music-rating-2-stars.applescript` |
| `workflows/music/music-rating-3-stars.applescript` | Rate the current track 3 stars | `osascript scripts/workflows/music/music-rating-3-stars.applescript` |
| `workflows/music/music-rating-4-stars.applescript` | Rate the current track 4 stars | `osascript scripts/workflows/music/music-rating-4-stars.applescript` |
| `workflows/music/music-get-lyrics.applescript` | Show lyrics of current track | `osascript scripts/workflows/music/music-get-lyrics.applescript` |
| `workflows/music/music-track-info-detail.applescript` | Show detailed info about current track | `osascript scripts/workflows/music/music-track-info-detail.applescript` |
| `workflows/music/music-toggle-eq.applescript` | Toggle equalizer on/off | `osascript scripts/workflows/music/music-toggle-eq.applescript` |
| `workflows/music/music-set-eq-preset.applescript` | Choose an EQ preset from list | `osascript scripts/workflows/music/music-set-eq-preset.applescript` |
| `workflows/music/music-toggle-visuals.applescript` | Toggle visual effects on/off | `osascript scripts/workflows/music/music-toggle-visuals.applescript` |
| `workflows/music/music-play-playlist.applescript` | Choose a playlist to play | `osascript scripts/workflows/music/music-play-playlist.applescript` |
| `workflows/music/music-reveal-current.applescript` | Reveal current track in Music library | `osascript scripts/workflows/music/music-reveal-current.applescript` |
| `workflows/music/music-count-library.applescript` | Show total track count in library | `osascript scripts/workflows/music/music-count-library.applescript` |
| `workflows/music/music-played-count-current.applescript` | Show how many times current track was played | `osascript scripts/workflows/music/music-played-count-current.applescript` |
| `workflows/music/music-toggle-fullscreen.applescript` | Toggle Music fullscreen mode | `osascript scripts/workflows/music/music-toggle-fullscreen.applescript` |
| `workflows/music/music-seek-forward-30.applescript` | Jump forward 30 seconds | `osascript scripts/workflows/music/music-seek-forward-30.applescript` |
| `workflows/music/music-seek-backward-30.applescript` | Jump backward 30 seconds | `osascript scripts/workflows/music/music-seek-backward-30.applescript` |
| `workflows/music/music-list-playlists.applescript` | Show all user playlists as notification | `osascript scripts/workflows/music/music-list-playlists.applescript` |
| `workflows/music/music-create-playlist.applescript` | Create a new empty playlist | `osascript scripts/workflows/music/music-create-playlist.applescript` |
| `workflows/music/music-airplay-list.applescript` | Show available AirPlay devices | `osascript scripts/workflows/music/music-airplay-list.applescript` |
| `workflows/music/music-current-stream-info.applescript` | Show stream title and URL if streaming | `osascript scripts/workflows/music/music-current-stream-info.applescript` |

### Notes

| Script | Description | Run |
|--------|-------------|-----|
| `workflows/notes/notes-new-note.applescript` | Create a new note with title and body | `osascript scripts/workflows/notes/notes-new-note.applescript` |
| `workflows/notes/notes-new-note-from-clipboard.applescript` | Create a new note from clipboard contents | `osascript scripts/workflows/notes/notes-new-note-from-clipboard.applescript` |
| `workflows/notes/notes-list-notes.applescript` | List names of recent notes | `osascript scripts/workflows/notes/notes-list-notes.applescript` |
| `workflows/notes/notes-search-notes.applescript` | Search notes by name | `osascript scripts/workflows/notes/notes-search-notes.applescript` |
| `workflows/notes/notes-count-notes.applescript` | Show total note count | `osascript scripts/workflows/notes/notes-count-notes.applescript` |
| `workflows/notes/notes-list-folders.applescript` | List all Notes folders | `osascript scripts/workflows/notes/notes-list-folders.applescript` |
| `workflows/notes/notes-append-to-note.applescript` | Append text to an existing note | `osascript scripts/workflows/notes/notes-append-to-note.applescript` |
| `workflows/notes/notes-show-recent-note.applescript` | Open the most recently modified note | `osascript scripts/workflows/notes/notes-show-recent-note.applescript` |

### Numbers

| Script | Description | Run |
|--------|-------------|-----|
| `workflows/numbers/numbers-new-spreadsheet.applescript` | Create a new blank Numbers spreadsheet | `osascript scripts/workflows/numbers/numbers-new-spreadsheet.applescript` |
| `workflows/numbers/numbers-export-csv.applescript` | Export front document as CSV to Desktop | `osascript scripts/workflows/numbers/numbers-export-csv.applescript` |
| `workflows/numbers/numbers-sheet-count.applescript` | Show sheet count of front document | `osascript scripts/workflows/numbers/numbers-sheet-count.applescript` |
| `workflows/numbers/numbers-table-count.applescript` | Show table count in active sheet | `osascript scripts/workflows/numbers/numbers-table-count.applescript` |
| `workflows/numbers/numbers-list-sheets.applescript` | List sheet names in a dialog | `osascript scripts/workflows/numbers/numbers-list-sheets.applescript` |
| `workflows/numbers/numbers-export-pdf.applescript` | Export front document as PDF to Desktop | `osascript scripts/workflows/numbers/numbers-export-pdf.applescript` |

### Pages

| Script | Description | Run |
|--------|-------------|-----|
| `workflows/pages/pages-new-document.applescript` | Create a new blank Pages document | `osascript scripts/workflows/pages/pages-new-document.applescript` |
| `workflows/pages/pages-word-count.applescript` | Show word count of front document | `osascript scripts/workflows/pages/pages-word-count.applescript` |
| `workflows/pages/pages-export-pdf.applescript` | Export front document as PDF to Desktop | `osascript scripts/workflows/pages/pages-export-pdf.applescript` |
| `workflows/pages/pages-character-count.applescript` | Show character count of front document | `osascript scripts/workflows/pages/pages-character-count.applescript` |
| `workflows/pages/pages-page-count.applescript` | Show page count of front document | `osascript scripts/workflows/pages/pages-page-count.applescript` |
| `workflows/pages/pages-list-documents.applescript` | List all open Pages documents | `osascript scripts/workflows/pages/pages-list-documents.applescript` |

### Photos

| Script | Description | Run |
|--------|-------------|-----|
| `workflows/photos/photos-search.applescript` | Search Photos library | `osascript scripts/workflows/photos/photos-search.applescript` |
| `workflows/photos/photos-export-selected.applescript` | Export selected photos to Desktop | `osascript scripts/workflows/photos/photos-export-selected.applescript` |
| `workflows/photos/photos-favorites-count.applescript` | Count favorited photos | `osascript scripts/workflows/photos/photos-favorites-count.applescript` |
| `workflows/photos/photos-start-slideshow.applescript` | Start a slideshow of selected photos | `osascript scripts/workflows/photos/photos-start-slideshow.applescript` |
| `workflows/photos/photos-stop-slideshow.applescript` | Stop the currently playing slideshow | `osascript scripts/workflows/photos/photos-stop-slideshow.applescript` |
| `workflows/photos/photos-count-photos.applescript` | Show total photo count in library | `osascript scripts/workflows/photos/photos-count-photos.applescript` |
| `workflows/photos/photos-list-albums.applescript` | List all album names | `osascript scripts/workflows/photos/photos-list-albums.applescript` |
| `workflows/photos/photos-create-album.applescript` | Create a new empty album | `osascript scripts/workflows/photos/photos-create-album.applescript` |
| `workflows/photos/photos-favorite-selected.applescript` | Favorite the selected photos | `osascript scripts/workflows/photos/photos-favorite-selected.applescript` |

### Preview

| Script | Description | Run |
|--------|-------------|-----|
| `workflows/preview/preview-open-file.applescript` | Open a file in Preview via choose dialog | `osascript scripts/workflows/preview/preview-open-file.applescript` |
| `workflows/preview/preview-zoom-in.applescript` | Zoom in on current Preview document | `osascript scripts/workflows/preview/preview-zoom-in.applescript` |
| `workflows/preview/preview-zoom-out.applescript` | Zoom out on current Preview document | `osascript scripts/workflows/preview/preview-zoom-out.applescript` |
| `workflows/preview/preview-rotate-left.applescript` | Rotate current Preview document left | `osascript scripts/workflows/preview/preview-rotate-left.applescript` |

### Quicktime

| Script | Description | Run |
|--------|-------------|-----|
| `workflows/quicktime/quicktime-new-screen-recording.applescript` | Start a new screen recording | `osascript scripts/workflows/quicktime/quicktime-new-screen-recording.applescript` |
| `workflows/quicktime/quicktime-new-audio-recording.applescript` | Start a new audio recording | `osascript scripts/workflows/quicktime/quicktime-new-audio-recording.applescript` |
| `workflows/quicktime/quicktime-new-movie-recording.applescript` | Start a new movie recording | `osascript scripts/workflows/quicktime/quicktime-new-movie-recording.applescript` |
| `workflows/quicktime/quicktime-play-frontmost.applescript` | Play the frontmost QuickTime document | `osascript scripts/workflows/quicktime/quicktime-play-frontmost.applescript` |
| `workflows/quicktime/quicktime-pause-frontmost.applescript` | Pause the frontmost QuickTime document | `osascript scripts/workflows/quicktime/quicktime-pause-frontmost.applescript` |
| `workflows/quicktime/quicktime-present-fullscreen.applescript` | Present the frontmost document in fullscreen | `osascript scripts/workflows/quicktime/quicktime-present-fullscreen.applescript` |

### Reminders

| Script | Description | Run |
|--------|-------------|-----|
| `workflows/reminders/reminders-quick-reminder.applescript` | Create a quick reminder | `osascript scripts/workflows/reminders/reminders-quick-reminder.applescript` |
| `workflows/reminders/reminders-reminder-due-today.applescript` | Create a reminder due today | `osascript scripts/workflows/reminders/reminders-reminder-due-today.applescript` |
| `workflows/reminders/reminders-reminder-from-clipboard.applescript` | Create a reminder from clipboard text | `osascript scripts/workflows/reminders/reminders-reminder-from-clipboard.applescript` |
| `workflows/reminders/reminders-show-today.applescript` | Show reminders due today | `osascript scripts/workflows/reminders/reminders-show-today.applescript` |
| `workflows/reminders/reminders-complete-latest.applescript` | Mark the most recent incomplete reminder as done | `osascript scripts/workflows/reminders/reminders-complete-latest.applescript` |
| `workflows/reminders/reminders-list-lists.applescript` | Show all reminder lists | `osascript scripts/workflows/reminders/reminders-list-lists.applescript` |
| `workflows/reminders/reminders-count-incomplete.applescript` | Count incomplete reminders | `osascript scripts/workflows/reminders/reminders-count-incomplete.applescript` |
| `workflows/reminders/reminders-reminder-with-priority.applescript` | Create a high-priority reminder | `osascript scripts/workflows/reminders/reminders-reminder-with-priority.applescript` |
| `workflows/reminders/reminders-flagged-reminders.applescript` | Show all flagged reminders | `osascript scripts/workflows/reminders/reminders-flagged-reminders.applescript` |

### Safari

| Script | Description | Run |
|--------|-------------|-----|
| `workflows/safari/safari-current-url.applescript` | Copy the URL of the current Safari tab to clipboard | `osascript scripts/workflows/safari/safari-current-url.applescript` |
| `workflows/safari/safari-current-title.applescript` | Copy the title of the current Safari tab to clipboard | `osascript scripts/workflows/safari/safari-current-title.applescript` |
| `workflows/safari/safari-current-url-and-title.applescript` | Copy URL and title as markdown link | `osascript scripts/workflows/safari/safari-current-url-and-title.applescript` |
| `workflows/safari/safari-open-url.applescript` | Open a URL in a new Safari tab | `osascript scripts/workflows/safari/safari-open-url.applescript` |
| `workflows/safari/safari-search-web.applescript` | Search the web using Safari | `osascript scripts/workflows/safari/safari-search-web.applescript` |
| `workflows/safari/safari-add-reading-list.applescript` | Add the current page to Reading List | `osascript scripts/workflows/safari/safari-add-reading-list.applescript` |
| `workflows/safari/safari-close-all-tabs.applescript` | Close all tabs in the front Safari window | `osascript scripts/workflows/safari/safari-close-all-tabs.applescript` |
| `workflows/safari/safari-list-all-tabs.applescript` | List all open Safari tab URLs | `osascript scripts/workflows/safari/safari-list-all-tabs.applescript` |
| `workflows/safari/safari-page-source.applescript` | Copy page source of current tab to clipboard | `osascript scripts/workflows/safari/safari-page-source.applescript` |
| `workflows/safari/safari-do-javascript.applescript` | Run JavaScript in the current Safari tab | `osascript scripts/workflows/safari/safari-do-javascript.applescript` |
| `workflows/safari/safari-show-bookmarks.applescript` | Show Safari bookmarks | `osascript scripts/workflows/safari/safari-show-bookmarks.applescript` |
| `workflows/safari/safari-reload-tab.applescript` | Reload the current Safari tab | `osascript scripts/workflows/safari/safari-reload-tab.applescript` |
| `workflows/safari/safari-show-privacy-report.applescript` | Show Safari Privacy Report | `osascript scripts/workflows/safari/safari-show-privacy-report.applescript` |
| `workflows/safari/safari-tab-count.applescript` | Show number of open tabs across all windows | `osascript scripts/workflows/safari/safari-tab-count.applescript` |
| `workflows/safari/safari-close-other-tabs.applescript` | Close all tabs except the current one | `osascript scripts/workflows/safari/safari-close-other-tabs.applescript` |

### Screenshot

| Script | Description | Run |
|--------|-------------|-----|
| `workflows/screenshot/screenshot-fullscreen.applescript` | Capture full screen to Desktop | `osascript scripts/workflows/screenshot/screenshot-fullscreen.applescript` |
| `workflows/screenshot/screenshot-area.applescript` | Capture selected area to Desktop | `osascript scripts/workflows/screenshot/screenshot-area.applescript` |
| `workflows/screenshot/screenshot-window.applescript` | Capture front window to Desktop | `osascript scripts/workflows/screenshot/screenshot-window.applescript` |
| `workflows/screenshot/screenshot-clipboard.applescript` | Capture selected area to clipboard | `osascript scripts/workflows/screenshot/screenshot-clipboard.applescript` |

### Script Editor

| Script | Description | Run |
|--------|-------------|-----|
| `workflows/script-editor/script-editor-compile.applescript` | Compile the front Script Editor document | `osascript scripts/workflows/script-editor/script-editor-compile.applescript` |
| `workflows/script-editor/script-editor-run.applescript` | Run the front Script Editor document | `osascript scripts/workflows/script-editor/script-editor-run.applescript` |
| `workflows/script-editor/script-editor-new-script.applescript` | Create a new Script Editor document with a template | `osascript scripts/workflows/script-editor/script-editor-new-script.applescript` |
| `workflows/script-editor/script-editor-get-result.applescript` | Get the result of the last script run | `osascript scripts/workflows/script-editor/script-editor-get-result.applescript` |
| `workflows/script-editor/script-editor-open-dictionary.applescript` | Open the scripting dictionary browser | `osascript scripts/workflows/script-editor/script-editor-open-dictionary.applescript` |

### Shortcuts

| Script | Description | Run |
|--------|-------------|-----|
| `workflows/shortcuts/shortcuts-run-shortcut.applescript` | Run a named Shortcut | `osascript scripts/workflows/shortcuts/shortcuts-run-shortcut.applescript` |
| `workflows/shortcuts/shortcuts-list-shortcuts.applescript` | List all available Shortcuts | `osascript scripts/workflows/shortcuts/shortcuts-list-shortcuts.applescript` |
| `workflows/shortcuts/shortcuts-run-shortcut-with-input.applescript` | Run a Shortcut with text input | `osascript scripts/workflows/shortcuts/shortcuts-run-shortcut-with-input.applescript` |
| `workflows/shortcuts/shortcuts-search-shortcuts.applescript` | Search for a Shortcut by name and run it | `osascript scripts/workflows/shortcuts/shortcuts-search-shortcuts.applescript` |

### System Events

| Script | Description | Run |
|--------|-------------|-----|
| `workflows/system-events/system-events-dark-mode-toggle.applescript` | Toggle macOS Dark Mode | `osascript scripts/workflows/system-events/system-events-dark-mode-toggle.applescript` |
| `workflows/system-events/system-events-screenshot-area.applescript` | Take a screenshot of a selected area | `osascript scripts/workflows/system-events/system-events-screenshot-area.applescript` |
| `workflows/system-events/system-events-screenshot-window.applescript` | Take a screenshot of the frontmost window | `osascript scripts/workflows/system-events/system-events-screenshot-window.applescript` |
| `workflows/system-events/system-events-get-frontmost-app.applescript` | Get the name of the frontmost application | `osascript scripts/workflows/system-events/system-events-get-frontmost-app.applescript` |
| `workflows/system-events/system-events-list-running-apps.applescript` | List all running applications | `osascript scripts/workflows/system-events/system-events-list-running-apps.applescript` |
| `workflows/system-events/system-events-spotlight-status.applescript` | Check Spotlight indexing status | `osascript scripts/workflows/system-events/system-events-spotlight-status.applescript` |
| `workflows/system-events/system-events-wifi-toggle.applescript` | Toggle Wi-Fi on/off | `osascript scripts/workflows/system-events/system-events-wifi-toggle.applescript` |
| `workflows/system-events/system-events-volume-set.applescript` | Set system volume to a specific level | `osascript scripts/workflows/system-events/system-events-volume-set.applescript` |
| `workflows/system-events/system-events-do-not-disturb.applescript` | Toggle Do Not Disturb (Focus) | `osascript scripts/workflows/system-events/system-events-do-not-disturb.applescript` |
| `workflows/system-events/system-events-type-text.applescript` | Type text via System Events (paste alternative) | `osascript scripts/workflows/system-events/system-events-type-text.applescript` |
| `workflows/system-events/system-events-hide-dock.applescript` | Hide the Dock (autohide on) | `osascript scripts/workflows/system-events/system-events-hide-dock.applescript` |
| `workflows/system-events/system-events-show-dock.applescript` | Show the Dock (autohide off) | `osascript scripts/workflows/system-events/system-events-show-dock.applescript` |
| `workflows/system-events/system-events-dock-add-spacer.applescript` | Add a spacer tile to the Dock | `osascript scripts/workflows/system-events/system-events-dock-add-spacer.applescript` |
| `workflows/system-events/system-events-dock-add-recent-apps.applescript` | Add Recent Apps stack to the Dock | `osascript scripts/workflows/system-events/system-events-dock-add-recent-apps.applescript` |
| `workflows/system-events/system-events-restart-menu-bar.applescript` | Restart the macOS menu bar (topbar) | `osascript scripts/workflows/system-events/system-events-restart-menu-bar.applescript` |
| `workflows/system-events/system-events-reset-apple-events.applescript` | Reset Apple Events daemon (fixes -1712 errors) | `osascript scripts/workflows/system-events/system-events-reset-apple-events.applescript` |
| `workflows/system-events/system-events-key-shortcut.applescript` | Send a keyboard shortcut to the frontmost app | `osascript scripts/workflows/system-events/system-events-key-shortcut.applescript` |
| `workflows/system-events/system-events-battery-status.applescript` | Show battery percentage and charging state | `osascript scripts/workflows/system-events/system-events-battery-status.applescript` |
| `workflows/system-events/system-events-disk-usage.applescript` | Show disk space usage for the main drive | `osascript scripts/workflows/system-events/system-events-disk-usage.applescript` |
| `workflows/system-events/system-events-uptime.applescript` | Show system uptime | `osascript scripts/workflows/system-events/system-events-uptime.applescript` |
| `workflows/system-events/system-events-ip-address.applescript` | Show current IP addresses (local and external) | `osascript scripts/workflows/system-events/system-events-ip-address.applescript` |
| `workflows/system-events/system-events-bluetooth-toggle.applescript` | Toggle Bluetooth on/off | `osascript scripts/workflows/system-events/system-events-bluetooth-toggle.applescript` |
| `workflows/system-events/system-events-screen-lock.applescript` | Lock the screen immediately | `osascript scripts/workflows/system-events/system-events-screen-lock.applescript` |
| `workflows/system-events/system-events-empty-clipboard.applescript` | Clear the clipboard | `osascript scripts/workflows/system-events/system-events-empty-clipboard.applescript` |
| `workflows/system-events/system-events-trash-size.applescript` | Show the size of the Trash | `osascript scripts/workflows/system-events/system-events-trash-size.applescript` |
| `workflows/system-events/system-events-notification-count.applescript` | Show pending notification count | `osascript scripts/workflows/system-events/system-events-notification-count.applescript` |

### System Information

| Script | Description | Run |
|--------|-------------|-----|
| `workflows/system-information/system-information-hardware.applescript` | Show hardware overview | `osascript scripts/workflows/system-information/system-information-hardware.applescript` |
| `workflows/system-information/system-information-software.applescript` | Show software overview | `osascript scripts/workflows/system-information/system-information-software.applescript` |
| `workflows/system-information/system-information-network.applescript` | Show network configuration info | `osascript scripts/workflows/system-information/system-information-network.applescript` |
| `workflows/system-information/system-information-storage.applescript` | Show storage and disk info | `osascript scripts/workflows/system-information/system-information-storage.applescript` |

### System Settings

| Script | Description | Run |
|--------|-------------|-----|
| `workflows/system-settings/system-settings-wifi.applescript` | Open Wi-Fi settings pane | `osascript scripts/workflows/system-settings/system-settings-wifi.applescript` |
| `workflows/system-settings/system-settings-bluetooth.applescript` | Open Bluetooth settings pane | `osascript scripts/workflows/system-settings/system-settings-bluetooth.applescript` |
| `workflows/system-settings/system-settings-sound.applescript` | Open Sound settings pane | `osascript scripts/workflows/system-settings/system-settings-sound.applescript` |
| `workflows/system-settings/system-settings-displays.applescript` | Open Displays settings pane | `osascript scripts/workflows/system-settings/system-settings-displays.applescript` |
| `workflows/system-settings/system-settings-battery.applescript` | Open Battery settings pane | `osascript scripts/workflows/system-settings/system-settings-battery.applescript` |
| `workflows/system-settings/system-settings-notifications.applescript` | Open Notifications settings pane | `osascript scripts/workflows/system-settings/system-settings-notifications.applescript` |
| `workflows/system-settings/system-settings-privacy.applescript` | Open Privacy and Security settings pane | `osascript scripts/workflows/system-settings/system-settings-privacy.applescript` |
| `workflows/system-settings/system-settings-general.applescript` | Open General settings pane | `osascript scripts/workflows/system-settings/system-settings-general.applescript` |

### Terminal

| Script | Description | Run |
|--------|-------------|-----|
| `workflows/terminal/terminal-new-tab.applescript` | Open a new Terminal tab | `osascript scripts/workflows/terminal/terminal-new-tab.applescript` |
| `workflows/terminal/terminal-new-tab-at-path.applescript` | Open Terminal tab at a specific directory | `osascript scripts/workflows/terminal/terminal-new-tab-at-path.applescript` |
| `workflows/terminal/terminal-run-command.applescript` | Run a command in a new Terminal tab | `osascript scripts/workflows/terminal/terminal-run-command.applescript` |
| `workflows/terminal/terminal-clear-scrollback.applescript` | Clear scrollback in the front Terminal tab | `osascript scripts/workflows/terminal/terminal-clear-scrollback.applescript` |
| `workflows/terminal/terminal-set-title.applescript` | Set a custom title for the front Terminal tab | `osascript scripts/workflows/terminal/terminal-set-title.applescript` |
| `workflows/terminal/terminal-ssh-connect.applescript` | Open an SSH connection in a new tab | `osascript scripts/workflows/terminal/terminal-ssh-connect.applescript` |

### Textedit

| Script | Description | Run |
|--------|-------------|-----|
| `workflows/textedit/textedit-new-from-clipboard.applescript` | Open TextEdit with clipboard contents | `osascript scripts/workflows/textedit/textedit-new-from-clipboard.applescript` |
| `workflows/textedit/textedit-word-count.applescript` | Count words in frontmost TextEdit document | `osascript scripts/workflows/textedit/textedit-word-count.applescript` |
| `workflows/textedit/textedit-new-document.applescript` | Create a new blank TextEdit document | `osascript scripts/workflows/textedit/textedit-new-document.applescript` |
| `workflows/textedit/textedit-save-as-txt.applescript` | Save frontmost TextEdit document as plain text to Desktop | `osascript scripts/workflows/textedit/textedit-save-as-txt.applescript` |
| `workflows/textedit/textedit-char-count.applescript` | Count characters in frontmost TextEdit document | `osascript scripts/workflows/textedit/textedit-char-count.applescript` |

### Time Machine

| Script | Description | Run |
|--------|-------------|-----|
| `workflows/time-machine/time-machine-status.applescript` | Show Time Machine backup status | `osascript scripts/workflows/time-machine/time-machine-status.applescript` |
| `workflows/time-machine/time-machine-list-backups.applescript` | List recent Time Machine backups | `osascript scripts/workflows/time-machine/time-machine-list-backups.applescript` |
| `workflows/time-machine/time-machine-start-backup.applescript` | Start a Time Machine backup | `osascript scripts/workflows/time-machine/time-machine-start-backup.applescript` |
| `workflows/time-machine/time-machine-latest-backup.applescript` | Show latest Time Machine backup timestamp | `osascript scripts/workflows/time-machine/time-machine-latest-backup.applescript` |

### Tv

| Script | Description | Run |
|--------|-------------|-----|
| `workflows/tv/tv-playpause.applescript` | Toggle play/pause | `osascript scripts/workflows/tv/tv-playpause.applescript` |
| `workflows/tv/tv-next-track.applescript` | Skip to next track | `osascript scripts/workflows/tv/tv-next-track.applescript` |
| `workflows/tv/tv-previous-track.applescript` | Go to previous track | `osascript scripts/workflows/tv/tv-previous-track.applescript` |
| `workflows/tv/tv-now-playing.applescript` | Show current track as notification | `osascript scripts/workflows/tv/tv-now-playing.applescript` |
| `workflows/tv/tv-list-playlists.applescript` | List playlists in a dialog | `osascript scripts/workflows/tv/tv-list-playlists.applescript` |
| `workflows/tv/tv-search-library.applescript` | Search TV library by name | `osascript scripts/workflows/tv/tv-search-library.applescript` |
| `workflows/tv/tv-mute-toggle.applescript` | Toggle TV mute | `osascript scripts/workflows/tv/tv-mute-toggle.applescript` |
| `workflows/tv/tv-volume-up.applescript` | Increase TV volume by 10 | `osascript scripts/workflows/tv/tv-volume-up.applescript` |
| `workflows/tv/tv-volume-down.applescript` | Decrease TV volume by 10 | `osascript scripts/workflows/tv/tv-volume-down.applescript` |
| `workflows/tv/tv-reveal-current.applescript` | Reveal current track in library | `osascript scripts/workflows/tv/tv-reveal-current.applescript` |

---

**Total: 64 launchers + 281 workflows = 345 scripts**
