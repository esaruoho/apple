---
name: Subtitle a screen recording (.srt sidecar + burn-in)
slug: subtitle-a-screen-recording-srt-sidecar-burn-in
kind: feature
confidence: 0.6
updated: 2026-11-02
---

## Summary
Convey feature: features/rec-subtitle.feature.

## Claims
- Scenario (L33): transcribe → .srt sidecar via whisp (Whisper) (ran live)
- Scenario (L40): --burn hard-paints the subtitles into the video (ran live)
- Scenario (L53): version-safe burn export (Ventura+) (ran live)
- Scenario (L58): --mini routes transcription to the Mac Mini (keeps CPU off this mac)
- Scenario (L68): one-command pipeline — rec --mic --pip --burn
- Scenario (L78): transcription shows progress and elapsed time
- Scenario (L88): burn-in reports its export time
- Scenario (L95): subtitle glyphs keep their counters open (no more muddy a/e) (ran live)
- Scenario (L114): known mishearings are rewritten to the canonical spelling (ran live)
- Scenario (L123): mishearings NOBODY listed are caught by sound (ran live)
- Scenario (L131): ordinary speech is never rewritten (ran live)
- Scenario (L140): the same vocabulary biases Whisper before it decodes
- Scenario (L149): the vocabulary is a file, editable without a rebuild (ran live)
- Scenario (L160): the rules are checked headlessly, so a regression fails the build (ran live)
- Scenario (L174): "Paketti" came back as "Pocket to" and every guard let it through (2026-08-27)
- Scenario (L188): Whisper's own capitalisation is what makes the fix safe (2026-08-27)
- Scenario (L203): list the letters, never the spacings (2026-08-27)
- Scenario (L212): fixing a line once and reporting it twice (caught + fixed 2026-08-27)

## Relationships
