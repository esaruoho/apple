# notes-export

Export Apple Notes folders to clean Markdown with YAML frontmatter, copy media/audio attachments, transcribe audio with Whisper, and maintain an Obsidian-compatible vault. Hybrid AppleScript + SQLite for completeness — handles smart folders, attributedBody quirks, and modern iCloud sync.

## What it does

- Reads `NoteStore.sqlite` for metadata (folders, notes, attachments) and copies media files from `~/Library/Group Containers/group.com.apple.notes/`
- Uses AppleScript (`osascript`) to fetch the HTML body of each note (the body is a protobuf blob in SQLite — AppleScript hands you clean HTML)
- Converts HTML → Markdown via `markdownify`, extracting inline base64 images to files
- Copies audio recordings into per-note `assets/` subdirectories
- Optional: transcribes audio with OpenAI Whisper, embeds preview into the markdown
- Optional: continuous sync daemon that re-runs on an interval
- Incremental: only re-exports notes whose `ZMODIFICATIONDATE1` advanced since the last run
- Output is plain markdown with YAML frontmatter — works with Obsidian, Logseq, or any consumer

## Installation

```bash
git clone https://github.com/esaruoho/apple.git
cd apple/notes-export

pip3 install -r requirements.txt   # markdownify + openai-whisper

cp .env.example .env               # set vault path + account UUID
cp config.example.json config.json # list folders to export
```

### Find your iCloud account UUID

```bash
ls ~/Library/Group\ Containers/group.com.apple.notes/Accounts/
```

The directory name is your account ID. Put it into `.env` as `NOTES_ACCOUNT_ID`.

### AppleScript permission

The first run will prompt you to grant the terminal app permission to control Notes. Approve it. (System Settings → Privacy & Security → Automation if you need to revisit.)

## Configuration

Two files, both gitignored:

### `.env` — paths and identity

```env
VAULT_PATH=~/work/apple/exported/notes
EXPORT_PATH=~/work/apple/exported/notes-manifest
NOTES_DB=~/Library/Group Containers/group.com.apple.notes/NoteStore.sqlite
NOTES_ACCOUNT_ID=51781730-D2BA-45AB-8E20-CEFE28B642A1
WHISPER_MODEL=base
WATCH_INTERVAL=300
```

### `config.json` — folder selection

```json
{
  "folders": ["Notes", "Work", "Recipes", "Travel"]
}
```

`folders` is the list used by `--all`. You can always pass `--folders A,B,C` explicitly to override.

## Usage

```bash
./scripts/notes-export folders                         # list all Apple Notes folders
./scripts/notes-export export --folders Notes,Work     # export specific folders
./scripts/notes-export export --all                    # export everything in config.json
./scripts/notes-export export --force                  # re-export unchanged notes too
./scripts/notes-export status                          # show last run / per-folder counts

./scripts/notes-export transcribe                      # transcribe new audio (Whisper)
./scripts/notes-export transcribe --folder Notes --model medium

./scripts/notes-export watch --interval 300            # continuous sync daemon
./scripts/notes-export watch --once                    # one-shot
```

## Output structure

```
$VAULT_PATH/
├── Notes/
│   ├── shopping-list.md
│   ├── meeting-notes.md
│   └── assets/
│       ├── shopping-list/
│       │   └── image-9a3f2c.jpg
│       └── meeting-notes/
│           ├── recording-abc12345.m4a
│           └── recording-abc12345.transcript.md
└── Work/
    └── …

$EXPORT_PATH/
└── manifest.json    # flat index for programmatic consumers
```

Each note becomes a markdown file:

```markdown
---
title: "Meeting Notes"
created: 2026-01-30T07:44:24+00:00
modified: 2026-01-30T12:13:50+00:00
source: apple-notes
folder: Notes
attachments: 2
tags: [apple-notes, notes]
---

# Meeting Notes

Body content here…

## Audio Recordings

- [recording-abc12345.m4a](assets/meeting-notes/recording-abc12345.m4a)
  > **Transcript:** "Today we discussed the roadmap for Q2…"
```

## How it works (highlights)

### `ZCREATIONDATE3` and `ZMODIFICATIONDATE1` — not the obvious columns

Apple Notes' SQLite has both `ZCREATIONDATE` and `ZCREATIONDATE3` (and `ZMODIFICATIONDATE` vs `ZMODIFICATIONDATE1`). On modern iCloud-synced installs, the unsuffixed columns are **always NULL**. Use the numbered ones. Same trap with `ZNOTE` (correct) vs `ZNOTE1` (NULL).

### Smart folders need AppleScript

Smart folders have `ZFOLDERTYPE = 2` and don't have a direct membership relation in SQLite — they're query-based (`ZSMARTFOLDERQUERYJSON`). Easiest path: enumerate via AppleScript, then enrich with SQLite metadata using the note's `Z_PK` (extracted from the CoreData URI `x-coredata://UUID/ICNote/p<PK>`).

### Hybrid SQLite + AppleScript

The note body (`ZNOTEDATA`) is a compressed protobuf blob — possible to parse but messy. AppleScript's `body of theNote` returns clean HTML, which `markdownify` converts to Markdown cleanly.

### Inline base64 images

Apple Notes embeds pasted images inline as `data:image/png;base64,…` URIs. The custom `NotesConverter` extracts these to per-note `assets/` directories with hash-based filenames, dedupes, and rewrites the markdown to point at the relative file path.

### Media file resolution

```
~/Library/Group Containers/group.com.apple.notes/
  Accounts/{ACCOUNT_ID}/Media/{MEDIA_IDENTIFIER}/{VERSION_SUBDIR}/{FILENAME}
```

Files live in versioned subdirectories — the script walks them to find the live version.

### Recording filename collisions

Apple Notes names every voice memo `recording.m4a`. The script appends the first 8 chars of the attachment ID (`recording-abc12345.m4a`) so multiple recordings in one note don't clobber each other.

### Apple epoch

Timestamps are seconds since `2001-01-01 UTC` (offset 978307200). Same convention as iMessage and most Core Data apps.

## Privacy

- The script reads `NoteStore.sqlite` **read-only** via SQLite URI mode
- Nothing is uploaded; transcription runs locally with Whisper
- `.env` and `config.json` are gitignored — your account ID and folder names never end up in version control
- Output directory is yours to choose — keep it outside this repo

## Limitations

- macOS only
- Requires Notes to be running for AppleScript access to body HTML
- Drawings (`com.apple.drawing.2`), tables (`com.apple.notes.table`), and gallery layouts are skipped — they don't have backing media files in the same way
- Locked notes will not export their body via AppleScript unless unlocked
- Pinned/checklist state is preserved in HTML but not separately exposed in frontmatter

## Part of `esaruoho/apple`

This tool lives in the `apple` repo's automation collection — practical macOS automation in the spirit of Sal Soghoian's "Product Manager of Automation Technologies" role. See the parent repo for AppleScript reference, scripting dictionary indexes, automation tier guides, and more.

## License

See `../LICENSE` in the parent `apple` repository.
