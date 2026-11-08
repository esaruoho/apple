---
name: Capture one application's audio to a .wav without a loopback driver
slug: capture-one-application-s-audio-to-a-wav-without-a-loopback-driver
kind: feature
confidence: 0.6
updated: 2026-11-08
---

## Summary
Convey feature: features/app-audio-record.feature.

## Claims
- Scenario (L49): all-system tap writes a real, non-silent WAV (ran live 2026-07-29)
- Scenario (L60): app scoping really scopes — a silent app yields digital silence while other audio plays (ran live 2026-07-29)
- Scenario (L70): --out is a FILE only if it ends in .wav, otherwise a FOLDER (ran live 2026-07-29)
- Scenario (L82): an app that holds an open stream but renders nothing is called out (ran live 2026-07-29)
- Scenario (L92): teardown is silent, not an error (ran live 2026-07-29)
- Scenario (L100): --list enumerates tappable applications (ran live 2026-07-29)
- Scenario (L107): no --seconds means record until Ctrl-C
- Scenario (L117): recorder's own audio never leaks into the capture
- Scenario (L123): a capture that never received audio fails loudly instead of writing a stub
- Scenario (L157): the picker lists apps and marks who is ACTUALLY making sound (ran live 2026-07-29)
- Scenario (L172): it survives a terminal that can't hide the cursor (ran live 2026-07-29)
- Scenario (L185): arrow keys + Enter produce a .wav (ran live 2026-07-29, driven through a pty)
- Scenario (L196): Enter raises the picked app before the tap opens (logic ran headlessly 2026-07-29)
- Scenario (L211): the meter line is also the clock (ran live 2026-07-29, pty)
- Scenario (L222): stop the capture with a keypress, not just Ctrl-C (ran live 2026-07-29, pty)
- Scenario (L234): "first, then" — record Renoise TO Ableton Live as one gesture (2026-07-29)
- Scenario (L244): the path is handed over as DATA, not scraped from prose (ran live 2026-07-29)
- Scenario (L256): a silent grab is never handed onward (ran live 2026-07-29)
- Scenario (L265): destinations resolve by bundle id or by name, and refusals are admitted (2026-07-29)
- Scenario (L278): combos are remembered — the second time is one keypress (ran live 2026-07-29)
- Scenario (L292): two MIDI buttons — fire a combo with no UI at all (ran live 2026-07-29)
- Scenario (L304): the second MIDI button stops an open-ended capture (ran live 2026-07-29)
- Scenario (L316): every entry path is smoke-tested, including the bare one (ran live 2026-07-29)

## Relationships
