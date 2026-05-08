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
voice-memos-export list --with-transcripts       # only ones Apple already transcribed
voice-memos-export list --without-transcripts
voice-memos-export list --audio                  # add codec/sample-rate/channels/device
voice-memos-export list --sort duration
voice-memos-export list --json                   # machine-readable
voice-memos-export list --csv
```

Columns:
- Storage flag: `   ` = local, `CLD` = cloud-only, `MIS` = local row but m4a missing
- Transcript flag: `T` = Apple has auto-generated a transcript embedded in the m4a
- `--audio` adds: `codec sr_kHz ch_count bitrate device` (cached via ffprobe in `.audio-meta.cache.json`)

### `transcripts` — Apple's auto-generated transcripts (no Whisper involved)

Voice Memos.app generates English transcripts on supported devices and
embeds them in the .m4a as a `tsrp` JSON atom in the file trailer. We can
detect (via ZFLAGS bit 3) and extract them without running Whisper.

```bash
voice-memos-export transcripts                            # list all that have transcripts
voice-memos-export transcripts --extract --print "Mauri"  # one transcript to stdout
voice-memos-export transcripts --extract --all            # write .apple-transcript.txt for each
voice-memos-export transcripts --extract --no-timestamps "Jon C. Fox"
```

Caveat: Apple's transcript engine on macOS 15.6.1 is **English-only and
poor quality on Finnish-mixed speech**. Use Whisper (`whisp --fi`) for
your Finnish recordings — Apple's transcripts are kept here mainly so
you know which recordings already have any kind of automated transcript
and can compare quality.

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
voice-memos-export export --all --audio                  # bake codec/device into sidecars
voice-memos-export export --all --in 2025                # one year
voice-memos-export export --all --longer-than 10m
voice-memos-export export --all --copy-audio             # copy instead of symlink
voice-memos-export export latest                         # single recording
voice-memos-export export "Mauri Rantala"
```

Live numbers from Esa's Mac: 392 recordings, 327 with audio on disk,
13 with Apple-generated transcripts. Vault total after `--all --audio`:
**1.6 MB** (symlinks + sidecars; the 3.4 GB of m4a files stay where Voice
Memos put them).

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
apple_transcript: true
flags_raw: 1548
audio_in_vault: "2026-05-07__1036__mauri-rantala__2EC8B04E.m4a"
source_db: "/Users/.../CloudRecordings.db"
sample_rate: 48000
channels: 1
bit_rate: 62951
codec: "aac"
encoder: "com.apple.VoiceMemos (iPad Version 15.6.1 (Build 24G90))"
device: "iPad"
---
```

The bottom six fields appear when you pass `--audio` (probes via ffprobe,
caches in `.audio-meta.cache.json`).

## What's NOT in this package

- **Whisper transcription** — coming in Phase 2 (use `whisp <m4a>` directly for now).
- **Watch daemon** — coming in Phase 2.
- **Force-download evicted recordings** — needs Shortcuts integration.
- **Cross-reference Calendar/Notes/Reminders** — Phase 2.
- **Direct DB writes** (rename/move/delete) — deliberately omitted; UI-script
  via Voice Memos.app is safer.

## Apple's transcript trailer (`tsrp` atom)

Findings from this session, worth recording in case Apple changes the
format:

- ZFLAGS bit 3 (mask `0x08`) in `ZCLOUDRECORDING` indicates an
  Apple-generated transcript exists for that recording. Verified across
  13 recordings on this Mac.
- The transcript itself is appended to the .m4a file after the audio
  data, prefixed by the 4-byte ASCII marker `tsrp`, followed by a JSON
  object with `locale` and `attributedString` fields.
- `attributedString.runs` is a flat array alternating
  `[text_str, attribute_index, text_str, attribute_index, ...]`.
  Each `attribute_index` indexes into `attributeTable` whose entries
  carry a `timeRange: [start_sec, end_sec]`.
- Concatenating the even-indexed strings reconstructs the full transcript
  text. The exporter does this and produces line-broken output keyed on
  > 2 s gaps with `[MM:SS]` markers.

Quality on multilingual / Finnish-heavy speech is poor (Apple's
on-device transcript is English-only on macOS 15.6.1). For real
transcription, route through Whisper.

See `~/work/apple/dictionaries/voice-memos/voice-memos-capability-map.md`
for the full roadmap.
