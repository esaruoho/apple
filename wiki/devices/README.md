# Devices

One page per Apple device **family**, treated as a monolith — `MacBookPro.md`, not `2019-MacBookPro.md`. Specs change every year; the automation surface does not.

## What each page answers

1. **Role** — what this device is for in the lineup
2. **Automation surface** — Shortcuts? App Intents? AppleScript? Siri? HomeKit? Accessibility?
3. **Cross-device fabric** — how it talks to the Mac (Continuity, Handoff, AirPlay, AirDrop, Sidecar, Universal Control, iCloud)
4. **Trigger surface** — can this device *start* automation that lands on the Mac?
5. **Painpoints** — known Apple-way footguns

## Why this matters for the apple skill

The skill is the LLM-driven Automator. Knowing which device can fire which trigger is the difference between "Watch tap → Mac runs a Shortcut" working and silently failing. Every device page is one paragraph of theory + one section of "what you can actually script."

## The lineup (current monoliths)

### Macs

- [MacBookPro](MacBookPro.md) — pro portable
- [MacBookAir](MacBookAir.md) — consumer portable
- [MacMini](MacMini.md) — headless small-form server / always-on
- [MacStudio](MacStudio.md) — pro desktop
- [MacPro](MacPro.md) — workstation
- [iMac](iMac.md) — all-in-one desktop

### iOS / iPadOS

- [iPhone](iPhone.md) — pocket trigger surface
- [iPad](iPad.md) — Sidecar canvas + Shortcuts host

### Wearables / spatial / ambient

- [AppleWatch](AppleWatch.md) — wrist trigger surface
- [AirPods](AirPods.md) — head-gesture trigger + audio routing
- [VisionPro](VisionPro.md) — spatial Shortcuts host

### TV / home

- [AppleTV](AppleTV.md) — living-room Shortcuts target + HomeKit hub
- [HomePod](HomePod.md) — voice surface + climate sensor + HomeKit hub

## Naming convention

CamelCase, no spaces, no year, no generation. The Watch is `AppleWatch.md` whether it's S9, S10, or Ultra 2. The skill cares about the automation surface, not the silicon revision.

## Cross-refs

- Climate sensor pipeline: `wiki/entities/homepod.md` (operational detail) ↔ `wiki/devices/HomePod.md` (device profile)
- iPhone notification pipeline: `wiki/concepts/iphone-notify-pipeline.md` ↔ `wiki/devices/iPhone.md`
- Driver's License lesson: `wiki/lessons/apple-drivers-license.md` (the "what to understand" curriculum) plugs into per-device profiles here
