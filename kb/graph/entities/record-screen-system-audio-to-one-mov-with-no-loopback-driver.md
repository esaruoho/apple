---
name: Record screen + system audio to one .mov with no loopback driver
slug: record-screen-system-audio-to-one-mov-with-no-loopback-driver
kind: feature
confidence: 0.6
updated: 2026-11-08
---

## Summary
Convey feature: features/screen-audio-record.feature.

## Claims
- Scenario (L58): single-app audio isolation captures screen + only that app's sound (ran live)
- Scenario (L69): Ctrl-C stops cleanly and finalizes a playable file (ran live)
- Scenario (L79): --list enumerates displays and audible apps (ran live)
- Scenario (L87): whole-display capture with all system audio
- Scenario (L95): optional microphone as a second audio track
- Scenario (L104): --out omitted writes into the CURRENT folder (ran live)
- Scenario (L117): rec is the one-word terminal launcher (ran live)
- Scenario (L127): AppleToolbox 🧰 ▸ Record Screen & Audio is a start/stop toggle
- Scenario (L142): mic toggles on/off live during a recording via SIGUSR1 (ran live)
- Scenario (L153): an unused mic track does not break finalization (ran live)
- Scenario (L161): --reveal opens the file in Finder on finalize (ran live)
- Scenario (L169): AppleToolbox ⌃⌥⌘R start/stop with a Sound-only vs Sound+Mic chooser
- Scenario (L181): AppleToolbox ⌃⌥⌘M toggles the mic live during a recording
- Scenario (L191): --pip bakes the webcam into a corner as a circle (ran live)
- Scenario (L200): --burn runs the whole pipeline in one command
- Scenario (L209): on-stop summary reports the recording length and mic status (ran live)
- Scenario (L220): start banner states plainly whether the mic is recording (ran live)
- Scenario (L227): q + Enter stops the recording as an alternative to Ctrl-C
- Scenario (L235): Sequoia re-prompts screen-recording permission
- Scenario (L241): The terminal says when frames are being dropped, and names the thief

## Relationships
