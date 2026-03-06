# Automator vs Shortcuts — The Gap Analysis

What Automator can do that Shortcuts can't. What Shortcuts can do that Automator can't. And what neither can do that someone at Apple should be thinking about.

---

## By the Numbers

| | Automator | Shortcuts |
|--|:---------:|:---------:|
| Built-in actions | **227** | **246** (across 20 apps via App Intents) |
| Third-party extensible | Yes (`.action` bundles) | Yes (App Intents framework) |
| AppleScript inside | **Yes** (`Run AppleScript` action) | No |
| Shell scripts inside | **Yes** (`Run Shell Script` action) | No |
| JavaScript inside | **Yes** (`Run JavaScript` action) | No (removed) |
| Cross-device | Mac only | **Mac + iPhone + iPad + Watch** |
| Siri integration | No | **Yes** (1,254 phrases across 20 apps) |
| URL scheme | No | **Yes** (`shortcuts://`, `workflow://`) |
| CLI interface | No built-in | **Yes** (`shortcuts run/list/view/sign`) |
| Scripting dictionary | 16 cmds, 17 classes | 1 cmd (`run`), 2 classes |
| Can save as app | **Yes** (`.app` bundle) | No |
| Can save as service | **Yes** (Services menu) | No |
| Can save as folder action | **Yes** | No |
| Can save as calendar alarm | **Yes** | No |
| Can save as print plugin | **Yes** | No |
| UI recording | **Yes** (`Watch Me Do`) | No |
| Status | **Deprecated** (still ships, no updates) | Active development |

---

## What Automator Has That Shortcuts Doesn't

### 1. Scripting Escape Hatches

Automator's killer feature: when the built-in actions aren't enough, drop to code.

- **Run AppleScript** — full AppleScript with access to every scripting dictionary
- **Run Shell Script** — bash, zsh, python, ruby, perl, any CLI tool
- **Run JavaScript** — JXA with Cocoa bridge

Shortcuts has none of these. If a Shortcuts action doesn't exist for what you want, you're stuck. There's no escape hatch to raw code.

### 2. Save As Anything

Automator workflows can become:

| Output | What it means |
|--------|--------------|
| **Application** (`.app`) | Double-click to run. Drag files onto it. Put it in the Dock. |
| **Quick Action / Service** | Right-click context menu, Services menu, Touch Bar |
| **Folder Action** | Triggers automatically when files are added to a folder |
| **Calendar Alarm** | Triggers at a scheduled time via Calendar |
| **Print Plugin** | Appears in the Print dialog |
| **Dictation Command** | Triggers by voice (Sal's addition) |
| **Image Capture Plugin** | Triggers when importing from scanner/camera |

Shortcuts can be: a Shortcut. That's it. You can add it to the menu bar or dock, but it's always a Shortcut.

### 3. Watch Me Do

Record mouse clicks and keystrokes and replay them. Fragile, yes — but it works for automating apps with zero scripting support. Shortcuts has no equivalent.

### 4. Variables and Flow Control

Automator has explicit variables (`Set Value of Variable`, `Get Value of Variable`), loops (`Loop`), and user interaction (`Ask for Confirmation`, `Choose from List`, `Wait for User Action`).

Shortcuts has its own flow control (If/Otherwise, Repeat, Choose from Menu) — but no persistent variables across runs without workarounds.

### 5. Deep App Actions (Legacy)

227 built-in actions covering apps Shortcuts ignores:

| Category | Actions Shortcuts doesn't have |
|----------|-------------------------------|
| **PDF** | Combine, split, encrypt, watermark, extract annotations, render pages as images, search, set metadata, extract text, create contact sheets |
| **iDVD** | Full disc authoring pipeline (dead app, but the actions existed) |
| **iPod** | Direct iPod management (obsolete) |
| **Finder deep** | Label items, set Spotlight comments, set folder views, create aliases, sort items, set application for files |
| **Web** | Download URLs, get webpage contents/links/images, run web service, save images from web content, website popup |
| **Text processing** | Extract data from text (dates, URLs, addresses), filter paragraphs, combine text files, text to EPUB, text to audio |
| **Image processing** | Crop, flip, rotate, pad, scale, watermark, change type, apply Quartz filters, create thumbnails, create banner from text |
| **Developer** | Build Xcode Project, CVS operations, Apply SQL, Convert CSV to SQL, Create Package |
| **System** | Change system appearance, set computer volume, eject disk, mount disk image, start screen saver, system profile, take screenshot |

---

## What Shortcuts Has That Automator Doesn't

### 1. Cross-Device

Shortcuts runs on Mac, iPhone, iPad, and Apple Watch. Automator is Mac-only. This is the width Sal talked about.

### 2. App Intents (Modern API)

20 apps expose 246 Shortcuts actions via the App Intents framework:

| App | Actions | Siri Phrases |
|-----|:-------:|:------------:|
| Notes | 50 | 318 |
| Books | 27 | 125 |
| Mail | 26 | 164 |
| Music | 23 | 123 |
| Freeform | 23 | 144 |
| Preview | 17 | 35 |
| Maps | 16 | 17 |
| Finder | 16 | 67 |
| Voice Memos | 14 | 45 |
| Shortcuts | 13 | 49 |
| Weather | 6 | 149 |
| Home | 4 | — |
| Pages | 2 | — |
| Numbers | 2 | — |
| Keynote | 2 | — |
| Tips | 1 | 8 |
| Reminders | 1 | — |
| News | 1 | — |
| Calculator | 1 | — |
| App Store | 1 | 27 |

Automator has zero App Intents awareness.

### 3. Siri Voice Triggering

"Hey Siri, run my shortcut" — no equivalent in Automator. (Sal added Dictation Commands to macOS, but those were OS-level, not Automator-level.)

### 4. The `shortcuts` CLI

```bash
shortcuts list                    # Show all shortcuts
shortcuts run "My Shortcut"       # Run by name
shortcuts run "My Shortcut" -i input.txt  # With file input
shortcuts view "My Shortcut"      # Open in editor
shortcuts sign -i in.shortcut -o out.shortcut  # Code sign
```

Automator has no CLI. You can `open workflow.app` or `automator workflow.workflow` but there's no `automator run`.

### 5. Automation Triggers

Shortcuts can trigger automatically on:
- Time of day
- Arriving at / leaving a location
- Connecting to Wi-Fi / Bluetooth
- Opening an app
- NFC tag
- Email/message received (limited)

Automator only triggers via folder actions or calendar alarms.

### 6. Share Sheet Integration

Shortcuts appear in the Share Sheet across iOS and macOS. Automator Quick Actions appear in Services menus on Mac only.

---

## What NEITHER Can Do

This is the real gap — the things someone at Apple should be building.

| Gap | Why it matters |
|-----|---------------|
| **Record audio in one action** | [NOTES-001](painpoints/NOTES-001-record-audio.md) — Notes has 318 Siri phrases but "start recording" isn't one |
| **Chain AppleScript into Shortcuts** | No `Run AppleScript` action in Shortcuts. The depth layer is severed from the width layer. This is the AND Sal asked for. |
| **Access scripting dictionaries from Shortcuts** | Shortcuts can't send Apple Events. 30 apps with rich sdef dictionaries are invisible to Shortcuts. |
| **UI recording/playback** | Automator's Watch Me Do is frozen in time. Shortcuts has nothing. No modern macro recorder. |
| **Read message content** | Messages has 3 sdef commands (send, login, logout). Neither tool can read or search messages. |
| **Automate System Settings** | 3 sdef commands, no App Intents. The entire preferences system is dark. `defaults` CLI is the only way. |
| **Deep PDF workflows in Shortcuts** | Automator has 12 PDF actions. Shortcuts has zero. |
| **Deep image processing in Shortcuts** | Automator has 10+ image actions. Shortcuts has basic resize/convert only. |
| **Automate Disk Utility** | Zero sdef, zero Intents. `diskutil` CLI only. |
| **Automate Activity Monitor** | Zero sdef, zero Intents. `top`/`ps` CLI only. |
| **Save Shortcuts as standalone apps** | Automator can. Shortcuts can't. |
| **Folder actions in Shortcuts** | Automator can trigger on folder changes. Shortcuts can't watch folders. |

---

## The 36 Apps With Zero sdef

These apps have **no scripting dictionary at all** — AppleScript can only activate them, nothing more.

| App | Has App Intents? | Has URL Schemes? | The only way in |
|-----|:----------------:|:----------------:|-----------------|
| Activity Monitor | No | No | `top`, `ps`, `vm_stat` CLI |
| AirPort Utility | No | Yes (`apconfig:`) | URL scheme only |
| App Store | Yes (1 action) | Yes (`itms-apps:`) | URL + 1 Intent |
| Audio MIDI Setup | No | No | `system_profiler SPAudioDataType` |
| Books | Yes (27 actions) | Yes (`ibooks:`) | Intents + URL (no depth) |
| Calculator | Yes (1 action) | No | 1 Intent. `bc` CLI. |
| Chess | No | No | PGN files only |
| Clock | No | No | Widget. `date` CLI. |
| ColorSync Utility | No | No | `colorsync` CLI |
| Dictionary | No | Yes (`dict:`) | URL scheme + Services menu |
| Digital Color Meter | No | No | System Events UI only |
| Disk Utility | No | No | `diskutil`, `hdiutil` CLI |
| FaceTime | No | Yes (`facetime:`) | URL scheme to call contacts |
| Find My | No | Yes (`findmy:`) | URL scheme only |
| Font Book | No | Yes (`fontbook:`) | URL + `atsutil` CLI |
| Freeform | Yes (23 actions) | Yes (`freeform:`) | Rich Intents, no sdef depth |
| Grapher | No | No | GCX files only |
| Home | Yes (4 actions) | No | HomeKit Intents |
| Image Capture | No | No | `sips`, `system_profiler` |
| Launchpad | No | No | `open -a` CLI |
| Maps | Yes (16 actions) | Yes (`maps:`) | Rich Intents + URL |
| Migration Assistant | No | No | Not meaningfully automatable |
| Mission Control | No | No | `defaults write com.apple.dock` |
| News | Yes (1 action) | Yes (`applenews:`) | URL + 1 Intent |
| Passwords | No | Yes (`otpauth:`) | `security` CLI |
| Photo Booth | No | No | System Events UI only |
| Podcasts | No | Yes (`pcast:`) | URL scheme only |
| Preview | Yes (17 actions) | No | Intents but no sdef |
| Screenshot | No | No | `screencapture` CLI |
| Stickies | No | No | 1 Service ("Make Sticky") |
| Stocks | No | Yes (`stocks:`) | URL scheme only |
| Time Machine | No | No | `tmutil` CLI |
| Tips | Yes (1 action) | Yes (`help:`) | URL + 1 Intent |
| Voice Memos | Yes (14 actions) | No | Intents only |
| VoiceOver Utility | No | No | `VoiceOver` CLI |
| Weather | Yes (6 actions) | Yes (`weather:`) | Intents + URL |

**20 of these 36 have NO automation surface at all** — no sdef, no Intents, no URL schemes. The only way to control them is System Events UI scripting or CLI tools.

---

## The Bridge That Doesn't Exist

Sal's "AND not OR" — the bridge between AppleScript depth and Shortcuts width — would look like this:

```
┌─────────────────────────────────┐
│         Shortcuts               │  ← WIDTH: every app, every device
│  ┌───────────────────────────┐  │
│  │   Run AppleScript Action  │  │  ← THE MISSING BRIDGE
│  │   (like Automator has)    │  │
│  └───────────────────────────┘  │
│              ↓                  │
│     Apple Events / sdef         │  ← DEPTH: 30 apps, every property
└─────────────────────────────────┘
```

If Shortcuts had a `Run AppleScript` action, every scripting dictionary in the system would instantly become a Shortcuts action. 30 apps. Hundreds of commands. Thousands of properties. That's the AND.

Instead, each app must individually implement App Intents in Swift. 20 have. 46 haven't. And the 30 apps with rich scripting dictionaries — the depth layer Sal spent 20 years building — are invisible to Shortcuts entirely.

---

*The whole sausage. The whole widget. The whole service. Someone at Apple needs to think about this.*
