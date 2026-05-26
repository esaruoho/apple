# iPad

> Sidecar canvas + Shortcuts host. Bigger iPhone-shaped surface, with desktop-class Shortcuts and a more permissive Files app. iPadOS, not macOS.

## Role

Two distinct uses, picked per session:

1. **As a Mac peripheral** — Sidecar second display, Universal Control cursor target, Stage Manager canvas for writing/drawing
2. **As a standalone device** — Shortcuts host with a real keyboard (Magic Keyboard) and pencil (Apple Pencil), running iPadOS app intents

The skill cares about both, because either mode can originate or receive automation.

## Automation surface

Superset of iPhone, subset of macOS:

- **Shortcuts** — full editor, same as iPhone, but iPad gets a larger workspace and more multi-action layouts
- **App Intents** — every installed app's intents
- **Personal Automations** — same trigger catalog as iPhone (time, location, NFC, Focus, etc.)
- **Stage Manager Shortcuts** — window-arrangement actions exist; can drive multi-app layouts via Shortcut
- **Files.app** — more permissive than iPhone; can read/write to external drives, SMB shares, iCloud Drive folders that Mac scripts also see
- **Pencil + Scribble** — handwriting → text input, scriptable via Accessibility
- **No AppleScript / no JXA / no shell** — iPadOS automation is still declarative-only

## Cross-device fabric — iPad ↔ Mac

- **Sidecar** — iPad as second display *for the Mac*; Mac drives, iPad renders
- **Universal Control** — single cursor moves between Mac and iPad seamlessly; clipboard / drag-and-drop crosses boundary
- **Continuity Sketch** — draw on iPad, lands as inline image in Mac document
- **Continuity Markup** — annotate PDF on iPad, lands on Mac
- **Handoff** — Mail, Safari, Notes, Pages, Numbers, Keynote, Reminders cross between iPad and Mac
- **AirDrop** — bidirectional
- **iCloud Drive** — every file the Mac sees, iPad sees too (subject to "Optimize Storage" eviction)
- **Universal Clipboard** — copy iPad, paste Mac

## Trigger surface

Same as iPhone Personal Automations, plus:

- **Hover** events with Apple Pencil (iPad Pro M-series)
- **Stage Manager scene switching** — can fire on Focus change

## Painpoints specific to iPad

- **Sidecar quality** — wireless Sidecar can be laggy; wired Sidecar via USB-C is solid
- **Stage Manager + external display** — Apple keeps changing how this works; scripted display-arrangement should not assume a stable behavior across macOS versions
- **Files.app vs iCloud Drive eviction** — same trap as Mac; an iPad-side script may see a cloud stub instead of a real file
- **No persistent background process** — long-running automations get killed; design for one-shot Shortcuts

## Cross-refs

- Sidecar on Mac side: [MacBookPro.md](MacBookPro.md), [iMac.md](iMac.md)
- Whiteboard Knob (drawing surface considerations): `wiki/entities/whiteboard-knob.md`
