# VisionPro

> Spatial Shortcuts host. visionOS, eye + hand tracking, Mac Virtual Display receiver. The first Apple device where Shortcuts run in 3D space.

## Role

Two roles in this skill:

1. **Mac Virtual Display target** — the Mac's screen rendered as a floating window in visionOS; effectively a wireless Sidecar with infinite canvas
2. **Spatial Shortcuts host** — visionOS Shortcuts run as windowed apps; App Intents drive immersive experiences

VisionPro is included here for completeness even if Esa doesn't own one; the skill should know what to do if/when one shows up.

## Automation surface

visionOS Shortcuts are a superset of iPadOS Shortcuts, with spatial-specific actions:

- **Shortcuts on visionOS** — sync via iCloud from iPhone/Mac, runnable from Home View, Siri, Control Center
- **App Intents** for visionOS apps, with spatial-specific parameters (volumetric vs windowed)
- **Mac Virtual Display** — Mac's full screen as a floating window; Mac side is just an AirPlay-style receiver pairing, no Mac-side scripting needed
- **Personal Automations** — same trigger catalog as iPhone (time, location, Focus, etc.)
- **Eye + hand gestures** — system-level UI, not user-scriptable in the Shortcuts sense
- **No AppleScript, no shell** — declarative-only, same as iOS

## Cross-device fabric — VisionPro ↔ Mac

- **Mac Virtual Display** — Mac mirrors into VisionPro as a floating window; bidirectional input via keyboard/trackpad
- **Universal Clipboard** — copy Mac, paste VisionPro
- **Handoff** — Mail, Safari, Notes continue from Mac to VisionPro
- **AirDrop** — bidirectional
- **Continuity Camera / Continuity Markup** — limited support
- **iCloud sync** — same as every other device

## Trigger surface

- Pinch gesture on Home View Shortcut tile
- Siri voice
- Personal Automation (iPhone-paired)
- Focus mode transition
- App Intent surfaced contextually in Smart Stack-equivalent

## Painpoints specific to VisionPro

- **Mac Virtual Display is single-Mac-only** — you can't extend it like multi-monitor
- **No keyboard for Shortcuts editing on-device** — author on iPhone/Mac, run on VisionPro
- **Battery + thermals** — long-running automations drain the external battery quickly
- **Persona / camera** automations are gated by privacy review
- **visionOS catalog is sparser than iOS** — App Intent availability per app is uneven

## Cross-refs

- Mac side of Virtual Display: [MacBookPro.md](MacBookPro.md)
- For "spatial computing for Esa's workflow," this is mostly aspirational until a Vision Pro lands on the desk
