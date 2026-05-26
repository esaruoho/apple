# HomePod

> Voice surface + climate sensor + HomeKit hub. audioOS, Siri-first, no screen. The most "ambient" Apple device.

For the operational climate-sensor pipeline (Syncthing → MacMini watcher → graphs), see `wiki/entities/homepod.md`. This page is the device-profile sibling.

## Role

Three roles in this skill:

1. **"Hey Siri" surface** — voice trigger that can fire Shortcuts on a paired Mac/iPhone
2. **Climate sensor** — temperature + humidity readings, exposed via Home app and via the `homepod` skill's read pipeline
3. **HomeKit hub** — coordinates Home accessories when iPhone/iPad aren't local

## Automation surface

audioOS exposes almost no direct scripting — everything goes through Siri / Home:

- **Siri voice** — runs Shortcuts that have "Use with Siri" enabled and are synced via iCloud
- **Home app automations** — time / sensor / arrival / departure can call Shortcuts
- **"Hey [Sal phrase]"** — custom Siri phrases work on HomePod the same as on iPhone (the Sal phrase catalog at `wiki/compiled/siri-phrases.md` applies)
- **Sound recognition** (HomePod mini onwards) — alarms / dog barks / crying baby → Home automation
- **Temperature + humidity sensors** (mini 2nd gen, full HomePod 2) — readable via Home → Climate
- **No App Store, no Shortcuts editor on-device** — author elsewhere, sync via iCloud

## Cross-device fabric

- **AirPlay receive** — Mac/iPhone/iPad push audio here; multiple HomePods can be stereo-paired or whole-house grouped
- **Handoff (audio)** — bring iPhone close to HomePod, audio transfers
- **HomeKit hub** — coordinates with [AppleTV.md](AppleTV.md) when both present
- **"Hey Siri" routing** — most-active or nearest device wins; suppress on devices that shouldn't listen
- **Find My** — HomePod reports its own location
- **Climate sensor → MacMini** — the `homepod` skill at `~/.claude/skills/homepod/` provides the read pipeline; data Syncthing-mirrored to MacMini for graphing

## Trigger surface

- "Hey Siri" voice command
- Home app automation calling a Shortcut
- Sound recognition event
- Climate threshold (via Home automation)
- Arrival / departure of household member (via Home)
- AirPlay session start/end (visible to source)

## Painpoints specific to HomePod

- **Custom Siri phrases must be on the iCloud-syncing device** — Shortcuts authored on a different Apple ID won't appear
- **"Hey Siri" target disambiguation** — Mac, iPhone, AirPods, Watch, HomePod, Apple TV all compete; Esa's setup needs explicit per-device "Listen for Hey Siri" toggles
- **No App Store** — every action goes through Shortcuts + Home; complex flows require iPhone/Mac authoring
- **Climate sensor accuracy** — drifts vs. dedicated sensors; the `homepod` skill documents calibration considerations
- **Multi-room audio routing** can't be scripted from Mac in a clean way; AppleScript control of Music.app speakers is limited

## Cross-refs

- Climate sensor read pipeline (operational): `wiki/entities/homepod.md`
- `homepod` skill (read sensor from CLI): `~/.claude/skills/homepod/`
- Apple TV as competing HomeKit hub: [AppleTV.md](AppleTV.md)
- Siri phrase catalog (Sal + user): `wiki/compiled/siri-phrases.md`
