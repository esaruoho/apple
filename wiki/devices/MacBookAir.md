# MacBookAir

> Consumer portable. Same software stack as MacBookPro, lighter chassis, fanless on most M-series. Automation surface is identical.

## Role

The "secondary Mac" — a couch laptop, a travel laptop, a writing-only Mac. Identical software capabilities to MacBookPro; the only differences are thermals, RAM ceiling, and port count.

## Automation surface

**Identical to [MacBookPro](MacBookPro.md).** Every AppleScript, JXA, Shortcut, App Intent, Cocoa class, and Carbon hotkey works the same. macOS makes no automation-surface distinction between Air and Pro.

The only practical caveat: **fanless thermal throttling**. Long-running CPU-pinning workloads (multi-pattern grep loops, video renders, model inference) throttle harder on Air than on Pro. The catastrophic-backtracking-regex incident in `~/.claude/CLAUDE.md` is a category of bug that hurts Air more than Pro.

## Cross-device fabric

Identical to MacBookPro: Sidecar, Universal Control, AirDrop, Handoff, Continuity Camera, Continuity Markup, AirPlay receive.

## Trigger surface

Same as MacBookPro — time, filesystem, app state, hardware controllers, login events.

## Painpoints specific to Air

- **Fanless thermals** — sustained 100% CPU drops clock speed within ~3 min; schedule long jobs for the MacMini instead
- **RAM ceiling** — Air maxes lower than Pro; large in-memory operations (Photos library scans, Spotlight reindex) hit swap earlier
- **Single external display** on entry-level M-series Air — affects multi-monitor automation assumptions

## Cross-refs

- MacBookPro (full automation surface description): [MacBookPro.md](MacBookPro.md)
- Heavy workloads belong on the always-on box: [MacMini.md](MacMini.md)
