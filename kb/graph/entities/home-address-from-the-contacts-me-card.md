---
name: Home address from the Contacts me-card
slug: home-address-from-the-contacts-me-card
kind: feature
confidence: 0.6
updated: 2026-11-08
---

## Summary
Convey feature: features/me-address.feature.

## Claims
- Scenario (L36): "where is my home" routes to the address lookup, not the thermostat
- Scenario (L43): Climate questions still route to the HomePod sensor
- Scenario (L50): The address resolves from the me-card, or by name if none is set
- Scenario (L62): Resolve once, then serve from cache (no repeated Contacts prompts)
- Scenario (L73): The address reads through unstyled (whitelabel passthrough)
- Scenario (L79): It uses Contacts AppleScript, not the network

## Relationships
