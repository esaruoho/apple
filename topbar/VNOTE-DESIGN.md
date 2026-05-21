# AppleToolbox — Voice Note ("vnote") Design

Status: **design draft** — 2026-05-21
Owner: Esa
Related: `AppleToolbox.swift` (SmartDictation controller), `voice-memos-exporter/`, `notes-exporter/`, `scripts/workflows/quicktime/`

## Problem

Across Apple's surface, audio-of-self capture is fragmented:

| Surface | Audio | Transcript | Destination |
|---|---|---|---|
| System dictation | ✗ thrown away | ✓ inline | wherever cursor is |
| AppleToolbox ⌘D (smart dictation) | ✓ `.caf` buried in `~/.claude/projects/.../audio/` | ✓ inline in chat | chat cwd only |
| Voice Memos | ✓ `.m4a` | partial `tsrp` (English-only) | flat list, no folders |
| Notes attachment | ✓ `.m4a` | ✗ (needs Whisper) | the parent Note |

Missing primitive: **a voice note with a destination folder**, paired audio + transcript, optionally with video. The user picks where it lands; AppleToolbox does the capture; both the inflection-bearing audio and the searchable transcript end up side-by-side in the chosen folder.

## Goal

One button in the AppleToolbox panel. Press → recording starts; press again → recording stops and writes `<folder>/<stamp>__<slug>.m4a` + `.md` sidecar. Folder is chosen once (or per-press from a small saved list). Optional video toggle switches the capture from audio-only to QuickTime movie/screen recording, same destination, same sidecar.

## Non-goals

- Replacing Voice Memos (vnote is local-only, no iCloud sync, no Voice Memos.app surfacing)
- Replacing Notes audio attachments (those stay where they are; `notes-exporter` already handles them)
- Building a new transcription engine — reuse SmartDictation (SFSpeechRecognizer) live, fall back to `whisp` for Finnish

## UI surface

### 1. Panel button row

Add a third recording-related button next to the existing 〰 SmartDictation button:

- `🎙` plain mic — **vnote audio**
- `📹` movie — **vnote video** (toggle; long-press or right-click to pick screen vs movie vs audio-only with screen-share)

States (same visual grammar as SmartDictation):
- OFF — outline icon, no tint
- LIVE — filled icon, `systemRed`
- WRITING — filled icon, `systemBlue` (the ~1-2s window where AVAssetWriter is finalizing the file)

### 2. Destination selector

Three ways to pick the folder, in priority order:

1. **CLI / hotkey arg** — `apple-vnote ~/notes/ideas` (the slash command form, see §6).
2. **Submenu of saved destinations** — `🎙 ▸ Send to ▸ ideas | family | work | scratch | …`. Backed by `~/.config/appletoolbox/vnote-destinations.json`.
3. **Voice-prefix routing** — say "note to ideas: …" → the prefix is stripped, the matched destination is used, the rest is the body. Matcher reuses the Hey Sal phrase-matcher pattern.

Default destination if none specified: `~/notes/inbox/`. Created on first run.

### 3. Output layout

```
<destination>/
└── 2026-05-21/
    ├── 2026-05-21__1542__three-thoughts-on-rbi__a7f3.m4a
    └── 2026-05-21__1542__three-thoughts-on-rbi__a7f3.md
```

Slug = first 6 transcribed words, hyphenated, lowercased, ASCII-folded. `a7f3` = first 4 hex chars of a UUID to disambiguate collisions within the same minute.

Sidecar YAML:

```yaml
---
uuid: "a7f3c2e1-..."
created: "2026-05-21T15:42:08+03:00"
duration_seconds: 47.2
duration_human: "0:47"
destination: "ideas"
source: appletoolbox-vnote
audio: "2026-05-21__1542__three-thoughts-on-rbi__a7f3.m4a"
video: null            # filled in vnote-video mode
codec: "aac"
sample_rate: 48000
channels: 1
device: "MacBook Pro Microphone"
transcript_engine: "SFSpeechRecognizer (live)"
transcript_locale: "fi-FI"
inflection_markers:    # gaps > 1.5s from speech timing
  - { at: 12.4, gap_seconds: 2.1 }
  - { at: 29.0, gap_seconds: 1.8 }
---

Today I want to record three thoughts on RBI.

First, the rhythmic part is not metronomic …

[12.4s · 2.1s pause]

Second …
```

## Architecture

### 4. Audio path — extend SmartDictation, don't fork it

**Decision (2026-05-21): M4A (AAC) + live SFSpeechRecognizer transcript from the same input tap. No CAF.**

Current `SmartDictation` (AppleToolbox.swift:2783+) already:

- Owns `AVAudioEngine` + input tap
- Wires to `SFSpeechRecognizer` for the live transcript
- Writes raw audio to `nextAudioPath` (currently `.caf`)

Changes:

- Add a `mode` field: `.chatDictation` (current behavior) | `.vnote(destination: URL)`
- In `.vnote` mode, write **AVAudioFile with AAC settings** (M4A container, 48k mono, ~64 kbps) — Voice-Memos-compatible, plays in QuickTime, indexed by Spotlight. If AVAudioFile's AAC encoder rejects the tap format, fall back to AVAssetWriter on the same tap — same M4A target.
- When the recognizer emits a finalized segment, append `(text, startSec, endSec)` to an in-memory `[Segment]` buffer. Live transcript is the SOURCE — no second Whisper pass at write-time. Whisper stays available as an opt-in re-transcribe verb for Finnish-heavy notes where SFSpeechRecognizer's quality matters.
- On stop: serialize buffer to `.md`, write sidecar YAML, name files using slug-from-first-segment.

### 4a. Destinations route into existing source-archive folders

**Decision (2026-05-21): vnote video (and audio) routes into the relevant source-archive folder under `~/work/<project>/sources/<topic>/`, not a separate notes silo.**

Esa's work is organized by topic: `~/work/merlib-dump/sources/schauberger/`, `.../tesla/`, `.../russell/`, etc. When recording a thought about Schauberger water-vortex experiments, the M4A + transcript belongs IN the Schauberger source folder — adjacent to the PDFs, scans, and primary sources it relates to. That way later archive passes find the recording without having to cross-reference a separate notes folder.

Destination JSON evolves:

```json
{
  "default": "inbox",
  "destinations": {
    "inbox":       { "path": "~/notes/inbox" },
    "schauberger": { "path": "~/work/merlib-dump/sources/schauberger",
                     "audio_subdir": "voice-notes",
                     "video_subdir": "videos" },
    "tesla":       { "path": "~/work/merlib-dump/sources/tesla",
                     "audio_subdir": "voice-notes",
                     "video_subdir": "videos" },
    "russell":     { "path": "~/work/merlib-dump/sources/russell",
                     "audio_subdir": "voice-notes",
                     "video_subdir": "videos" },
    "apple":       { "path": "~/work/apple/notes" },
    "family":      { "path": "~/notes/family" }
  }
}
```

Per-destination subdir overrides keep the source folder tidy: audio lands in `<dest>/voice-notes/YYYY-MM-DD/`, video in `<dest>/videos/YYYY-MM-DD/`. If no subdir is set (the `inbox` / `family` style destinations), files land directly under the destination path. Voice-prefix routing now reads like archival shorthand: "note to Schauberger: the implosion observation in the May 1934 Stuttgart letter…" lands as `~/work/merlib-dump/sources/schauberger/voice-notes/2026-05-21/2026-05-21__1815__implosion-observation-may-1934__7a2c.m4a`.

### 5. Video path — QuickTime via existing AppleScript (option A)

Two options considered:

| | (A) QuickTime + AppleScript | (B) AVCaptureSession in-Swift |
|---|---|---|
| Lines of new code | ~30 | ~150 |
| Device picker | UI-script QT's chooser | Swift enumerates `AVCaptureDevice.devices` directly |
| Apple-native | ✓ (uses bundled QT Player + sdef) | ✓ (AVFoundation is bundled) |
| File format control | QT's defaults (`.mov`) | full control |
| Failure mode | QT Player X has stripped scriptability (memory: `quicktime_pro_scriptability_cliff`) — `new movie recording` works but stop/save needs UI scripting | none, but more code to maintain |

**Recommendation: A first, B if A proves brittle.** Three existing scripts already work:

- `scripts/workflows/quicktime/quicktime-new-audio-recording.applescript`
- `scripts/workflows/quicktime/quicktime-new-movie-recording.applescript`
- `scripts/workflows/quicktime/quicktime-new-screen-recording.applescript`

vnote-video flow:
1. Pick destination (same selector as audio mode)
2. Tap 📹 → `osascript quicktime-new-movie-recording.applescript`
3. UI-script the red-circle Start button via System Events
4. Tap 📹 again → UI-script Stop, UI-script `⌘S`, type the target filename into the save sheet (Cmd+Shift+G with the destination path, then the slug), Enter
5. Move the resulting `.mov` into `<destination>/<date>/`, write the `.md` sidecar (transcript runs in parallel via SmartDictation on the mic input)

**Device selection**: QT's recording window has a tiny ⌄ next to the red button — UI-scripted via accessibility. For first cut, accept whatever input QT defaults to; add device-picker UI in V2.

### 6. CLI + slash

`bin/apple-vnote` — thin wrapper:

```
apple-vnote                                 # uses default destination, audio mode
apple-vnote ~/notes/ideas                   # explicit destination
apple-vnote --video                         # vnote-video mode
apple-vnote --screen                        # screen recording mode
apple-vnote --list-destinations             # print saved destinations
apple-vnote --add-destination ideas ~/notes/ideas
```

Under the hood it pings AppleToolbox via a Distributed Notification (same channel SmartDictation already uses for ⌃⌥⌘D global hotkey, AppleToolbox.swift:1058). AppleToolbox handles the actual capture so the user sees the panel state change.

Slash: `commands/vnote.md` → shells `$ARGUMENTS` to `bin/apple-vnote`. Zero-roundtrip after the slash.

### 7. Persistence + config

`~/.config/appletoolbox/vnote-destinations.json`:

```json
{
  "default": "inbox",
  "destinations": {
    "inbox":  "~/notes/inbox",
    "ideas":  "~/notes/ideas",
    "family": "~/notes/family",
    "work":   "~/notes/work"
  },
  "locale": "fi-FI",
  "audio": { "format": "m4a", "sample_rate": 48000, "channels": 1, "bitrate": 64000 }
}
```

Created on first run. The submenu in AppleToolbox reads this on every panel open (cheap, ~1KB).

## Apple-native compliance

All pieces are Apple-bundled: AVFoundation, SFSpeechRecognizer, AppleScript, QuickTime Player, System Events, Distributed Notifications. No Homebrew, no pip, no Node. Whisper fallback is opt-in and runs through the existing `whisp` CLI which is already in the user's $PATH.

## Open questions

1. **Inflection markers** — gap timestamps only, or also pitch/energy contour? Gap timestamps are free from SFSpeechRecognizer; contour needs AVAudioEngine analysis. Start with gaps.
2. **Live transcript window** — show transcript in the panel as it's being captured? Useful but eats panel real estate. Default off; toggle in settings.
3. **Per-destination locale** — `~/notes/family` is Finnish, `~/notes/work` is English. Worth per-destination override in the JSON, or global locale + Whisper post-pass for Finnish? Probably the former.
4. **Voice-prefix routing first cut** — exact-match destination names only, or fuzzy? Exact first.
5. **Vault integration** — should vnote outputs auto-link into the Cloudcity vault (`~/work/cc/vault/`)? Probably yes for `ideas`, no for `family`. Per-destination flag.

## Build order (when greenlit)

1. **M1 — audio-only vnote, default destination**
   - Extend SmartDictation with `.vnote` mode + M4A writer
   - Add 🎙 button to panel
   - Hardcode destination = `~/notes/inbox/`
   - Sidecar writer (YAML + transcript)
2. **M2 — destination selector**
   - JSON config + submenu
   - CLI + slash
3. **M3 — voice-prefix routing**
   - Reuse Hey Sal matcher
4. **M4 — video mode**
   - QuickTime AppleScript bridge + UI-scripted stop/save
5. **M5 — vault link-out + per-destination locale**

Each milestone is independently shippable.
