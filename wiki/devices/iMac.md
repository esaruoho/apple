# iMac

> All-in-one desktop. M-series, integrated 4.5K display, fixed peripherals built-in. Same software stack as every other Mac.

## Role

The "single object on the desk" Mac. Distinguishing feature is the integrated display + camera + speakers + mic, all in one chassis — relevant when scripting display-arrangement, Continuity Camera defaults, or audio-routing.

## Automation surface

Identical to MacBookPro. Every AppleScript, Shortcut, App Intent, Cocoa class works the same.

## Cross-device fabric

Full Continuity cluster member. Notable iMac-specific cases:

- **Built-in camera** is the default Continuity Camera target *unless* an iPhone is nearby and unlocked, in which case macOS may auto-select the iPhone
- **Built-in speakers + AirPlay receive** can both be active; routing precedence matters when scripting audio output
- **Sidecar with iPad** works but is unusual since iMac already has a large display

## Trigger surface

Same as MacBookPro / MacStudio. Because iMac is desk-mounted and almost always on, it's a viable LaunchAgent server like MacMini.

## Painpoints specific to iMac

- **Single integrated display** — extending via Sidecar or external display requires Thunderbolt; scripted display-arrangement assumes a specific topology
- **Fixed camera position** — Continuity Camera (iPhone mounted on iMac top edge) offers higher-quality video than the built-in webcam; if your automation `defaults` Continuity Camera, expect the iPhone to be picked

## Cross-refs

- Display/camera switching specifics: see Continuity Camera in [MacBookPro.md](MacBookPro.md)
- For always-on headless work: [MacMini.md](MacMini.md)
