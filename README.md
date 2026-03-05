# apple

### Apple Automation Architecture & Workflows — studying macOS automation libraries and continuing [Sal Soghoian's](sal-soghoian.md) vision.

[![macOS](https://img.shields.io/badge/macOS-Sequoia-000000?style=flat-square&logo=apple&logoColor=white)](https://www.apple.com/macos/)
[![AppleScript](https://img.shields.io/badge/AppleScript-Automation-blue?style=flat-square)](https://developer.apple.com/library/archive/documentation/AppleScript/Conceptual/AppleScriptLangGuide/introduction/ASLR_intro.html)
[![Built with Claude Code](https://img.shields.io/badge/Built_with-Claude_Code-blueviolet?style=flat-square)](https://claude.ai/)
[![License: MIT](https://img.shields.io/badge/License-MIT-green?style=flat-square)](LICENSE)

---

## What is this?

In November 2016, Apple eliminated the position of **Product Manager of Automation Technologies** — the role [Sal Soghoian](sal-soghoian.md) held for nearly 20 years. The person who built Automator, championed AppleScript, and believed *"the power of the computer should reside in the hands of the one using it"* was told his job no longer existed.

This repo picks up where that role left off.

`bin/app-probe.py` extracts **13 layers of automation intelligence** from every Apple app in a single 60-second pass — the complete automation surface of macOS that no one else has mapped. The results below are the current state of the platform.

---

## The Automation Atlas — 66 Apps, 13 Layers

```
66 apps probed · 378 layer hits · 30 with scripting dictionaries
20 with App Intents · 35 with URL schemes · 11 with Services menu
```

### Tier 1: Fully Automatable (AppleScript + Intents + URL schemes)

These apps can be controlled from every angle — deep scripting, Shortcuts actions, Siri voice commands, and URL invocation.

| App | AppleScript | App Intents | URL Schemes | Services | Also |
|-----|:-----------:|:-----------:|:-----------:|:--------:|------|
| **Mail** | 16 cmds, 25 classes | 26 actions, 164 Siri phrases | `mailto:`, `message:` | 2 | 6 plugins, 6 notification actions |
| **Notes** | 2 cmds, 4 classes | 50 actions, **318 Siri phrases** | `applenotes:`, `notes:` | — | 5 plugins |
| **Finder** | 25 cmds, 32 classes | 16 actions, 67 Siri phrases | `file:`, `afp:`, `smb:`, `ftp:` +5 | 3 | 1 plugin |
| **Music** | 31 cmds, 26 classes | 23 actions, 123 Siri phrases | `music:`, `itunes:`, `itms:` +10 | — | 2 plugins |
| **Keynote** | 28 cmds, 22 classes | 2 actions | `com.apple.iwork.keynote-share:` | — | 1 plugin |
| **Numbers** | 16 cmds, 21 classes | 2 actions | `com.apple.iwork.numbers-share:` | — | 1 plugin |
| **Pages** | 11 cmds, 23 classes | 2 actions | `com.apple.iwork.pages-share:` | — | 1 plugin |
| **Reminders** | 1 cmd, 3 classes | 1 action | `x-apple-reminderkit:` | — | 5 plugins |
| **Shortcuts** | 1 cmd, 2 classes | 13 actions, 49 Siri phrases | `shortcuts:`, `workflow:` | — | 4 plugins |

**Notes is the Siri champion** with 318 phrases and 50 actions — Apple's most intent-rich app. Mail is the deepest overall with 10 automation layers active.

### Tier 2: Deep AppleScript, No Intents

Rich scripting dictionaries for programmatic control, but Apple hasn't added Shortcuts/Siri integration yet. These are the power user apps.

| App | AppleScript | URL Schemes | Services | Notes |
|-----|:-----------:|:-----------:|:--------:|-------|
| **System Events** | **31 cmds, 89 classes** | — | — | The deepest dictionary on macOS. UI scripting, processes, property lists, disk management. The Swiss army knife. |
| **TV** | 29 cmds, 16 classes | `com.apple.tv:`, `videos:` +5 | — | Full media library control |
| **Photos** | 18 cmds, 5 classes | `photos:`, `cloudphoto:` | — | Album/media management |
| **QuickTime Player** | 15 cmds, 5 classes | — | — | Recording and playback control |
| **Logic Pro** | 13 cmds, 12 classes | `logicpro:`, `applelogicpro:` | — | Track, region, and mixing automation |
| **iMovie** | 13 cmds, 12 classes | — | — | Project and event scripting |
| **Terminal** | 13 cmds, 4 classes | `ssh:`, `telnet:`, `x-man-page:` | 4 | The bridge between GUI and CLI |
| **TextEdit** | 13 cmds, 12 classes | — | 2 | Rich text automation |
| **Script Editor** | 16 cmds, 16 classes | `applescript:` | 3 | Meta: scripting the scripting tool |
| **Safari** | 10 cmds, 1 class | `http:`, `https:` +3 | 2 | Tab/window/URL control |
| **Calendar** | 8 cmds, 7 classes | `ical:`, `webcal:` | — | Event and calendar management |
| **Contacts** | 8 cmds, 12 classes | `addressbook:` | — | People data access |
| **Messages** | 3 cmds, 4 classes | `imessage:`, `sms:` +5 | — | Send/receive automation |
| **Final Cut Pro** | 1 cmd, 5 classes | — | — | Minimal sdef, mostly XML workflow |
| **Automator** | 16 cmds, 17 classes | — | 2 | Sal's creation, still scriptable |

**System Events** (31 commands, 89 classes) is the most powerful scripting dictionary on the platform — and it has zero Intents. It's the foundation for UI scripting everything else.

### Tier 3: Intents But No AppleScript

These apps went straight to Shortcuts/Siri without adding AppleScript. Modern automation — wide but not deep.

| App | App Intents | URL Schemes | How to automate deeper |
|-----|:-----------:|:-----------:|------------------------|
| **Freeform** | 23 actions, 144 phrases | `freeform:` | System Events UI scripting for board manipulation |
| **Books** | 27 actions, 125 phrases | `ibooks:`, `itms-books:` | URL schemes for navigation, Intents for library management |
| **Weather** | 6 actions, **149 Siri phrases** | `weather:` | Intents-only — "Hey Siri" is the primary interface |
| **Maps** | 16 actions, 17 queries | `maps:`, `map:`, `mapitem:` +4 | URL schemes are powerful: pass addresses, coordinates directly |
| **Preview** | 17 actions, 35 phrases | — | System Events for window/document control; `qlmanage` CLI for Quick Look |
| **Voice Memos** | 14 actions, 45 phrases | — | Intents for recording control; files in `~/Library/Group Containers/` |
| **Home** | 4 actions | — | HomeKit framework; `shortcuts run` for scene triggers |
| **Calculator** | 1 action | — | `python3 -c` or `bc` from Terminal. Calculator is a UI, not an API. |
| **App Store** | 1 action, 27 phrases | `itms-apps:`, `macappstore:` | URL schemes to open specific app pages |
| **News** | 1 action | `applenews:` | URL scheme to open articles; limited automation surface |
| **Tips** | 1 action, 8 phrases | `help:`, `x-apple-tips:` | URL scheme only |

### Tier 4: URL Schemes Only

Not scriptable, no Intents, but you can launch and navigate via URL.

| App | URL Schemes | Workaround |
|-----|:-----------:|------------|
| **FaceTime** | `facetime:`, `facetime-audio:`, `tel:` +3 | URL to call specific contacts. System Events for UI. |
| **Passwords** | `otpauth:`, `apple-otpauth:` +2 | OTP URL scheme. Keychain CLI: `security find-generic-password` |
| **Podcasts** | `pcast:`, `podcast:`, `itms-podcasts:` | URL to open specific podcasts. No scripting at all. |
| **Stocks** | `stocks:` | URL to open specific tickers. System Events for UI. |
| **Find My** | `findmy:`, `fmf1:`, `fmip1:` +2 | URL only. No scripting, no Intents. |
| **Font Book** | `fontbook:` | URL to open fonts. `atsutil` CLI for font management. |
| **Dictionary** | `dict:`, `x-dictionary:` | URL + Services menu ("Look Up in Dictionary"). |
| **Screen Sharing** | `vnc:` | 1 sdef command. `open vnc://host` from CLI. |

### Tier 5: Nearly Dark — Minimal Automation

These apps have almost no automation surface. The only way in is System Events UI scripting (click menus, press buttons by accessibility label) or CLI tools.

| App | What it has | The only way in |
|-----|-------------|-----------------|
| **Activity Monitor** | entitlements only | `top`, `ps`, `vm_stat`, `iostat` from CLI. The app is just a GUI for these. |
| **Audio MIDI Setup** | entitlements only | `system_profiler SPAudioDataType`, `coreaudiod`. The app is a GUI wrapper. |
| **Disk Utility** | entitlements only | `diskutil` CLI does everything the app does. `hdiutil` for disk images. |
| **Image Capture** | entitlements only | `system_profiler SPUSBDataType` for device detection. `sips` for image processing. |
| **Screenshot** | entitlements only | `screencapture` CLI. More flags than the GUI offers. |
| **Digital Color Meter** | entitlements only | System Events UI scripting or `colorpicker` third-party tools. |
| **System Settings** | 3 cmds, 2 classes + URL | `open "x-apple.systempreferences:..."` for specific panes. `defaults` CLI for all prefs. |
| **Photo Booth** | document types only | System Events UI scripting. `imagecapture` framework. |
| **Stickies** | document types + 1 service | "Make Sticky" service from any text selection. That's it. |
| **Console** | 1 sdef command | `log` CLI. `log show --predicate '...'` is more powerful than the GUI. |
| **Chess** | document types only | PGN file format. No scripting. |
| **Grapher** | document types only | GCX file format. System Events UI only. |
| **VoiceOver Utility** | document types only | `VoiceOver` CLI. Accessibility API scripting. |
| **Clock** | activity_types + plugin | Widget only. System Events or `date` CLI. |
| **Migration Assistant** | activity_types only | Not meaningfully automatable — it's a one-time wizard. |

### Tier 6: Completely Dark

| App | Layers | Reality |
|-----|--------|---------|
| **Launchpad** | 2 (frameworks, spotlight) | It's just a view of `/Applications`. Use `open -a` instead. |
| **Mission Control** | 2 (frameworks, spotlight) | `defaults write com.apple.dock` + `killall Dock`. Or keyboard shortcut via System Events. |
| **Time Machine** | 2 (frameworks, spotlight) | `tmutil` CLI does everything. `tmutil startbackup`, `tmutil listbackups`, etc. |

---

## The Pattern: Everything Dark Has a CLI

The key insight from the probe: **every "dark" app is a GUI wrapper around a CLI tool that's more powerful.**

| Dark App | Its CLI Equivalent | More Powerful? |
|----------|--------------------|:--------------:|
| Activity Monitor | `top`, `ps`, `vm_stat` | Yes |
| Disk Utility | `diskutil`, `hdiutil` | Yes |
| Screenshot | `screencapture` | Yes |
| Console | `log show` | Yes |
| Time Machine | `tmutil` | Yes |
| System Settings | `defaults` | Yes |
| Image Capture | `sips`, `system_profiler` | Yes |
| Launchpad | `open -a` | Same |
| Mission Control | `defaults write com.apple.dock` | Same |

**Sal knew this.** His "use the whole toolkit" principle (#6 from [WWSD](sal-soghoian.md)) — AppleScript is the hub, but chain with `do shell script` for anything the GUI can't reach. The CLI tools ARE the automation surface for these apps.

---

## Sal-Like Tools

Tools in this repo that follow [Sal Soghoian's automation philosophy](sal-like.md): one action, one result.

| Tool | Command | What it does |
|------|---------|-------------|
| [`ghc`](bin/ghc) | `ghc owner/repo` | Clone a GitHub repo + launch Claude Code + generate a permanent project skill. 7 steps → 1. |
| [`ask`](bin/ask) | `ask` | Launch Claude Code + trigger macOS dictation simultaneously. AppleScript + CLI fusion. |
| [`app-probe`](bin/app-probe.py) | `python3 bin/app-probe.py` | Extract 13 automation layers from 66 apps in 60 seconds. The census Sal never had. |

---

## App Automation Probe

```bash
python3 bin/app-probe.py                    # All 66 apps, all layers
python3 bin/app-probe.py Mail               # Single app
python3 bin/app-probe.py --layer intents    # Only App Intents
python3 bin/app-probe.py --cli              # Include CLI tools
python3 bin/app-probe.py --list             # Show available apps
```

Output per app: `dictionaries/<app>/<app>-probe.yaml` + `<app>-probe.md`
Cross-app index: `dictionaries/_probe-index.yaml`

---

## About

**Esa Ruoho** — user automation practitioner, software developer, musician (30+ albums, 203 gigs, 20 countries), and workflow optimizer. Works at [Ray Browser](https://raybrowser.com). Creator of [Paketti](https://github.com/esaruoho/paketti) (3,022-feature workflow suite for Renoise). Believes automation is a right, not a feature.

Built with [Claude Code](https://claude.ai/) and a custom [Apple skill](https://github.com/esaruoho/esa-skills).

Inspired by **Sal Soghoian** — Apple's Product Manager of Automation Technologies (1997–2016), co-inventor of Automator ([US Patent 7,428,535](patents/US7428535-analysis.md)), and the person who proved that the power of the computer should reside in the hands of the one using it. [Read the full profile →](sal-soghoian.md)

---

*The power of the computer should reside in the hands of the one using it.*
