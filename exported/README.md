# exported/

Local landing zone for the bulk-exporter packages. Every other Apple
user can have the same convention — the export tools live in the repo,
the exported data lives here. **Only this README is tracked**; everything
else under `exported/` is gitignored, so cloning the repo never carries
anyone else's data.

## Layout

```
exported/
├── README.md                 ← tracked; everything below is local-only
├── notes/                    notes-exporter → Apple Notes markdown vault
├── imessage/                 imessage-exporter → iMessage links + conversations
├── reminders/                reminders-exporter → Apple Reminders by list
├── voice-memos/              voice-memos-exporter → m4a symlinks + sidecars + transcripts
├── safari/                   safari-exporter → windows / tab groups / bookmarks /
│                             iCloud tabs / history / per-URL dedup pages
├── stickies/                 stickies-exporter → markdown of each Stickies note + .rtfd symlinks
├── console/                  console-exporter → diagnostic reports + saved log queries
├── audio-midi/               audio-midi-exporter → audio + MIDI device markdown + .mcfg symlinks
└── image-capture/            image-capture-exporter → cameras / iOS devices / scanners / `snap` photos
```

Each subfolder is the default `VAULT_PATH` (or `OUTPUT_PATH`) of its
matching `<name>-exporter/` package. The `.env.example` files in the
package directories all point here, so a fresh user just runs:

```bash
cd ~/work/apple/<package>-exporter
cp .env.example .env
./scripts/<package>-exporter export
```

…and their vault lands at `~/work/apple/exported/<package>/`, alongside
this file.

## Why this layout

- **One mental model**: Apple → live data on the OS → tools in
  `~/work/apple/<thing>-export/` → vault in `~/work/apple/exported/<thing>/`.
- **Browse + script in one place**: Open `~/work/apple/` in a single
  Obsidian vault or editor session and you have both the tooling and
  the data.
- **Safe to share**: `exported/` is gitignored entirely, so anything
  Esa-specific (Reminder list contents, Safari tab URLs, Voice Memo
  transcripts, iMessage logs, Apple Notes contents) stays on Esa's
  disk. Other contributors clone the repo and only see this README.
- **Disk-lean by default**: `voice-memos-export` symlinks the m4a back
  into Apple's container instead of copying — the vault stays under
  20 MB even for hundreds of recordings.

## Override

Don't want it under the repo? Edit your `.env`:

```env
VAULT_PATH=/some/other/place/I/prefer
```

Each package's `.env` is gitignored, so individual overrides don't leak.

## Snapshot of Esa's local vault (2026-05-08)

```
exported/safari       14 MB   3,088 per-URL pages + window/group/bookmark trees
exported/voice-memos  1.6 MB  392 .md sidecars + 327 m4a symlinks
exported/reminders    2.0 MB  520 active reminders across 19 list folders
exported/stickies     40 KB   10 stickies as markdown + .rtfd symlinks
exported/console      varies  diagnostic reports (symlinks) + saved log queries
exported/audio-midi   <50 KB  8 audio devices, 1 saved MIDI config
exported/image-capture <20 KB 3 cameras + iOS / scanner / prefs markdown
exported/notes        (not run yet)
exported/imessage     (not run yet)
```

Run any of `notes-export`, `imessage-export`, `reminders-export`,
`voice-memos-export`, `safari-export` to populate your own.
