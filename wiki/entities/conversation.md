# Conversation — Live-Transcribing Provenance-Tracked Text Editor

**Status:** Architecture draft 2026-05-27. Pre-MVP. **Doctrine reconfirmed 2026-05-27 by ENVOY review** — the architecture below is the local-first half of ENVOY Livefile. See `~/work/converse/DOCTRINE.md` for the compatibility doctrine and `~/work/apple/wiki/concepts/envoy-foundry-compatibility.md` for the general principles that apply to all chassis tools.

**Core sentence:** *The transcript is a view. The event log is the document.*

**One-line:** Shift-Cmd-D opens a text editor that records audio, transcribes it live (M3 Pro = 11× realtime via mlx-whisper), and writes the transcript at a "live edge" while you edit anywhere else without collision. Every character in the document knows where it came from — mic, keyboard, paste, import. Git-versioned from instant zero.

## The category

This is not Voice Memos + post-hoc transcribe. It's the inverse: **a text editor whose document grows from the microphone while you work in it.**

It's also not a stenographer's tool. The microphone produces one stream of provenance; the keyboard produces another; the clipboard produces a third. The document is a merge of all three, with every span attributed to its source. A reader (or a future replay) can see at a glance what was spoken, what was typed, what was pasted in.

## Trigger

- **Shift-Cmd-D** — global Carbon hotkey registered by AppleToolbox.
  - First press: start a session (create session dir, open editor window, start recording + worker).
  - Second press: stop the session (flush last chunk, close audio file, finalize git, save).
- App is `Conversation.app`. Single window per session. Multiple sessions can run concurrently (each gets its own window + session dir + worker).

## Session file structure

Every session is a directory under `~/work/conversation/sessions/`:

```
~/work/conversation/sessions/2026-05-27-1432-aalto-32people/
├── manifest.json           — session metadata (start, end, sample rate, hotkey, host, app version)
├── audio.m4a               — canonical full-fidelity recording (the "voice memo")
├── transcript.md           — readable markdown document with provenance markers
├── provenance.jsonl        — append-only event log (every mutation, every source)
├── chunks/
│   ├── chunk-000001.wav    — 6-second rolling-window chunks for the worker
│   ├── chunk-000002.wav
│   └── ...
├── worker.log              — mlx_whisper daemon stdout/stderr
└── .git/                   — versioned from session start
```

The session dir IS the document. A reader who finds it in the filesystem in 2030 has audio + transcript + complete edit history + provenance, all in one place, all in human-readable formats.

### `manifest.json` (one per session)

```json
{
  "session_id": "2026-05-27-1432-aalto-32people",
  "started_at": "2026-05-27T14:32:11+03:00",
  "ended_at": null,
  "host": "MacBookPro-M3",
  "app_version": "0.1.0",
  "audio": { "format": "m4a", "sample_rate": 48000, "channels": 1 },
  "whisper": { "model": "mlx-community/whisper-large-v3-turbo", "language": "auto" },
  "chunk_seconds": 6,
  "chunk_overlap_seconds": 1,
  "speakers": []
}
```

### `transcript.md` (the readable document)

Standard markdown. Provenance is encoded as HTML-comment markers that the editor parses but a plain markdown reader ignores:

```markdown
<!--prov:mic:chunk=000001:t=0.0-5.8:speaker=unknown-->
Tervetuloa Aalto-yliopistoon. Tänään puhumme...
<!--/prov-->

<!--prov:keyboard:t=2026-05-27T14:33:02-->
[note to self: ask about the lambda parameter]
<!--/prov-->

<!--prov:paste:source=safari:t=2026-05-27T14:34:15-->
> The eigenvalue equation reduces to...
<!--/prov-->
```

When opened in any markdown reader (Obsidian, GitHub, plain `cat`), the provenance comments are invisible and the content reads cleanly. When opened in Conversation, the editor lifts the markers into a sidebar / underline overlay.

### `provenance.jsonl` (the event log)

Append-only. One JSON event per line. This is the **source of truth for what happened** — the markdown file is derived from it and could be re-rendered from scratch.

```json
{"t":"2026-05-27T14:32:11.001+03:00","op":"session_start","session_id":"2026-05-27-1432-aalto-32people"}
{"t":"2026-05-27T14:32:17.412+03:00","op":"mic_chunk_pending","chunk":1,"t_start":0.0,"t_end":5.8,"text":"Tervetuloa Aalto-yliopistoon...","speaker":"unknown"}
{"t":"2026-05-27T14:32:24.108+03:00","op":"mic_chunk_committed","chunk":1,"range":[0,142]}
{"t":"2026-05-27T14:32:31.220+03:00","op":"keyboard_insert","range":[143,143],"text":"[note to self: ask about the lambda parameter]"}
{"t":"2026-05-27T14:33:02.901+03:00","op":"paste","range":[189,189],"text":"> The eigenvalue equation reduces to...","source_hint":"safari"}
{"t":"2026-05-27T14:33:45.001+03:00","op":"speaker_assign","range":[0,142],"speaker":"prof_kortela"}
{"t":"2026-05-27T14:35:01.001+03:00","op":"correction","range":[55,68],"old":"Aalto-yliopistoon","new":"Aalto-yliopiston","author":"keyboard"}
```

Every event has timestamp, operation, range, and source. The full document at any point in time is the result of replaying events 0..N. This is also what powers undo/redo, time-travel, and provenance highlighting.

### Git versioning

`git init` at session start. Auto-commit triggers:

- **chunk_committed** — every time a mic chunk transitions from pending to committed (~every 5-6s during active speech). Commit message: `chunk NNNN @ MM:SS committed`.
- **idle_pause** — 10s of no keystrokes and no mic input. Commit message: `idle pause @ MM:SS`.
- **manual_save** — Cmd-S. Commit message: `manual save @ MM:SS`.
- **session_end** — Shift-Cmd-D second press. Commit message: `session end (duration MM:SS)`.

The commit contains `transcript.md` + `provenance.jsonl` + `manifest.json`. (Audio is gitignored — too large and immutable; it's the same file as on disk.)

`git log` IS the session history. `git diff <hash1> <hash2>` shows exactly what changed between any two checkpoints. A user who said "I want to see what the transcript looked like 3 minutes ago" gets it via `git checkout`.

## Provenance model

Every character in `transcript.md` has exactly one source:

| Source | When | Marker |
|---|---|---|
| `mic` | Whisper transcribed it from audio chunk N | `<!--prov:mic:chunk=N:t=a-b:speaker=X-->` |
| `keyboard` | User typed it | `<!--prov:keyboard:t=ISO-->` |
| `paste` | User pasted from clipboard | `<!--prov:paste:source=HINT?:t=ISO-->` |
| `import` | User dragged a file in / used File→Insert | `<!--prov:import:path=PATH:t=ISO-->` |
| `correction` | User edited a mic-segment (replaces a `mic` span) | `<!--prov:correction:replaces=mic:chunk=N:t=ISO-->` |
| `system` | Conversation itself wrote it (timestamps, speaker labels, separators) | `<!--prov:system:t=ISO-->` |

**Why corrections are tracked separately:** if Whisper got "yliopistoon" wrong and you fix it to "yliopiston", the original mic source is preserved in the event log AND the new span is tagged as a correction. The transcript reads cleanly, but the provenance sidebar shows "user-corrected from mic transcription". Reviewing the audio against the transcript stays honest.

## Live-edge editor model

NSTextStorage owns the document. A **live-edge marker** (NSRange) tracks the tail. New transcript text only ever inserts at the live-edge, never elsewhere. Two states for the tail:

- **Pending** — the most recent chunk's text, rendered in faint italic. May be revised on next worker pass (whisper has 1s overlap context).
- **Committed** — older than the overlap window. Locked from the worker side. User can still edit it; that becomes a `correction` event.

The user's cursor is fully independent of the live-edge. Type, paste, select, copy anywhere. The worker thread only mutates the live-edge range, on the main thread, via `NSTextStorage.replaceCharacters(in:with:)`. Zero collision with user edits.

## Multi-speaker

Whisper does not diarize. For MVP:

1. Each mic chunk is tagged `speaker=unknown` on creation.
2. User can assign a speaker to any range via menu / hotkey: select text → Speaker → Choose existing or "New speaker…". Assignment writes a `speaker_assign` event to provenance.jsonl and updates the markdown marker.
3. Once a speaker is named, all future mic chunks default to "same speaker as previous" until the user changes it (toggle via hotkey).

Post-MVP: optional `pyannote` post-pass over `audio.m4a` after session end. Produces speaker turns by timestamp; we backfill `speaker_assign` events by matching audio timestamps to chunk ranges. `pyannote` is third-party — it lives as an OPTIONAL post-process, not in the live path. The session works without it; this is additive.

## Audio capture

Single Swift process using `AVAudioEngine`:

- Tap `inputNode`'s output bus
- Sink A: continuous `AVAudioFile` writer → `audio.m4a` (AAC, 48kHz mono). Never read by anything else during the session.
- Sink B: rolling buffer flushes every 6s with 1s overlap into `chunks/chunk-NNNNNN.wav` (PCM 16k mono, the format Whisper expects). Emits the chunk path on a Unix domain socket to the worker.

Apple-native, no third-party dependencies for the audio path.

## Hot worker daemon

**Critical detail:** `mlx_whisper` as a one-shot CLI loads the model on every call (~3-5s). That kills live mode. The worker MUST be a long-lived Python process that loads the model once.

Python daemon (`conversation_worker.py`, stdlib + mlx-whisper only):

```python
import mlx_whisper, json, sys
model = mlx_whisper.load_models.load_model("mlx-community/whisper-large-v3-turbo")
prior_tail = ""
for line in sys.stdin:
    chunk_path = line.strip()
    result = mlx_whisper.transcribe(chunk_path, path_or_hf_repo=model, initial_prompt=prior_tail, ...)
    print(json.dumps({"chunk": ..., "text": result["text"], "segments": result["segments"], ...}), flush=True)
    prior_tail = result["text"][-200:]
```

Reads chunk paths from stdin, writes JSON results to stdout. Single process per session. At 11× realtime, a 6s chunk transcribes in ~0.55s — comfortably ahead of audio arrival.

## Stitcher

Tiny Python (stdlib only) between worker and editor. Reads worker JSON, produces patch ops:

- `{"op": "append_pending", "text": "..."}` — when a new chunk's result arrives, append to live-edge as pending.
- `{"op": "revise_pending", "text": "..."}` — when overlap with prior chunk suggests a revision.
- `{"op": "commit_pending", "range": [a,b]}` — when pending text ages out of the overlap window.

Patches are sent to the editor over a Unix domain socket at `<session_dir>/editor.sock`. The editor applies them on the main thread.

## MVP scope (smallest working version)

**The smallest thing I can build that demonstrates the loop.** Everything below ships in v0.1.

- [ ] Swift `Conversation.app` with a single NSTextView window
- [ ] Shift-Cmd-D starts a session: creates session dir, opens window, begins recording
- [ ] AVAudioEngine writes `audio.m4a` continuously
- [ ] Chunk emitter writes `chunks/chunk-NNNNNN.wav` every 6s with 1s overlap
- [ ] Hot Python worker daemon transcribes chunks, emits JSON
- [ ] Stitcher sends patches; editor appends to live-edge with pending → committed visual states
- [ ] User can type/paste/edit anywhere in the doc without collision
- [ ] Every mutation logged to `provenance.jsonl` (mic, keyboard, paste)
- [ ] `transcript.md` rewritten on every mutation (derived from event log)
- [ ] `git init` at session start, auto-commit on chunk_committed + idle_pause + Cmd-S + session_end
- [ ] Shift-Cmd-D second press cleanly closes the session

**Out of MVP, on the roadmap:**

- Multi-speaker UI (assign / toggle / pyannote post-pass)
- Provenance sidebar (visual underlines per source)
- Time-travel view (`git log` browser inside the app)
- Re-transcribe an existing audio.m4a (offline rebuild)
- Export to plain markdown (provenance stripped)
- Cmd-Shift-C "copy with provenance" (selection + source annotations)
- Multiple concurrent sessions (multiple windows, multiple workers)
- Whisper model selector (turbo vs large-v3 quality/speed tradeoff)

## Why this matters

The Aalto example is the proof: 32 people, two professors, equations and formulas mile-a-minute. Voice Memos captured the audio. Post-hoc transcription captured the text. Neither captured **the thinking that happened in the room** — the note you would have typed to yourself, the paragraph you would have pasted into a chat to a colleague, the formula you would have copied into a calculator.

Conversation makes the editor present in the room while the conversation is happening, and the conversation present in the editor while you work. The merger has been possible since M3 Pro shipped mlx-whisper at 11× realtime. It just hadn't been built yet.

## Companion entries

- See `wiki/concepts/global-keyboard-shortcuts.md` for the Carbon hotkey registration path (Shift-Cmd-D wiring).
- See `wiki/entities/appletoolbox.md` for the LaunchAgent / menu-bar surface this hangs off.
- See `wiki/concepts/clipboard-rich-text.md` for paste-source-hint detection (Safari, Mail, etc.).
- See `wiki/concepts/finder-tag-pipeline.md` for the chassis pattern (trigger → worker → result) this follows.
