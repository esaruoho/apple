# Voice Memos — Extraction Research

> Generated 2026-05-07 from live probe of this Mac
> 392 cloud recordings, 327 .m4a files on disk, 31 .waveform sidecars, 17 .composition bundles

## TL;DR

Voice Memos has **no AppleScript dictionary** (`sdef` returns error -192). Extraction
must go straight to its SQLite store. Audio files are plain `.m4a` next to the DB,
so the entire archive can be exported with: SQLite query → copy m4a → write
markdown sidecar → optional Whisper transcription.

This is *simpler* than Reminders (no osascript dance, no permission dialog
beyond Full Disk Access for the Group Container).

### Update 2026-05-08 — `tsrp` atom found

Apple's auto-generated transcripts ARE persisted to disk after all — but
they're appended to the **m4a file itself** as a `tsrp` JSON atom in the
trailer, not stored in the SQLite database. Two-line summary:

- Detection: `ZFLAGS & 0x08` is the "has transcript" bit on
  `ZCLOUDRECORDING`. Verified across 13 recordings on this Mac.
- Extraction: scan the m4a file (last ~256 KB is enough) for the ASCII
  marker `tsrp`, then parse the JSON object that follows. The transcript
  is an NSAttributedString with `attributeTable` (timeRanges) and `runs`
  (alternating `[text, attribute_index, ...]`).

Implementation: `voice-memos-export transcripts --extract`. See
`voice-memos-cli-feasibility.md` for the longer history of this finding
(initial probe missed it; second probe of the m4a tail uncovered it).

## Storage layout

```
~/Library/Group Containers/group.com.apple.VoiceMemos.shared/
├── Library/                           # app preferences (ignore)
└── Recordings/
    ├── CloudRecordings.db             # the metadata index (Core Data SQLite)
    ├── CloudRecordings.db-shm         # WAL shared memory
    ├── CloudRecordings.db-wal         # WAL log
    ├── CloudRecordings_ckAssets/      # CloudKit asset cache
    ├── 20260507 133626.m4a            # ← audio file (filename = ZPATH)
    ├── 20260507 133626-track0.waveform   # waveform preview blob
    ├── 20260507 133626.composition/   # multi-track edit project (newer recordings)
    └── ... 327 .m4a, 31 .waveform, 17 .composition ...
```

Filename pattern: `YYYYMMDD HHMMSS[-XXXXXXXX].m4a` (8-hex suffix appears for
synced/imported recordings; locally-made recordings sometimes lack it).

## SQLite schema (Core Data backed)

Database file: `CloudRecordings.db`

### Key table: `ZCLOUDRECORDING` (392 rows here)

| Column | Type | What |
|--------|------|------|
| `Z_PK` | INTEGER | primary key |
| `ZDATE` | TIMESTAMP | **Cocoa epoch** (seconds since 2001-01-01 UTC) |
| `ZDURATION` | FLOAT | length in seconds |
| `ZLOCALDURATION` | FLOAT | local duration (matches ZDURATION when not evicted) |
| `ZCUSTOMLABEL` | VARCHAR | user-set title (e.g. "Lea Osasto 13 MRSA") |
| `ZCUSTOMLABELFORSORTING` | VARCHAR | normalized title for sort |
| `ZENCRYPTEDTITLE` | VARCHAR | **misnamed — plaintext title** identical to ZCUSTOMLABEL |
| `ZPATH` | VARCHAR | filename relative to `Recordings/` |
| `ZUNIQUEID` | VARCHAR | UUID, stable across iCloud sync |
| `ZFOLDER` | INTEGER | FK to ZFOLDER (nullable; 0 folders in this Mac's DB) |
| `ZFLAGS` | INTEGER | bit flags (favorited, etc.) |
| `ZEVICTIONDATE` | TIMESTAMP | non-null if cloud-only (audio not on disk) |
| `ZPLAYBACKPOSITION` | FLOAT | last scrub position |
| `ZSILENCEREMOVERENABLED` | INTEGER | bool |
| `ZAUDIODIGEST` | BLOB | bplist hash of audio |
| `ZAUDIOFUTURE` | BLOB | bplist of edit operations / future state |
| `ZMTAUDIOFUTURE` | BLOB | multi-track equivalent |

### Other tables

- `ZRECORDING` — older/legacy table (0 rows on this Mac, but exists). Same
  basic shape minus the cloud-specific columns. Older OSes may still write
  here.
- `ZFOLDER` — user-created folders (0 here, can have rows). `ZENCRYPTEDNAME`
  holds the folder name (also misnamed-as-encrypted; plaintext).
- `ANSCK*` — CloudKit sync bookkeeping (ignore for export).
- `ATRANSACTION`, `ACHANGE` — Core Data persistent history (ignore).

## Date conversion

Apple Cocoa reference date: `2001-01-01 00:00:00 UTC`. Convert to Unix epoch:

```python
from datetime import datetime, timedelta, timezone
COCOA_EPOCH = datetime(2001, 1, 1, tzinfo=timezone.utc)
def cocoa_to_iso(z: float) -> str:
    return (COCOA_EPOCH + timedelta(seconds=z)).isoformat()
```

SQLite's `datetime(zdate + 978307200, 'unixepoch')` works as a one-liner.

## Eviction (cloud-only recordings)

If `ZEVICTIONDATE IS NOT NULL`, the m4a was offloaded to iCloud and isn't on
local disk. Voice Memos.app downloads on demand. Three ways to handle in an
exporter:

1. Skip evicted rows — export only what's locally available.
2. Open Voice Memos.app and play the recording (forces download), then poll.
3. Use Shortcuts' "Get Voice Memo" action which auto-downloads.

Option 1 is the safe default; option 3 is the Sal-grade automation move.

## What scripting/automation surfaces exist

| Surface | Available | Notes |
|---------|-----------|-------|
| AppleScript sdef | ❌ | `sdef` returns error -192 |
| `osascript -e 'tell application "Voice Memos" to ...'` | partial | activate/quit only; no document model |
| App Intents (Siri / Shortcuts) | ✅ | 41 phrases extracted (record, stop, play, delete, search, folders) |
| URL scheme | ❌ | none registered |
| Spotlight | partial | recording titles indexed by Voice Memos itself |
| Direct SQLite + filesystem | ✅ | the only path to bulk metadata |
| Shortcuts.app actions | ✅ | "Get Recent Voice Memos", "Make Voice Memo", folder query |

## Permissions required

To read `~/Library/Group Containers/group.com.apple.VoiceMemos.shared/`,
the running process needs **Full Disk Access** in System Settings →
Privacy & Security. (Terminal already has it on this Mac — verified by
the successful sqlite3 query above.)

## Export plan (for `voice-memos-export/` package)

Mirror notes-export / reminders-export shape:

```
voice-memos-export/
├── README.md
├── .env.example          # VAULT_PATH, INCLUDE_EVICTED, WHISPER_MODEL, COPY_AUDIO
├── config.example.json   # optional: folder filter
├── .gitignore            # .env, config.json, .state.json
└── scripts/
    ├── voice-memos-export        # bash wrapper
    └── voice_memos_export.py     # SQLite reader + file copier + transcribe hook
```

### Commands
```
voice-memos-export folders                # list folders + counts
voice-memos-export export --all           # export everything
voice-memos-export export --since 2025    # year/month filter on ZDATE
voice-memos-export export --include-evicted   # include cloud-only (no audio)
voice-memos-export export --copy-audio    # copy m4a alongside .md (default: just symlink)
voice-memos-export transcribe             # whisp pass over copied audio
voice-memos-export status
```

### Output shape (per recording)
```
~/voice-memos-vault/
└── 2026/
    └── 05/
        └── 2026-05-07__1336__mauri-rantala__2EC8B04E.md   # YAML frontmatter
        └── 2026-05-07__1336__mauri-rantala__2EC8B04E.m4a  # copied audio (or symlink)
        └── 2026-05-07__1336__mauri-rantala__2EC8B04E.txt  # whisp transcript (after transcribe)
```

YAML frontmatter:
```yaml
---
id: "2EC8B04E-3744-429B-A46D-4BC1BBDD441D"
title: "Mauri Rantala"
date: "2026-05-07T13:36:26"
duration_seconds: 1246.33
duration_human: "20:46"
folder: ""
favorited: false
evicted: false
audio_path: "20260507 133626.m4a"
silence_remover: false
---
```

### Incremental
Track each `ZUNIQUEID` → `(ZDATE, ZDURATION)` in `.state.json`. Re-export
on change (Voice Memos can edit a recording in-app, advancing duration but
keeping ZUNIQUEID).

## Open questions / decisions to make before building

1. **Audio: copy or symlink?** Copy doubles disk; symlink keeps the vault
   pointing into the protected Group Container (Obsidian etc may not follow).
   Recommendation: symlink default, `--copy-audio` opt-in.
2. **Transcription pass: inline vs separate command?** notes-export keeps it
   as a separate `transcribe` subcommand. Match that.
3. **Folder default name?** Recordings without `ZFOLDER` go where? Suggested:
   group by year/month (since user-folders are rarely used per this Mac).
4. **Evicted recordings**: skip silently or list as `evicted: true` with no
   audio_path? Suggested: write the .md anyway so the catalog is complete,
   include `evicted: true` flag.
