---
name: On-device dictation button
slug: on-device-dictation-button
kind: feature
confidence: 0.6
updated: 2026-11-08
---

## Summary
Convey feature: features/dictation-button.feature.

## Claims
- Scenario (L43): A fresh engine is idle
- Scenario (L49): On-device recognition is preferred (audio stays local)
- Scenario (L56): AppleBar's button is the real dictation glyph, not a cartoon emoji
- Scenario (L65): Stopping an idle engine is a safe no-op
- Scenario (L72): Tapping the mic authorises, listens, and streams text into the field
- Scenario (L82): Return stops the mic, then runs what was heard
- Scenario (L89): A final result arriving after stop is dropped (no duplicate text)
- Scenario (L97): AppleBar consumes the shared engine, not its own copy (DRY)
- Scenario (L105): AppleToolbox's SpeechDictationController sits on top of the shared engine
- Scenario (L113): Converse is a separate path, not a consumer

## Relationships
