---
name: One button for "Claude talks to me" (server + speech together)
slug: one-button-for-claude-talks-to-me-server-speech-together
kind: feature
confidence: 0.6
updated: 2026-11-08
---

## Summary
Convey feature: features/voicebox-speak-toggle.feature.

## Claims
- Scenario (L55): Default is ON when no state file exists
- Scenario (L61): Enabling starts the server if it is down, then sets Claude talking
- Scenario (L72): Enabling when the server is already up just sets the flag
- Scenario (L79): Disabling silences Claude and cuts current playback
- Scenario (L88): status reports both halves and the effective outcome
- Scenario (L95): toggle does the sensible thing from any state
- Scenario (L103): The AppleToolbox row shows the COMBINED truth in three states
- Scenario (L117): This is NOT the server-side speaker-claim gate
- Scenario (L124): Server detection is by listening port, not a brittle cmdline match

## Relationships
