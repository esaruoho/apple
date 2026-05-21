# macOS Automation Tiers — Full Stack Atlas

> 10 automation layers mapped. From AppleScript to IOKit.

## Tier Model

| Tier | Surface | Tool | Access | Count |
|------|---------|------|--------|-------|
| 1 | AppleScript sdef | `sdef-extract.py` | Open (TCC since 2012) | 31 apps |
| 2 | App Intents (Shortcuts) | `app-probe.py` | Open | 20 apps |
| 3 | URL Schemes | `app-probe.py` | Open | 35 apps |
| 4 | CLI tools | manual | Open | varies |
| 5 | XPC user-session agents | `xpc-probe.py` | Entitlement-gated | 1,519 |
| 6 | XPC system daemons | `xpc-probe.py` | Root + entitlements | 840 |
| 7 | Private frameworks | Frida/dsdump | SIP-protected | — |
| **8** | **Accessibility API** | **osascript (AX)** | **TCC: Accessibility** | **all GUI apps** |
| **9** | **Distributed Notifications** | **CFNotificationCenter** | **Open (observe)** | **~50 known** |
| **10** | **IOKit** | **ioreg / IOKit.framework** | **Open (read) / Entitlement (write)** | **252 classes** |

---

## Tier 8 — Accessibility API (AX)

Every GUI element on macOS is reachable through the Accessibility API. This is how VoiceOver works, and it's how automation can reach apps that have **zero** AppleScript support.

**Access:** Requires TCC "Accessibility" permission for the calling app (Terminal, iTerm, etc.)

### What AX Can Reach

| App | AX Surface |
|-----|-----------|
| **Finder** | Full menu bar (File, Edit, View, Go, Window, Help — all commands), toolbar buttons, sidebar, file list |
| **Safari** | Menu bar (Apple, Safari, File, Edit, View, History, Bookmarks, Develop, Window, Help), tab bar, address bar |
| **Music** | Menu bar (Apple, Music, File, Edit, Song, View, Controls, Account, Window, Help), player controls, library |
| **System Settings** | Sidebar panes (33 total), all toggle switches, text fields, buttons |
| **Any app** | Every button, menu item, text field, checkbox, slider — anything rendered in the GUI |

### System Settings — 33 Sidebar Panes via AX

This is the key workaround for SYSTEM-SETTINGS-001. While System Settings has only 3 AppleScript commands, **all 33 panes are reachable via Accessibility**:

Wi-Fi, Bluetooth, Network, VPN, Battery, General, Accessibility, Appearance, Apple Intelligence & Siri, Control Center, Desktop & Dock, Displays, Screen Saver, Spotlight, Wallpaper, Notifications, Sound, Focus, Screen Time, Lock Screen, Privacy & Security, Touch ID & Password, Users & Groups, Internet Accounts, Game Center, iCloud, Wallet & Apple Pay, Keyboard, Trackpad, Game Controllers, Printers & Scanners

**Example — open Wi-Fi pane:**
```applescript
tell application "System Settings" to activate
delay 1
tell application "System Events"
    tell process "System Settings"
        -- Click sidebar item
        click static text "Wi-Fi" of group 1 of scroll area 1 of group 1 of splitter group 1 of group 1 of window 1
    end tell
end tell
```

### Limitations

- **Fragile:** UI hierarchies change between macOS versions. `button 2 of scroll area 1 of group 1` may break.
- **Slow:** Each AX call is an IPC roundtrip. Enumerating a whole window can take seconds.
- **TCC-gated:** The calling process needs Accessibility permission — users must grant it manually.
- **No data model:** AX sees the GUI, not the data. You can click "Wi-Fi" but you can't query "is Wi-Fi on?" without reading the toggle state from the UI.

---

## Tier 9 — Distributed Notifications

Apps broadcast state changes as Darwin/NSDistributed notifications. Any process can observe them — no entitlements needed.

### Known Notification Names

**Music / iTunes:**
| Notification | Trigger |
|-------------|---------|
| `com.apple.iTunes.libraryChanged` | Library modified |
| `com.apple.iTunes.prefsChanged` | Preferences changed |
| `com.apple.iTunes.parentalPrefsChanged` | Parental controls changed |
| `com.apple.music.RecentSearchesDidChange` | Search history updated |
| `com.apple.amp.StoreServices.UserChangedNotification` | Store user changed |
| `com.apple.amp.StoreServices.UserPropertiesChangedNotification` | Store user props changed |
| `com.apple.AMPLibraryAgent.HomeSharingDisabledNotification` | Home Sharing toggled |

**System-wide:**
| Notification | Trigger |
|-------------|---------|
| `com.apple.screensaver.didstart` | Screen saver started |
| `com.apple.screensaver.didstop` | Screen saver stopped |
| `com.apple.KeyboardUIModeDidChange` | Keyboard UI mode changed |
| `com.apple.BiometricKit.enrollmentChanged` | Touch ID enrollment changed |

**Mail:**
| Notification | Trigger |
|-------------|---------|
| `com.apple.mail.update-blocklist` | Mail blocklist updated |
| `com.apple.message.general.newmessagenotifications` | New message received |

**Calendar:**
| Notification | Trigger |
|-------------|---------|
| `com.apple.calendar.LocaleChanged` | Locale changed |
| `com.apple.calendar.TimeZoneChanged` | Time zone changed |
| `com.apple.suggestions.settingsChanged` | Siri suggestions settings changed |

**Preview:**
| Notification | Trigger |
|-------------|---------|
| `com.apple.Preview.BookmarksChanged` | Bookmarks changed |
| `com.apple.Preview.image.AnnotationControllerChanged` | Image annotation changed |
| `com.apple.Preview.pdf.AnnotationControllerChanged` | PDF annotation changed |

**System Settings:**
| Notification | Trigger |
|-------------|---------|
| `com.apple.systemsettings.extensions.didchange` | Settings extension changed |

### How to Observe

```python
# Python (pyobjc)
from Foundation import NSDistributedNotificationCenter

def callback(notification):
    print(f"{notification.name()}: {notification.userInfo()}")

center = NSDistributedNotificationCenter.defaultCenter()
center.addObserverForName_object_queue_usingBlock_(
    "com.apple.iTunes.libraryChanged", None, None, callback
)
```

```bash
# Shell (one-liner watch)
# Requires pyobjc: pip3 install pyobjc-framework-Cocoa
```

### Limitations

- **Observe only:** You can watch for changes, not trigger them.
- **No guaranteed delivery:** Notifications are best-effort.
- **Undocumented names:** Apple doesn't publish notification names. Found via binary string extraction.
- **Many are internal:** Some notifications carry no userInfo, making them less useful.

---

## Tier 10 — IOKit (Hardware Abstraction)

IOKit is the kernel framework for hardware. It exposes 252 unique classes on this system (MacBook Pro, Apple Silicon).

### Automation-Relevant Hardware Classes

**Battery & Power (6 classes):**
| Class | What It Controls |
|-------|-----------------|
| `AppleSmartBatteryManager` | Battery state: charge level, cycle count, temperature, AC status |
| `AppleSMCPMU` | Power management unit |
| `IOHIDPowerSourceController` | HID power source events |
| `AppleCLPC` | Closed Loop Performance Controller (thermal/power management) |
| `AppleSMCSensorDispatcher` | SMC sensor data dispatch |
| `DCPAVPowerControllerProxy` | Display power control |

**Current battery:** 100%, AC connected, 30.86°C, design cycle 1000

**Display & Backlight (4 classes):**
| Class | What It Controls |
|-------|-----------------|
| `AppleARMBacklight` | Keyboard backlight (active, controllable) |
| `AppleARMLightEmUp` | Display brightness |
| `IODisplayWrangler` | Display sleep/wake |
| `AppleT603XDisplayCrossbar` | Multi-display routing |

**Keyboard & Input (8 classes):**
| Class | What It Controls |
|-------|-----------------|
| `AppleHIDKeyboardEventDriverV2` | Keyboard event driver |
| `AppleMultitouchTrackpadHIDEventDriver` | Trackpad events |
| `AppleActuatorHIDEventDriver` | Haptic feedback actuator |
| `AppleDeviceManagementHIDEventService` | Device management HID |
| `IOHIDSystem` | Global HID event system |
| `IOHIDResource` | HID resource manager |
| `AppleUserHIDDevice` | User-space HID device |
| `AppleSPUHIDDevice` | SPU HID device |

**Audio (5 classes):**
| Class | What It Controls |
|-------|-----------------|
| `AppleCS42L84Audio` | Internal speaker/mic codec |
| `AppleUSBAudioDevice` | USB audio (CalDigit Thunderbolt 3 Audio) |
| `AppleExternalSecondaryAudio` | External secondary audio output |
| `AppleSecondaryAudio` | Secondary audio channel |
| `AudioDMAController` | Audio DMA engine |

**USB & Thunderbolt (8 classes):**
| Class | What It Controls |
|-------|-----------------|
| `AppleUSBHostCompositeDevice` | USB composite devices |
| `AppleUSBHostResourcesTypeC` | USB-C host resources |
| `AppleUSBXHCIFL1100` | USB 3.0 XHCI controller |
| `AppleThunderboltIPService` | Thunderbolt networking |
| `AppleThunderboltPCIDownAdapter` | Thunderbolt PCIe devices |
| `AppleThunderboltUSBDownAdapter` | Thunderbolt USB adapter |
| `AppleThunderboltDPInAdapterOS` | Thunderbolt DisplayPort in |
| `AppleThunderboltDPOutAdapterCM` | Thunderbolt DisplayPort out |

**Bluetooth (2 classes):**
| Class | What It Controls |
|-------|-----------------|
| `IOBluetoothHCIController` | Bluetooth radio (connected, active) |
| `AppleBluetoothModule` | Bluetooth module |

**Connected USB devices:** CalDigit Thunderbolt 3 Audio, Card Reader

### Example — Read Battery Level

```bash
ioreg -rc AppleSmartBattery | grep '"CurrentCapacity"'
# "CurrentCapacity" = 100
```

### Example — Check Keyboard Backlight

```bash
ioreg -rc AppleARMBacklight | grep "backlight-control"
# "backlight-control" = Yes
```

### Limitations

- **Read-mostly:** IOKit is primarily for reading hardware state. Writing requires entitlements or root.
- **No stable API for scripting:** Must use `ioreg` CLI or IOKit.framework (C/ObjC).
- **Apple Silicon differences:** Many classes are ARM-specific. Intel Macs have different class names.
- **Kernel-level:** Errors can crash the system. IOKit is not designed for casual automation.

---

## Coverage Matrix

| App | T1 sdef | T2 Intents | T3 URL | T5-6 XPC | T8 AX | T9 Notif | T10 IOKit |
|-----|:-------:|:----------:|:------:|:--------:|:-----:|:--------:|:---------:|
| Finder | 122 cmd | — | — | 12 | Full menus | — | — |
| Music | 63 cmd | Yes | — | 35 | Full menus | 7 notifs | — |
| Safari | 19 cmd | — | Yes | 18 | Full menus | — | — |
| Mail | 12 cmd | — | Yes | 10 | Full menus | 3 notifs | — |
| Calendar | 17 cmd | Yes | — | 8 | Full menus | 3 notifs | — |
| System Settings | 3 cmd | Yes | Yes | 35 | **33 panes** | 1 notif | — |
| Photos | 18 cmd | Yes | — | 18 | — | — | — |
| Messages | 3 cmd | — | — | 9 | — | — | — |
| Notes | 7 cmd | Yes | — | 5 | — | — | — |
| Preview | 0 cmd | — | — | 33 | Full menus | 3 notifs | — |
| Home | 0 cmd | Yes | — | 22 | — | — | — |
| Shortcuts | 5 cmd | Yes | Yes | 56 | — | — | — |
| **Hardware** | — | — | — | — | — | 3 notifs | **252 classes** |

---

## Probing Tools

| Tier | Tool | Command |
|------|------|---------|
| 1 | sdef-extract.py | `python3 bin/sdef-extract.py` |
| 2-4 | app-probe.py | `python3 bin/app-probe.py` |
| 5-6 | xpc-probe.py | `python3 bin/xpc-probe.py` |
| 8 | osascript (AX) | `osascript -e 'tell app "System Events" ...'` |
| 9 | strings + pyobjc | `strings /path/to/binary \| grep notification` |
| 10 | ioreg | `ioreg -rc AppleSmartBattery` |

---

## What Sal Would Say

Sal's Principle #1: "The power of the computer should reside in the hands of the one using it."

Across all 10 tiers, macOS has **enormous** automation capability. But it's scattered:
- Tier 1 (AppleScript) covers 31 apps well
- Tiers 2-4 (Intents, URLs, CLI) add ~35 more apps partially
- Tiers 5-6 (XPC) hold 2,359 services — 87% of the real power — behind entitlement gates
- Tier 8 (Accessibility) can reach **everything visible** but is fragile and slow
- Tier 9 (Notifications) lets you **watch** state changes but not cause them
- Tier 10 (IOKit) gives read access to 252 hardware classes

The dream: one protocol, one permission, one way to automate everything. The reality: 10 layers, 5 permission models, 40 years of accumulation.

---

*Generated 2026-03-08. Part of the [Apple Automation Atlas](README.md).*
