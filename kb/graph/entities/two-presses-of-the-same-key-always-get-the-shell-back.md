---
name: Two presses of the same key always get the shell back
slug: two-presses-of-the-same-key-always-get-the-shell-back
kind: feature
confidence: 0.6
updated: 2026-11-08
---

## Summary
Convey feature: features/recburn-abort.feature.

## Claims
- Scenario (L38): the second Ctrl-C abandons transcription and exits at once (measured 2026-08-22)
- Scenario (L48): killing the child is not enough — the tree has to go (measured 2026-08-22)
- Scenario (L60): what is kept and what is deleted (measured 2026-08-22)
- Scenario (L71): the escape hatch is announced when it becomes true (2026-08-22)
- Scenario (L79): the watchdog fires when finishWriting never returns (observed 2026-08-22)
- Scenario (L91): an abort must never corrupt the .mov it is abandoning
- Scenario (L100): SIGTERM climbs the same ladder
- Scenario (L107): one press is never destructive
- Scenario (L115): the manifest says so

## Relationships
