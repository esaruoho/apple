---
name: 0003-on-device-dictation
slug: 0003-on-device-dictation
kind: feature
confidence: 0.6
updated: 2026-11-08
---

## Summary
Convey feature: principles/0003-on-device-dictation/intent.feature.

## Claims
- Scenario (L47): A fresh engine is idle
- Scenario (L53): On-device recognition is preferred (audio stays local)
- Scenario (L60): AppleBar's button is the real dictation glyph, not a cartoon emoji
- Scenario (L69): Stopping an idle engine is a safe no-op
- Scenario (L76): Tapping the mic authorises, listens, and streams text into the field
- Scenario (L86): Return stops the mic, then runs what was heard
- Scenario (L93): A final result arriving after stop is dropped (no duplicate text)
- Scenario (L101): AppleBar consumes the shared engine, not its own copy (DRY)
- Scenario (L109): AppleToolbox's SpeechDictationController sits on top of the shared engine
- Scenario (L117): Converse is a separate path, not a consumer

## Relationships
