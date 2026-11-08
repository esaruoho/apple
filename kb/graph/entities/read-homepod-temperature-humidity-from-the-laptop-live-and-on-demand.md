---
name: Read HomePod temperature + humidity from the laptop, live and on demand
slug: read-homepod-temperature-humidity-from-the-laptop-live-and-on-demand
kind: feature
confidence: 0.6
updated: 2026-11-08
---

## Summary
Convey feature: features/homepod-live-climate.feature.

## Claims
- Scenario (L36): Default read returns the latest synced reading, offline
- Scenario (L44): --live polls the sensor directly via the local Shortcut
- Scenario (L53): --live persists the fresh reading so the default read reflects it
- Scenario (L61): --live falls back to the synced file when it can't read live
- Scenario (L68): /climate in mlx-here surfaces a live reading with zero LLM tokens
- Scenario (L76): quit leaves mlx-here, with or without a slash
- Scenario (L83): `homepod` in the terminal shows the climate (alias repaired)

## Relationships
