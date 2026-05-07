---
title: Sal's Seven-Purpose Framework — Audit of apple-skill workflow catalog
date: 2026-05-07
source: WWSD principle #30, derived from WWDC 2016 session 717 transcript lines 480-504
generator: bin/sal-7-purpose-audit.py
---

# Framework recap (WWSD #30)

Build a voice command (= grant a Siri phrase + Spotlight .app + Loupedeck button) when a workflow scores 3+ on:

1. **Remain in context** — don't break flow
2. **Multi-step** — ≥3 manual steps
3. **Requires dexterity** — precise mouse/sequencing
4. **Moves data between apps**
5. **Transforms data type**
6. **Not in app's UI**
7. **User wants but doesn't know how**

# Tallies

- Total workflows scanned: **360**
- Score 3+ (triple-channel candidates): **73**
- Score 1-2 (script-only): **191**
- Score 0 (re-evaluate): **96**

Score distribution:
- 0: 96
- 1: 81
- 2: 110
- 3: 58
- 4: 13
- 5: 1
- 6: 1

# Triple-channel candidates (score 3+)

These earn voice (dictation command), Spotlight (osacompile .app), and Loupedeck button. Sorted by score descending then path.

| Score | Workflow | Reasons |
|-------|----------|---------|
| 6 | `scripts/workflows/system-events/System-Events-MosaicKnob.applescript` | 1:no-activate, 2:lines=118, 3:geometry, 5:coercion, 6:shell-or-js, 7:system-events |
| 5 | `scripts/workflows/system-events/System-Events-MosaicWindows.applescript` | 1:no-activate, 2:lines=54, 3:geometry, 5:coercion, 7:system-events |
| 4 | `scripts/workflows/accessibility/ax-system-settings-battery.applescript` | 2:lines=13, 4:apps=2, 6:shell-or-js, 7:system-events |
| 4 | `scripts/workflows/accessibility/ax-system-settings-bluetooth.applescript` | 2:lines=13, 4:apps=2, 6:shell-or-js, 7:system-events |
| 4 | `scripts/workflows/accessibility/ax-system-settings-displays.applescript` | 2:lines=13, 4:apps=2, 6:shell-or-js, 7:system-events |
| 4 | `scripts/workflows/accessibility/ax-system-settings-keyboard.applescript` | 2:lines=13, 4:apps=2, 6:shell-or-js, 7:system-events |
| 4 | `scripts/workflows/accessibility/ax-system-settings-notifications.applescript` | 2:lines=13, 4:apps=2, 6:shell-or-js, 7:system-events |
| 4 | `scripts/workflows/accessibility/ax-system-settings-privacy.applescript` | 2:lines=13, 4:apps=2, 6:shell-or-js, 7:system-events |
| 4 | `scripts/workflows/accessibility/ax-system-settings-sound.applescript` | 2:lines=13, 4:apps=2, 6:shell-or-js, 7:system-events |
| 4 | `scripts/workflows/accessibility/ax-system-settings-wifi.applescript` | 2:lines=13, 4:apps=2, 6:shell-or-js, 7:system-events |
| 4 | `scripts/workflows/finder/finder-compress-selected.applescript` | 1:no-activate, 2:lines=11, 5:coercion, 6:shell-or-js |
| 4 | `scripts/workflows/system-events/system-events-bluetooth-toggle.applescript` | 2:lines=8, 5:coercion, 6:shell-or-js, 7:system-events |
| 4 | `scripts/workflows/system-events/system-events-ip-address.applescript` | 2:lines=8, 5:coercion, 6:shell-or-js, 7:system-events |
| 4 | `scripts/workflows/system-events/system-events-spotlight-status.applescript` | 2:lines=10, 5:coercion, 6:shell-or-js, 7:system-events |
| 4 | `scripts/workflows/system-events/system-events-wifi-toggle.applescript` | 2:lines=8, 5:coercion, 6:shell-or-js, 7:system-events |
| 3 | `scripts/workflows/calendar/calendar-count-events-today.applescript` | 1:no-activate, 2:lines=11, 5:coercion |
| 3 | `scripts/workflows/calendar/calendar-event-at-time.applescript` | 1:no-activate, 2:lines=13, 5:coercion |
| 3 | `scripts/workflows/calendar/calendar-next-event.applescript` | 1:no-activate, 2:lines=16, 5:coercion |
| 3 | `scripts/workflows/finder/finder-copy-path.applescript` | 1:no-activate, 2:lines=11, 5:coercion |
| 3 | `scripts/workflows/finder/finder-count-items.applescript` | 1:no-activate, 2:lines=9, 5:coercion |
| 3 | `scripts/workflows/finder/finder-file-info.applescript` | 1:no-activate, 2:lines=14, 5:coercion |
| 3 | `scripts/workflows/finder/finder-get-selection.applescript` | 1:no-activate, 2:lines=11, 5:coercion |
| 3 | `scripts/workflows/finder/finder-toggle-hidden-files.applescript` | 2:lines=9, 5:coercion, 6:shell-or-js |
| 3 | `scripts/workflows/homepod/homepod-climate-reading.applescript` | 2:lines=8, 5:coercion, 6:shell-or-js |
| 3 | `scripts/workflows/image-events/image-events-convert-format.applescript` | 1:no-activate, 2:lines=16, 5:coercion |
| 3 | `scripts/workflows/image-events/image-events-get-dimensions.applescript` | 1:no-activate, 2:lines=11, 5:coercion |
| 3 | `scripts/workflows/keynote/keynote-export-pdf.applescript` | 1:no-activate, 2:lines=11, 5:coercion |
| 3 | `scripts/workflows/keynote/keynote-list-slides.applescript` | 1:no-activate, 2:lines=20, 5:coercion |
| 3 | `scripts/workflows/keynote/keynote-presenter-notes.applescript` | 1:no-activate, 2:lines=12, 5:coercion |
| 3 | `scripts/workflows/keynote/keynote-slide-count.applescript` | 1:no-activate, 2:lines=8, 5:coercion |
| 3 | `scripts/workflows/mail/mail-delete-junk.applescript` | 1:no-activate, 2:lines=8, 5:coercion |
| 3 | `scripts/workflows/mail/mail-unread-count.applescript` | 1:no-activate, 2:lines=9, 5:coercion |
| 3 | `scripts/workflows/messages/messages-send-clipboard.applescript` | 1:no-activate, 2:lines=8, 5:coercion |
| 3 | `scripts/workflows/music/music-track-info-detail.applescript` | 1:no-activate, 2:lines=16, 5:coercion |
| 3 | `scripts/workflows/numbers/numbers-export-csv.applescript` | 1:no-activate, 2:lines=11, 5:coercion |
| 3 | `scripts/workflows/numbers/numbers-export-pdf.applescript` | 1:no-activate, 2:lines=11, 5:coercion |
| 3 | `scripts/workflows/numbers/numbers-list-sheets.applescript` | 1:no-activate, 2:lines=11, 5:coercion |
| 3 | `scripts/workflows/numbers/numbers-sheet-count.applescript` | 1:no-activate, 2:lines=8, 5:coercion |
| 3 | `scripts/workflows/numbers/numbers-table-count.applescript` | 1:no-activate, 2:lines=8, 5:coercion |
| 3 | `scripts/workflows/pages/pages-character-count.applescript` | 1:no-activate, 2:lines=8, 5:coercion |
| 3 | `scripts/workflows/pages/pages-export-pdf.applescript` | 1:no-activate, 2:lines=11, 5:coercion |
| 3 | `scripts/workflows/pages/pages-list-documents.applescript` | 1:no-activate, 2:lines=11, 5:coercion |
| 3 | `scripts/workflows/pages/pages-page-count.applescript` | 1:no-activate, 2:lines=8, 5:coercion |
| 3 | `scripts/workflows/pages/pages-word-count.applescript` | 1:no-activate, 2:lines=8, 5:coercion |
| 3 | `scripts/workflows/photos/photos-export-selected.applescript` | 1:no-activate, 2:lines=10, 5:coercion |
| 3 | `scripts/workflows/safari/safari-do-javascript.applescript` | 1:no-activate, 2:lines=8, 6:shell-or-js |
| 3 | `scripts/workflows/script-editor/script-editor-open-dictionary.applescript` | 2:lines=8, 4:apps=2, 7:system-events |
| 3 | `scripts/workflows/shortcuts/shortcuts-search-shortcuts.applescript` | 2:lines=12, 5:coercion, 6:shell-or-js |
| 3 | `scripts/workflows/system-events/System-Events-WhiteboardKnob.applescript` | 2:lines=68, 5:coercion, 6:shell-or-js |
| 3 | `scripts/workflows/system-events/system-events-battery-status.applescript` | 5:coercion, 6:shell-or-js, 7:system-events |
| 3 | `scripts/workflows/system-events/system-events-disk-usage.applescript` | 5:coercion, 6:shell-or-js, 7:system-events |
| 3 | `scripts/workflows/system-events/system-events-dock-add-recent-apps.applescript` | 5:coercion, 6:shell-or-js, 7:system-events |
| 3 | `scripts/workflows/system-events/system-events-dock-add-spacer.applescript` | 5:coercion, 6:shell-or-js, 7:system-events |
| 3 | `scripts/workflows/system-events/system-events-hide-dock.applescript` | 5:coercion, 6:shell-or-js, 7:system-events |
| 3 | `scripts/workflows/system-events/system-events-list-running-apps.applescript` | 1:no-activate, 2:lines=9, 7:system-events |
| 3 | `scripts/workflows/system-events/system-events-notification-count.applescript` | 5:coercion, 6:shell-or-js, 7:system-events |
| 3 | `scripts/workflows/system-events/system-events-reset-apple-events.applescript` | 5:coercion, 6:shell-or-js, 7:system-events |
| 3 | `scripts/workflows/system-events/system-events-restart-menu-bar.applescript` | 5:coercion, 6:shell-or-js, 7:system-events |
| 3 | `scripts/workflows/system-events/system-events-screen-lock.applescript` | 5:coercion, 6:shell-or-js, 7:system-events |
| 3 | `scripts/workflows/system-events/system-events-screenshot-area.applescript` | 5:coercion, 6:shell-or-js, 7:system-events |
| 3 | `scripts/workflows/system-events/system-events-screenshot-window.applescript` | 5:coercion, 6:shell-or-js, 7:system-events |
| 3 | `scripts/workflows/system-events/system-events-show-dock.applescript` | 5:coercion, 6:shell-or-js, 7:system-events |
| 3 | `scripts/workflows/system-events/system-events-trash-size.applescript` | 5:coercion, 6:shell-or-js, 7:system-events |
| 3 | `scripts/workflows/system-events/system-events-uptime.applescript` | 5:coercion, 6:shell-or-js, 7:system-events |
| 3 | `scripts/workflows/system-settings/system-settings-battery.applescript` | 5:coercion, 6:shell-or-js, 7:system-events |
| 3 | `scripts/workflows/system-settings/system-settings-bluetooth.applescript` | 5:coercion, 6:shell-or-js, 7:system-events |
| 3 | `scripts/workflows/system-settings/system-settings-displays.applescript` | 5:coercion, 6:shell-or-js, 7:system-events |
| 3 | `scripts/workflows/system-settings/system-settings-general.applescript` | 5:coercion, 6:shell-or-js, 7:system-events |
| 3 | `scripts/workflows/system-settings/system-settings-notifications.applescript` | 5:coercion, 6:shell-or-js, 7:system-events |
| 3 | `scripts/workflows/system-settings/system-settings-privacy.applescript` | 5:coercion, 6:shell-or-js, 7:system-events |
| 3 | `scripts/workflows/system-settings/system-settings-sound.applescript` | 5:coercion, 6:shell-or-js, 7:system-events |
| 3 | `scripts/workflows/system-settings/system-settings-wifi.applescript` | 5:coercion, 6:shell-or-js, 7:system-events |
| 3 | `scripts/workflows/terminal/terminal-new-tab-at-path.applescript` | 2:lines=11, 4:apps=2, 5:coercion |

# Script-only workflows (score 1-2)

Keep as scripts; do not allocate Siri/Loupedeck channel.

| Score | Workflow | Reasons |
|-------|----------|---------|
| 2 | `scripts/workflows/automator/automator-get-result.applescript` | 2:lines=21, 5:coercion |
| 2 | `scripts/workflows/automator/automator-list-actions.applescript` | 2:lines=12, 5:coercion |
| 2 | `scripts/workflows/automator/automator-run-workflow.applescript` | 2:lines=18, 5:coercion |
| 2 | `scripts/workflows/calendar/calendar-list-calendars.applescript` | 1:no-activate, 2:lines=8 |
| 2 | `scripts/workflows/calendar/calendar-quick-event.applescript` | 1:no-activate, 2:lines=9 |
| 2 | `scripts/workflows/console/console-app-log.applescript` | 5:coercion, 6:shell-or-js |
| 2 | `scripts/workflows/console/console-recent-errors.applescript` | 5:coercion, 6:shell-or-js |
| 2 | `scripts/workflows/console/console-system-log.applescript` | 5:coercion, 6:shell-or-js |
| 2 | `scripts/workflows/contacts/contacts-count-contacts.applescript` | 1:no-activate, 5:coercion |
| 2 | `scripts/workflows/contacts/contacts-list-groups.applescript` | 1:no-activate, 2:lines=12 |
| 2 | `scripts/workflows/contacts/contacts-search-contact.applescript` | 1:no-activate, 2:lines=17 |
| 2 | `scripts/workflows/disk-utility/disk-utility-apfs-list.applescript` | 5:coercion, 6:shell-or-js |
| 2 | `scripts/workflows/disk-utility/disk-utility-disk-info.applescript` | 5:coercion, 6:shell-or-js |
| 2 | `scripts/workflows/disk-utility/disk-utility-list-disks.applescript` | 5:coercion, 6:shell-or-js |
| 2 | `scripts/workflows/finder/finder-airdrop-reveal.applescript` | 5:coercion, 6:shell-or-js |
| 2 | `scripts/workflows/finder/finder-duplicate-selected.applescript` | 1:no-activate, 2:lines=11 |
| 2 | `scripts/workflows/finder/finder-eject-all.applescript` | 1:no-activate, 2:lines=11 |
| 2 | `scripts/workflows/finder/finder-empty-trash-confirm.applescript` | 1:no-activate, 2:lines=10 |
| 2 | `scripts/workflows/finder/finder-get-window-path.applescript` | 1:no-activate, 5:coercion |
| 2 | `scripts/workflows/finder/finder-hide-desktop-icons.applescript` | 5:coercion, 6:shell-or-js |
| 2 | `scripts/workflows/finder/finder-move-to-trash.applescript` | 1:no-activate, 2:lines=11 |
| 2 | `scripts/workflows/finder/finder-open-current-dir.applescript` | 5:coercion, 6:shell-or-js |
| 2 | `scripts/workflows/finder/finder-restart-finder.applescript` | 5:coercion, 6:shell-or-js |
| 2 | `scripts/workflows/finder/finder-show-desktop-icons.applescript` | 5:coercion, 6:shell-or-js |
| 2 | `scripts/workflows/hardware/hardware-battery-status.applescript` | 2:lines=16, 6:shell-or-js |
| 2 | `scripts/workflows/hardware/hardware-cpu-info.applescript` | 2:lines=22, 6:shell-or-js |
| 2 | `scripts/workflows/hardware/hardware-disk-usage.applescript` | 2:lines=10, 6:shell-or-js |
| 2 | `scripts/workflows/hardware/hardware-display-brightness.applescript` | 2:lines=24, 6:shell-or-js |
| 2 | `scripts/workflows/hardware/hardware-memory-pressure.applescript` | 2:lines=18, 6:shell-or-js |
| 2 | `scripts/workflows/homepod/homepod-climate-dashboard.applescript` | 5:coercion, 6:shell-or-js |
| 2 | `scripts/workflows/homepod/homepod-climate-log.applescript` | 5:coercion, 6:shell-or-js |
| 2 | `scripts/workflows/homepod/homepod-climate-summary.applescript` | 5:coercion, 6:shell-or-js |
| 2 | `scripts/workflows/homepod/homepod-set-volume.applescript` | 2:lines=9, 6:shell-or-js |
| 2 | `scripts/workflows/image-events/image-events-flip.applescript` | 1:no-activate, 2:lines=8 |
| 2 | `scripts/workflows/image-events/image-events-resize.applescript` | 1:no-activate, 2:lines=11 |
| 2 | `scripts/workflows/image-events/image-events-rotate.applescript` | 1:no-activate, 2:lines=8 |
| 2 | `scripts/workflows/keynote/keynote-current-slide.applescript` | 1:no-activate, 2:lines=9 |
| 2 | `scripts/workflows/mail/mail-archive-selected.applescript` | 1:no-activate, 2:lines=14 |
| 2 | `scripts/workflows/mail/mail-list-accounts.applescript` | 1:no-activate, 2:lines=8 |
| 2 | `scripts/workflows/mail/mail-read-latest-subject.applescript` | 1:no-activate, 2:lines=11 |
| 2 | `scripts/workflows/mail/mail-send-quick.applescript` | 1:no-activate, 2:lines=11 |
| 2 | `scripts/workflows/messages/messages-list-chats.applescript` | 1:no-activate, 2:lines=11 |
| 2 | `scripts/workflows/messages/messages-send-message.applescript` | 1:no-activate, 2:lines=8 |
| 2 | `scripts/workflows/music/music-add-to-playlist.applescript` | 1:no-activate, 2:lines=11 |
| 2 | `scripts/workflows/music/music-airplay-list.applescript` | 1:no-activate, 2:lines=12 |
| 2 | `scripts/workflows/music/music-count-library.applescript` | 1:no-activate, 5:coercion |
| 2 | `scripts/workflows/music/music-current-stream-info.applescript` | 1:no-activate, 2:lines=9 |
| 2 | `scripts/workflows/music/music-get-lyrics.applescript` | 1:no-activate, 2:lines=9 |
| 2 | `scripts/workflows/music/music-list-playlists.applescript` | 1:no-activate, 2:lines=8 |
| 2 | `scripts/workflows/music/music-now-playing-clipboard.applescript` | 1:no-activate, 2:lines=12 |
| 2 | `scripts/workflows/music/music-now-playing.applescript` | 1:no-activate, 2:lines=10 |
| 2 | `scripts/workflows/music/music-play-playlist.applescript` | 1:no-activate, 2:lines=8 |
| 2 | `scripts/workflows/music/music-played-count-current.applescript` | 1:no-activate, 5:coercion |
| 2 | `scripts/workflows/music/music-search-library.applescript` | 1:no-activate, 2:lines=11 |
| 2 | `scripts/workflows/music/music-seek-backward-30.applescript` | 1:no-activate, 2:lines=8 |
| 2 | `scripts/workflows/music/music-set-eq-preset.applescript` | 1:no-activate, 2:lines=9 |
| 2 | `scripts/workflows/music/music-toggle-eq.applescript` | 1:no-activate, 2:lines=8 |
| 2 | `scripts/workflows/music/music-toggle-repeat.applescript` | 1:no-activate, 2:lines=12 |
| 2 | `scripts/workflows/music/music-toggle-shuffle.applescript` | 1:no-activate, 2:lines=8 |
| 2 | `scripts/workflows/music/music-volume-down.applescript` | 1:no-activate, 2:lines=8 |
| 2 | `scripts/workflows/music/music-volume-up.applescript` | 1:no-activate, 2:lines=8 |
| 2 | `scripts/workflows/notes/notes-append-to-note.applescript` | 1:no-activate, 2:lines=12 |
| 2 | `scripts/workflows/notes/notes-count-notes.applescript` | 1:no-activate, 5:coercion |
| 2 | `scripts/workflows/notes/notes-list-folders.applescript` | 1:no-activate, 2:lines=8 |
| 2 | `scripts/workflows/notes/notes-list-notes.applescript` | 1:no-activate, 2:lines=11 |
| 2 | `scripts/workflows/notes/notes-new-note-from-clipboard.applescript` | 2:lines=8, 5:coercion |
| 2 | `scripts/workflows/photos/photos-count-photos.applescript` | 1:no-activate, 5:coercion |
| 2 | `scripts/workflows/photos/photos-favorite-selected.applescript` | 1:no-activate, 2:lines=11 |
| 2 | `scripts/workflows/photos/photos-list-albums.applescript` | 1:no-activate, 2:lines=9 |
| 2 | `scripts/workflows/preview/preview-rotate-left.applescript` | 4:apps=2, 7:system-events |
| 2 | `scripts/workflows/preview/preview-zoom-in.applescript` | 4:apps=2, 7:system-events |
| 2 | `scripts/workflows/preview/preview-zoom-out.applescript` | 4:apps=2, 7:system-events |
| 2 | `scripts/workflows/reminders/reminders-complete-latest.applescript` | 1:no-activate, 2:lines=10 |
| 2 | `scripts/workflows/reminders/reminders-flagged-reminders.applescript` | 1:no-activate, 2:lines=12 |
| 2 | `scripts/workflows/reminders/reminders-list-lists.applescript` | 1:no-activate, 2:lines=8 |
| 2 | `scripts/workflows/reminders/reminders-reminder-from-clipboard.applescript` | 1:no-activate, 5:coercion |
| 2 | `scripts/workflows/reminders/reminders-show-today.applescript` | 1:no-activate, 2:lines=15 |
| 2 | `scripts/workflows/safari/safari-close-all-tabs.applescript` | 1:no-activate, 2:lines=8 |
| 2 | `scripts/workflows/safari/safari-close-other-tabs.applescript` | 1:no-activate, 2:lines=9 |
| 2 | `scripts/workflows/safari/safari-list-all-tabs.applescript` | 1:no-activate, 2:lines=10 |
| 2 | `scripts/workflows/safari/safari-tab-count.applescript` | 1:no-activate, 5:coercion |
| 2 | `scripts/workflows/screenshot/screenshot-area.applescript` | 5:coercion, 6:shell-or-js |
| 2 | `scripts/workflows/screenshot/screenshot-clipboard.applescript` | 5:coercion, 6:shell-or-js |
| 2 | `scripts/workflows/screenshot/screenshot-fullscreen.applescript` | 5:coercion, 6:shell-or-js |
| 2 | `scripts/workflows/screenshot/screenshot-window.applescript` | 5:coercion, 6:shell-or-js |
| 2 | `scripts/workflows/shortcuts/shortcuts-list-shortcuts.applescript` | 5:coercion, 6:shell-or-js |
| 2 | `scripts/workflows/shortcuts/shortcuts-run-shortcut-with-input.applescript` | 5:coercion, 6:shell-or-js |
| 2 | `scripts/workflows/shortcuts/shortcuts-run-shortcut.applescript` | 5:coercion, 6:shell-or-js |
| 2 | `scripts/workflows/system-events/System-Events-HideAllOthers.applescript` | 1:no-activate, 7:system-events |
| 2 | `scripts/workflows/system-events/system-events-dark-mode-toggle.applescript` | 1:no-activate, 7:system-events |
| 2 | `scripts/workflows/system-events/system-events-do-not-disturb.applescript` | 1:no-activate, 7:system-events |
| 2 | `scripts/workflows/system-events/system-events-get-frontmost-app.applescript` | 1:no-activate, 7:system-events |
| 2 | `scripts/workflows/system-events/system-events-key-shortcut.applescript` | 1:no-activate, 7:system-events |
| 2 | `scripts/workflows/system-events/system-events-type-text.applescript` | 1:no-activate, 7:system-events |
| 2 | `scripts/workflows/system-events/system-events-volume-set.applescript` | 5:coercion, 7:system-events |
| 2 | `scripts/workflows/system-information/system-information-hardware.applescript` | 5:coercion, 6:shell-or-js |
| 2 | `scripts/workflows/system-information/system-information-network.applescript` | 5:coercion, 6:shell-or-js |
| 2 | `scripts/workflows/system-information/system-information-software.applescript` | 5:coercion, 6:shell-or-js |
| 2 | `scripts/workflows/system-information/system-information-storage.applescript` | 5:coercion, 6:shell-or-js |
| 2 | `scripts/workflows/textedit/textedit-char-count.applescript` | 1:no-activate, 5:coercion |
| 2 | `scripts/workflows/textedit/textedit-word-count.applescript` | 1:no-activate, 5:coercion |
| 2 | `scripts/workflows/time-machine/time-machine-latest-backup.applescript` | 5:coercion, 6:shell-or-js |
| 2 | `scripts/workflows/time-machine/time-machine-list-backups.applescript` | 5:coercion, 6:shell-or-js |
| 2 | `scripts/workflows/time-machine/time-machine-start-backup.applescript` | 5:coercion, 6:shell-or-js |
| 2 | `scripts/workflows/time-machine/time-machine-status.applescript` | 5:coercion, 6:shell-or-js |
| 2 | `scripts/workflows/tv/tv-list-playlists.applescript` | 1:no-activate, 5:coercion |
| 2 | `scripts/workflows/tv/tv-now-playing.applescript` | 1:no-activate, 2:lines=9 |
| 2 | `scripts/workflows/tv/tv-search-library.applescript` | 1:no-activate, 2:lines=11 |
| 2 | `scripts/workflows/tv/tv-volume-down.applescript` | 1:no-activate, 2:lines=8 |
| 2 | `scripts/workflows/tv/tv-volume-up.applescript` | 1:no-activate, 2:lines=8 |
| 1 | `scripts/launchers/activate-system-settings.applescript` | 7:system-events |
| 1 | `scripts/workflows/automator/automator-save-as-app.applescript` | 2:lines=10 |
| 1 | `scripts/workflows/calendar/calendar-reload.applescript` | 1:no-activate |
| 1 | `scripts/workflows/contacts/contacts-new-contact.applescript` | 1:no-activate |
| 1 | `scripts/workflows/finder/finder-close-all-windows.applescript` | 1:no-activate |
| 1 | `scripts/workflows/finder/finder-empty-trash.applescript` | 1:no-activate |
| 1 | `scripts/workflows/finder/finder-set-wallpaper.applescript` | 1:no-activate |
| 1 | `scripts/workflows/finder/finder-sort-by-name.applescript` | 1:no-activate |
| 1 | `scripts/workflows/finder/finder-tag-clear.applescript` | 1:no-activate |
| 1 | `scripts/workflows/finder/finder-tag-orange.applescript` | 1:no-activate |
| 1 | `scripts/workflows/finder/finder-tag-red.applescript` | 1:no-activate |
| 1 | `scripts/workflows/hardware/hardware-audio-devices.applescript` | 6:shell-or-js |
| 1 | `scripts/workflows/hardware/hardware-bluetooth-devices.applescript` | 6:shell-or-js |
| 1 | `scripts/workflows/hardware/hardware-usb-devices.applescript` | 6:shell-or-js |
| 1 | `scripts/workflows/homepod/homepod-good-morning-scene.applescript` | 6:shell-or-js |
| 1 | `scripts/workflows/homepod/homepod-good-night-scene.applescript` | 6:shell-or-js |
| 1 | `scripts/workflows/homepod/homepod-lights-off.applescript` | 6:shell-or-js |
| 1 | `scripts/workflows/homepod/homepod-lights-on.applescript` | 6:shell-or-js |
| 1 | `scripts/workflows/homepod/homepod-pause-music.applescript` | 6:shell-or-js |
| 1 | `scripts/workflows/homepod/homepod-play-music.applescript` | 6:shell-or-js |
| 1 | `scripts/workflows/imovie/imovie-list-projects.applescript` | 2:lines=13 |
| 1 | `scripts/workflows/keynote/keynote-next-slide.applescript` | 1:no-activate |
| 1 | `scripts/workflows/keynote/keynote-previous-slide.applescript` | 1:no-activate |
| 1 | `scripts/workflows/keynote/keynote-start-slideshow.applescript` | 1:no-activate |
| 1 | `scripts/workflows/keynote/keynote-stop-slideshow.applescript` | 1:no-activate |
| 1 | `scripts/workflows/mail/mail-check-mail.applescript` | 1:no-activate |
| 1 | `scripts/workflows/mail/mail-compose-to.applescript` | 2:lines=8 |
| 1 | `scripts/workflows/mail/mail-flag-selected.applescript` | 1:no-activate |
| 1 | `scripts/workflows/mail/mail-forward-selected.applescript` | 2:lines=8 |
| 1 | `scripts/workflows/mail/mail-mark-all-read.applescript` | 1:no-activate |
| 1 | `scripts/workflows/mail/mail-reply-to-selected.applescript` | 2:lines=8 |
| 1 | `scripts/workflows/music/music-create-playlist.applescript` | 1:no-activate |
| 1 | `scripts/workflows/music/music-dislike-current.applescript` | 1:no-activate |
| 1 | `scripts/workflows/music/music-love-current.applescript` | 1:no-activate |
| 1 | `scripts/workflows/music/music-mute-toggle.applescript` | 1:no-activate |
| 1 | `scripts/workflows/music/music-next-track.applescript` | 1:no-activate |
| 1 | `scripts/workflows/music/music-playpause.applescript` | 1:no-activate |
| 1 | `scripts/workflows/music/music-previous-track.applescript` | 1:no-activate |
| 1 | `scripts/workflows/music/music-rating-0-stars.applescript` | 1:no-activate |
| 1 | `scripts/workflows/music/music-rating-1-star.applescript` | 1:no-activate |
| 1 | `scripts/workflows/music/music-rating-2-stars.applescript` | 1:no-activate |
| 1 | `scripts/workflows/music/music-rating-3-stars.applescript` | 1:no-activate |
| 1 | `scripts/workflows/music/music-rating-4-stars.applescript` | 1:no-activate |
| 1 | `scripts/workflows/music/music-rating-5-stars.applescript` | 1:no-activate |
| 1 | `scripts/workflows/music/music-seek-forward-30.applescript` | 1:no-activate |
| 1 | `scripts/workflows/music/music-stop.applescript` | 1:no-activate |
| 1 | `scripts/workflows/music/music-toggle-fullscreen.applescript` | 1:no-activate |
| 1 | `scripts/workflows/music/music-toggle-visuals.applescript` | 1:no-activate |
| 1 | `scripts/workflows/notes/notes-new-note.applescript` | 2:lines=9 |
| 1 | `scripts/workflows/notes/notes-search-notes.applescript` | 2:lines=12 |
| 1 | `scripts/workflows/photos/photos-create-album.applescript` | 1:no-activate |
| 1 | `scripts/workflows/photos/photos-favorites-count.applescript` | 1:no-activate |
| 1 | `scripts/workflows/photos/photos-start-slideshow.applescript` | 2:lines=9 |
| 1 | `scripts/workflows/photos/photos-stop-slideshow.applescript` | 1:no-activate |
| 1 | `scripts/workflows/quicktime/quicktime-pause-frontmost.applescript` | 1:no-activate |
| 1 | `scripts/workflows/quicktime/quicktime-play-frontmost.applescript` | 1:no-activate |
| 1 | `scripts/workflows/quicktime/quicktime-present-fullscreen.applescript` | 1:no-activate |
| 1 | `scripts/workflows/reminders/reminders-count-incomplete.applescript` | 1:no-activate |
| 1 | `scripts/workflows/reminders/reminders-quick-reminder.applescript` | 1:no-activate |
| 1 | `scripts/workflows/reminders/reminders-reminder-due-today.applescript` | 1:no-activate |
| 1 | `scripts/workflows/reminders/reminders-reminder-with-priority.applescript` | 1:no-activate |
| 1 | `scripts/workflows/safari/safari-add-reading-list.applescript` | 1:no-activate |
| 1 | `scripts/workflows/safari/safari-current-title.applescript` | 1:no-activate |
| 1 | `scripts/workflows/safari/safari-current-url-and-title.applescript` | 1:no-activate |
| 1 | `scripts/workflows/safari/safari-current-url.applescript` | 1:no-activate |
| 1 | `scripts/workflows/safari/safari-page-source.applescript` | 1:no-activate |
| 1 | `scripts/workflows/safari/safari-reload-tab.applescript` | 1:no-activate |
| 1 | `scripts/workflows/script-editor/script-editor-compile.applescript` | 2:lines=17 |
| 1 | `scripts/workflows/script-editor/script-editor-get-result.applescript` | 2:lines=16 |
| 1 | `scripts/workflows/script-editor/script-editor-new-script.applescript` | 5:coercion |
| 1 | `scripts/workflows/script-editor/script-editor-run.applescript` | 2:lines=16 |
| 1 | `scripts/workflows/system-events/system-events-empty-clipboard.applescript` | 7:system-events |
| 1 | `scripts/workflows/terminal/terminal-clear-scrollback.applescript` | 1:no-activate |
| 1 | `scripts/workflows/terminal/terminal-set-title.applescript` | 1:no-activate |
| 1 | `scripts/workflows/textedit/textedit-new-from-clipboard.applescript` | 5:coercion |
| 1 | `scripts/workflows/textedit/textedit-save-as-txt.applescript` | 1:no-activate |
| 1 | `scripts/workflows/tv/tv-mute-toggle.applescript` | 1:no-activate |
| 1 | `scripts/workflows/tv/tv-next-track.applescript` | 1:no-activate |
| 1 | `scripts/workflows/tv/tv-playpause.applescript` | 1:no-activate |
| 1 | `scripts/workflows/tv/tv-previous-track.applescript` | 1:no-activate |
| 1 | `scripts/workflows/tv/tv-reveal-current.applescript` | 2:lines=8 |

# Re-evaluate (score 0)

These workflows didn't trigger any of the 7 criteria. Likely launchers or one-line activations. Triage each: keep as launcher, or reconsider whether the workflow earns its existence.

| Workflow |
|----------|
| `scripts/launchers/activate-activity-monitor.applescript` |
| `scripts/launchers/activate-airport-utility.applescript` |
| `scripts/launchers/activate-app-store.applescript` |
| `scripts/launchers/activate-audio-midi-setup.applescript` |
| `scripts/launchers/activate-automator.applescript` |
| `scripts/launchers/activate-bluetooth-file-exchange.applescript` |
| `scripts/launchers/activate-books.applescript` |
| `scripts/launchers/activate-calculator.applescript` |
| `scripts/launchers/activate-calendar.applescript` |
| `scripts/launchers/activate-chess.applescript` |
| `scripts/launchers/activate-clock.applescript` |
| `scripts/launchers/activate-colorsync-utility.applescript` |
| `scripts/launchers/activate-console.applescript` |
| `scripts/launchers/activate-contacts.applescript` |
| `scripts/launchers/activate-dictionary.applescript` |
| `scripts/launchers/activate-digital-color-meter.applescript` |
| `scripts/launchers/activate-disk-utility.applescript` |
| `scripts/launchers/activate-facetime.applescript` |
| `scripts/launchers/activate-final-cut-pro.applescript` |
| `scripts/launchers/activate-find-my.applescript` |
| `scripts/launchers/activate-finder.applescript` |
| `scripts/launchers/activate-font-book.applescript` |
| `scripts/launchers/activate-freeform.applescript` |
| `scripts/launchers/activate-grapher.applescript` |
| `scripts/launchers/activate-home.applescript` |
| `scripts/launchers/activate-image-capture.applescript` |
| `scripts/launchers/activate-imovie.applescript` |
| `scripts/launchers/activate-keynote.applescript` |
| `scripts/launchers/activate-launchpad.applescript` |
| `scripts/launchers/activate-logic-pro.applescript` |
| `scripts/launchers/activate-mail.applescript` |
| `scripts/launchers/activate-maps.applescript` |
| `scripts/launchers/activate-messages.applescript` |
| `scripts/launchers/activate-migration-assistant.applescript` |
| `scripts/launchers/activate-mission-control.applescript` |
| `scripts/launchers/activate-music.applescript` |
| `scripts/launchers/activate-news.applescript` |
| `scripts/launchers/activate-notes.applescript` |
| `scripts/launchers/activate-numbers.applescript` |
| `scripts/launchers/activate-pages.applescript` |
| `scripts/launchers/activate-passwords.applescript` |
| `scripts/launchers/activate-photo-booth.applescript` |
| `scripts/launchers/activate-photos.applescript` |
| `scripts/launchers/activate-podcasts.applescript` |
| `scripts/launchers/activate-preview.applescript` |
| `scripts/launchers/activate-quicktime-player.applescript` |
| `scripts/launchers/activate-reminders.applescript` |
| `scripts/launchers/activate-safari.applescript` |
| `scripts/launchers/activate-screen-sharing.applescript` |
| `scripts/launchers/activate-screenshot.applescript` |
| `scripts/launchers/activate-script-editor.applescript` |
| `scripts/launchers/activate-shortcuts.applescript` |
| `scripts/launchers/activate-stickies.applescript` |
| `scripts/launchers/activate-stocks.applescript` |
| `scripts/launchers/activate-system-information.applescript` |
| `scripts/launchers/activate-terminal.applescript` |
| `scripts/launchers/activate-textedit.applescript` |
| `scripts/launchers/activate-time-machine.applescript` |
| `scripts/launchers/activate-tips.applescript` |
| `scripts/launchers/activate-tv.applescript` |
| `scripts/launchers/activate-voice-memos.applescript` |
| `scripts/launchers/activate-voiceover-utility.applescript` |
| `scripts/launchers/activate-weather.applescript` |
| `scripts/workflows/automator/automator-new-workflow.applescript` |
| `scripts/workflows/calendar/calendar-show-month.applescript` |
| `scripts/workflows/calendar/calendar-show-today.applescript` |
| `scripts/workflows/calendar/calendar-show-week.applescript` |
| `scripts/workflows/finder/finder-new-folder.applescript` |
| `scripts/workflows/finder/finder-new-window-desktop.applescript` |
| `scripts/workflows/finder/finder-new-window-downloads.applescript` |
| `scripts/workflows/finder/finder-new-window.applescript` |
| `scripts/workflows/finder/finder-reveal-downloads.applescript` |
| `scripts/workflows/imovie/imovie-new-project.applescript` |
| `scripts/workflows/keynote/keynote-new-presentation.applescript` |
| `scripts/workflows/mail/mail-compose.applescript` |
| `scripts/workflows/music/music-reveal-current.applescript` |
| `scripts/workflows/notes/notes-show-recent-note.applescript` |
| `scripts/workflows/numbers/numbers-new-spreadsheet.applescript` |
| `scripts/workflows/pages/pages-new-document.applescript` |
| `scripts/workflows/photos/photos-search.applescript` |
| `scripts/workflows/preview/preview-open-file.applescript` |
| `scripts/workflows/quicktime/quicktime-new-audio-recording.applescript` |
| `scripts/workflows/quicktime/quicktime-new-movie-recording.applescript` |
| `scripts/workflows/quicktime/quicktime-new-screen-recording.applescript` |
| `scripts/workflows/safari/safari-open-url.applescript` |
| `scripts/workflows/safari/safari-search-web.applescript` |
| `scripts/workflows/safari/safari-show-bookmarks.applescript` |
| `scripts/workflows/safari/safari-show-privacy-report.applescript` |
| `scripts/workflows/system-events/System-Events-WhiteboardBrowse.applescript` |
| `scripts/workflows/system-events/System-Events-WhiteboardNext.applescript` |
| `scripts/workflows/system-events/System-Events-WhiteboardOpen.applescript` |
| `scripts/workflows/system-events/System-Events-WhiteboardPrev.applescript` |
| `scripts/workflows/terminal/terminal-new-tab.applescript` |
| `scripts/workflows/terminal/terminal-run-command.applescript` |
| `scripts/workflows/terminal/terminal-ssh-connect.applescript` |
| `scripts/workflows/textedit/textedit-new-document.applescript` |

# Heuristic limits

This audit is heuristic, not authoritative. Manual review is needed for borderline workflows. Specific blind spots:

- Criterion 7 ("user wants but doesn't know how") is the hardest to detect from source — it's a UX judgment. The current heuristic catches System Events / keystroke usage, which is a proxy at best.
- Single-line launchers correctly score 0 (they're trivial). They should be evaluated separately as candidates for Loupedeck buttons regardless of this audit.
- Workflows that pipeline through `set theData to ...` and pass it across apps without explicit `tell` blocks may underscore on criterion 4.

# Next step

For each triple-channel candidate, generate the three artifacts:

1. Run `bin/dictation-commands-to-shortcuts.py` style to emit a Siri phrase + Shortcut
2. Run `bin/spotlight-export.sh` (already existing) to ensure it's compiled to an .app for Spotlight
3. Add to `bin/loupedeck-import-dictation-commands.py`'s catalog
