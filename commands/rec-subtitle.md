---
description: Transcribe a recording to .srt subtitles (via whisp/Whisper) and optionally BURN them into the video. `/rec-subtitle <video>` → <stem>.srt sidecar (upload to YouTube as captions). Add --burn → <stem>-subtitled.mov with subtitles hard-painted into the picture (Apple-native Core Animation).
allowed-tools: Bash
argument-hint: <video> [--burn] [--srt FILE] [--mic voice.m4a] [--model NAME] [--vocab FILE|--no-vocab] | --fix-srt <file.srt>
---

Run the apple-skill `rec-subtitle` tool on `$ARGUMENTS`.

Use Bash to execute (one call, then stop):

```
/Users/esaruoho/work/apple/bin/rec-subtitle $ARGUMENTS
```

- `/rec-subtitle <video>` → transcribes the audio → `<stem>.srt`. Upload the video to YouTube
  and add this `.srt` as a caption track (soft subtitles — viewers can toggle them).
- `/rec-subtitle <video> --burn` → transcribes if needed, then hard-burns the subtitles into
  `<stem>-subtitled.mov` (white text, black outline, bottom-center; timed per cue). Use for
  platforms without a caption track, or when the captions must be permanent.
- `--srt FILE` uses an existing/edited `.srt` instead of transcribing.
- `--mic <stem>-mic.m4a` transcribes the **voice-only** track (from `rec-audio split`) for the
  cleanest transcript — best when the recording also has loud system audio.
- `--model NAME` picks the Whisper model (default: whisp's own default).
- **Proper nouns are aligned automatically.** `bin/recburn-vocabulary.json` (or
  `~/.config/recburn/vocabulary.json`, or `.recburn-vocabulary.json` beside the recording)
  both biases Whisper (`--initial_prompt`) and sweeps the finished `.srt`, so Paketti /
  Renoise / Lackluster are never "Pucketty" / "Reno" / "Lacklustre". Unlisted mishearings are
  caught by sound (Soundex); real English words are never rewritten.
  `--vocab FILE` uses another vocabulary, `--no-vocab` turns it off.
- `--fix-srt <file.srt>` aligns a transcript you already have, in place (no video needed).
- `--self-test` checks the vocabulary rules headlessly (no media, no Whisper).

Transcription runs Whisper locally via `~/work/whisp/whisp`; burn-in is Apple-native
AVFoundation (video re-encoded). After the command completes, report only the lines it printed.
