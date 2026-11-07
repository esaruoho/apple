---
name: Redact a region of a finished recburn video without re-rendering it
slug: redact-a-region-of-a-finished-recburn-video-without-re-rendering-it
kind: feature
confidence: 0.6
updated: 2026-11-02
---

## Summary
Convey feature: features/recburn-redact.feature.

## Claims
- Scenario (L56): only the keyframe span that contains the frames is re-encoded (real file, 2026-08-13)
- Scenario (L68): the audio track is remuxed, never cut and never re-encoded (real file, 2026-08-13)
- Scenario (L79): a cut point is MEASURED, never computed from timestamps (bug found + fixed 2026-08-13)
- Scenario (L93): the container's own frame count can be a lie (observed 2026-08-13)
- Scenario (L104): the head is cut by frame count, not by -to (bug found + fixed 2026-08-13)
- Scenario (L113): the redaction is gated on FRAME NUMBER, not on time (bug found + fixed 2026-08-13)
- Scenario (L126): never pass both -map 0:v:0 and -map "[vout]" (bug found + fixed 2026-08-13)
- Scenario (L137): segments are joined as MPEG-TS, not MOV (real file, 2026-08-13)
- Scenario (L149): a frame shift is caught even though the counts add up (verified both ways 2026-08-13)
- Scenario (L162): the coverage is a mosaic THEN a blur, not a soft smudge (real file, 2026-08-13)
- Scenario (L173): --find needs no times at all (run live 2026-08-13)
- Scenario (L187): --find samples at FULL resolution and ACCURATE, both for a measured reason (2026-08-13)
- Scenario (L200): the •••• mask is not four bullets (bug found + fixed 2026-08-13)
- Scenario (L210): the first full sweep produced 3 false windows out of 4 (found + fixed 2026-08-13)
- Scenario (L225): the redaction defeats OCR, proven by pointing --find at the output (2026-08-13)
- Scenario (L234): --find prints the sampling gap instead of implying completeness (2026-08-13)
- Scenario (L244): a matched secret is truncated in the report (2026-08-13)
- Scenario (L252): --scan finds WHICH frames, --probe finds WHERE (both run live 2026-08-13)
- Scenario (L264): the source file is never touched (enforced 2026-08-13)
- Scenario (L273): verification is fast enough to always run (measured 2026-08-13)
- Scenario (L283): --method black and --method blur
- Scenario (L295): a window that reaches the first or last frame of the file
- Scenario (L303): a source with no audio track
- Scenario (L309): the presets are measured, not universal
- Scenario (L320): --find is triage, not a guarantee
- Scenario (L329): this redacts the copy, not the past
- Scenario (L340): --find-text hunts a name, not just the built-in secret patterns (2026-08-14)
- Scenario (L352): the splice produces a silent 2-frame A/V drift on some files (FOUND 2026-08-14)
- Scenario (L372): the GOP length is measured, not assumed (2026-08-14)

## Relationships
