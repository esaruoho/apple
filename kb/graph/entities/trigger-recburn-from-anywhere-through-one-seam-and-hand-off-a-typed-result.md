---
name: Trigger recburn from anywhere through one seam, and hand off a typed result
slug: trigger-recburn-from-anywhere-through-one-seam-and-hand-off-a-typed-result
kind: feature
confidence: 0.6
updated: 2026-11-02
---

## Summary
Convey feature: features/recburn-automation-surfaces.feature.

## Claims
- Scenario (L61): the engine emits a typed manifest that round-trips into the app's decoder (contract ran)
- Scenario (L71): on stop the engine writes <stem>.recburn.json and prints its path
- Scenario (L81): the app reads the manifest instead of scraping prose, with a two-level fallback
- Scenario (L91): recburn:// is the single control seam and routes toggle/start/stop (compiled + registered)
- Scenario (L101): Services menu exposes Toggle/Start/Stop, assignable to a global hotkey
- Scenario (L110): App Intents surface Toggle/Start/Stop to Shortcuts + Siri
- Scenario (L119): recburn-url is the portable seam for hardware buttons + shell (installed)
- Scenario (L127): this card adds entrances + an exit, not new capture mechanics
- Scenario (L133): the app persists the completed recording to one stable manifest for chaining
- Scenario (L141): value intents return the recording as chainable Shortcuts values
- Scenario (L151): "Record" is the start action's title (compiled + verified in binary)
- Scenario (L158): recburn-youtube uploads a recording and returns its URL
- Scenario (L169): Publish to YouTube is a first-class chainable action
- Scenario (L179): sane upload defaults — unlisted, timestamp title, category, caption track

## Relationships
