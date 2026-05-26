# MacBookPro

> Pro portable. Full macOS, full automation surface, runs on battery. The default "I'm at the keyboard" assumption in this skill.

## Role

The primary work surface. When the skill says "the Mac," it usually means this. Apple-silicon (M-series) is the assumed baseline — Rosetta 2 only matters for legacy binaries.

## Automation surface

Full Mac stack — nothing is gated by form factor:

- **AppleScript / JXA / osascript** — every Apple app's scripting dictionary
- **Shortcuts** — full editor + runner
- **Automator** — still works, still legacy, still useful for Folder Actions and Quick Actions
- **App Intents** — Swift-defined intents callable from Shortcuts / Siri / Spotlight
- **Cocoa via Swift** — `xcrun swiftc`, NSStatusItem, Carbon hotkeys, full AppKit
- **Carbon RegisterEventHotKey** — global keyboard shortcuts (see `wiki/concepts/global-keyboard-shortcuts.md`)
- **Vocal Shortcuts** — voice-trigger surface (see `wiki/concepts/vocal-shortcuts-trigger.md`)
- **Folder Actions / FSEvents** — filesystem triggers
- **LaunchAgents** — but watch the container-read gotcha (`feedback_launchd_cannot_read_app_containers.md`)

## Cross-device fabric — outbound from MBP

- **Sidecar** → iPad as second display / drawing tablet
- **Universal Control** → iPad / other Mac as extended cursor
- **AirDrop** → push files to iPhone / iPad / other Mac
- **Handoff** → continue activity on iPhone / iPad
- **Continuity Camera** → use iPhone as webcam / scanner
- **Continuity Markup / Sketch** → annotate via iPhone, lands on Mac
- **AirPlay receive** → MBP can be an AirPlay target (System Settings → General → AirDrop & Handoff)

## Trigger surface — what fires automation here

This device is the **default receiver**, not usually the originator. But it can self-trigger via:

- Time (cron, LaunchAgent calendar interval)
- Filesystem events (FSEvents, Folder Actions)
- App state (Mail rules, Calendar alarms running AppleScripts)
- Hardware (Loupedeck, Stream Deck, Shuttle — see `wiki/entities/loupedeck-guide.md`)
- Lid open / wake / login (LaunchAgent `RunAtLoad`)

## Painpoints specific to portable Macs

- **Lid-closed clamshell** kills the internal display; LaunchAgents that depend on a logged-in GUI may misbehave during sleep transitions
- **Battery-mode throttling** affects long-running render / build jobs — check Low Power Mode state before scheduling heavy work
- **Wi-Fi-only roaming** means Syncthing reachability changes per network; the `mini-up` preflight pattern (`~/.claude/CLAUDE.md`) exists because of this

## Cross-refs

- Loupedeck pairing on portable: `wiki/entities/loupedeck-guide.md`
- TCC permission gotchas: `wiki/concepts/tier-5-backdoor.md`
- Apple Driver's License (this device IS the steering wheel): `wiki/lessons/apple-drivers-license.md`
