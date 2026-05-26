> 🚧 **PAINPOINT — Cross-platform parity gap.** iOS Shortcuts has no file/folder/iCloud-Drive trigger. macOS Shortcuts does. Watching an iCloud Drive folder and reacting on iPhone is **impossible** as of this date. Full painpoint write-up: [`painpoints/SHORTCUTS-001-ios-no-file-folder-trigger.md`](../../painpoints/SHORTCUTS-001-ios-no-file-folder-trigger.md). If Apple closes this gap in a future iOS release, re-architect the Mac→iPhone file-arrival reactions accordingly.

# iOS Personal Automation — Available Triggers (state as of 2026-05-26)

Authoritative inventory of every trigger Apple exposes in the iPhone
Shortcuts app → Automation tab → + → New Automation → Personal Automation,
captured 2026-05-26 from Esa's iPhone running iOS 18.x (4G, batt 90%).

**Critical takeaway: there is NO "File Added to Folder", "iCloud Drive",
"Files app", or "File" trigger of any kind on iOS Personal Automation.**
That trigger exists on macOS Shortcuts only. Any architecture that assumes
the iPhone can watch an iCloud Drive folder and react to new files is
**impossible on iOS** as of this date and will not work no matter how the
Shortcut is built. The Mac→iPhone notification path must go through one
of the triggers below (or sidestep Shortcuts entirely — see "Sidestep" at
bottom).

## Full trigger list (3 screenshots, scrolled top to bottom)

### Time / sleep / motion
| Trigger | Example |
|---|---|
| **Time of Day** | "At 8:00 am, weekdays" |
| **Alarm** | "When my alarm is stopped" |
| **Sleep** | "When Wind Down starts" |
| **Arrive** | "When I arrive at the gym" |
| **Leave** | "When I leave work" |

### Communications
| Trigger | Example |
|---|---|
| **Email** | "When I get an email from Jane" |
| **Message** | "When I get a message from Mum" |

### Connectivity
| Trigger | Example |
|---|---|
| **Airplane Mode** | "When Airplane Mode is turned on" |
| **Wi-Fi** | "When my iPhone joins the Home network" |
| **Bluetooth** | "When my iPhone connects to AirPods" |
| **NFC** | "When I tap an NFC tag" |
| **CarPlay** | "When CarPlay is connected" |

### Apps & physical
| Trigger | Example |
|---|---|
| **App** | "When Weather is opened or closed" |
| **Wallet** | "When I tap a Wallet Card or Pass" |
| **Apple Watch Workout** | "When I start a workout" |
| **Battery Level** | "When battery level rises above 50%" |
| **Charger** | "When my iPhone connects to power" |
| **Low Power Mode** | "When Low Power Mode is turned off" |

### Focus modes
| Trigger | Example |
|---|---|
| **Do Not Disturb** | "When turning Do Not Disturb on" |
| **Personal** | "When turning Personal on" |
| **Work** | "When turning Work on" |
| **Reduce Interruptions** | "When turning Reduce Interruptions on" |
| **Driving** | "When turning Driving on" |
| **Music** | "When turning Music on" |

### Sensors
| Trigger | Example |
|---|---|
| **Sound Recognition** | "When my iPhone recognises a doorbell sound" |

### Home Automation (separate section, HomeKit-only)
"Create an automation that works for everyone in the home." — Home accessories,
not Shortcuts personal automation. Not applicable to Mac→iPhone notify use cases.

## What's NOT here

Compared to macOS Shortcuts, iOS Personal Automation is missing:
- **File / Folder / iCloud Drive triggers** — no watch-folder pattern possible
- **Document / image / video file-added** — no
- **Webhook / URL trigger** — no
- **Server / shared-folder trigger** — no
- **Shortcut-run trigger** (chaining shortcuts) — no

The only iOS Personal Automation triggers that could plausibly be repurposed
for Mac→iPhone signalling:
- **Email** trigger ("from <sender>") — Mac could send an email, iPhone
  triggers a Shortcut on receipt. Brittle (depends on mail check interval,
  could be 30+ min), spam-prone.
- **Message** trigger ("from <sender>") — Mac iMessages, iPhone triggers
  Shortcut. But the iMessage itself is already a banner — Shortcut layer
  is redundant.

## Sidestep: don't use Personal Automation at all for Mac→iPhone notify

The cleanest Apple-native Mac→iPhone notification is **`bin/notify-iphone`**,
which is now a thin wrapper around `bin/imessage`. The iMessage bubble IS
the iOS push notification (APNs-delivered, banner + sound + lock screen +
Notification Center). No Personal Automation, no Shortcut, no iCloud Drive,
no trigger required. Sub-second cross-device, cross-network.

See:
- `wiki/concepts/imessage-from-terminal.md` for the underlying CLI
- Project memory `feedback_imessage_is_the_iphone_banner.md` for why this
  is the right architecture (and why the 2026-05-26 iCloud-Drive-folder-watch
  attempt was structurally wrong)

## When this page needs updating

Re-screenshot the entire Personal Automation trigger list whenever iOS goes
through a major version bump (annually in September). Apple has been known
to add triggers (e.g. NFC, Sound Recognition, Reduce Interruptions all
arrived in later iOS versions). Until then this is the authoritative state.
