---
name: Fleet shows each Mac once, correctly named, and one click screen-shares to it
slug: fleet-shows-each-mac-once-correctly-named-and-one-click-screen-shares-to-it
kind: feature
confidence: 0.6
updated: 2026-11-02
---

## Summary
Convey feature: features/fleet-identity-and-view.feature.

## Claims
- Scenario (L44): A churned hostname no longer splits a Mac into two Fleet cards
- Scenario (L54): Pinning a static HostName ends the mDNSResponder name-conflict storm
- Scenario (L63): Fleet forgets a card whose file was deleted
- Scenario (L73): The Mini probes Hertsi over a static IP, immune to mDNS breakage
- Scenario (L81): Hertsi's card is always titled HertsiMacPro, never MacPro
- Scenario (L89): The Mac Pro is genuinely renamed to HertsiMacPro
- Scenario (L98): fleet-files screen accepts a Machine Card id and picks the right transport
- Scenario (L107): A clickable app screen-shares to a peer in one double-click
- Scenario (L115): Fleet shows a VIEW button on every peer card
- Scenario (L123): AppleToolbox lists a VIEW item per peer under a Screen Share menu

## Relationships
