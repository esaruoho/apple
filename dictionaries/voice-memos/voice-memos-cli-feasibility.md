# Voice Memos — CLI Feasibility Answers

> 2026-05-07. Probed live on this Mac (macOS 15.6.1, 392 recordings).
> Answers three concrete questions about a `voicememos` CLI.

## Q1. `voicememos --list` (lengths, names, locations) — **YES, easy**

All 392 recordings are indexed in:
```
~/Library/Group Containers/group.com.apple.VoiceMemos.shared/Recordings/CloudRecordings.db
```

One SQL query gives everything:
```sql
SELECT
  datetime(ZDATE+978307200,'unixepoch')             AS date_iso,
  printf('%6.1fs', ZDURATION)                       AS duration,
  COALESCE(ZENCRYPTEDTITLE, ZCUSTOMLABEL, '?')      AS title,
  ZPATH                                             AS file,
  ZUNIQUEID                                         AS uuid,
  CASE WHEN ZEVICTIONDATE IS NULL THEN 'local'
       ELSE 'cloud-only' END                        AS storage
FROM ZCLOUDRECORDING
ORDER BY ZDATE DESC;
```

**Title-column gotcha**: `ZCUSTOMLABEL` often holds the system-default name
(timestamp like `"2026-05-07T10:36:26Z"` or `"New Recording 18"`). The
human-edited title is in `ZENCRYPTEDTITLE` (column is misnamed — plaintext)
and mirrored to `ZCUSTOMLABELFORSORTING`. Always prefer
`ZENCRYPTEDTITLE` first.

Audio file lives at:
```
~/Library/Group Containers/group.com.apple.VoiceMemos.shared/Recordings/<ZPATH>
```
(327 of the 392 are on local disk; 65 are evicted/cloud-only.)

Permission: process needs **Full Disk Access** to read the Group Container.
Terminal already has it on this Mac.

## Q2. `voicememos --whisper <recording>` — **YES, trivial wrapper around `whisp`**

`whisp` is already installed at `~/work/whisp/whisp` and accepts m4a:

```bash
whisp ~/Library/Group\ Containers/group.com.apple.VoiceMemos.shared/Recordings/20260507\ 133626.m4a
whisp --en --model turbo "<path>.m4a"
whisp --fi "<path>.m4a"          # Esa speaks Finnish too
```

A `voicememos --whisper` flag would just need to:
1. resolve the recording (by UUID prefix, title substring, index, or "latest")
2. shell out to `whisp` with the m4a path
3. write the .txt next to the m4a in the export vault
4. record the transcript path back into `.state.json` so re-runs skip done

## Q3. Apple's auto-generated English transcripts — **YES, embedded in the m4a trailer**

> **Updated 2026-05-08.** Initial probe missed the storage location and
> reported "no transcript archive exists". Second probe of the m4a tail
> bytes turned up the actual format. Below is the corrected answer; the
> historical (negative) findings follow at the end for the record.

### Where they live

Each m4a that has a transcript carries a `tsrp` 4-byte ASCII marker
followed by a JSON object, appended after the audio data. Structure:

```json
{
  "locale": {"identifier": "en_US@rg=fizzzz", "current": 1},
  "attributedString": {
    "attributeTable": [{"timeRange": [9.9, 19.14]}, ...],
    "runs": ["text fragment", 0, " more text", 1, ...]
  }
}
```

`runs` alternates `text_str, attribute_index, text_str, attribute_index, ...`.
Each `attribute_index` looks up a `timeRange` in `attributeTable`. The
even-indexed entries concatenate to the full transcript text.

### How to find which recordings have one

```sql
SELECT ZUNIQUEID, ZFLAGS, ZPATH, ZCUSTOMLABEL
FROM ZCLOUDRECORDING
WHERE (ZFLAGS & 0x08) != 0;
```

ZFLAGS bit 3 (mask 0x08) is the "has transcript" bit. Live verified
against 13 recordings on this Mac (7 from 2026 made on iPad, 6 older
interviews). Cross-checked against the on-disk `tsrp` byte marker —
matches exactly.

### Implementation

`voice-memos-export transcripts --extract --print "<selector>"` parses
the trailer in <50ms even for the 25-hour file. Output is line-broken
on >2 s gaps with `[MM:SS]` timestamps.

### Quality caveat

Apple's transcript engine on macOS 15.6.1 is **English-only** and
performs poorly on Finnish-mixed speech. The 13-minute "FinnLines"
recording (Finnish) yields 541 chars of fragmented half-recognised text.
For Esa's archive, Whisper with `--fi` is the practical path. Apple's
embedded transcripts are useful primarily for inventory comparison and
(eventually) for diff-quality benchmarking when Apple's engine improves.

### Original (incorrect) answer for the record

Voice Memos.app on macOS 15.6.1 **has transcription wired in** — confirmed
by symbols in the binary:
```
RCLiveTranscription
RCCopyTranscriptActivity
TranscriptViewCoordinator
_beginFileTranscriptionIfNeeded
_displayTranscriptAvailableIcon
shouldShowTranscriptionActivity
```

But on this Mac, **none of the 392 recordings has a stored transcript** I can
locate:

- ❌ No `transcript`/`speech` column in `CloudRecordings.db` schema.
- ❌ No transcript files in the Recordings/ directory (only `.m4a`,
  `.waveform`, `.composition` bundles, CloudKit asset cache).
- ❌ `.composition` bundles contain only a `manifest.plist` referencing the
  m4a — no transcript blob.
- ❌ `~/Library/Accessibility/com.apple.RTTTranscripts.sqlite` is for
  Real-Time Text (TTY/FaceTime captions), not Voice Memos.
- ❌ `~/Library/Biome/databases/IntelligenceFlow.Transcript.Datastream.Indexes/`
  contains only **bookmark/index tables** (datestamp + eventId pointers) —
  the actual transcript text isn't here.
- ❌ `~/Library/Biome/streams/restricted/IntelligenceFlow.Transcript.Datastream/`
  exists but contains opaque segment files (`local/768217736818796`,
  `local/tombstone/768852392243855`) — not human-readable, no documented
  parser.

**Why nothing is stored**:
Voice Memos transcription is **opt-in per-recording**. The user has to tap
"Transcribe" on each memo in the app. Even after that, evidence suggests
the transcript is held in a private cache (or regenerated live each time
the transcript pane is opened) rather than persisted as a file the user
can grep.

**Three practical conclusions**:

1. **No bulk export of Apple's transcripts is possible** without driving
   the Voice Memos UI itself (UI scripting, simulating the Transcribe tap,
   then `RCCopyTranscriptActivity` → clipboard → save). That is doable but
   slow and brittle (one-recording-at-a-time UI automation).
2. **Whisper via `whisp` is the practical path** for any bulk transcript
   archive. We control the model, language hints (Finnish/English/Farsi),
   hallucination filtering, and we keep the .txt files alongside the m4a.
3. **If/when Apple does start persisting transcripts to disk**, the
   `IntelligenceFlow.Transcript.Datastream` segments are where to look
   first — re-probe after each macOS point release.

## Recommended `voicememos` CLI surface

```
voicememos list [--json] [--since YYYY-MM]      # query DB, no copy
voicememos export --all [--include-evicted]      # vault-mode like reminders-export
voicememos transcribe <selector> [--lang fi|en]  # whisp wrapper
voicememos transcribe --all                      # batch transcribe vault
voicememos play <selector>                       # open in QuickTime / Voice Memos
voicememos status
```

Selector grammar: `<selector>` accepts UUID prefix (`2EC8B`), title
substring (`"Mauri"`), date (`2026-05-07`), index (`#0` = latest), or
`latest` keyword.

Whisper output goes alongside the copied m4a in the vault, named
`<same-stem>.txt`. State file tracks per-recording: copied?, transcribed?,
which whisper model, language.
