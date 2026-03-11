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

**288 workflow scripts** across 31 apps. A four-stage pipeline that extracts what apps can do, writes scripts, makes them Spotlight-searchable, and creates Siri-speakable Shortcuts — all from a single Python run. Plus 121 auto-generated scripts from YAML dictionaries, a HomePod climate sensor bridge, and the full [10-tier automation atlas](automation-tiers.md) mapping every layer from AppleScript to IOKit.

---

## The Pipeline

```
sdef-extract.py → workflow-gen.py → spotlight-export.sh → shortcut-gen.py
"what can apps do"  "write scripts"   "make findable"       "make speakable"
```

Each tool's output feeds the next. Add a recipe, run the chain, and it appears in Spotlight AND Siri automatically.

| Stage | Tool | What it does |
|-------|------|-------------|
| 1. Extract | [`bin/sdef-extract.py`](bin/sdef-extract.py) | Parse AppleScript dictionaries (sdef) into structured YAML |
| 2. Generate | [`bin/workflow-gen.py`](bin/workflow-gen.py) | 288 curated workflow recipes → `.applescript` files with teaching comments |
| 2b. Auto-gen | [`bin/auto-gen.py`](bin/auto-gen.py) | 121 additional scripts auto-generated from YAML dictionaries |
| 3. Export | [`bin/spotlight-export.sh`](bin/spotlight-export.sh) | Compile to `.app` bundles in `/Applications/Apple-Workflows/` for Spotlight |
| 4. Shortcut | [`bin/shortcut-gen.py`](bin/shortcut-gen.py) | Generate signed `.shortcut` files for Siri and Shortcuts app |
| 5. Import | [`bin/batch-import.sh`](bin/batch-import.sh) | Batch-import all shortcuts into Shortcuts.app with folder organization |

---

## 288 Workflow Scripts

Every script in [`scripts/workflows/`](scripts/workflows/) is a real automation — not just an app launcher. Skip a song, empty the trash, toggle dark mode, copy the current Safari URL, create a calendar event, check battery status, open System Settings panes.

Each script includes **teaching comments** that explain the AppleScript concepts used (tell blocks, error handling, notifications, shell scripts, etc.).

```
Finder ............. 28    Music .............. 37    System Events ...... 26
Safari ............. 15    Mail ............... 13    Calendar ............ 9
Reminders ........... 9    Photos .............. 9    Notes ............... 8
Keynote ............ 10    TV ................. 10    System Settings ..... 8
Terminal ............ 6    QuickTime ........... 6    Pages ............... 6
Numbers ............ 6    Automator ........... 5    Image Events ........ 5
Script Editor ....... 5    Screenshot .......... 4    Contacts ............ 4
Shortcuts ........... 4    HomePod ............ 11    Time Machine ........ 4
System Information .. 4    Disk Utility ........ 3    Console ............. 3
Preview ............ 4    Messages ............ 3    iMovie .............. 2
TextEdit ............ 5    Accessibility ....... 8    Hardware ............ 8
```

**v3.2:** Added 15 new apps: TV, Keynote, Pages, Numbers, Automator, Script Editor, Image Events, iMovie, System Information, Preview, System Settings, Disk Utility, Screenshot, Console, Time Machine. Plus Accessibility API (Tier 8) and Hardware/IOKit (Tier 10) scripts.

```bash
# Run any workflow directly
osascript scripts/workflows/music/music-playpause.applescript
osascript scripts/workflows/finder/finder-empty-trash.applescript
osascript scripts/workflows/system-events/system-events-dark-mode-toggle.applescript

# Generate all 288 scripts from recipes
python3 bin/workflow-gen.py

# Compile to Spotlight-searchable .app bundles
bin/spotlight-export.sh

# Generate Siri Shortcuts
python3 bin/shortcut-gen.py
```

### Auto-Generated Scripts (121 additional)

[`bin/auto-gen.py`](bin/auto-gen.py) reads the YAML scripting dictionaries and auto-generates workflow scripts for every safe no-arg command and readable property. It skips anything already covered by the 288 hand-curated scripts.

```bash
python3 bin/auto-gen.py              # Generate all 121 auto-workflows
python3 bin/auto-gen.py --app music  # Generate for one app
python3 bin/auto-gen.py --list       # Dry run — show what would be generated
```

Output: [`scripts/auto-workflows/`](scripts/auto-workflows/) — 121 scripts across 10 apps (Music: 69, System Events: 30, Finder: 6, Safari: 6, Photos: 4, QuickTime: 3, Messages: 2, Calendar: 1).

### Batch Import to Shortcuts.app

[`bin/batch-import.sh`](bin/batch-import.sh) imports all generated `.shortcut` files into Shortcuts.app, creates an "Apple Workflows" folder, and organizes everything automatically.

```bash
bin/batch-import.sh                    # Import all shortcuts
bin/batch-import.sh finder             # Import one app's shortcuts
bin/batch-import.sh --dry-run          # Show what would be imported
bin/batch-import.sh --count            # Count available shortcuts
bin/batch-import.sh --folder "My Name" # Custom folder name
```

---

## HomePod Climate Sensor

Reads temperature and humidity from a HomePod's hidden sensor via the Shortcuts CLI, logs to JSONL, and serves a live dashboard.

```
HomePod sensor → Shortcuts app → shortcuts run CLI → bash script → JSONL log → live graph
```

```bash
cd homepod/
./homepod-climate.sh              # Single reading — log + graph
./homepod-climate.sh --stdout     # Print JSON only
./homepod-climate.sh --dump       # Show today's readings
./climate-summary.sh              # Daily min/max/avg
./start.sh                        # Continuous logger + dashboard server (port 3007)
```

Calibrated against a professional sensor (Feb 2026): +0.45C temperature, +4.5% humidity. Runs as a LaunchAgent every 10 minutes. See [`homepod/README.md`](homepod/README.md) for setup.

---

## GitHub Watcher — PR & CI Awareness

Monitors your open-source repos for PR and CI changes — macOS notifications + live dashboard. Same architecture as the HomePod climate sensor: periodic poll → state diff → notification → dashboard.

```
gh CLI (poll) → JSON state (diff) → display notification (alert) → Python server (dashboard)
```

```bash
cd github-watcher/
./github-watcher.sh              # Run once — notify on changes
./github-watcher.sh --stdout     # Print status to terminal
./github-watcher.sh --reset      # Clear state, start fresh
python3 prwhy.py                 # Strategic view — PRs grouped by pillar
python3 prwhy.py --all           # All watched repos
```

**`prwhy`** groups PRs by *what they advance*, not when they were created. Each project gets its own strategic pillars:

| Project | Pillars |
|---------|---------|
| **Apple** | Automation, Probing, Tools, Documentation |
| **Paketti** | Workflow, Instruments, Import/Export, UI, Bug Fixes |
| **CircuitJS1** | Simulation Accuracy, New Components, Visual/UX, Import/Export, Example Circuits |
| **LENR Academy** | Content, Discovery, UI/UX, Infrastructure |

Runs as a LaunchAgent every 10 minutes. Dashboard at `http://localhost:3008`. See `github-watcher/repos.json` to configure which repos to watch.

---

## The Automation Atlas — 66 Apps, 13 Layers

`bin/app-probe.py` extracts **13 layers of automation intelligence** from every Apple app in a single 60-second pass — the complete automation surface of macOS that no one else has mapped.

```
66 apps probed · 378 layer hits · 31 with scripting dictionaries
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
| [`ghc`](bin/ghc) | `ghc owner/repo` | Clone a GitHub repo + launch Claude Code + generate a permanent project skill. 7 steps -> 1. |
| [`ask`](bin/ask) | `ask` | Launch Claude Code + trigger macOS dictation simultaneously. AppleScript + CLI fusion. |
| [`app-probe`](bin/app-probe.py) | `python3 bin/app-probe.py` | Extract 13 automation layers from 66 apps in 60 seconds. The census Sal never had. |
| [`workflow-gen`](bin/workflow-gen.py) | `python3 bin/workflow-gen.py` | Generate 288 workflow scripts from curated recipes with teaching comments. |
| [`spotlight-export`](bin/spotlight-export.sh) | `bin/spotlight-export.sh` | Compile all workflows to Spotlight-searchable `.app` bundles. |
| [`shortcut-gen`](bin/shortcut-gen.py) | `python3 bin/shortcut-gen.py` | Generate signed Siri Shortcuts from AppleScript workflows. |
| [`auto-gen`](bin/auto-gen.py) | `python3 bin/auto-gen.py` | Auto-generate 121 scripts from YAML dictionaries. Fill the gaps. |
| [`batch-import`](bin/batch-import.sh) | `bin/batch-import.sh` | Import all shortcuts into Shortcuts.app with folder organization. |
| [`xpc-probe`](bin/xpc-probe.py) | `python3 bin/xpc-probe.py` | Map 2,359 XPC services — the hidden automation layer. |
| [`github-watcher`](github-watcher/github-watcher.sh) | `github-watcher.sh` | PR & CI awareness bot — polls repos, macOS notifications on changes. |
| [`prwhy`](github-watcher/prwhy.py) | `prwhy.py` | Strategic PR viewer — PRs grouped by project pillar with the WHY. |

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

## Launcher Scripts

64 one-liner AppleScripts in [`scripts/launchers/`](scripts/launchers/) — one per Apple app. Use from Terminal, Loupedeck Live buttons, or any automation tool:

```bash
osascript scripts/launchers/activate-mail.applescript
osascript scripts/launchers/activate-logic-pro.applescript
```

---

## Deep Dives

| Document | What it covers |
|----------|---------------|
| [**Automation Tiers**](automation-tiers.md) | Full 10-tier stack: AppleScript → XPC → Accessibility → IOKit. Coverage matrix. |
| [**XPC Atlas**](xpc-atlas.md) | 2,359 XPC services mapped across 18 app categories. The hidden 87%. |
| [**Data Type Chaining**](data-type-chaining.md) | How apps pass data between each other. The Automator patent vision. |
| [**WWSD Decision Tree**](wwsd-decision-tree.md) | "What Would Sal Do?" — choosing the right automation approach. |
| [**Siri Phrases**](siri-phrases.md) | All 288 voice commands for generated shortcuts in a browsable table. |
| [**Compatibility**](compatibility.md) | Apple Silicon vs Intel, macOS version requirements. |
| [**Automator vs Shortcuts**](automator-vs-shortcuts.md) | 227 vs 246 actions. The gap analysis. |
| [**Spotlight Automation**](spotlight-automation.md) | 5 paths to make scripts Cmd+Space searchable. TCC fix for Sequoia. |
| [**Apple Driver's License**](apple-drivers-license.md) | The user knowledge layer: where your data lives, what you own vs. rent, what breaks when. |
| [**Loupedeck Guide**](loupedeck-guide.md) | Setup guide for Loupedeck Live, Stream Deck, and hardware controllers. |
| [**How It Was Built**](how-it-was-built.md) | One conversation, 167 files — the build story. |
| [**App Probe Pitch**](app-probe-sal-pitch.md) | Why app-probe.py is the tool Sal would have killed for in 1997. |
| [**Video Script**](video-script.md) | Demo script for the "288 Workflows, One Pipeline" walkthrough. |

---

## Painpoints

UX evaluations by **[@esaruoho](https://github.com/esaruoho)** (Esa Juhani Ruoho) — software tester, UI enthusiast, amateur scripter, automation/workflow obsessive, and user experience evaluator. These are my takes on Apple's current state, reported one at a time: the missing bits and pieces where the automation surface fails the user. Filed with click counts, Sal's principles, and fix paths.

| ID | App | Issue | Status |
|----|-----|-------|--------|
| [PLATFORM-001](painpoints/PLATFORM-001-automation-fragmentation.md) | macOS | Automation splintered across 5 incompatible layers | Open |
| [SYSTEM-SETTINGS-001](painpoints/SYSTEM-SETTINGS-001-most-important-app-least-scriptable.md) | System Settings | Most-used app, least scriptable (3 commands) | Open |
| [PREVIEW-001](painpoints/PREVIEW-001-no-applescript-despite-being-default-viewer.md) | Preview | Default viewer with zero AppleScript support | Open |
| [HOME-001](painpoints/HOME-001-no-applescript-homekit-cli.md) | Home | No AppleScript, no CLI for HomeKit | Open |
| [PHOTOS-001](painpoints/PHOTOS-001-shallow-scripting-dictionary.md) | Photos | Shallow scripting dictionary (read-only) | Open |
| [MESSAGES-001](painpoints/MESSAGES-001-write-only-automation.md) | Messages | Write-only automation (can send, can't read) | Open |
| [NOTES-001](painpoints/NOTES-001-record-audio.md) | Notes | Recording audio should be one action, not five clicks | Open |
| [DISK-UTILITY-001](painpoints/DISK-UTILITY-001-no-scripting-for-disk-management.md) | Disk Utility | Zero scripting for the only disk management GUI | Open |
| [ACTIVITY-MONITOR-001](painpoints/ACTIVITY-MONITOR-001-no-scripting-for-process-management.md) | Activity Monitor | Zero scripting for process monitoring and management | Open |
| [TIME-MACHINE-001](painpoints/TIME-MACHINE-001-no-scripting-for-backups.md) | Time Machine | Zero scripting for the most critical data protection app | Open |
| [SCREENSHOT-001](painpoints/SCREENSHOT-001-no-scripting-for-screen-capture.md) | Screenshot | CLI is more powerful than the GUI, neither connects to Shortcuts | Open |

---

## Automator vs Shortcuts

[**The Gap Analysis**](automator-vs-shortcuts.md) — 227 Automator actions vs 246 Shortcuts actions. What each can do that the other can't. And the bridge that doesn't exist: Shortcuts has no `Run AppleScript` action, so 30 apps with rich scripting dictionaries are invisible to it. 36 apps have zero sdef. 20 apps have zero automation surface at all. The whole sausage.

---

## How It All Connects

[**From Publishing Consultant to Patent to This Repo**](sal-career-to-code.md) — the cross-analysis tracing Sal's career arc through the Automator patent to what this repository builds. Publishing automation in the 1990s -> Automator at Apple -> context-aware relevance filtering -> scripting dictionaries -> departure -> this repo as open-source continuation.

---

## About

**Esa Ruoho** — user automation practitioner, software developer, musician (30+ albums, 203 gigs, 20 countries), and workflow optimizer. Works at [Ray Browser](https://raybrowser.com). Creator of [Paketti](https://github.com/esaruoho/paketti) (3,022-feature workflow suite for Renoise). Believes automation is a right, not a feature.

Built with [Claude Code](https://claude.ai/) and a custom [Apple skill](https://github.com/esaruoho/esa-skills).

Inspired by **Sal Soghoian** — Apple's Product Manager of Automation Technologies (1997-2016), co-inventor of Automator ([US Patent 7,428,535](patents/US7428535-analysis.md)), and the person who proved that the power of the computer should reside in the hands of the one using it. [Read the full profile ->](sal-soghoian.md)

---

*The power of the computer should reside in the hands of the one using it.*
