# AppleTV

> Living-room Shortcuts target + HomeKit hub. tvOS, paired to an Apple ID. AirPlay receiver. The "screen the family looks at."

## Role

Three roles in this skill:

1. **AirPlay target** — Mac/iPhone/iPad can push media or full screen mirror
2. **HomeKit hub** — coordinates Home accessories when iPhones/iPads aren't home
3. **Shortcuts host (limited)** — tvOS has Shortcuts, but the editor lives on iPhone/Mac

## Automation surface

tvOS Shortcuts are functional but constrained:

- **Shortcuts on tvOS** — Shortcuts authored on iPhone/Mac sync via iCloud; run on Apple TV from Shortcuts app
- **Siri Remote** — voice surface, runs Shortcuts and App Intents
- **HomeKit / Home app** — Apple TV acts as the always-on hub coordinating scenes, automations, sensor triggers
- **App Intents** for tvOS apps — install on Apple TV, intents sync via App Store
- **No AppleScript, no shell, no FSEvents** — same iOS-style constraint set

## Cross-device fabric

- **AirPlay receive** — Mac/iPhone/iPad can mirror or stream; scripted AirPlay routing on Mac picks Apple TV by name
- **Home app coordination** — Apple TV is the rendezvous point for HomeKit automations when no iPhone is home
- **"Hey Siri"** — Apple TV listens; can be suppressed per-device to avoid the multi-Siri collision
- **Continuity** — there's no Continuity in the laptop-style sense; Apple TV does not Handoff with the Mac
- **Find My** — Apple TV reports location
- **Universal Control** — does not extend to Apple TV

## Trigger surface

- Tap Shortcut in Shortcuts app via Siri Remote
- Siri voice via Siri Remote
- "Hey Siri" (if AppleTV is the active listener)
- HomeKit automation — sunset, geofence, sensor — that runs through this hub
- AirPlay session start/end (visible to source device, not really to Apple TV)

## Painpoints specific to AppleTV

- **Remote Siri target collision** — Apple TV often "wins" the "Hey Siri" race when it's the most recently-active device; disable "Hey Siri on Apple TV" if HomePod should handle it
- **HomeKit hub election** — if multiple hubs (Apple TV, HomePod, iPad) are present, Apple decides which is primary; you can see this in Home app → Settings, but you can't force it programmatically in a stable way
- **No file-drop pipeline** — the Syncthing-default channel doesn't extend here; Apple TV is not a target for the apple skill's file-bridge work
- **App Store on tvOS** is its own catalog — App Intents you want must be installable as a tvOS app

## Cross-refs

- HomePod is the other HomeKit hub: [HomePod.md](HomePod.md)
- AirPlay routing from Mac: [MacBookPro.md](MacBookPro.md), [iMac.md](iMac.md)
- HomeKit / Home automation is mostly out of this skill's current scope but lives here when surfaced
