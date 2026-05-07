# voice-memos-export

Read-only catalog + vault export for Apple Voice Memos. Reads
`CloudRecordings.db` and the m4a files directly — no AppleScript needed
(Voice Memos has no scripting dictionary). All commands operate
read-only on Apple's data; writes go only into your vault.

Source of truth: `~/Library/Group Containers/group.com.apple.VoiceMemos.shared/Recordings/`.
Background: see `~/work/apple/dictionaries/voice-memos/voice-memos-extraction-research.md`
and `voice-memos-capability-map.md` in the same folder.

## Install

```bash
cd ~/work/apple/voice-memos-export
cp .env.example .env          # set VAULT_PATH
chmod +x scripts/voice-memos-export
```

Terminal needs **Full Disk Access** (System Settings → Privacy & Security)
to read the protected Group Container. Already granted on Esa's Mac.

## Selector grammar

Used by `open` and single-recording `export`:

| Selector | Example | Notes |
|----------|---------|-------|
| `latest` | `latest` | newest recording |
| `#N` | `#0`, `#3` | 0-based index in date-desc order |
| YYYY-MM-DD | `2026-04-26` | first match on that day |
| UUID prefix | `2EC8B` | 4+ hex chars |
| Title substring | `"Mauri"` | case-insensitive |

When a substring matches multiple recordings, the tool prints the top 10
hits and asks you to narrow with UUID prefix or `#N`.

## Commands

### `list` — filtered listing

```bash
voice-memos-export list                          # all 392 recordings
voice-memos-export list --in 2025                # one year
voice-memos-export list --in 2025-04             # one month
voice-memos-export list --since 2024-06          # everything since
voice-memos-export list --longer-than 30m
voice-memos-export list --shorter-than 5s        # likely accidental taps
voice-memos-export list --match 'Kortela|Grotz|Russell'
voice-memos-export list --at "Inkiväärikuja"
voice-memos-export list --evicted                # cloud-only
voice-memos-export list --local                  # audio on disk
voice-memos-export list --sort duration
voice-memos-export list --json                   # machine-readable
voice-memos-export list --csv
```

Storage flag column: `   ` = local, `CLD` = cloud-only, `MIS` = local row but m4a missing.

### `stats` — aggregates

```bash
voice-memos-export stats
voice-memos-export stats --in 2025
voice-memos-export stats --at "Inkiväärikuja"
```

Reports: total hours, by-year breakdown, place-prefix clusters
(Inkiväärikuja, Sahaajankatu, Kauppakeskus Columbus, …), longest 10,
shortest 5 (the 0.0s rows are usually accidental).

### `open` — open a recording

```bash
voice-memos-export open latest                   # opens Voice Memos.app + Finder
voice-memos-export open #0 --quicktime           # plays in QuickTime
voice-memos-export open 2EC8B --reveal           # Finder only
voice-memos-export open "Mauri Rantala"
voice-memos-export open 2026-04-26
```

Cloud-only recordings open Voice Memos.app to trigger an iCloud download.

### `export` — copy/symlink m4a + write .md sidecars

```bash
voice-memos-export export --all                          # whole archive
voice-memos-export export --all --in 2025                # one year
voice-memos-export export --all --longer-than 10m
voice-memos-export export --all --copy-audio             # copy instead of symlink
voice-memos-export export latest                         # single recording
voice-memos-export export "Mauri Rantala"
```

Default mode is **symlink** the m4a — keeps the vault tiny and the audio
stays where Voice Memos.app expects it. Pass `--copy-audio` if you want
duplicate files (e.g. to ship the vault to another machine).

Vault layout:

```
$VAULT_PATH/
└── 2026/
    └── 05/
        ├── 2026-05-07__1336__mauri-rantala__2EC8B04E.md      # YAML+body
        └── 2026-05-07__1336__mauri-rantala__2EC8B04E.m4a     # symlink (or copy)
```

Sidecar frontmatter:

```yaml
---
uuid: "2EC8B04E-3744-429B-A46D-4BC1BBDD441D"
title: "Mauri Rantala"
raw_label: "2026-05-07T10:36:26Z"
date: "2026-05-07 10:36:26"
duration_seconds: 1246.33
duration_human: "20:46"
path: "20260507 133626.m4a"
evicted: false
audio_in_vault: "2026-05-07__1336__mauri-rantala__2EC8B04E.m4a"
source_db: "/Users/.../CloudRecordings.db"
---
```

## What's NOT in this package

- **Transcription** (`whisp` wrapper) — coming in Phase 2.
- **Watch daemon** — coming in Phase 2.
- **Force-download evicted recordings** — needs Shortcuts integration.
- **Cross-reference Calendar/Notes/Reminders** — Phase 2.
- **Direct DB writes** (rename/move/delete) — deliberately omitted; UI-script
  via Voice Memos.app is safer.

See `~/work/apple/dictionaries/voice-memos/voice-memos-capability-map.md`
for the full roadmap.
