---
description: Game Apple Speech against Whisper on the same audio clip — runs both engines on this machine, times them, prints side-by-side. Usage `/transcribe-bench <audio> [--locale en-US]`.
allowed-tools: Bash
argument-hint: "<audio-file> [--locale en-US]"
---

Compare Apple's on-device Speech against Whisper on one clip.

Use Bash to execute (one call):

```
/Users/esaruoho/work/apple/bin/transcribe-bench $ARGUMENTS
```

Notes:
- Runs `speech-transcribe` (Apple, on-device) + the local `whisp`/`whisper` if present,
  times each, prints both transcripts and a summary.
- Best on a machine with both engines (the Mini). Speech is ~1 s; Whisper is more
  accurate (punctuation/casing) but slower — and its first run pays a model-load /
  download cost, so the very first timing is inflated (warm ≈ 14 s for a short clip).
- See `wiki/concepts/apple-silicon-ml.md`.
