# Voice Memos — Capability Map

> What's possible beyond `list` and `transcribe`. Generated 2026-05-07
> from live probe of this Mac (392 recordings, 327 m4a on disk).

Capabilities grouped by surface (read-only, write-via-app, write-direct,
analysis). Each one is rated **EASY / MEDIUM / HARD / RISKY** so we know
what to build first and what to leave alone.

---

## A. Read-only — pure SQLite + filesystem

These are all safe. They read the user's data without touching it.

### A1. `voicememos list` — filtered listings (EASY)
- **By year/month**: `--since 2024-06`, `--in 2025`
- **By duration**: `--longer-than 1h`, `--shorter-than 30s`
- **By title regex**: `--match 'Kortela|Grotz|Russell'`
- **By location-substring**: `--at "Inkiväärikuja"` (titles double as addresses)
- **By storage**: `--evicted`, `--local`
- **Sort**: by date desc (default), duration desc, title
- **Output**: table (default), `--json`, `--csv`, `--obsidian`

### A2. `voicememos stats` — aggregates (EASY)
- Total hours of recordings (per year, per location)
- Recordings-per-day calendar heatmap (data only; viewer optional)
- Longest, shortest, average duration
- "Place clusters" — group by title-prefix substring (Inkiväärikuja N=14, Sahaajankatu N=11, Kauppakeskus N=6, Family Hotel The Rocks N=11, etc)
- "Series" detection — auto-numbered "Recording N" runs vs named-event recordings

### A3. `voicememos open <selector>` — open in Voice Memos.app or QuickTime (EASY)
- Selector grammar shared with all subcommands: UUID prefix, title substring, date, index `#0`/`#1`, `latest`
- `--quicktime` opens in QuickTime instead (lightweight, no app launch lag)
- `--reveal` opens Finder pointed at the m4a

### A4. `voicememos export-audio <selector|--all>` — copy m4a out (EASY)
- Copy/symlink to a vault path (the build we already designed for `voicememos-export`)
- Optional `--rename "{date}__{title}__{id8}.m4a"` for clean filenames
- Skips evicted (or `--include-evicted` writes a `.placeholder.txt`)

### A5. `voicememos pull <selector>` — force download of cloud-only recording (MEDIUM)
- Three viable paths, in increasing reliability:
  1. `open -a "Voice Memos" voicememos://<UUID>` (URL scheme, if registered)
  2. UI scripting: open app → click recording → wait for download
  3. **Shortcuts.app action** "Get Voice Memo" (auto-downloads; this is the cleanest)
- Output: blocks until `ZEVICTIONDATE IS NULL` for that row, then exits

### A6. `voicememos cross-reference --calendar` (MEDIUM, requires Calendar.app sdef)
- Match each recording's `ZDATE` to nearby Calendar events (±30 min window)
- "What was I doing when I made this recording?" — auto-attach event title to a transcript header
- Output: extra YAML field `event: "Perheneuvola — Vuosaari"` in the .md sidecar

### A7. `voicememos cross-reference --notes` / `--reminders` (MEDIUM)
- Same idea: scan Notes.app and Reminders.app for entries created/modified within ±10 minutes of a recording
- Cross-link in the sidecar markdown ("Created Note 'X' shortly after this recording")

---

## B. Transcription pipeline

Built around `whisp` (already installed at `~/work/whisp/whisp`).

### B1. `voicememos transcribe <selector>` (EASY)
- Resolves selector → m4a path → shells out to `whisp`
- Writes `.txt` next to the m4a in the export vault
- State file tracks: which model used, language, when run, whisp version

### B2. `voicememos transcribe --all [--lang fi|en|fa]` (EASY)
- Batch over the vault. Skips any recording with an existing `.txt` unless `--force`
- Sequential by default, `--parallel N` to fan out
- Auto-language detection if no flag passed (whisp's default)

### B3. `voicememos transcribe --route` (MEDIUM)
- Inspect recording title/duration to pick the model:
  - <1 min → `tiny.en` (fast, fine for speech notes)
  - 1–10 min → `base` (default speech)
  - 10–60 min → `medium` (interviews, accuracy matters)
  - >60 min → `medium` + chunking with overlap
- Auto-detect Finnish from common name patterns ("Inkiväärikuja", "Vuosaari", "Sahaajankatu") and force `--fi`

### B4. `voicememos transcribe --apple-ui` — drive Apple Intelligence transcripts (HARD)
- For Apple-Intelligence-eligible Macs only (M-series 8GB+, English-only on macOS 15.x)
- UI scripting: select recording → click Transcribe button → wait for ready icon → click Copy Transcript → read clipboard
- Brittle; depends on UI not changing across point releases. Worth attempting on a test recording first to see if Apple's transcript ever beats Whisper for your audio
- **Note**: this Mac doesn't appear to have Apple Intelligence enabled — would need to test on the M-series Mac mini or iPhone-mirror flow

### B5. `voicememos transcribe --diarize` (HARD; needs additional model)
- Pyannote-audio or whisper-x for speaker diarization
- Output as: `[Speaker 1, 00:12:30] ...` lines
- Useful for interviews (Jon C. Fox, Jeremy call, Toby Grotz, Ruby — many of your long recordings are 2-person)

### B6. `voicememos summarize <selector>` (MEDIUM)
- Pipe transcript into a local LLM (or Claude API) for a 5-bullet summary
- Append summary to top of the .md sidecar under `## TL;DR`
- This crosses into Sage / BBS territory — could become the bridge between Voice Memos and the BBS

---

## C. Watch + automation

### C1. `voicememos watch` — daemon (EASY)
- `fswatch` on `~/Library/Group Containers/group.com.apple.VoiceMemos.shared/Recordings/`
- New `.m4a` lands → run export + transcribe pipeline + Discord ping (via pakettibot file-drop bridge)
- LaunchAgent option for boot-persistent (reuse the homepod-climate plist pattern)

### C2. `voicememos hook --on-record <command>` (EASY)
- Same fswatch underneath, but user supplies a shell command template
- Variables: `{path}`, `{title}`, `{duration}`, `{date}`, `{uuid}`
- Examples:
  - "On every new recording, copy the m4a to NAS"
  - "On every recording > 30 min, kick off Whisper and Discord-ping when done"
  - "On every recording in the morning, append to today's journal markdown"

### C3. Live record from CLI (EASY — `whisp record` already exists)
- `voicememos record --title "Kari Ketonen v3" [--lang fi]`
- Wraps `whisp record` so the audio lands in the vault under the same naming scheme as Apple's own
- Cleaner than opening Voice Memos.app for quick captures
- Could optionally also create the row in Voice Memos' SQLite so the recording shows up in the iOS/Mac app — though that's RISKY (see D2)

---

## D. Write-direct (RISKY — modify the SQLite or filesystem)

Apple's own Voice Memos sync may overwrite or quarantine direct edits.
Always test on a backup of `CloudRecordings.db` first.

### D1. `voicememos rename <selector> "<new title>"` (MEDIUM-RISKY)
- Update `ZENCRYPTEDTITLE`, `ZCUSTOMLABEL`, `ZCUSTOMLABELFORSORTING` in DB
- Likely needs a CloudKit sync trigger for it to push back to iPhone. CoreData persistent history may help; or the `ANSCKMETADATAENTRY` rows need touching
- Safer path: use the AppleScript-via-UI route — open the recording, click title, type new name. Slow but uses Apple's own write paths.

### D2. `voicememos move <selector> --to-folder <name>` (MEDIUM-RISKY)
- Update `ZFOLDER` FK on the recording. ZFOLDER table is empty on this Mac so requires creating one first
- Same caveat: CloudKit may not sync directly-written rows

### D3. `voicememos delete <selector>` (RISKY)
- Tombstone via `ANSCKHISTORYANALYZERSTATE` + delete files
- Strongly prefer using Voice Memos.app's UI delete via `osascript` UI scripting instead
- Or: sidecar-only delete (just remove the export from the vault, leave Apple's data alone) — safer default

### D4. `voicememos import <file.m4a> [--title "..."] [--date YYYY-MM-DD]` (MEDIUM-RISKY)
- Drop an external m4a (e.g. Zoom recording, Audacity export) into Voice Memos
- Two ways:
  1. Use Voice Memos' Import file menu via UI scripting
  2. Direct: copy file to Recordings/, INSERT row into `ZCLOUDRECORDING`, generate a `.composition` and `.waveform` — much harder, undocumented

---

## E. Analysis / cross-tool

### E1. Duplicate detection (EASY)
- Audio fingerprint via `chromaprint` / `acoustid` → group identical or near-identical recordings (you have a few `_1`/`_2` suffixed pairs that look like accidental dupes — `JP8_1`/`JP8_1 2`, `Recording 89`/`Recording 90` near-zero-byte twins, etc.)

### E2. Silence-strip + chapter detection (MEDIUM)
- ffmpeg silencedetect filter → list silent regions
- Use to: trim leading/trailing silence; auto-chapter long recordings (the 25-hour `Uusi äänitys` likely has dozens of silent gaps where it could be split)

### E3. Geo-tag extraction from titles (EASY)
- Titles like "Inkiväärikuja 6", "Kauppakeskus Columbus", "Marjan Mökki", "Sofia-keskus kellot", "Roihuvuorentie", "Putouskuja 6", "Kaivokatu" are place names
- Geocode against Finnish address services → output a GeoJSON of where Esa records
- Heatmap of "where do I record" — feed into the Ray BBS map view

### E4. Title-prefix clustering (EASY)
- Auto-detect numbered series (`Inkiväärikuja 6 N` → "Inkiväärikuja 6" topic with 14 entries)
- Build a topic tree without folders — implicit hierarchy from naming

### E5. Speaker recognition (HARD)
- Build voice prints from transcribed/diarized recordings → identify recurring speakers (Jon C. Fox, Toby Grotz, Jukka Kortela, Jeremy, Ruby, Bryan, Mauri, Lange, Lauri Salo)
- Auto-tag who's in each recording — speeds up search across the LENR / Free-Energy interview archive

### E6. RBI integration (MEDIUM)
- Many recordings are LENR/Free-Energy interviews (Kortela, Grotz, Fox, Mueller, Russell-related). After transcription, route the .txt into the `free-energy` skill's archive intake pipeline so it joins the Tesla / Schauberger / Russell corpus
- Esa→archive flow without manual copy-paste

---

## F. App Intents / Siri / Shortcuts surface

Voice Memos exposes these via App Intents (probed earlier — 41 phrases):

- "Record a Voice Memo named X" → start recording
- "Stop recording"
- "Play my Voice Memo X"
- "Delete Voice Memo X"
- "Create a folder X" / "Delete folder X"
- "Search Voice Memos for X"
- "Change my recording playback setting to X"

### F1. `voicememos siri-trigger <phrase>` (EASY)
- Wrap `osascript -e 'tell application "Shortcuts Events" to run shortcut "X"'`
- Build canned shortcuts that match Apple's Siri phrases — bind to Loupedeck buttons
- Loupedeck button → "Record a Voice Memo called Inkiväärikuja {today}" → instant titled recording

### F2. Shortcuts wrapper (EASY — `bin/shortcut-gen.py` already exists in repo)
- Generate signed `.shortcut` files for the most-used voice-memo workflows: "Record Now", "Latest Transcript to Clipboard", "Show Today's Recordings"
- Auto-install via the existing batch-import.sh

---

## G. Long-game / wishlist

### G1. Voice Memos → Cloudcity BBS pipeline
- Watch daemon (C1) → on new recording → transcribe (B3 routing) → summarize (B6) → publish to BBS open circle (Ray BBS Human Layer)
- Recording becomes a first-class BBS post automatically. The mic becomes Esa's keyboard.

### G2. Apple Intelligence transcript poller
- Once Apple's transcript IS reliably stored to disk (probably Sequoia 15.7+ or macOS 16), re-probe `IntelligenceFlow.Transcript.Datastream` segments. If the format is documented or reverse-engineerable, replace whisp for English audio with Apple's free on-device transcript.

### G3. Transcript-aware search across the whole archive
- Once N transcripts exist, build a Sage-style RAG index. "Find every recording where I talked about Kortela's pyrolysis paper." Returns timestamped clips.

### G4. Auto-import from external recorders
- Zoom H1 / iPhone Voice Memos → AirDrop → Hot folder → Voice Memos vault
- Then transcribe+summarize+publish through the same pipeline

---

## Recommended build order

For a `voicememos-export/` package mirroring `reminders-export/`:

**Phase 1 (one session):**
1. A1 list + filters
2. A2 stats
3. A3 open
4. A4 export-audio (the actual vault export)
5. B1 transcribe single
6. B2 transcribe --all
7. C1 watch daemon (LaunchAgent)

**Phase 2:**
8. A5 pull (force download evicted)
9. A6/A7 cross-reference Calendar/Notes/Reminders
10. C3 record from CLI
11. E1 duplicate detection

**Phase 3:**
12. B3 transcribe --route (model selection)
13. B5 diarize
14. B6 summarize
15. E2 silence-strip / chapters
16. F1/F2 Shortcuts + Siri triggers

**Long-tail / when you ask:**
- D1-D4 write-direct (rename, move, delete, import) — only if the UI-scripting path isn't good enough
- B4 Apple-Intelligence UI scraper (when you have an AI-enabled Mac to test on)
- E5 speaker recognition
- G* BBS integration
