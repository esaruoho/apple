# iPhone

> Pocket trigger surface. The originator-device for most "from anywhere → Mac runs a Shortcut" flows. iOS, not macOS — automation surface is narrower but different in interesting ways.

## Role

The device that is **always with the user**. Anything Esa wants to trigger from outside the office goes through iPhone. The skill treats iPhone as primarily an *originator* of automation, not a runner.

## Automation surface

**Shortcuts** is the dominant automation API on iOS:

- **Shortcuts app** — full editor, Shortcuts run via Spotlight, Siri, Share Sheet, Home Screen widget, Lock Screen, Back Tap
- **App Intents** — Swift-defined intents from any installed app
- **Personal Automations** — time, location, NFC tag, Focus mode, app open/close, Wi-Fi join, Bluetooth connect, charger plug/unplug, low battery, sleep/wake, email/message received
- **Siri** — voice surface for Shortcuts + App Intents
- **Action Button** (Pro models) — single configurable hardware button → Shortcut
- **Camera Control** (15 Pro / 16 line) — physical capture surface, Visual Intelligence
- **Back Tap** (Accessibility) — double/triple-tap on back of phone → Shortcut

**Notably absent on iOS:** AppleScript, JXA, Cocoa shell tools, LaunchAgents, FSEvents. iOS automation is **declarative-only**.

## Cross-device fabric — iPhone → Mac

This is where iPhone earns its place in the apple skill. Triggers on iPhone can fire automation on the Mac via:

- **Run Shortcut on Mac** — iOS Shortcut → "Run Script Over SSH" or "Run Shortcut" with device picker = Mac
- **Universal Clipboard** — copy on iPhone, paste on Mac (Continuity)
- **Handoff** — Continue activity (Mail draft, Safari tab, Notes edit) on Mac
- **AirDrop** — push file from iPhone to Mac
- **Continuity Camera** — iPhone becomes Mac's webcam / scanner / mic
- **iMessage / iCloud Drive drops** — file shows up on Mac via Syncthing-equivalent native sync
- **Find My / Notify When Found** — passive location signal a Mac LaunchAgent can read
- **Focus mode sync** — iPhone Focus state propagates to Mac, which can run AppleScripts on Focus-change

## Trigger surface — what fires Shortcuts on iPhone

- Time of day (Personal Automation)
- Arrive at / leave location
- Connect to specific Wi-Fi / Bluetooth device
- Plug in / unplug charger
- NFC tag scan
- Focus mode entered/exited
- Specific app opened/closed
- Email received from / message received from
- CarPlay connected
- Sleep mode start/end
- Battery falls below threshold
- Action Button press (Pro)
- Back Tap (Accessibility)
- Lock Screen widget tap
- Home Screen widget tap

## iPhone-specific automation surfaces worth knowing

- **Live Activities** — pinned-to-Dynamic-Island state, App Intent-driven
- **Interactive Widgets** — App Intent buttons on Home Screen / Lock Screen
- **Visual Intelligence** (Camera Control + Apple Intelligence) — point camera, take action
- **Image Playground / Genmoji** — App Intent-callable from Shortcuts
- **Notification actions** — App Intent-driven, scriptable
- **Spotlight on iOS** — runs Shortcuts directly

## Painpoints specific to iPhone

- **Personal Automations sometimes need "Ask Before Running" off** to be useful, but Apple keeps flipping defaults
- **Background execution is heavily restricted** — Shortcuts that need network or long-running work can be killed
- **iCloud Shortcuts share gates** can't be bypassed programmatically (Apple-way respect, not a bug)
- **Notification permissions are gated** — see `wiki/concepts/iphone-notify-pipeline.md` for the working pipeline
- **File-attach in Messages** is not scriptable; this is the canonical "respect the gate, use side-channel" case (`feedback_never_ui_hijack_active_session.md`)

## Cross-refs

- iPhone → MacMini notification path: `wiki/concepts/iphone-notify-pipeline.md`
- Why we don't UI-hijack iMessage file-attach: `feedback_never_ui_hijack_active_session.md`
- Siri phrase catalog (Sal + user): `wiki/compiled/siri-phrases.md`
- Vocal Shortcuts (the macOS sibling to iPhone Siri trigger): `wiki/concepts/vocal-shortcuts-trigger.md`
