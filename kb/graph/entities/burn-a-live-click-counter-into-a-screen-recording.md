---
name: Burn a live click counter into a screen recording
slug: burn-a-live-click-counter-into-a-screen-recording
kind: feature
confidence: 0.6
updated: 2026-11-08
---

## Summary
Convey feature: features/recburnclick.feature.

## Claims
- Scenario (L44): counting clicks needs NO event tap and NO Accessibility prompt (probed live 2026-07-29)
- Scenario (L55): the number is really in the pixels (ran live 2026-07-29)
- Scenario (L66): corner and label are honoured (ran live 2026-07-29)
- Scenario (L73): plain `rec` is unchanged (ran live 2026-07-29)
- Scenario (L81): the counter goes UP as you click
- Scenario (L96): --clicks composes with --pip and --mic
- Scenario (L104): recburnclick inherits RECBURN's settings, not rec's (ran live 2026-07-29)
- Scenario (L114): a chained wrapper can be subtracted from (ran live 2026-07-29)
- Scenario (L122): the click counter is a RecBurn.app menu setting with its own corner
- Scenario (L137): the counter can be zeroed mid-recording (ran live 2026-08-10)
- Scenario (L150): the counter really does go UP on real clicks (observed live 2026-08-10)
- Scenario (L159): any trigger can fire the reset — it is a signal, not a keystroke (ran live 2026-08-10)
- Scenario (L170): ⌃⌥⌘Space zeroes the counter from anywhere

## Relationships
