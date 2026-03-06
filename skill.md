---
name: apple
description: Product Manager of Automation Technologies — the role Apple eliminated, continued as open-source
domain: global
version: 3.0.0
generated: 2026-03-05T00:00:00Z
tags: [applescript, macos, automation, hardware-controllers, finder, system-events, workflow, sdef, scripting-dictionary, sal-soghoian, data-type-chaining, app-intents, shortcuts, url-schemes, painpoints]
triggers:
  keywords:
    primary: [applescript, apple script, osascript, apple]
    secondary: [loupedeck, streamdeck, contour shuttle, macos automation, finder, system events, activate app, bring to front, sal, what would sal do, wwsd, shortcuts, app intents, siri phrases, painpoint]
---

# Apple Skill

> Product Manager of Automation Technologies — the role Apple eliminated in November 2016, continued as open-source. 66 apps probed across 13 layers, 1,254 Siri phrases, 246 Shortcuts actions, 111 URL schemes, 31 scripting dictionaries. The credo lives on: *"The power of the computer should reside in the hands of the one using it."*

## User Context

- **User**: Esa Juhani Ruoho ([@esaruoho](https://github.com/esaruoho)) — software tester, UI enthusiast, amateur scripter, automation/workflow obsessive, and user experience evaluator
- **OS**: macOS Sequoia (Darwin)
- **Hardware controllers**: Loupedeck Live, Contour Shuttle Pro, Stream Deck, and any programmable controller that can trigger shell commands
- **Use case**: Hardware buttons, keyboard shortcuts, Siri, and CLI all trigger AppleScripts via osascript to launch/activate apps, automate workflows, and optimize the workday

## Hardware Controller Integration

Any programmable controller (Loupedeck Live, Stream Deck, Contour Shuttle Pro, etc.) that can run shell commands works with these scripts:

```bash
osascript /path/to/script.scpt
# or inline:
osascript -e 'tell application "Finder" to activate'
# or Shortcuts:
shortcuts run "Shortcut Name"
```

For hardware-triggered scripts:
- **Fast** — no unnecessary delays
- **Reliable** — handle edge cases (app not running, etc.)
- **Single-purpose** — one button = one action

## AppleScript Best Practices

1. **Activate apps**: Use `tell application "AppName" to activate`
2. **Check if running**: `if application "AppName" is running then`
3. **System Events for UI**: `tell application "System Events"` for keystroke simulation, menu clicks, window manipulation
4. **Error handling**: Wrap risky operations in `try ... on error ... end try`
5. **Delays**: Only use `delay` when absolutely necessary (UI needs time to respond)
6. **Finder operations**: Finder is always running on macOS — just activate it
7. **AppleScript + CLI combo**: Run `osascript script.scpt &` in background from bash — fire and forget
8. **Use scripting dictionaries**: Before writing a script, check `dictionaries/<app>.md` for available commands, classes, and properties
9. **Use `shortcuts run`**: The `shortcuts` CLI bridges AppleScript (depth) to App Intents (width) — Sal's AND not OR

## The Automation Atlas — 6 Tiers

The README is the Automation Atlas — every Apple app tiered by automation depth. Key findings:

### Tier 1: Fully Automatable (AppleScript + Intents + URL schemes)
Mail (10 layers, 164 Siri phrases), Notes (318 Siri phrases, 50 actions — Siri champion), Finder (25 cmds, 67 phrases), Music (31 cmds, 123 phrases), Keynote, Numbers, Pages, Reminders, Shortcuts

### Tier 2: Deep AppleScript, No Intents
System Events (31 cmds, **89 classes** — deepest dictionary), TV, Photos, QuickTime, Logic Pro, iMovie, Terminal, TextEdit, Script Editor, Safari, Calendar, Contacts, Messages, Final Cut Pro, Automator

### Tier 3: Intents But No AppleScript
Freeform (144 phrases), Books (125 phrases), Weather (149 phrases), Maps (17 queries), Preview (35 phrases), Voice Memos (45 phrases), Home, Calculator, App Store, News, Tips

### Tier 4: URL Schemes Only
FaceTime, Passwords, Podcasts, Stocks, Find My, Font Book, Dictionary, Screen Sharing

### Tier 5: Nearly Dark
Activity Monitor, Audio MIDI Setup, Disk Utility, Image Capture, Screenshot, System Settings, Photo Booth, Stickies, Console, Chess, Grapher, VoiceOver Utility, Clock, Migration Assistant

### Tier 6: Completely Dark
Launchpad, Mission Control, Time Machine

**Key insight**: Every "dark" app is a GUI wrapper around a CLI tool that's more powerful (diskutil > Disk Utility, screencapture > Screenshot, tmutil > Time Machine, defaults > System Settings).

## Scripting Dictionaries (Domain Knowledge)

**31 apps extracted** to `dictionaries/` via `bin/sdef-extract.py`. Each app has:
- `<app>.yaml` — machine-readable: commands, classes, properties, data types
- `<app>.md` — human-readable: full scripting reference with descriptions
- `<app>-examples.md` — ready-to-use AppleScript snippets
- `<app>-probe.yaml` — 13-layer automation probe (from app-probe.py)
- `<app>-probe.md` — human-readable probe results

**Data type chaining** (`dictionaries/_index.yaml`): maps which apps produce/consume which data types — the Automator patent (US 7,428,535) vision realized as a lookup table.

### Key Chains Discovered
- **Image Events → 7 apps**: Produces `alias`/`file` → feeds into Automator, Logic Pro, Preview, Script Editor, TextEdit, iMovie, System Information
- **System Events → 9 apps**: Produces `file` → feeds into Music, Photos, Keynote, Numbers, Pages, QuickTime, Terminal, Mail, Bluetooth
- **Mail → Mail**: `outgoing message` loops back for mail merge workflows
- **Contacts → Contacts**: `person` type for contact manipulation
- **12 apps produce `document`** → feeds into Keynote, Numbers, Pages, QuickTime
- **System Events** is the universal bridge (89 classes, 31 commands) — it can control ANY app's UI

## App Intelligence Layers (13 Layers via app-probe.py)

`bin/app-probe.py` extracts **13 layers** from every Apple app into `dictionaries/<app>/<app>-probe.yaml`:

| # | Layer | Source | Method |
|---|-------|--------|--------|
| 1 | Scripting Dictionary | App bundle | `sdef` tool |
| 2 | URL Schemes | Info.plist `CFBundleURLTypes` | `plistlib` |
| 3 | Document Types | Info.plist `CFBundleDocumentTypes` | `plistlib` |
| 4 | **App Intents / Siri Phrases** | `Metadata.appintents/extract.actionsdata` | `json.load` |
| 5 | NSServices | Info.plist `NSServices` | `plistlib` |
| 6 | User Activity Types | Info.plist `NSUserActivityTypes` | `plistlib` |
| 7 | Entitlements | App binary | `codesign --entitlements` |
| 8 | Linked Frameworks | App binary | `otool -L` |
| 9 | Spotlight Metadata | Spotlight index | `mdls` |
| 10 | LaunchServices | LS database | `lsregister -dump` (opt-in) |
| 11 | Plugin Extensions | `Contents/PlugIns/*.appex` | Directory scan |
| 12 | Notification Actions | Info.plist `UNUserNotificationCenter` | `plistlib` |
| 13 | CLI Tools | `/usr/bin/*` | Path check |

**66 apps, 378 layer hits, 20 with App Intents, 35 with URL schemes, 32 CLI tools.**

Cross-app index: `dictionaries/_probe-index.yaml` — URL scheme registry, App Intents summary, framework matrix, services map.

## Apple's Automation Architecture — 7 Layers

Discovered through framework analysis:

```
Layer 1: Apple Events / OSA        ← osascript, OSAKit, ScriptingBridge (DEPTH)
Layer 2: Automator                  ← AMWorkflow, AMAction
Layer 3: Intents (legacy, ObjC)     ← INIntent, 14 apps
Layer 4: AppIntents (modern, Swift) ← 82 protocols, 23 apps (WIDTH)
Layer 5: Shortcuts/WorkflowKit      ← Visual composition of Layer 4
Layer 6: Siri/AssistantSchema       ← Natural language routing
Layer 7: Apple Intelligence         ← GenerativeAssistantActions
```

The `shortcuts run` CLI is the bridge: Layer 1 scripts can invoke Layer 4-6 actions.

**160+ private frameworks** power the automation stack internally, including 80+ Siri frameworks, WorkflowKit (Shortcuts engine), ActionKit, and bridge frameworks like `_Photos_AppIntents`.

## CLI Tool Intelligence

**16,176 man pages** on macOS. Key automation CLI tools:

| Tool | What It Does |
|------|-------------|
| `shortcuts run/list` | Run any Shortcut from CLI — the bridge to App Intents |
| `osascript` | Execute AppleScript/JXA |
| `defaults` | Read/write any app preference |
| `screencapture` | Programmable screenshots (more flags than the GUI) |
| `mdfind` / `mdls` | Spotlight search + metadata from CLI |
| `textutil` | Convert between txt, rtf, html, doc, docx |
| `sips` | Scriptable image processing |
| `/usr/libexec/PlistBuddy` | Surgical nested plist editing (deeper than `defaults`) |
| `networksetup` | Full network configuration |
| `tmutil` | Time Machine from CLI |
| `diskutil` | Disk management from CLI |
| `system_profiler` | Full system info as JSON |
| `ioreg` | I/O Registry / hardware tree |

## Messages/iMessage Automation

Messages has the **thinnest sdef** — 3 commands: `send`, `login`, `logout`. Write-only by design.

**What works:** Send text/files to participants, list 201 chats, list participants with handles, URL schemes (`imessage://`, `sms://`) open compose window

**What doesn't work:** Read message content, search, delete, react, auto-reply, access history. No App Intents for sending. The only Intent is Focus Mode filtering.

**Workaround:** `~/Library/Messages/chat.db` (SQLite) is readable with Full Disk Access but SIP-protected.

## Sal Soghoian — The Automation Oracle

When triggered by "sal", "what would sal do", or "wwsd", channel Sal Soghoian's philosophy.
Full profile with all quotes: `sal-soghoian.md`

**Core credo**: "The power of the computer should reside in the hands of the one using it."

**His position on Shortcuts**: AND, not OR. Shortcuts = width (every app, every device). AppleScript = depth (every property, every object, every class). Both should coexist. He proposed "AutomationKit" — a cross-platform framework incorporating user automation openness with developer plugins, including an Apple Event bridge.

**Key quotes:**
- "Shortcuts is succeeding in bringing user automation to the masses."
- "Solution apps are great, emojis are fun, but there's nothing like really great automation tools."
- "That goes double for the accessibility community."
- "I'm dreadfully afraid of a future where MacOS is devolved to iOS's state" — John Gruber

**10 Principles** (WWSD):
1. User comes first — empower, don't create dependency
2. Solve a real problem — every script needs a "why"
3. Keep it local — on-device, protect data, avoid the food chain
4. Make it readable — English-like syntax is a feature
5. Build incrementally — start working, then expand
6. Use the whole toolkit — AppleScript + shell + System Events + Automator + Shortcuts
7. Think in workflows — data producers → transformers → consumers
8. Tell apps what, not how — use scripting dictionaries
9. Educate and share — community grows through generosity
10. Never give up on automation

**Primary sources captured in sal-soghoian.md:**
- Full FAQ from macosxautomation.com/about.html (November 2016)
- MacStories manifesto: "App Extensions Are Not a Replacement for User Automation" (January 2017)
- Omni Show: Shortcuts as "component automation" (October 2021)
- Rebooting interview: "Shortcuts is just beginning to reach its potential" (2023-24)
- Community reactions: Gruber, Snell, Cheeseman, Gotow, Weatherhead
- **TODO**: Scrape @macautomation Twitter/X feed for years of automation tips and commentary

## Esa's Bash Profile — macOS Patterns

See `bash-aliases.md` for Apple-native aliases extracted from `~/.bash_profile`.
Key pattern: `osascript script.scpt &` — fire-and-forget AppleScript from bash (used in `ask()` function).

## Public/Private Split

**Public** (pushed to GitHub `esaruoho/apple`):
- README.md, skill.md, scripts/, dictionaries/, bin/, patents/, sal-soghoian.md, scripts.md

**Private** (gitignored, local only):
- bash-aliases.md, whiteboards/, icons/

## Whiteboards Generated

34 whiteboards across 5 sets in `whiteboards/`:

| Set | Boards | Topic |
|-----|--------|-------|
| `bash-aliases/` | 5 | macOS bash patterns, osascript integration |
| `automation-atlas/` | 5 | Full scriptability map, CLI tools |
| `sal-soghoian/` | 4 | Sal's career, philosophy, WWSD |
| `sdef-deep-dive/` | 10 | Atlas deep dive: all 4 tiers, CLI tools, terminal automation |
| `sdef-understanding/` | 10 | How Sal connected every app: sdef architecture, data type chains, narrative |

## Sal-Like Tools

Tools in this repo that follow Sal's philosophy: one action, one result.

| Tool | Command | What it does |
|------|---------|-------------|
| `ghc` | `ghc owner/repo` | Clone a GitHub repo + launch Claude Code + generate a permanent project skill. 7 steps → 1. |
| `ask` | `ask` | Launch Claude Code + trigger macOS dictation simultaneously. AppleScript + CLI fusion. |
| `app-probe` | `python3 bin/app-probe.py` | Extract 13 automation layers from 66 apps in 60 seconds. |
| `sdef-extract` | `python3 bin/sdef-extract.py` | Extract scripting dictionaries for 31 apps. |
| `workflow-gen` | `python3 bin/workflow-gen.py` | Generate 109 workflow scripts from curated recipes across 15 apps. |
| `spotlight-export` | `./bin/spotlight-export.sh` | Compile workflows to .app bundles in ~/Applications/ — Spotlight-reachable. |
| `extract-icons` | `./bin/extract-icons.sh` | Extract 64 app icons as PNG for Loupedeck buttons. |

## Spotlight Integration — The Final Sal Mile

Every workflow script can be compiled to a Spotlight-reachable `.app` via `osacompile`. Full guide: `spotlight-automation.md`.

**5 paths to Spotlight:**

| # | Method | Best For | How |
|---|--------|----------|-----|
| 1 | `osacompile` to .app | AppleScripts (our workflows) | `osacompile -o ~/Applications/X.app script.applescript` |
| 2 | Shortcuts | App Intents width | Create Shortcut with "Run AppleScript" action |
| 3 | Automator Quick Actions | Context-dependent (selected files/text) | Save to `~/Library/Services/` |
| 4 | Automator Application | Multi-action pipelines | Save as .app to `~/Applications/` |
| 5 | Shell wrapper | CLI tools (ghc, ask, etc.) | `osacompile -o X.app -e 'do shell script "cmd"'` |

**Pipeline:** `sdef-extract.py` (extract) → `workflow-gen.py` (generate) → `spotlight-export.sh` (export to Spotlight)

```bash
# Export all 109 workflows as Spotlight-reachable apps
./bin/spotlight-export.sh

# Then: Cmd+Space → "Music PlayPause" → Enter
```

**Critical `osacompile` gotcha:** Apps compiled with `osacompile` have NO `CFBundleIdentifier` in their `Info.plist`. Without a bundle ID, Spotlight ignores them. `spotlight-export.sh` injects one via PlistBuddy.

**APFS Spotlight bug:** On APFS Macs, `/Applications/` lives on the Data volume (`/System/Volumes/Data`). If indexing is disabled on that volume, Spotlight can't find ANY installed apps — only system apps in `/System/Applications/`. Diagnose with `mdutil -sa`. Fix with `sudo mdutil -i on /System/Volumes/Data && sudo mdutil -E /System/Volumes/Data`. Full troubleshooting guide in `spotlight-automation.md`.

**14 Apple apps use CoreSpotlight framework** for content indexing: App Store, Books, Calendar, Freeform, Mail, Maps, News, Notes, Photos, Podcasts, Reminders, System Settings, Tips, Voice Memos.

## Patents

| Patent | Title | Relevance |
|--------|-------|-----------|
| US 7,428,535 B1 | Automatic Relevance Filtering | The Automator patent — context-aware action filtering, data type bridging, modular workflows |

Full analysis: `patents/US7428535-analysis.md`

## Knowledge Files

| File | Purpose |
|------|---------|
| `skill.md` | This file — skill definition + knowledge base (public) |
| `README.md` | **The Automation Atlas** — 66 apps tiered by automation depth |
| `sal-soghoian.md` | **Sal Soghoian knowledge base** — full profile, quotes, Shortcuts position, community reactions, @macautomation scraping plan |
| `spotlight-automation.md` | **Spotlight integration guide** — 5 paths to make scripts Cmd+Space reachable |
| `scripts.md` | Catalog of all AppleScripts (64 launchers + 109 workflows = 173 scripts) |
| `scripts/launchers/` | 64 app launcher scripts (every Apple app + utility) |
| `scripts/workflows/` | **109 workflow scripts** across 15 apps — the action layer |
| `dictionaries/` | **31 scripting dictionaries + 66 probe files** |
| `dictionaries/_index.yaml` | Data type chaining index — cross-app workflow compatibility |
| `dictionaries/_probe-index.yaml` | 13-layer probe index — URL schemes, App Intents, frameworks, services |
| `bin/app-probe.py` | 13-layer automation probe |
| `bin/sdef-extract.py` | Scripting dictionary extractor |
| `bin/workflow-gen.py` | Workflow script generator (109 recipes across 15 apps) |
| `bin/spotlight-export.sh` | Compile workflows to Spotlight-reachable .app bundles |
| `bin/extract-icons.sh` | App icon extractor for Loupedeck |
| `bin/ghc` | GitHub Clone + Claude skill generator |
| `bin/ask` | Voice dictation + Claude launcher |
| `patents/` | Apple automation patents and analyses |
| `icons/` | 64 app icons as 256x256 PNG (gitignored, regenerable) |
| `whiteboards/` | 34 visual educational whiteboards (gitignored) |

## Self-Learning Behavior

**This skill is self-updating.** Every conversation in `/Users/esaruoho/work/apple/`:
- **Learn**: When Esa describes workflows, preferences, app behaviors, or macOS quirks — capture them in skill files
- **Update**: New scripts get added to `scripts.md`, new patterns get added to this file, new context gets added to memory
- **Remember**: The skill maintains a living memory at `~/.claude/projects/-Users-esaruoho-work-apple/memory/MEMORY.md`
- **Grow**: Over time this skill accumulates deep knowledge of Esa's exact macOS setup, apps, workflows, and automation needs
- **Push**: All knowledge goes to GitHub `esaruoho/apple` so nothing is lost

When Esa tells you something new about his setup, apps, or preferences — **write it down immediately**. Don't wait to be asked.

## Whiteboard Integration

The Apple skill uses the **BBS Whiteboard skill** (`~/.claude/skills/whiteboard/`) to generate visual educational whiteboards. When Esa asks for whiteboards in this workspace:

```bash
~/.claude/skills/whiteboard/bin/whiteboard-generate.sh --full --count N --text "content"
```

Output goes to `/Users/esaruoho/work/apple/whiteboards/`

## App Icon Extraction

When Esa says "gimme logo of Photos" or "icon for Mail":

1. **Single icon:** `./bin/extract-icons.sh --app Photos --open`
2. **All icons:** `./bin/extract-icons.sh --open`
3. **Custom size:** `./bin/extract-icons.sh --size 512`

Icons are 256x256 PNG by default — ideal for Loupedeck Live button icons.

## Patterns Catalog

See `scripts.md` for the growing catalog of AppleScripts created for Loupedeck Live buttons.
