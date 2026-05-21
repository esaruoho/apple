# Bulk Exporters Index — 19 exporters

**The agent should ONLY read a specific exporter's directory when the user's question is about that data source.**
An AppleScript question never needs to touch any exporter. A 'where are my safari bookmarks' question reads ONLY `safari-exporter/`.

Format: `exporter-name` — purpose — `path/`
Regenerate: `python3 bin/gen-skill-indexes.py`
`audio-midi-exporter` — Audio MIDI Setup data without launching Audio MIDI Setup. Tier 5 dark — `audio-midi-exporter/`
`books-exporter` — Apple Books library, collections, and annotations → markdown vault. — `books-exporter/`
`calendar-exporter` — Apple Calendar → markdown vault. Reads — `calendar-exporter/`
`console-exporter` — Console.app catalog + filtered-query exporter. Console has no — `console-exporter/`
`contacts-exporter` — Apple Contacts → markdown vault. — `contacts-exporter/`
`finder-exporter` — Finder tags, sidebar favorites, recent documents, recent — `finder-exporter/`
`image-capture-exporter` — Image Capture surface unlocked. The app is Tier 5 dark — no — `image-capture-exporter/`
`imessage-exporter` — Extract URLs (with surrounding message context) and full conversations from specific iMessage contacts into Markdown with YAML frontmatter. Pure macOS, pure Python stdlib, zero external dependencies. — `imessage-exporter/`
`iwork-exporter` — Pages + Numbers + Keynote catalog. On macOS Sequoia, Apple ships — `iwork-exporter/`
`mail-exporter` — Apple Mail.app metadata catalog via the Envelope Index SQLite. — `mail-exporter/`
`music-exporter` — Apple Music.app library + playlists via AppleScript sdef. Music is — `music-exporter/`
`notes-exporter` — Export Apple Notes folders to clean Markdown with YAML frontmatter, copy media/audio attachments, transcribe audio with Whisper, and maintain an Obsidian-compatible vault. Hybrid AppleScript + SQLite for completeness — handles smart folders, attributedBody quirks, and modern iCloud sync. — `notes-exporter/`
`photos-exporter` — Apple Photos library catalog via the `Photos.sqlite` database. The — `photos-exporter/`
`preview-exporter` — Apple Preview recent docs + per-file metadata → markdown vault. — `preview-exporter/`
`reminders-exporter` — Export Apple Reminders lists to clean Markdown with YAML frontmatter. — `reminders-exporter/`
`safari-exporter` — Read-only catalog + markdown vault for Safari data: windows, tab groups, — `safari-exporter/`
`shortcuts-exporter` — Catalog every Shortcut in Shortcuts.app as readable markdown so AI assistants — `shortcuts-exporter/`
`stickies-exporter` — Read-only catalog + markdown vault for Apple Stickies notes. Sixth — `stickies-exporter/`
`voice-memos-exporter` — Read-only catalog + vault export for Apple Voice Memos. Reads — `voice-memos-exporter/`
