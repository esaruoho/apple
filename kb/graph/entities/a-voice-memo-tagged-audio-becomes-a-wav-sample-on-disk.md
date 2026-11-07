---
name: A Voice Memo tagged #audio becomes a .wav sample on disk
slug: a-voice-memo-tagged-audio-becomes-a-wav-sample-on-disk
kind: feature
confidence: 0.6
updated: 2026-11-02
---

## Summary
Convey feature: features/voicememo-audio-tag-to-wav.feature.

## Claims
- Scenario (L30): a downloaded memo tagged #audio is exported to WAV
- Scenario (L43): the export fires automatically once a deferred memo downloads
- Scenario (L54): #audio and #process on the same memo both fire
- Scenario (L61): idempotent + atomic

## Relationships
