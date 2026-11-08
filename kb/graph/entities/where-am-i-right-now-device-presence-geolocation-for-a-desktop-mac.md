---
name: Where am I right now — device-presence geolocation for a desktop Mac
slug: where-am-i-right-now-device-presence-geolocation-for-a-desktop-mac
kind: feature
confidence: 0.6
updated: 2026-11-08
---

## Summary
Convey feature: features/me-location.feature.

## Claims
- Scenario (L61): the Workspace LAN fingerprint resolves to the Workspace address
- Scenario (L71): no known place → print nothing, exit 1 (caller falls back gracefully)
- Scenario (L79): gateway_mac beats peers beats ssid
- Scenario (L87): --learn captures the current signature into a named place
- Scenario (L95): the Home LAN fingerprint resolves to Home, and the commute partner flips
- Scenario (L106): a named Bonjour device (Time Capsule) is a location signal — lazily browsed
- Scenario (L118): --route resolves the whole route in one call (origin + destination)
- Scenario (L126): commute_to makes "here" generate "there" — the clever-Directions seam
- Scenario (L132): home is a constant, here is a variable — they are different questions

## Relationships
