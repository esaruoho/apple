# SHORTCUTS-001: iOS Has No "When File Added to Folder" Trigger

**App:** Shortcuts.app (iOS / iPadOS)
**Intent:** Watch an iCloud Drive folder on iPhone/iPad and run a Shortcut when a new file lands — the same trigger that exists on Mac Shortcuts
**Severity:** Cross-platform parity gap — Mac has it, iOS doesn't, and nothing fills the gap
**Status:** Open
**Filed:** 2026-05-26
**Verified:** 2026-05-26 from Esa's iPhone running iOS 18.x — full trigger inventory at [`wiki/concepts/ios-personal-automation-triggers.md`](../wiki/concepts/ios-personal-automation-triggers.md)

---

## The Friction

The iOS Shortcuts app's **Personal Automation** tab exposes ~25 triggers (Time of Day, Alarm, Sleep, Email, Message, Wi-Fi, Bluetooth, NFC, App, Battery, Focus modes, Sound Recognition, etc.). **None of them watch the filesystem.** There is no "When File is Added to Folder", no "When iCloud Drive Receives", no "When Files App Sees New Item". The macOS Shortcuts app has exactly this trigger — `When File is Added to <Folder>` — and it works reliably. iOS does not.

| What iCloud Drive sync gives you on iPhone | What you can react to |
|---|---|
| New file appears in any iCloud Drive folder (within seconds) | **Nothing** |
| New file appears in a specific folder you nominate | **Nothing** |
| File modified, renamed, or moved | **Nothing** |
| Specific file type (image, PDF, JSON) arrives | **Nothing** |

You can browse the file in the Files app. You can open it manually. **You cannot have the iPhone react automatically.** The data is there; the trigger is missing.

The Mac→iPhone equivalent of macOS's Folder Actions / Hazel rules / `fswatch` does not exist on iOS in any user-accessible form.

---

## Workarounds (none satisfying)

| Workaround | Cost |
|---|---|
| **Use Email trigger instead** ("When I get an email from Mac") | Brittle — mail check interval can be 30+ min; spam-prone; requires email infrastructure |
| **Use Message trigger** ("When I get an iMessage from <self>") | Works, but redundant — the iMessage IS already a banner (see `feedback_imessage_is_the_iphone_banner.md`) |
| **Time of Day poll** — fire a Shortcut every N minutes that scans iCloud folder | Battery cost; minimum 1-hour interval on iOS; misses real-time events |
| **NFC tag at the iPhone** — physically tap to invoke | Defeats the point of remote signalling from Mac |
| **Use a Mac-side trigger + iMessage banner** | What we actually do (`bin/notify-iphone` wraps `bin/imessage`); but it's a routing of the banner, not a way for iPhone to scan iCloud for files |

The "use iMessage as the notification transport" pattern (`bin/notify-iphone`) is the right Apple-native workaround for **notifications**. It does not solve the underlying capability gap for **file-arrival reactions** — e.g. "when a Shortcut bundle lands in my iCloud inbox folder, auto-import it on the iPhone".

---

## Why This Matters

The Mac→iPhone push-data use cases that should "just work":

- Drop a file into an iCloud Drive folder on Mac → iPhone gets it AND reacts (move to Files app library, tag it, fire a Shortcut, install if it's a `.shortcut`).
- Generate a screenshot on Mac → iPhone auto-files it into a per-project folder.
- Mac CI run produces a report → iPhone notification with link AND a Shortcut to read it aloud.
- Mac drops a `.json` config → iPhone Shortcut auto-applies it.

All of these are routine on macOS via Folder Actions, Hazel, `fswatch`, or Shortcuts file-trigger. On iOS, the file syncs (iCloud Drive is reliable for that) but **the iPhone cannot react**. The user has to manually open Files, tap the file, decide what to do. Sync without trigger.

For Esa's Apple-skill specifically: this is what caused the 2026-05-26 over-engineering. The `notify-iphone` v1 design assumed an iOS file-watch trigger existed (it doesn't), built a `.shortcut` to parse JSON drops (couldn't be triggered), and burned hours before the trigger inventory confirmed the gap. The Mac side worked perfectly; the iPhone side was structurally impossible.

---

## What Would Sal Do (WWSD)

Sal would have shipped this as a Folder Action equivalent on iOS — a per-folder "When item added → run this Shortcut" affordance, exactly mirroring the macOS Folder Actions pattern that's been in AppleScript since Mac OS 9. The infrastructure exists (iOS Shortcuts already has the action runtime, iCloud Drive already syncs reliably, Personal Automations already have a trigger UI). Wiring "new file in folder" to that trigger UI is a one-line addition to the trigger picker. Apple's choice not to expose it is a product decision, not a technical limitation.

---

## What This Means For The Apple-Skill Roadmap

- `bin/notify-iphone` correctly uses iMessage-to-self (the iMessage IS the iOS push banner). Nothing more to build for **notifications**.
- For **file delivery** Mac→iPhone with auto-reaction: there is no clean automation path on iOS. We deliver via `bin/icloud-drop --imessage` (file goes to iCloud Drive; URL goes via iMessage text bubble). iPhone receives the banner; user manually taps the URL → Files opens → user manually decides what to do. No auto-reaction.
- If Apple ever adds the file-folder trigger in a future iOS release: revisit `wiki/concepts/ios-personal-automation-triggers.md` and re-architect the file-arrival reactions Mac→iPhone. Until then, the gap is closed by manual user action on the iPhone side, full stop.

---

## Related

- [`wiki/concepts/ios-personal-automation-triggers.md`](../wiki/concepts/ios-personal-automation-triggers.md) — full iOS trigger inventory (2026-05-26)
- [`wiki/concepts/iphone-notify-pipeline.md`](../wiki/concepts/iphone-notify-pipeline.md) — current Mac→iPhone notify architecture
- Memory: `feedback_imessage_is_the_iphone_banner.md` — why iMessage is the right notification transport
- macOS counterpart: Folder Actions (`/Library/Scripts/Folder Action Scripts/`) and macOS Shortcuts "When File is Added to Folder" trigger — both work; iOS has neither
