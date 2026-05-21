# Workflows Index — 301 scripts across 33 apps

**Grep this file to find the right script without scanning every app.**
Grep by trigger keyword (`grep airdrop`), by app name (`^## finder`), or by description token.

Format: `script-name` — description — triggers: a, b, c — `path`
Regenerate: `python3 bin/gen-skill-indexes.py`
Re-seed trigger headers after adding scripts: `python3 bin/seed-script-triggers.py`

## accessibility (8)

`ax-system-settings-battery` — Open System Settings Battery pane via Accessibility API — triggers: ax, system, settings, battery, open, pane, accessibility, api — `scripts/workflows/accessibility/ax-system-settings-battery.applescript`
`ax-system-settings-bluetooth` — Open System Settings Bluetooth pane via Accessibility API — triggers: ax, system, settings, bluetooth, open, pane, accessibility, api — `scripts/workflows/accessibility/ax-system-settings-bluetooth.applescript`
`ax-system-settings-displays` — Open System Settings Displays pane via Accessibility API — triggers: ax, system, settings, displays, open, pane, accessibility, api — `scripts/workflows/accessibility/ax-system-settings-displays.applescript`
`ax-system-settings-keyboard` — Open System Settings Keyboard pane via Accessibility API — triggers: ax, system, settings, keyboard, open, pane, accessibility, api — `scripts/workflows/accessibility/ax-system-settings-keyboard.applescript`
`ax-system-settings-notifications` — Open System Settings Notifications pane via Accessibility API — triggers: ax, system, settings, notifications, open, pane, accessibility, api — `scripts/workflows/accessibility/ax-system-settings-notifications.applescript`
`ax-system-settings-privacy` — Open System Settings Privacy & Security pane via Accessibility API — triggers: ax, system, settings, privacy, open, security, pane, accessibility — `scripts/workflows/accessibility/ax-system-settings-privacy.applescript`
`ax-system-settings-sound` — Open System Settings Sound pane via Accessibility API — triggers: ax, system, settings, sound, open, pane, accessibility, api — `scripts/workflows/accessibility/ax-system-settings-sound.applescript`
`ax-system-settings-wifi` — Open System Settings Wi-Fi pane via Accessibility API — triggers: ax, system, settings, wifi, open, pane, accessibility, api — `scripts/workflows/accessibility/ax-system-settings-wifi.applescript`

## automator (5)

`automator-get-result` — Get the execution result of the front workflow — triggers: get, result, execution, front, workflow — `scripts/workflows/automator/automator-get-result.applescript`
`automator-list-actions` — List available Automator actions and copy to clipboard — triggers: list, actions, available, automator, copy, clipboard — `scripts/workflows/automator/automator-list-actions.applescript`
`automator-new-workflow` — Create a new Automator workflow document — triggers: new, workflow, create, automator, document — `scripts/workflows/automator/automator-new-workflow.applescript`
`automator-run-workflow` — Run an Automator workflow file by path — triggers: run, workflow, automator, file, path — `scripts/workflows/automator/automator-run-workflow.applescript`
`automator-save-as-app` — Save the front Automator workflow as an application — triggers: save, app, front, automator, workflow, application — `scripts/workflows/automator/automator-save-as-app.applescript`

## calendar (9)

`calendar-count-events-today` — Count events happening today — triggers: count, events, today, happening — `scripts/workflows/calendar/calendar-count-events-today.applescript`
`calendar-event-at-time` — Create an event at a specific time today — triggers: event, time, create, specific, today — `scripts/workflows/calendar/calendar-event-at-time.applescript`
`calendar-list-calendars` — List all calendar names — triggers: list, calendars, calendar, names — `scripts/workflows/calendar/calendar-list-calendars.applescript`
`calendar-next-event` — Show the next upcoming calendar event — triggers: next, event, show, upcoming, calendar — `scripts/workflows/calendar/calendar-next-event.applescript`
`calendar-quick-event` — Create a quick calendar event — triggers: quick, event, create, calendar — `scripts/workflows/calendar/calendar-quick-event.applescript`
`calendar-reload` — Reload all calendars — triggers: reload, calendars — `scripts/workflows/calendar/calendar-reload.applescript`
`calendar-show-month` — Switch Calendar to month view — triggers: show, month, switch, calendar, view — `scripts/workflows/calendar/calendar-show-month.applescript`
`calendar-show-today` — Switch Calendar to today view — triggers: show, today, switch, calendar, view — `scripts/workflows/calendar/calendar-show-today.applescript`
`calendar-show-week` — Switch Calendar to week view — triggers: show, week, switch, calendar, view — `scripts/workflows/calendar/calendar-show-week.applescript`

## console (3)

`console-app-log` — Show recent log entries for a specific app — triggers: app, log, show, recent, entries, specific — `scripts/workflows/console/console-app-log.applescript`
`console-recent-errors` — Show recent system errors from last 5 minutes — triggers: recent, errors, show, system, last, minutes — `scripts/workflows/console/console-recent-errors.applescript`
`console-system-log` — Show recent system messages — triggers: system, log, show, recent, messages — `scripts/workflows/console/console-system-log.applescript`

## contacts (4)

`contacts-count-contacts` — Show total number of contacts — triggers: count, show, total, number, contacts — `scripts/workflows/contacts/contacts-count-contacts.applescript`
`contacts-list-groups` — List all contact groups — triggers: list, groups, contact — `scripts/workflows/contacts/contacts-list-groups.applescript`
`contacts-new-contact` — Create a new contact — triggers: new, contact, create — `scripts/workflows/contacts/contacts-new-contact.applescript`
`contacts-search-contact` — Search for a contact and show their info — triggers: search, contact, show, info — `scripts/workflows/contacts/contacts-search-contact.applescript`

## disk-utility (3)

`disk-utility-apfs-list` — List APFS containers via diskutil — triggers: apfs, list, containers, diskutil — `scripts/workflows/disk-utility/disk-utility-apfs-list.applescript`
`disk-utility-disk-info` — Show info for main disk via diskutil — triggers: info, show, main, disk, diskutil — `scripts/workflows/disk-utility/disk-utility-disk-info.applescript`
`disk-utility-list-disks` — List all disks via diskutil — triggers: list, disks, diskutil — `scripts/workflows/disk-utility/disk-utility-list-disks.applescript`

## finder (28)

`finder-airdrop-reveal` — Reveal a file in Finder for AirDrop sharing — triggers: airdrop, reveal, file, finder, sharing — `scripts/workflows/finder/finder-airdrop-reveal.applescript`
`finder-close-all-windows` — Close all Finder windows — triggers: close, windows, finder — `scripts/workflows/finder/finder-close-all-windows.applescript`
`finder-compress-selected` — Compress selected Finder items into a zip — triggers: compress, selected, finder, items, zip — `scripts/workflows/finder/finder-compress-selected.applescript`
`finder-copy-path` — Copy path of selected Finder item to clipboard — triggers: copy, path, selected, finder, item, clipboard — `scripts/workflows/finder/finder-copy-path.applescript`
`finder-count-items` — Count items in the frontmost Finder window — triggers: count, items, frontmost, finder, window — `scripts/workflows/finder/finder-count-items.applescript`
`finder-duplicate-selected` — Duplicate the selected Finder items — triggers: duplicate, selected, finder, items — `scripts/workflows/finder/finder-duplicate-selected.applescript`
`finder-eject-all` — Eject all mounted external volumes — triggers: eject, mounted, external, volumes — `scripts/workflows/finder/finder-eject-all.applescript`
`finder-empty-trash-confirm` — Empty the Trash with confirmation dialog — triggers: empty, trash, confirm, confirmation, dialog — `scripts/workflows/finder/finder-empty-trash-confirm.applescript`
`finder-empty-trash` — Empty the Trash (no confirmation) — triggers: empty, trash, confirmation — `scripts/workflows/finder/finder-empty-trash.applescript`
`finder-file-info` — Display info about the selected file — triggers: file, info, display, about, selected — `scripts/workflows/finder/finder-file-info.applescript`
`finder-get-selection` — Get names of selected Finder items — triggers: get, selection, names, selected, finder, items — `scripts/workflows/finder/finder-get-selection.applescript`
`finder-get-window-path` — Get POSIX path of the frontmost Finder window — triggers: get, window, path, posix, frontmost, finder — `scripts/workflows/finder/finder-get-window-path.applescript`
`finder-hide-desktop-icons` — Hide all desktop icons — triggers: hide, desktop, icons — `scripts/workflows/finder/finder-hide-desktop-icons.applescript`
`finder-move-to-trash` — Move selected Finder items to Trash — triggers: move, trash, selected, finder, items — `scripts/workflows/finder/finder-move-to-trash.applescript`
`finder-new-folder` — Create a new folder in the frontmost Finder window — triggers: new, folder, create, frontmost, finder, window — `scripts/workflows/finder/finder-new-folder.applescript`
`finder-new-window-desktop` — Open a new Finder window at Desktop — triggers: new, window, desktop, open, finder — `scripts/workflows/finder/finder-new-window-desktop.applescript`
`finder-new-window-downloads` — Open a new Finder window at Downloads — triggers: new, window, downloads, open, finder — `scripts/workflows/finder/finder-new-window-downloads.applescript`
`finder-new-window` — Open a new Finder window at home folder — triggers: new, window, open, finder, home, folder — `scripts/workflows/finder/finder-new-window.applescript`
`finder-open-current-dir` — Open current working directory in Finder — triggers: open, dir, working, directory, finder — `scripts/workflows/finder/finder-open-current-dir.applescript`
`finder-restart-finder` — Restart Finder (kf) — triggers: restart, finder — `scripts/workflows/finder/finder-restart-finder.applescript`
`finder-reveal-downloads` — Reveal Downloads folder in Finder — triggers: reveal, downloads, folder, finder — `scripts/workflows/finder/finder-reveal-downloads.applescript`
`finder-set-wallpaper` — Set desktop wallpaper from a file path — triggers: set, wallpaper, desktop, file, path — `scripts/workflows/finder/finder-set-wallpaper.applescript`
`finder-show-desktop-icons` — Show all desktop icons — triggers: show, desktop, icons — `scripts/workflows/finder/finder-show-desktop-icons.applescript`
`finder-sort-by-name` — Sort the frontmost Finder window by name — triggers: sort, name, frontmost, finder, window — `scripts/workflows/finder/finder-sort-by-name.applescript`
`finder-tag-clear` — Clear tags from selected Finder items — triggers: tag, clear, tags, selected, finder, items — `scripts/workflows/finder/finder-tag-clear.applescript`
`finder-tag-orange` — Tag selected Finder items orange — triggers: tag, orange, selected, finder, items — `scripts/workflows/finder/finder-tag-orange.applescript`
`finder-tag-red` — Tag selected Finder items red — triggers: tag, red, selected, finder, items — `scripts/workflows/finder/finder-tag-red.applescript`
`finder-toggle-hidden-files` — Toggle visibility of hidden files in Finder — triggers: toggle, hidden, files, visibility, finder — `scripts/workflows/finder/finder-toggle-hidden-files.applescript`

## hardware (8)

`hardware-audio-devices` — List audio input and output devices — triggers: audio, devices, list, input, output — `scripts/workflows/hardware/hardware-audio-devices.applescript`
`hardware-battery-status` — Full battery status via IOKit (ioreg) — triggers: battery, status, full, iokit, ioreg — `scripts/workflows/hardware/hardware-battery-status.applescript`
`hardware-bluetooth-devices` — List Bluetooth devices and connection status — triggers: bluetooth, devices, list, connection, status — `scripts/workflows/hardware/hardware-bluetooth-devices.applescript`
`hardware-cpu-info` — Show CPU model, core count, and current load — triggers: cpu, info, show, model, core, count, load — `scripts/workflows/hardware/hardware-cpu-info.applescript`
`hardware-disk-usage` — Show disk usage for the startup volume — triggers: disk, usage, show, startup, volume — `scripts/workflows/hardware/hardware-disk-usage.applescript`
`hardware-display-brightness` — Display current screen brightness level — triggers: display, brightness, screen, level — `scripts/workflows/hardware/hardware-display-brightness.applescript`
`hardware-memory-pressure` — Show memory pressure and usage statistics — triggers: memory, pressure, show, usage, statistics — `scripts/workflows/hardware/hardware-memory-pressure.applescript`
`hardware-usb-devices` — List connected USB devices — triggers: usb, devices, list, connected — `scripts/workflows/hardware/hardware-usb-devices.applescript`

## homepod (11)

`homepod-climate-dashboard` — Open the HomePod climate dashboard — triggers: climate, dashboard, open, homepod — `scripts/workflows/homepod/homepod-climate-dashboard.applescript`
`homepod-climate-log` — Take a climate reading and log it — triggers: climate, log, take, reading — `scripts/workflows/homepod/homepod-climate-log.applescript`
`homepod-climate-reading` — Read HomePod temperature and humidity — triggers: climate, reading, read, homepod, temperature, humidity — `scripts/workflows/homepod/homepod-climate-reading.applescript`
`homepod-climate-summary` — Show today's climate summary — triggers: climate, summary, show, today — `scripts/workflows/homepod/homepod-climate-summary.applescript`
`homepod-good-morning-scene` — Run the Good Morning HomeKit scene via Shortcuts — triggers: good, morning, scene, run, homekit, shortcuts — `scripts/workflows/homepod/homepod-good-morning-scene.applescript`
`homepod-good-night-scene` — Run the Good Night HomeKit scene via Shortcuts — triggers: good, night, scene, run, homekit, shortcuts — `scripts/workflows/homepod/homepod-good-night-scene.applescript`
`homepod-lights-off` — Turn off lights via HomeKit shortcut — triggers: lights, off, turn, homekit, shortcut — `scripts/workflows/homepod/homepod-lights-off.applescript`
`homepod-lights-on` — Turn on lights via HomeKit shortcut — triggers: lights, turn, homekit, shortcut — `scripts/workflows/homepod/homepod-lights-on.applescript`
`homepod-pause-music` — Pause music on HomePod via Shortcuts — triggers: pause, music, homepod, shortcuts — `scripts/workflows/homepod/homepod-pause-music.applescript`
`homepod-play-music` — Play music on HomePod via Shortcuts — triggers: play, music, homepod, shortcuts — `scripts/workflows/homepod/homepod-play-music.applescript`
`homepod-set-volume` — Set HomePod volume via dialog and Shortcuts — triggers: set, volume, homepod, dialog, shortcuts — `scripts/workflows/homepod/homepod-set-volume.applescript`

## image-events (5)

`image-events-convert-format` — Convert an image to JPEG, PNG, or TIFF — triggers: convert, format, image, jpeg, png, tiff — `scripts/workflows/image-events/image-events-convert-format.applescript`
`image-events-flip` — Flip an image horizontally — triggers: flip, image, horizontally — `scripts/workflows/image-events/image-events-flip.applescript`
`image-events-get-dimensions` — Show width and height of an image — triggers: get, dimensions, show, width, height, image — `scripts/workflows/image-events/image-events-get-dimensions.applescript`
`image-events-resize` — Resize an image file to specified dimensions — triggers: resize, image, file, specified, dimensions — `scripts/workflows/image-events/image-events-resize.applescript`
`image-events-rotate` — Rotate an image 90 degrees clockwise — triggers: rotate, image, degrees, clockwise — `scripts/workflows/image-events/image-events-rotate.applescript`

## imovie (2)

`imovie-list-projects` — List open iMovie projects — triggers: list, projects, open, imovie — `scripts/workflows/imovie/imovie-list-projects.applescript`
`imovie-new-project` — Create a new iMovie document — triggers: new, project, create, imovie, document — `scripts/workflows/imovie/imovie-new-project.applescript`

## keynote (10)

`keynote-current-slide` — Show current slide number — triggers: slide, show, number — `scripts/workflows/keynote/keynote-current-slide.applescript`
`keynote-export-pdf` — Export front presentation as PDF to Desktop — triggers: export, pdf, front, presentation, desktop — `scripts/workflows/keynote/keynote-export-pdf.applescript`
`keynote-list-slides` — List slide titles in a dialog — triggers: list, slides, slide, titles, dialog — `scripts/workflows/keynote/keynote-list-slides.applescript`
`keynote-new-presentation` — Create a new Keynote presentation — triggers: new, presentation, create, keynote — `scripts/workflows/keynote/keynote-new-presentation.applescript`
`keynote-next-slide` — Advance to the next slide — triggers: next, slide, advance — `scripts/workflows/keynote/keynote-next-slide.applescript`
`keynote-presenter-notes` — Show presenter notes for current slide — triggers: presenter, notes, show, slide — `scripts/workflows/keynote/keynote-presenter-notes.applescript`
`keynote-previous-slide` — Go to the previous slide — triggers: previous, slide — `scripts/workflows/keynote/keynote-previous-slide.applescript`
`keynote-slide-count` — Show slide count of front document — triggers: slide, count, show, front, document — `scripts/workflows/keynote/keynote-slide-count.applescript`
`keynote-start-slideshow` — Start slideshow from the beginning — triggers: start, slideshow, beginning — `scripts/workflows/keynote/keynote-start-slideshow.applescript`
`keynote-stop-slideshow` — Stop the current slideshow — triggers: stop, slideshow — `scripts/workflows/keynote/keynote-stop-slideshow.applescript`

## mail (13)

`mail-archive-selected` — Move selected messages to Archive — triggers: archive, selected, move, messages — `scripts/workflows/mail/mail-archive-selected.applescript`
`mail-check-mail` — Check for new mail — triggers: check, new, mail — `scripts/workflows/mail/mail-check-mail.applescript`
`mail-compose-to` — Compose a new message to a specific address — triggers: compose, new, message, specific, address — `scripts/workflows/mail/mail-compose-to.applescript`
`mail-compose` — Open a new blank compose window — triggers: compose, open, new, blank, window — `scripts/workflows/mail/mail-compose.applescript`
`mail-delete-junk` — Delete all junk mail — triggers: delete, junk, mail — `scripts/workflows/mail/mail-delete-junk.applescript`
`mail-flag-selected` — Flag the selected message — triggers: flag, selected, message — `scripts/workflows/mail/mail-flag-selected.applescript`
`mail-forward-selected` — Forward the selected message — triggers: forward, selected, message — `scripts/workflows/mail/mail-forward-selected.applescript`
`mail-list-accounts` — List all mail accounts — triggers: list, accounts, mail — `scripts/workflows/mail/mail-list-accounts.applescript`
`mail-mark-all-read` — Mark all inbox messages as read — triggers: mark, read, inbox, messages — `scripts/workflows/mail/mail-mark-all-read.applescript`
`mail-read-latest-subject` — Get the subject of the latest message in inbox — triggers: read, latest, subject, get, message, inbox — `scripts/workflows/mail/mail-read-latest-subject.applescript`
`mail-reply-to-selected` — Reply to the selected message — triggers: reply, selected, message — `scripts/workflows/mail/mail-reply-to-selected.applescript`
`mail-send-quick` — Send a quick email (dialog prompts for to/subject/body) — triggers: send, quick, email, dialog, prompts, subject, body — `scripts/workflows/mail/mail-send-quick.applescript`
`mail-unread-count` — Show unread mail count as notification — triggers: unread, count, show, mail, notification — `scripts/workflows/mail/mail-unread-count.applescript`

## messages (3)

`messages-list-chats` — List recent chat names — triggers: list, chats, recent, chat, names — `scripts/workflows/messages/messages-list-chats.applescript`
`messages-send-clipboard` — Send clipboard contents as an iMessage — triggers: send, clipboard, contents, imessage — `scripts/workflows/messages/messages-send-clipboard.applescript`
`messages-send-message` — Send an iMessage to a contact — triggers: send, message, imessage, contact — `scripts/workflows/messages/messages-send-message.applescript`

## music (37)

`music-add-to-playlist` — Add current track to a playlist by name — triggers: add, playlist, track, name — `scripts/workflows/music/music-add-to-playlist.applescript`
`music-airplay-list` — Show available AirPlay devices — triggers: airplay, list, show, available, devices — `scripts/workflows/music/music-airplay-list.applescript`
`music-count-library` — Show total track count in library — triggers: count, library, show, total, track — `scripts/workflows/music/music-count-library.applescript`
`music-create-playlist` — Create a new empty playlist — triggers: create, playlist, new, empty — `scripts/workflows/music/music-create-playlist.applescript`
`music-current-stream-info` — Show stream title and URL if streaming — triggers: stream, info, show, title, url, streaming — `scripts/workflows/music/music-current-stream-info.applescript`
`music-dislike-current` — Dislike the current track and skip — triggers: dislike, track, skip — `scripts/workflows/music/music-dislike-current.applescript`
`music-get-lyrics` — Show lyrics of current track — triggers: get, lyrics, show, track — `scripts/workflows/music/music-get-lyrics.applescript`
`music-list-playlists` — Show all user playlists as notification — triggers: list, playlists, show, user, notification — `scripts/workflows/music/music-list-playlists.applescript`
`music-love-current` — Favorite the current track — triggers: love, favorite, track — `scripts/workflows/music/music-love-current.applescript`
`music-mute-toggle` — Toggle Music mute — triggers: mute, toggle, music — `scripts/workflows/music/music-mute-toggle.applescript`
`music-next-track` — Skip to next track — triggers: next, track, skip — `scripts/workflows/music/music-next-track.applescript`
`music-now-playing-clipboard` — Copy current track info to clipboard — triggers: now, playing, clipboard, copy, track, info — `scripts/workflows/music/music-now-playing-clipboard.applescript`
`music-now-playing` — Show current track as notification — triggers: now, playing, show, track, notification — `scripts/workflows/music/music-now-playing.applescript`
`music-play-playlist` — Choose a playlist to play — triggers: play, playlist, choose — `scripts/workflows/music/music-play-playlist.applescript`
`music-played-count-current` — Show how many times current track was played — triggers: played, count, show, how, many, times, track — `scripts/workflows/music/music-played-count-current.applescript`
`music-playpause` — Toggle play/pause — triggers: playpause, toggle, play, pause — `scripts/workflows/music/music-playpause.applescript`
`music-previous-track` — Go to previous track — triggers: previous, track — `scripts/workflows/music/music-previous-track.applescript`
`music-rating-0-stars` — Clear rating of current track — triggers: rating, stars, clear, track — `scripts/workflows/music/music-rating-0-stars.applescript`
`music-rating-1-star` — Rate the current track 1 star — triggers: rating, star, rate, track — `scripts/workflows/music/music-rating-1-star.applescript`
`music-rating-2-stars` — Rate the current track 2 stars — triggers: rating, stars, rate, track — `scripts/workflows/music/music-rating-2-stars.applescript`
`music-rating-3-stars` — Rate the current track 3 stars — triggers: rating, stars, rate, track — `scripts/workflows/music/music-rating-3-stars.applescript`
`music-rating-4-stars` — Rate the current track 4 stars — triggers: rating, stars, rate, track — `scripts/workflows/music/music-rating-4-stars.applescript`
`music-rating-5-stars` — Rate the current track 5 stars — triggers: rating, stars, rate, track — `scripts/workflows/music/music-rating-5-stars.applescript`
`music-reveal-current` — Reveal current track in Music library — triggers: reveal, track, music, library — `scripts/workflows/music/music-reveal-current.applescript`
`music-search-library` — Search the music library — triggers: search, library, music — `scripts/workflows/music/music-search-library.applescript`
`music-seek-backward-30` — Jump backward 30 seconds — triggers: seek, backward, jump, seconds — `scripts/workflows/music/music-seek-backward-30.applescript`
`music-seek-forward-30` — Jump forward 30 seconds — triggers: seek, forward, jump, seconds — `scripts/workflows/music/music-seek-forward-30.applescript`
`music-set-eq-preset` — Choose an EQ preset from list — triggers: set, preset, choose, list — `scripts/workflows/music/music-set-eq-preset.applescript`
`music-stop` — Stop playback — triggers: stop, playback — `scripts/workflows/music/music-stop.applescript`
`music-toggle-eq` — Toggle equalizer on/off — triggers: toggle, equalizer, off — `scripts/workflows/music/music-toggle-eq.applescript`
`music-toggle-fullscreen` — Toggle Music fullscreen mode — triggers: toggle, fullscreen, music, mode — `scripts/workflows/music/music-toggle-fullscreen.applescript`
`music-toggle-repeat` — Cycle repeat mode: off → all → one → off — triggers: toggle, repeat, cycle, mode, off, one — `scripts/workflows/music/music-toggle-repeat.applescript`
`music-toggle-shuffle` — Toggle shuffle mode — triggers: toggle, shuffle, mode — `scripts/workflows/music/music-toggle-shuffle.applescript`
`music-toggle-visuals` — Toggle visual effects on/off — triggers: toggle, visuals, visual, effects, off — `scripts/workflows/music/music-toggle-visuals.applescript`
`music-track-info-detail` — Show detailed info about current track — triggers: track, info, detail, show, detailed, about — `scripts/workflows/music/music-track-info-detail.applescript`
`music-volume-down` — Decrease Music volume by 10 — triggers: volume, down, decrease, music — `scripts/workflows/music/music-volume-down.applescript`
`music-volume-up` — Increase Music volume by 10 — triggers: volume, increase, music — `scripts/workflows/music/music-volume-up.applescript`

## notes (8)

`notes-append-to-note` — Append text to an existing note — triggers: append, note, text, existing — `scripts/workflows/notes/notes-append-to-note.applescript`
`notes-count-notes` — Show total note count — triggers: count, show, total, note — `scripts/workflows/notes/notes-count-notes.applescript`
`notes-list-folders` — List all Notes folders — triggers: list, folders, notes — `scripts/workflows/notes/notes-list-folders.applescript`
`notes-list-notes` — List names of recent notes — triggers: list, names, recent, notes — `scripts/workflows/notes/notes-list-notes.applescript`
`notes-new-note-from-clipboard` — Create a new note from clipboard contents — triggers: new, note, clipboard, create, contents — `scripts/workflows/notes/notes-new-note-from-clipboard.applescript`
`notes-new-note` — Create a new note with title and body — triggers: new, note, create, title, body — `scripts/workflows/notes/notes-new-note.applescript`
`notes-search-notes` — Search notes by name — triggers: search, notes, name — `scripts/workflows/notes/notes-search-notes.applescript`
`notes-show-recent-note` — Open the most recently modified note — triggers: show, recent, note, open, most, recently, modified — `scripts/workflows/notes/notes-show-recent-note.applescript`

## numbers (6)

`numbers-export-csv` — Export front document as CSV to Desktop — triggers: export, csv, front, document, desktop — `scripts/workflows/numbers/numbers-export-csv.applescript`
`numbers-export-pdf` — Export front document as PDF to Desktop — triggers: export, pdf, front, document, desktop — `scripts/workflows/numbers/numbers-export-pdf.applescript`
`numbers-list-sheets` — List sheet names in a dialog — triggers: list, sheets, sheet, names, dialog — `scripts/workflows/numbers/numbers-list-sheets.applescript`
`numbers-new-spreadsheet` — Create a new blank Numbers spreadsheet — triggers: new, spreadsheet, create, blank, numbers — `scripts/workflows/numbers/numbers-new-spreadsheet.applescript`
`numbers-sheet-count` — Show sheet count of front document — triggers: sheet, count, show, front, document — `scripts/workflows/numbers/numbers-sheet-count.applescript`
`numbers-table-count` — Show table count in active sheet — triggers: table, count, show, active, sheet — `scripts/workflows/numbers/numbers-table-count.applescript`

## pages (6)

`pages-character-count` — Show character count of front document — triggers: character, count, show, front, document — `scripts/workflows/pages/pages-character-count.applescript`
`pages-export-pdf` — Export front document as PDF to Desktop — triggers: export, pdf, front, document, desktop — `scripts/workflows/pages/pages-export-pdf.applescript`
`pages-list-documents` — List all open Pages documents — triggers: list, documents, open, pages — `scripts/workflows/pages/pages-list-documents.applescript`
`pages-new-document` — Create a new blank Pages document — triggers: new, document, create, blank, pages — `scripts/workflows/pages/pages-new-document.applescript`
`pages-page-count` — Show page count of front document — triggers: page, count, show, front, document — `scripts/workflows/pages/pages-page-count.applescript`
`pages-word-count` — Show word count of front document — triggers: word, count, show, front, document — `scripts/workflows/pages/pages-word-count.applescript`

## photos (9)

`photos-count-photos` — Show total photo count in library — triggers: count, show, total, photo, library — `scripts/workflows/photos/photos-count-photos.applescript`
`photos-create-album` — Create a new empty album — triggers: create, album, new, empty — `scripts/workflows/photos/photos-create-album.applescript`
`photos-export-selected` — Export selected photos to Desktop — triggers: export, selected, photos, desktop — `scripts/workflows/photos/photos-export-selected.applescript`
`photos-favorite-selected` — Favorite the selected photos — triggers: favorite, selected, photos — `scripts/workflows/photos/photos-favorite-selected.applescript`
`photos-favorites-count` — Count favorited photos — triggers: favorites, count, favorited, photos — `scripts/workflows/photos/photos-favorites-count.applescript`
`photos-list-albums` — List all album names — triggers: list, albums, album, names — `scripts/workflows/photos/photos-list-albums.applescript`
`photos-search` — Search Photos library — triggers: search, photos, library — `scripts/workflows/photos/photos-search.applescript`
`photos-start-slideshow` — Start a slideshow of selected photos — triggers: start, slideshow, selected, photos — `scripts/workflows/photos/photos-start-slideshow.applescript`
`photos-stop-slideshow` — Stop the currently playing slideshow — triggers: stop, slideshow, currently, playing — `scripts/workflows/photos/photos-stop-slideshow.applescript`

## preview (4)

`preview-open-file` — Open a file in Preview via choose dialog — triggers: open, file, preview, choose, dialog — `scripts/workflows/preview/preview-open-file.applescript`
`preview-rotate-left` — Rotate current Preview document left — triggers: rotate, left, preview, document — `scripts/workflows/preview/preview-rotate-left.applescript`
`preview-zoom-in` — Zoom in on current Preview document — triggers: zoom, preview, document — `scripts/workflows/preview/preview-zoom-in.applescript`
`preview-zoom-out` — Zoom out on current Preview document — triggers: zoom, out, preview, document — `scripts/workflows/preview/preview-zoom-out.applescript`

## quicktime (6)

`quicktime-new-audio-recording` — Start a new audio recording — triggers: new, audio, recording, start — `scripts/workflows/quicktime/quicktime-new-audio-recording.applescript`
`quicktime-new-movie-recording` — Start a new movie recording — triggers: new, movie, recording, start — `scripts/workflows/quicktime/quicktime-new-movie-recording.applescript`
`quicktime-new-screen-recording` — Start a new screen recording — triggers: new, screen, recording, start — `scripts/workflows/quicktime/quicktime-new-screen-recording.applescript`
`quicktime-pause-frontmost` — Pause the frontmost QuickTime document — triggers: pause, frontmost, quicktime, document — `scripts/workflows/quicktime/quicktime-pause-frontmost.applescript`
`quicktime-play-frontmost` — Play the frontmost QuickTime document — triggers: play, frontmost, quicktime, document — `scripts/workflows/quicktime/quicktime-play-frontmost.applescript`
`quicktime-present-fullscreen` — Present the frontmost document in fullscreen — triggers: present, fullscreen, frontmost, document — `scripts/workflows/quicktime/quicktime-present-fullscreen.applescript`

## reminders (9)

`reminders-complete-latest` — Mark the most recent incomplete reminder as done — triggers: complete, latest, mark, most, recent, incomplete, reminder, done — `scripts/workflows/reminders/reminders-complete-latest.applescript`
`reminders-count-incomplete` — Count incomplete reminders — triggers: count, incomplete, reminders — `scripts/workflows/reminders/reminders-count-incomplete.applescript`
`reminders-flagged-reminders` — Show all flagged reminders — triggers: flagged, show, reminders — `scripts/workflows/reminders/reminders-flagged-reminders.applescript`
`reminders-list-lists` — Show all reminder lists — triggers: list, lists, show, reminder — `scripts/workflows/reminders/reminders-list-lists.applescript`
`reminders-quick-reminder` — Create a quick reminder — triggers: quick, reminder, create — `scripts/workflows/reminders/reminders-quick-reminder.applescript`
`reminders-reminder-due-today` — Create a reminder due today — triggers: reminder, due, today, create — `scripts/workflows/reminders/reminders-reminder-due-today.applescript`
`reminders-reminder-from-clipboard` — Create a reminder from clipboard text — triggers: reminder, clipboard, create, text — `scripts/workflows/reminders/reminders-reminder-from-clipboard.applescript`
`reminders-reminder-with-priority` — Create a high-priority reminder — triggers: reminder, priority, create, high — `scripts/workflows/reminders/reminders-reminder-with-priority.applescript`
`reminders-show-today` — Show reminders due today — triggers: show, today, reminders, due — `scripts/workflows/reminders/reminders-show-today.applescript`

## safari (15)

`safari-add-reading-list` — Add the current page to Reading List — triggers: add, reading, list, page — `scripts/workflows/safari/safari-add-reading-list.applescript`
`safari-close-all-tabs` — Close all tabs in the front Safari window — triggers: close, tabs, front, safari, window — `scripts/workflows/safari/safari-close-all-tabs.applescript`
`safari-close-other-tabs` — Close all tabs except the current one — triggers: close, other, tabs, except, one — `scripts/workflows/safari/safari-close-other-tabs.applescript`
`safari-current-title` — Copy the title of the current Safari tab to clipboard — triggers: title, copy, safari, tab, clipboard — `scripts/workflows/safari/safari-current-title.applescript`
`safari-current-url-and-title` — Copy URL and title as markdown link — triggers: url, title, copy, markdown, link — `scripts/workflows/safari/safari-current-url-and-title.applescript`
`safari-current-url` — Copy the URL of the current Safari tab to clipboard — triggers: url, copy, safari, tab, clipboard — `scripts/workflows/safari/safari-current-url.applescript`
`safari-do-javascript` — Run JavaScript in the current Safari tab — triggers: javascript, run, safari, tab — `scripts/workflows/safari/safari-do-javascript.applescript`
`safari-list-all-tabs` — List all open Safari tab URLs — triggers: list, tabs, open, safari, tab, urls — `scripts/workflows/safari/safari-list-all-tabs.applescript`
`safari-open-url` — Open a URL in a new Safari tab — triggers: open, url, new, safari, tab — `scripts/workflows/safari/safari-open-url.applescript`
`safari-page-source` — Copy page source of current tab to clipboard — triggers: page, source, copy, tab, clipboard — `scripts/workflows/safari/safari-page-source.applescript`
`safari-reload-tab` — Reload the current Safari tab — triggers: reload, tab, safari — `scripts/workflows/safari/safari-reload-tab.applescript`
`safari-search-web` — Search the web using Safari — triggers: search, web, safari — `scripts/workflows/safari/safari-search-web.applescript`
`safari-show-bookmarks` — Show Safari bookmarks — triggers: show, bookmarks, safari — `scripts/workflows/safari/safari-show-bookmarks.applescript`
`safari-show-privacy-report` — Show Safari Privacy Report — triggers: show, privacy, report, safari — `scripts/workflows/safari/safari-show-privacy-report.applescript`
`safari-tab-count` — Show number of open tabs across all windows — triggers: tab, count, show, number, open, tabs, across, windows — `scripts/workflows/safari/safari-tab-count.applescript`

## screenshot (4)

`screenshot-area` — Capture selected area to Desktop — triggers: area, capture, selected, desktop — `scripts/workflows/screenshot/screenshot-area.applescript`
`screenshot-clipboard` — Capture selected area to clipboard — triggers: clipboard, capture, selected, area — `scripts/workflows/screenshot/screenshot-clipboard.applescript`
`screenshot-fullscreen` — Capture full screen to Desktop — triggers: fullscreen, capture, full, screen, desktop — `scripts/workflows/screenshot/screenshot-fullscreen.applescript`
`screenshot-window` — Capture front window to Desktop — triggers: window, capture, front, desktop — `scripts/workflows/screenshot/screenshot-window.applescript`

## script-editor (5)

`script-editor-compile` — Compile the front Script Editor document — triggers: compile, front, script, editor, document — `scripts/workflows/script-editor/script-editor-compile.applescript`
`script-editor-get-result` — Get the result of the last script run — triggers: get, result, last, script, run — `scripts/workflows/script-editor/script-editor-get-result.applescript`
`script-editor-new-script` — Create a new Script Editor document with a template — triggers: new, create, script, editor, document, template — `scripts/workflows/script-editor/script-editor-new-script.applescript`
`script-editor-open-dictionary` — Open the scripting dictionary browser — triggers: open, dictionary, scripting, browser — `scripts/workflows/script-editor/script-editor-open-dictionary.applescript`
`script-editor-run` — Run the front Script Editor document — triggers: run, front, script, editor, document — `scripts/workflows/script-editor/script-editor-run.applescript`

## shortcuts (4)

`shortcuts-list-shortcuts` — List all available Shortcuts — triggers: list, available, shortcuts — `scripts/workflows/shortcuts/shortcuts-list-shortcuts.applescript`
`shortcuts-run-shortcut-with-input` — Run a Shortcut with text input — triggers: run, shortcut, input, text — `scripts/workflows/shortcuts/shortcuts-run-shortcut-with-input.applescript`
`shortcuts-run-shortcut` — Run a named Shortcut — triggers: run, shortcut, named — `scripts/workflows/shortcuts/shortcuts-run-shortcut.applescript`
`shortcuts-search-shortcuts` — Search for a Shortcut by name and run it — triggers: search, shortcut, name, run — `scripts/workflows/shortcuts/shortcuts-search-shortcuts.applescript`

## system-events (39)

`SideBySide` — SideBySide.applescript — triggers: sidebyside, applescript — `scripts/workflows/system-events/SideBySide.applescript`
`System-Events-HideAllOthers` — Hide All Others (native, no keystroke simulation) — triggers: hideallothers, hide, others, native, keystroke, simulation — `scripts/workflows/system-events/System-Events-HideAllOthers.applescript`
`System-Events-MosaicKnob` — Mosaic Knob: single script with two subroutines for Loupedeck knob. — triggers: mosaicknob, mosaic, knob, single, script, two, subroutines, loupedeck — `scripts/workflows/system-events/System-Events-MosaicKnob.applescript`
`System-Events-MosaicWindows` — Mosaic Windows: tile all windows of the frontmost app into a grid — triggers: mosaicwindows, mosaic, windows, tile, frontmost, app, grid — `scripts/workflows/system-events/System-Events-MosaicWindows.applescript`
`System-Events-WhiteboardBrowse` — WhiteboardBrowse: Button press — pick project → topic, show first board. — triggers: whiteboardbrowse, button, press, pick, project, topic, show, first — `scripts/workflows/system-events/System-Events-WhiteboardBrowse.applescript`
`System-Events-WhiteboardKnob` — WhiteboardKnob: Browse ALL whiteboards across ~/work/ and ~/.claude/skills/ with a Loupedeck knob. — triggers: whiteboardknob, browse, whiteboards, across, work, claude, skills, loupedeck — `scripts/workflows/system-events/System-Events-WhiteboardKnob.applescript`
`System-Events-WhiteboardNext` — WhiteboardNext: Knob turn RIGHT — next board in Quick Look. — triggers: whiteboardnext, knob, turn, right, next, board, quick, look — `scripts/workflows/system-events/System-Events-WhiteboardNext.applescript`
`System-Events-WhiteboardOpen` — WhiteboardOpen: Knob press — open current board in Preview. — triggers: whiteboardopen, knob, press, open, board, preview — `scripts/workflows/system-events/System-Events-WhiteboardOpen.applescript`
`System-Events-WhiteboardPrev` — WhiteboardPrev: Knob turn LEFT — previous board in Quick Look. — triggers: whiteboardprev, knob, turn, left, previous, board, quick, look — `scripts/workflows/system-events/System-Events-WhiteboardPrev.applescript`
`Thirds` — Thirds.applescript — triggers: thirds, applescript — `scripts/workflows/system-events/Thirds.applescript`
`TopBottom` — TopBottom.applescript — triggers: topbottom, applescript — `scripts/workflows/system-events/TopBottom.applescript`
`mosaic-less` — Mosaic Less: show one fewer window of the frontmost app, tiled. — triggers: mosaic, less, show, one, fewer, window, frontmost, app — `scripts/workflows/system-events/mosaic-less.sh`
`mosaic-more` — Mosaic More: show one more window of the frontmost app, tiled. — triggers: mosaic, more, show, one, window, frontmost, app, tiled — `scripts/workflows/system-events/mosaic-more.sh`
`system-events-battery-status` — Show battery percentage and charging state — triggers: battery, status, show, percentage, charging, state — `scripts/workflows/system-events/system-events-battery-status.applescript`
`system-events-bluetooth-toggle` — Toggle Bluetooth on/off — triggers: bluetooth, toggle, off — `scripts/workflows/system-events/system-events-bluetooth-toggle.applescript`
`system-events-dark-mode-toggle` — Toggle macOS Dark Mode — triggers: dark, mode, toggle, macos — `scripts/workflows/system-events/system-events-dark-mode-toggle.applescript`
`system-events-disk-usage` — Show disk space usage for the main drive — triggers: disk, usage, show, space, main, drive — `scripts/workflows/system-events/system-events-disk-usage.applescript`
`system-events-do-not-disturb` — Toggle Do Not Disturb (Focus) — triggers: disturb, toggle, focus — `scripts/workflows/system-events/system-events-do-not-disturb.applescript`
`system-events-dock-add-recent-apps` — Add Recent Apps stack to the Dock — triggers: dock, add, recent, apps, stack — `scripts/workflows/system-events/system-events-dock-add-recent-apps.applescript`
`system-events-dock-add-spacer` — Add a spacer tile to the Dock — triggers: dock, add, spacer, tile — `scripts/workflows/system-events/system-events-dock-add-spacer.applescript`
`system-events-empty-clipboard` — Clear the clipboard — triggers: empty, clipboard, clear — `scripts/workflows/system-events/system-events-empty-clipboard.applescript`
`system-events-get-frontmost-app` — Get the name of the frontmost application — triggers: get, frontmost, app, name, application — `scripts/workflows/system-events/system-events-get-frontmost-app.applescript`
`system-events-hide-dock` — Hide the Dock (autohide on) — triggers: hide, dock, autohide — `scripts/workflows/system-events/system-events-hide-dock.applescript`
`system-events-ip-address` — Show current IP addresses (local and external) — triggers: address, show, addresses, local, external — `scripts/workflows/system-events/system-events-ip-address.applescript`
`system-events-key-shortcut` — Send a keyboard shortcut to the frontmost app — triggers: key, shortcut, send, keyboard, frontmost, app — `scripts/workflows/system-events/system-events-key-shortcut.applescript`
`system-events-list-running-apps` — List all running applications — triggers: list, running, apps, applications — `scripts/workflows/system-events/system-events-list-running-apps.applescript`
`system-events-notification-count` — Show pending notification count — triggers: notification, count, show, pending — `scripts/workflows/system-events/system-events-notification-count.applescript`
`system-events-reset-apple-events` — Reset Apple Events daemon (fixes -1712 errors) — triggers: reset, apple, events, daemon, fixes, 1712, errors — `scripts/workflows/system-events/system-events-reset-apple-events.applescript`
`system-events-restart-menu-bar` — Restart the macOS menu bar (topbar) — triggers: restart, menu, bar, macos, topbar — `scripts/workflows/system-events/system-events-restart-menu-bar.applescript`
`system-events-screen-lock` — Lock the screen immediately — triggers: screen, lock, immediately — `scripts/workflows/system-events/system-events-screen-lock.applescript`
`system-events-screenshot-area` — Take a screenshot of a selected area — triggers: screenshot, area, take, selected — `scripts/workflows/system-events/system-events-screenshot-area.applescript`
`system-events-screenshot-window` — Take a screenshot of the frontmost window — triggers: screenshot, window, take, frontmost — `scripts/workflows/system-events/system-events-screenshot-window.applescript`
`system-events-show-dock` — Show the Dock (autohide off) — triggers: show, dock, autohide, off — `scripts/workflows/system-events/system-events-show-dock.applescript`
`system-events-spotlight-status` — Check Spotlight indexing status — triggers: spotlight, status, check, indexing — `scripts/workflows/system-events/system-events-spotlight-status.applescript`
`system-events-trash-size` — Show the size of the Trash — triggers: trash, size, show — `scripts/workflows/system-events/system-events-trash-size.applescript`
`system-events-type-text` — Type text via System Events (paste alternative) — triggers: type, text, system, events, paste, alternative — `scripts/workflows/system-events/system-events-type-text.applescript`
`system-events-uptime` — Show system uptime — triggers: uptime, show, system — `scripts/workflows/system-events/system-events-uptime.applescript`
`system-events-volume-set` — Set system volume to a specific level — triggers: volume, set, system, specific, level — `scripts/workflows/system-events/system-events-volume-set.applescript`
`system-events-wifi-toggle` — Toggle Wi-Fi on/off — triggers: wifi, toggle, off — `scripts/workflows/system-events/system-events-wifi-toggle.applescript`

## system-information (4)

`system-information-hardware` — Show hardware overview — triggers: hardware, show, overview — `scripts/workflows/system-information/system-information-hardware.applescript`
`system-information-network` — Show network configuration info — triggers: network, show, configuration, info — `scripts/workflows/system-information/system-information-network.applescript`
`system-information-software` — Show software overview — triggers: software, show, overview — `scripts/workflows/system-information/system-information-software.applescript`
`system-information-storage` — Show storage and disk info — triggers: storage, show, disk, info — `scripts/workflows/system-information/system-information-storage.applescript`

## system-settings (8)

`system-settings-battery` — Open Battery settings pane — triggers: battery, open, settings, pane — `scripts/workflows/system-settings/system-settings-battery.applescript`
`system-settings-bluetooth` — Open Bluetooth settings pane — triggers: bluetooth, open, settings, pane — `scripts/workflows/system-settings/system-settings-bluetooth.applescript`
`system-settings-displays` — Open Displays settings pane — triggers: displays, open, settings, pane — `scripts/workflows/system-settings/system-settings-displays.applescript`
`system-settings-general` — Open General settings pane — triggers: general, open, settings, pane — `scripts/workflows/system-settings/system-settings-general.applescript`
`system-settings-notifications` — Open Notifications settings pane — triggers: notifications, open, settings, pane — `scripts/workflows/system-settings/system-settings-notifications.applescript`
`system-settings-privacy` — Open Privacy and Security settings pane — triggers: privacy, open, security, settings, pane — `scripts/workflows/system-settings/system-settings-privacy.applescript`
`system-settings-sound` — Open Sound settings pane — triggers: sound, open, settings, pane — `scripts/workflows/system-settings/system-settings-sound.applescript`
`system-settings-wifi` — Open Wi-Fi settings pane — triggers: wifi, open, settings, pane — `scripts/workflows/system-settings/system-settings-wifi.applescript`

## terminal (6)

`terminal-clear-scrollback` — Clear scrollback in the front Terminal tab — triggers: clear, scrollback, front, terminal, tab — `scripts/workflows/terminal/terminal-clear-scrollback.applescript`
`terminal-new-tab-at-path` — Open Terminal tab at a specific directory — triggers: new, tab, path, open, terminal, specific, directory — `scripts/workflows/terminal/terminal-new-tab-at-path.applescript`
`terminal-new-tab` — Open a new Terminal tab — triggers: new, tab, open, terminal — `scripts/workflows/terminal/terminal-new-tab.applescript`
`terminal-run-command` — Run a command in a new Terminal tab — triggers: run, command, new, terminal, tab — `scripts/workflows/terminal/terminal-run-command.applescript`
`terminal-set-title` — Set a custom title for the front Terminal tab — triggers: set, title, custom, front, terminal, tab — `scripts/workflows/terminal/terminal-set-title.applescript`
`terminal-ssh-connect` — Open an SSH connection in a new tab — triggers: ssh, connect, open, connection, new, tab — `scripts/workflows/terminal/terminal-ssh-connect.applescript`

## textedit (5)

`textedit-char-count` — Count characters in frontmost TextEdit document — triggers: char, count, characters, frontmost, textedit, document — `scripts/workflows/textedit/textedit-char-count.applescript`
`textedit-new-document` — Create a new blank TextEdit document — triggers: new, document, create, blank, textedit — `scripts/workflows/textedit/textedit-new-document.applescript`
`textedit-new-from-clipboard` — Open TextEdit with clipboard contents — triggers: new, clipboard, open, textedit, contents — `scripts/workflows/textedit/textedit-new-from-clipboard.applescript`
`textedit-save-as-txt` — Save frontmost TextEdit document as plain text to Desktop — triggers: save, txt, frontmost, textedit, document, plain, text, desktop — `scripts/workflows/textedit/textedit-save-as-txt.applescript`
`textedit-word-count` — Count words in frontmost TextEdit document — triggers: word, count, words, frontmost, textedit, document — `scripts/workflows/textedit/textedit-word-count.applescript`

## time-machine (4)

`time-machine-latest-backup` — Show latest Time Machine backup timestamp — triggers: latest, backup, show, time, machine, timestamp — `scripts/workflows/time-machine/time-machine-latest-backup.applescript`
`time-machine-list-backups` — List recent Time Machine backups — triggers: list, backups, recent, time, machine — `scripts/workflows/time-machine/time-machine-list-backups.applescript`
`time-machine-start-backup` — Start a Time Machine backup — triggers: start, backup, time, machine — `scripts/workflows/time-machine/time-machine-start-backup.applescript`
`time-machine-status` — Show Time Machine backup status — triggers: status, show, time, machine, backup — `scripts/workflows/time-machine/time-machine-status.applescript`

## tv (10)

`tv-list-playlists` — List playlists in a dialog — triggers: list, playlists, dialog — `scripts/workflows/tv/tv-list-playlists.applescript`
`tv-mute-toggle` — Toggle TV mute — triggers: mute, toggle, tv — `scripts/workflows/tv/tv-mute-toggle.applescript`
`tv-next-track` — Skip to next track — triggers: next, track, skip — `scripts/workflows/tv/tv-next-track.applescript`
`tv-now-playing` — Show current track as notification — triggers: now, playing, show, track, notification — `scripts/workflows/tv/tv-now-playing.applescript`
`tv-playpause` — Toggle play/pause — triggers: playpause, toggle, play, pause — `scripts/workflows/tv/tv-playpause.applescript`
`tv-previous-track` — Go to previous track — triggers: previous, track — `scripts/workflows/tv/tv-previous-track.applescript`
`tv-reveal-current` — Reveal current track in library — triggers: reveal, track, library — `scripts/workflows/tv/tv-reveal-current.applescript`
`tv-search-library` — Search TV library by name — triggers: search, library, tv, name — `scripts/workflows/tv/tv-search-library.applescript`
`tv-volume-down` — Decrease TV volume by 10 — triggers: volume, down, decrease, tv — `scripts/workflows/tv/tv-volume-down.applescript`
`tv-volume-up` — Increase TV volume by 10 — triggers: volume, increase, tv — `scripts/workflows/tv/tv-volume-up.applescript`
