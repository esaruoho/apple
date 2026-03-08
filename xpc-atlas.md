# XPC Automation Atlas — macOS Sequoia

> The hidden automation layer beneath AppleScript. 2,359 XPC services mapped.

## What This Is

Every macOS app delegates its real work to XPC daemons — background services that handle the actual operations. AppleScript talks to apps via Apple Events. But apps like System Settings, Preview, and Home have **zero AppleScript support** — their automation surfaces are buried in XPC.

This atlas maps those services. It's the Tier 5/6 layer below what `sdef-extract.py` and `app-probe.py` can see.

## Service Counts

| App | XPC Services | Painpoint | Key Service |
|-----|:-----------:|-----------|-------------|
| Siri / Shortcuts | 56 | — | `siriactionsd.xpc` (dispatch hub) |
| System Settings | 35 | SYSTEM-SETTINGS-001 | `systemsettingsagent` |
| Spotlight | 35 | — | `mds`, `corespotlight` |
| Music | 35 | — | `amp.library`, `mediaremoted` |
| Preview | 33 | PREVIEW-001 | `previewsd`, `quicklookd.xpc` |
| Dock / Mission Control | 23 | — | `dock.server`, `dock.spaces` |
| Home / HomeKit | 22 | HOME-001 | `homed.xpc`, `homekit.xpc` |
| Accessibility | 19 | — | `axserver` |
| Photos | 18 | PHOTOS-001 | `photolibraryd`, `photos.service` |
| Safari | 18 | — | `webkit.webpushd` |
| Finder | 12 | — | `Finder`, `FileProvider` |
| Time Machine | 11 | — | `backupd`, `backupd-helper` |
| Mail | 10 | — | `email.maild` |
| Messages | 9 | MESSAGES-001 | `madrid` (iMessage codename) |
| Calendar | 8 | — | `CalendarAgent` |
| Disk Utility | 7 | — | `storagekitd`, `diskmanagementd` |
| Notes | 5 | NOTES-001 | `Notes.datastore` |
| Screenshots | 3 | — | `screencaptureui` |

**Total: 2,359 services (1,519 user-session + 840 system)**

---

## Painpoint App Deep Dives

### System Settings — 35 services

The most-used app on macOS has only 3 AppleScript commands. But it has 35 XPC services.

**Key endpoints:**
- `com.apple.systemsettingsagent` — the main settings engine (user-session, running)
- `com.apple.legacyagent.usersettingsprovider` — pre-Ventura preference panes
- `com.apple.legacyagent.usersettingsstore` — persistent settings storage
- `com.apple.ManagedSettingsAgent` — Screen Time restrictions
- `com.apple.UpdateSettings` — software update preferences (system-level)
- `com.apple.usernotifications.settings-vendor` — notification settings
- `com.apple.ScreenTimeAgent.settings` — Screen Time configuration

**Why it's "dark":** System Settings migrated from NSPreferencePane (accessible) to ExtensionKit (opaque) in Ventura. The actual work happens in XPC helpers that require specific entitlements.

---

### Home / HomeKit — 22 services

Our painpoint says "no CLI for HomeKit." But `homed` exposes 22 XPC endpoints.

**Key endpoints:**
- `com.apple.homed.xpc` — main HomeKit engine (running)
- `com.apple.homekit.xpc` — HomeKit framework bridge
- `com.apple.homekit.coredata.xpc` — HomeKit database
- `com.apple.matter.framework.xpc` — Matter protocol (smart home)
- `com.apple.matter.native.xpc` — native Matter support
- `com.apple.matter.support.xpc` — Matter commissioning
- `com.apple.homeenergyd.xpc` — energy monitoring
- `com.apple.ThreadNetwork.xpc` — Thread radio (IoT mesh networking)
- `com.apple.private.appintents.delegate.com.apple.homed` — App Intents bridge

**The bridge:** That last endpoint (`appintents.delegate`) is how Shortcuts talks to HomeKit. When you say "Hey Siri, turn off the lights," `siriactionsd` dispatches to `homed` via this XPC bridge.

---

### Preview — 33 services

Zero AppleScript. But 33 XPC services.

**Key endpoints:**
- `com.apple.previewsd` — the Preview rendering daemon
- `com.apple.Preview.ServiceProvider` — service extension host
- `com.apple.quicklookd.xpc` — Quick Look rendering engine
- `com.apple.quicklook.ThumbnailsAgent` — thumbnail generation
- `com.apple.quicklook.ui.helper` — Quick Look UI presentation

---

### Photos — 18 services

18 AppleScript commands that only read. But 18 XPC services that can do much more.

**Key endpoints:**
- `com.apple.photolibraryd` — the real photo library engine (running)
- `com.apple.photos.service` — Photos framework service
- `com.apple.cloudphotod` — iCloud Photos sync
- `com.apple.mediaanalysisd.photos` — ML photo analysis (faces, objects, scenes)
- `com.apple.photoanalysisd` — deep photo analysis
- `com.apple.corespotlight.receiver.photos.search` — photo search

---

### Messages — 9 services

3 AppleScript commands. Write-only. Can't read messages.

**Key endpoints:**
- `com.apple.madrid-idswake` — iMessage ("madrid" is the codename)
- `com.apple.MessagesBlastDoorService` — security sandbox for attachments (system-level)
- `com.apple.MobileSMS` — the SMS/iMessage engine
- `com.apple.screensharing.MessagesAgent` — screen sharing via Messages
- `com.apple.suggestd.messages` — message-based suggestions

---

### Notes — 5 services

**Key endpoints:**
- `com.apple.Notes.datastore` — the note database engine
- `com.apple.LinkedNotesUIService` — Quick Note floating window
- `com.apple.notes.exchangenotesd` — Exchange/IMAP note sync
- `com.apple.synapse.notes-activation-service` — note intelligence

---

## The Siri/Shortcuts Dispatch Chain

The single most important service for automation is `siriactionsd`. Here's how it works:

```
User: "Hey Siri, turn off the lights"
  → com.apple.siri.activation
  → com.apple.siriactionsd.xpc (resolves intent)
  → com.apple.private.appintents.delegate.com.apple.homed (XPC to target)
  → com.apple.homed.xpc (executes HomeKit command)
  → com.apple.homekit.xpc (talks to device)
```

**siriactionsd endpoints (31):**
- `com.apple.siriactionsd.xpc` — main dispatch
- `com.apple.siri.VoiceShortcuts.xpc` — voice-triggered shortcuts
- `com.apple.shortcuts` — Shortcuts app bridge
- `com.apple.shortcuts.daemon-wakeup-request` — wake shortcuts daemon

---

## Dock / Mission Control — 23 services

The Dock daemon controls far more than the Dock:

- `com.apple.dock.server` — main daemon
- `com.apple.dock.spaces` — **Mission Control** (virtual desktops)
- `com.apple.dock.launchpad` — **Launchpad** grid
- `com.apple.dock.fullscreen` — fullscreen management
- `com.apple.dock.controlcenter` — Control Center
- `com.apple.dock.notificationcenter` — Notification Center
- `com.apple.dock.sidecar` — Sidecar (iPad as display)
- `com.apple.dock.downloads` — Downloads stack
- `com.apple.dock.appstore` — App Store badge updates

---

## Automation Tier Model

| Tier | Surface | Tool | Access |
|------|---------|------|--------|
| 1 | AppleScript sdef | `sdef-extract.py` | Open |
| 2 | App Intents (Shortcuts) | `app-probe.py` | Open |
| 3 | URL Schemes | `app-probe.py` | Open |
| 4 | CLI tools | manual | Open |
| **5** | **XPC user-session agents** | **`xpc-probe.py`** | **Entitlement-gated** |
| **6** | **XPC system daemons** | **`xpc-probe.py`** | **Root + entitlements** |
| 7 | Private frameworks | Frida/dsdump | SIP-protected |

Our pipeline covers Tiers 1-4 comprehensively. This atlas maps Tiers 5-6.

---

## Probing Methodology

### Safe (no SIP disable needed)
1. `launchctl print gui/$(id -u)` — enumerate user-session services
2. `launchctl print gui/$(id -u)/<service>` — inspect a specific service
3. `python3 bin/xpc-probe.py --app <name>` — filtered probe
4. Static analysis with `dsdump` or `nm` on copied binaries

### Advanced (requires SIP considerations)
1. `xpcspy` (Frida wrapper) — monitor XPC messages in real-time
2. `ipsw` — extract binaries from dyld_shared_cache
3. Xcode test binary with Mach-lookup entitlements

---

## What Would Sal Do

Sal's Principle #1: "The power of the computer should reside in the hands of the one using it."

These 2,359 services represent the actual power of macOS. Apple chose to expose ~5% of it via AppleScript. The XPC layer is the other 95%.

The path to full automation:
1. Map all services (this atlas) ✓
2. Extract their protocols (dsdump + xpcspy)
3. Build entitlement-bearing test binaries
4. Create an XPC bridge tool that translates commands to XPC calls
5. Wire that into Shortcuts/Spotlight/Siri

---

*Generated by `bin/xpc-probe.py` on 2026-03-08. Part of the [Apple Automation Atlas](README.md).*
