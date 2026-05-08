# Voice Memos — Disk-Lean Operations

> Everything you can do without ever copying an m4a out of the Voice
> Memos Group Container. Generated 2026-05-08.

## The disk picture

```
Recordings/          3.4 GB  (392 m4a + waveforms + DB)
  largest m4a:       722 MB  ("Uusi äänitys", 25h18m, 2022-12-19)
  next two:          621 MB  / 202 MB
voice-memos-vault/   4 KB    (one .md sidecar, audio is a symlink)
```

So copy-mode would push the vault to ~7 GB. **Default symlink mode keeps
the vault at 4 KB per recording** — the .m4a "file" inside the vault is a
zero-byte pointer back into Apple's container. Apple sees no second copy;
your disk doesn't grow; deleting the recording in Voice Memos.app
breaks the symlink (recoverable: re-run export, the symlink rebuilds).

## Operating principle

**The audio stays where Apple put it. Everything we build operates on it
in place.** Symlinks let Obsidian/Finder/grep/whisp see it without
duplication. Transcripts and metadata are tiny (KB, not MB), so they can
live in the vault directly.

## Disk-lean Phase 2 operations

### 1. Transcribe in place — keep .txt, never copy .m4a (BIG WIN)

```bash
voice-memos-export transcribe latest             # whisp on the m4a in Apple's dir
voice-memos-export transcribe --all              # batch
voice-memos-export transcribe --since 2024 --lang fi
```

Implementation: pass the **original m4a path** to `whisp`, write the
`.txt` next to the `.md` sidecar in the vault. Total transcript bytes for
all 392 recordings: ~2 MB (estimate ~5 KB average). That's **0.06% the
size of the audio**.

State file tracks: which model used, language, run timestamp, source m4a
mtime. Re-running skips finished transcripts.

### 2. Stream to whisper without intermediate files

For long recordings, pipe m4a through ffmpeg directly to whisper:

```bash
ffmpeg -i "<m4a>" -ar 16000 -ac 1 -f wav - | whisper-cli -
```

Saves the temporary 16-kHz WAV that whisp normally creates. For the
25-hour recording, that intermediate WAV would be ~3 GB.

### 3. Chunked transcription for marathon recordings

For anything over 30 min, split into 10-min chunks (timestamp-aware),
transcribe each, write **separate .txt files per chunk**, plus a
combined merged transcript.

```
2026-05-07__1036__mauri-rantala__2EC8B04E.md
2026-05-07__1036__mauri-rantala__2EC8B04E.txt          # full transcript
2026-05-07__1036__mauri-rantala__2EC8B04E.chunks/
  ├── 00-00-00.txt   # 0:00:00–0:10:00
  ├── 00-10-00.txt
  ├── 00-20-00.txt
  └── ...
```

Two payoffs: resumable on crash; can re-transcribe one bad chunk without
redoing the whole 25-hour file.

### 4. Indexed metadata cache (replaces re-querying SQLite)

Every `list`/`stats` run currently re-reads `CloudRecordings.db`. Keep
a tiny `.cache.json` in the vault root with the last full snapshot
plus a hash. Refresh only when the DB mtime advances.

```
.cache.json   ~50 KB   (392 records, one JSON object each)
```

### 5. Full-text search across transcripts (after transcribe)

```bash
voice-memos-export search "Kortela pyrolysis"
voice-memos-export search "free energy" --in 2025
voice-memos-export search "ruby" --speaker      # if diarized
```

Implementation: ripgrep over `*.txt` files in the vault. No index
needed for archives this size; <100 ms even with `rg -n -i`.

For larger archives (or semantic search), build a sqlite-fts5 index
in the vault: `~50 KB per 10 hours of speech`.

### 6. Summaries — keep summary, drop transcript

Even more disk-frugal: for low-value recordings (short voicemails, kid
noises, ambient sound captures), store **only a 5-bullet summary** in
the .md sidecar and **delete** the transcript .txt. The audio stays in
Apple's container; the .md sidecar grows by maybe 500 bytes.

Two-tier policy:

| Tier | Examples | Stored |
|------|----------|--------|
| Archive | LENR interviews (Kortela, Grotz, Fox), perheneuvola, Mauri Rantala | full transcript + .md |
| Summary | "New Recording 18", short location captures, accidental taps | 5-line summary in .md only |

### 7. Embeddings (semantic search)

For the long-game RAG. ~1 KB per chunk after compression. The full
98.6-hour archive at 1-min chunks: ~5 MB embedding store.

### 8. Audio fingerprints (dedup, no audio copy)

`chromaprint` produces a ~10 KB fingerprint per recording. Compare
fingerprints to find duplicates without duplicating audio. Useful for
the visible "_1"/"_2" suffix pairs (`JP8_1`/`JP8_1 2`, near-zero-byte
twins).

### 9. Silence-map / chapter detection (timestamps only)

`ffmpeg silencedetect` outputs a list of `[start, end]` silent regions.
Save as a JSON sidecar:

```json
[
  {"start": 0.0, "end": 1.2, "kind": "silence"},
  {"start": 1.2, "end": 612.5, "kind": "speech"},
  ...
]
```

~few KB per recording. Lets you auto-chapter the 25-hour file without
ever splitting the audio.

### 10. Cross-reference — links, not copies

`voice-memos-export xref --calendar` finds Calendar events within ±30 min
of each recording. Output: a `xref:` block in the .md sidecar listing
event titles + attendees. **No data copied** — just the link.

```yaml
xref:
  calendar:
    - "Perheneuvola — Vuosaari" 2026-02-02 11:14
  notes:
    - "Vuosaari perheneuvola muistiinpanot"  (created 2026-02-02 12:31)
  reminders:
    - "Soita perheneuvolaan" (completed 2026-02-03)
```

### 11. Watch daemon — write only when needed

`fswatch` on Recordings/. On new m4a:
1. write .md sidecar (1 KB)
2. transcribe → .txt (~5 KB)
3. summarize → append summary block to .md (~500 B)
4. discord-ping (no disk)

Per-new-recording disk delta: ~7 KB. **Doesn't grow per duration**, only
per recording count.

### 12. Force-download evicted recordings (in-place)

For cloud-only rows: open Voice Memos.app, trigger Apple's own download.
The m4a lands back in Apple's container — we never store it ourselves.
Then transcribe, then leave the audio where it is. (Apple's iCloud
re-eviction may pull it back later; transcript stays.)

### 13. Selective audio extraction (sub-clip only)

If you ever need to share a clip without exporting the whole recording:

```bash
voice-memos-export clip "Mauri" --from 5:30 --to 7:15 --out share.m4a
```

Uses `ffmpeg -ss/-to -c copy` — produces a small targeted clip instead
of dumping the whole file. Audio leaves Apple's container only when
explicitly requested for a specific span.

### 14. Hash-only iCloud verification

Compare `ZAUDIODIGEST` BLOB against locally-computed digest to verify
the m4a hasn't been corrupted/re-encoded by iCloud sync. Pure read,
~32 bytes per recording.

## What this means for Phase 2 build order

Keep symlink mode the **only** mode for now. Layer these on top:

```
Phase 2a — transcribe (no audio copy):
  voice-memos-export transcribe <selector>
  voice-memos-export transcribe --all [--since YYYY] [--lang fi|en]
  voice-memos-export transcribe --route       # auto-pick model+lang
  voice-memos-export transcribe --chunked     # for >30m recordings

Phase 2b — search:
  voice-memos-export search "<query>"

Phase 2c — summarize:
  voice-memos-export summarize <selector>
  voice-memos-export summarize --tier         # tier-based: archive vs summary

Phase 2d — watch daemon:
  voice-memos-export watch                    # LaunchAgent

Phase 2e — cross-reference:
  voice-memos-export xref --calendar
  voice-memos-export xref --notes --reminders

Phase 2f — clip extraction:
  voice-memos-export clip <selector> --from --to
```

Vault size after **all** of Phase 2 ran on the full 392-recording archive:

```
.md sidecars:    ~400 KB   (1 KB × 392)
.txt transcripts ~2 MB     (5 KB × 392)
chunk transcripts ~6 MB    (a few long recordings, fine-grained)
silence-maps    ~400 KB
xref data       ~200 KB
sqlite-fts index ~5 MB
.cache.json     ~50 KB
─────────────────────────
total           ~14 MB     (vs 3.4 GB if copying)
```

**The vault stays smaller than a single large m4a, even after
transcribing the entire archive.**
