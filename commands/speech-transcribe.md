---
description: On-device speech-to-text via Apple's Speech framework (no Whisper, no network). Usage `/speech-transcribe <audio> [--locale en-US] [--timeout 120]`; `/speech-transcribe --auth` for permission status.
allowed-tools: Bash
argument-hint: "<audio-file> [--locale en-US] [--timeout N]  |  --auth"
---

Transcribe an audio file with Apple's on-device speech recognition.

Use Bash to execute (one call):

```
/Users/esaruoho/work/apple/bin/speech-transcribe $ARGUMENTS
```

Notes:
- Apple-native: `SFSpeechRecognizer` with `requiresOnDeviceRecognition` — no Whisper,
  no pip, no network. Verified ~3 s on a ~12 s clip (M3 Pro), high accuracy.
- TCC-gated: the terminal/app needs "Speech Recognition" in Privacy & Security.
  `--auth` reports/requests status.
- Gotcha (baked into the tool): SFSpeechRecognizer delivers callbacks to the **main
  run loop**, so the CLI spins `RunLoop.main.run()` and exits from the handler —
  blocking on a semaphore deadlocks and yields no result.
- A fast local alternative/complement to whisp (Whisper). See `wiki/concepts/apple-silicon-ml.md`.
