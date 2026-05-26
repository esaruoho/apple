# AppleWatch

> Wrist trigger surface. Smallest screen Apple makes, but the most ergonomically immediate trigger device. watchOS, paired to an iPhone.

## Role

The "I don't want to take my phone out" trigger. Shortcuts on the wrist fire scripts that land on the Mac via iPhone relay. Also: health/biometric sensor that produces a continuous data stream visible to Mac via HealthKit-on-iPhone sync.

## Automation surface

watchOS supports a meaningful subset of iOS automation:

- **Shortcuts on Watch** — Shortcuts app on watchOS runs Shortcuts authored on iPhone/Mac that sync via iCloud
- **Complications** — Shortcut-running complications can occupy watch face slots; tap = run
- **Smart Stack widgets** — App Intent widgets that surface contextually
- **Action Button** (Ultra) — single configurable hardware button → Shortcut or workout / dive / siren
- **Double Tap** (S9 / S10 / Ultra 2 onward) — pinch gesture, default = primary action of current screen, scriptable in some contexts
- **Siri on Watch** — voice surface for Shortcuts + App Intents
- **Workout API** — automation around workout start/end/heart-rate-zone
- **HealthKit** — heart rate, blood oxygen, sleep stage, ECG, fall detection, crash detection (all sync to iPhone, then to Mac if Health on Mac is enabled)

## Cross-device fabric — Watch → iPhone → Mac

The Watch does not talk directly to the Mac. Every Watch-originated automation traverses:

```
Watch (Shortcut / complication tap) → iPhone (Run Shortcut on Mac) → Mac (Shortcut / AppleScript)
```

What flows:

- **Shortcuts** authored on Mac/iPhone sync to Watch via iCloud, callable from Watch face / Siri
- **Notification actions** — interactive notifications on Watch can fire App Intents
- **HealthKit data** — Watch → iPhone HealthKit → Mac Health.app (read-only on Mac)
- **Find My** — Watch location signal visible to Mac via iCloud
- **Audio routing** — Watch + AirPods means audio plays from Watch without iPhone present
- **Apple Pay on Watch** — independent of iPhone presence (cellular Watch)

## Trigger surface — what fires on Watch

- Tap complication on watch face
- Tap Smart Stack widget
- Double Tap gesture (S9+/Ultra 2+)
- Action Button press (Ultra)
- Siri voice ("Hey Siri")
- Workout start/end (Personal Automation on paired iPhone fires on this)
- Time / location (Personal Automation, iPhone-side)
- Sleep stage transition (Personal Automation)
- ECG / fall / crash detection (system-triggered, can run user Shortcut as follow-up)

## Painpoints specific to Watch

- **No direct Mac path** — every Watch automation that ends on Mac requires the iPhone to be present and online (cellular Watch helps but not always)
- **Complication slot scarcity** — only N slots on each watch face; the watch face is the real trigger surface, and slots are zero-sum
- **Battery vs. always-on** — workout / GPS automations drain fast; design recurring automations to avoid pinning GPS
- **Sync lag** — Shortcuts edited on iPhone take seconds to minutes to appear on Watch via iCloud
- **"Hey Siri" recognition** is per-device — multi-Siri-device households need explicit "Hey Siri on my Watch" intent disambiguation

## Cross-refs

- iPhone is the bridge: [iPhone.md](iPhone.md)
- Siri phrase catalog: `wiki/compiled/siri-phrases.md`
- HomePod also handles "Hey Siri" — disambiguation matters: [HomePod.md](HomePod.md)
