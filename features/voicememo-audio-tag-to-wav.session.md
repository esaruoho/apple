# Session — Voice Memo #audio → .wav sample

## How to get back
- Transcript: this Claude Code session, project `~/work/convey` (session named "audio-tweak"), 2026-06-09.
- Resume: `claude --resume <id>` (id not captured at write time — find via `/sessions`).
- Real date: 2026-06-09, ~14:00–14:30 EEST.

## The request (verbatim intent)
Esa: "i licensed a system #audio — this is a hashtag in Voice Memos, that should
result in the audio being turned to .wav and slammed to
~/Music/samples/VoiceMemos/yyyy-mm-dd-hh-mm-ss-name.wav okay?"
Later, ordering: "first audio-to-wav, then mini duplicate workers … and then
unblock the perheneuvola and the two files with #audio on them."

## Decisions & why
- **Where it lives.** Two voice-memo submitters exist: a Python
  `mediabank/bin/voicememo-watcher.py` (DISABLED — `.disabled.*.plist`, no state
  file) and the Swift `VoiceMemoPipeline` in `topbar/AppleToolbox.swift` (LIVE —
  state updated today, it submitted Perheneuvola at 10:20). Built #audio into the
  LIVE Swift one.
- **Separate output, not a whisp job.** #audio does NOT go to whisp-inbox. It is
  its own branch: transcode → ~/Music/samples/VoiceMemos. So the SQL was widened
  to match `#process OR #audio`, and the row loop branches per-tag (a memo with
  both fires both).
- **Dedup in its own file** (`voicememo-audio-exports.json`) so it never collides
  with the Submission Codable schema in voicememo-pipeline.state.json.
- **Defer, don't fail, when iCloud-only.** Both real #audio memos ("Vuosaaren
  kartano", 2026-06-04) have ZLOCALDURATION 0.0 / empty ZPATH → exportAudio
  returns false and retries each poll. No error. They export automatically once
  downloaded.
- **Format:** `ffmpeg -c:a pcm_s16le` = 16-bit PCM WAV preserving native rate +
  channels (sampler-ready). Timestamp = recording's own ZDATE in LOCAL time.
  Slug strips all hashtags.

## Verification
- AppleToolbox.swift compiled + codesigned + installed + relaunched (build.sh).
- Pipeline log: new binary up at 11:25:38Z, `poll: matched=21` (up from 18–19 —
  the #audio rows are now matched), `submitted=0 (all already known)`.
- Smoke-tested the exact ffmpeg command on a real downloaded memo → valid
  `RIFF WAVE, 16-bit PCM, 44100 Hz`. Samples dir creatable + writable.

## Honest grade
- WAV transcode + naming + dir: @hw-verified (smoke test).
- End-to-end on a real #audio tag: @untested-on-real-tag — blocked purely on the
  iCloud download of the two Vuosaaren-kartano memos (Task 4). The deferral path
  is exercised live (matched=21, no export, no error).
