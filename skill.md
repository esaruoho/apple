---
name: apple
description: Write perfect AppleScript, automate macOS, and optimize workflows for Loupedeck Live integration
domain: global
version: 2.0.0
generated: 2026-03-05T00:00:00Z
tags: [applescript, macos, automation, loupedeck, finder, system-events, workflow, sdef, scripting-dictionary, sal-soghoian, data-type-chaining]
triggers:
  keywords:
    primary: [applescript, apple script, osascript, apple]
    secondary: [loupedeck, macos automation, finder, system events, activate app, bring to front, sal, what would sal do, wwsd]
---

# Apple Skill

> Write perfect AppleScript for macOS automation, Loupedeck Live integration, and Ray Browser workflow optimization.

## User Context

- **User**: Esa Ruoho — Apple aficionado, works at Ray Browser
- **Hardware**: Loupedeck Live (physical controller with programmable buttons)
- **Use case**: Loupedeck Live buttons trigger AppleScripts via osascript to launch/activate apps, automate workflows, and optimize the workday
- **OS**: macOS (Darwin)

## Loupedeck Live Integration

The Loupedeck Live software allows custom actions that can run shell commands. AppleScripts are executed via:
```bash
osascript /path/to/script.scpt
# or inline:
osascript -e 'tell application "Finder" to activate'
```

For Loupedeck buttons, scripts should be:
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
7. **AppleScript + CLI combo**: Run `osascript script.scpt &` in background from bash — fire and forget. The `ask()` function pattern: trigger macOS dictation via AppleScript, then launch a CLI tool. This is the Sal-worthy bridge between GUI automation and Terminal power.
8. **Use scripting dictionaries**: Before writing a script, check `dictionaries/<app>.md` for available commands, classes, and properties. Every scriptable app's full API is extracted there.

## Scripting Dictionaries (Domain Knowledge)

**31 apps extracted** to `dictionaries/` via `bin/sdef-extract.py`. Each app has:
- `<app>.yaml` — machine-readable: commands, classes, properties, data types
- `<app>.md` — human-readable: full scripting reference with descriptions
- `<app>-examples.md` — ready-to-use AppleScript snippets
- `<app>.sdef.xml` — raw Apple sdef XML

**Data type chaining** (`dictionaries/_index.yaml`): maps which apps produce/consume which data types — the Automator patent (US 7,428,535) vision realized as a lookup table.

### Key Chains Discovered
- **Image Events → 7 apps**: Produces `alias`/`file` → feeds into Automator, Logic Pro, Preview, Script Editor, TextEdit, iMovie, System Information
- **System Events → 9 apps**: Produces `file` → feeds into Music, Photos, Keynote, Numbers, Pages, QuickTime, Terminal, Mail, Bluetooth
- **Mail → Mail**: `outgoing message` loops back for mail merge workflows
- **Contacts → Contacts**: `person` type for contact manipulation
- **12 apps produce `document`** → feeds into Keynote, Numbers, Pages, QuickTime
- **System Events** is the universal bridge (89 classes, 31 commands) — it can control ANY app's UI

## Skill Location

Everything lives in `/Users/esaruoho/work/apple/`:
- `skill.md` — this file (skill definition + knowledge base)
- `scripts.md` — catalog of all AppleScripts
- `scripts/` — the actual `.applescript` files

## Self-Learning Behavior

**This skill is self-updating.** Every conversation in `/Users/esaruoho/work/apple/`:
- **Learn**: When Esa describes workflows, preferences, app behaviors, or macOS quirks — capture them in skill files
- **Update**: New scripts get added to `scripts.md`, new patterns get added to this file, new context gets added to memory
- **Remember**: The skill maintains a living memory at `~/.claude/projects/-Users-esaruoho-work-apple/memory/MEMORY.md` and topic-specific files in that directory
- **Grow**: Over time this skill accumulates deep knowledge of Esa's exact macOS setup, apps, workflows, and automation needs

When Esa tells you something new about his setup, apps, or preferences — **write it down immediately**. Don't wait to be asked.

## Sal Soghoian — The Automation Oracle

When triggered by "sal", "what would sal do", or "wwsd", channel Sal Soghoian's philosophy.
Full profile: `sal-soghoian.md`

**Core credo**: "The power of the computer should reside in the hands of the one using it."

**10 Principles** (WWSD):
1. User comes first — empower, don't create dependency
2. Solve a real problem — every script needs a "why"
3. Keep it local — on-device, protect data, avoid the food chain
4. Make it readable — English-like syntax is a feature
5. Build incrementally — start working, then expand
6. Use the whole toolkit — AppleScript + shell + System Events + Automator
7. Think in workflows — data producers → transformers → consumers
8. Tell apps what, not how — use scripting dictionaries
9. Educate and share — community grows through generosity
10. Never give up on automation

## Patents

| Patent | Title | Relevance |
|--------|-------|-----------|
| US 7,428,535 B1 | Automatic Relevance Filtering | The Automator patent — context-aware action filtering, data type bridging, modular workflows |

Full analysis: `patents/US7428535-analysis.md`

## Esa's Bash Profile — macOS Patterns

See `bash-aliases.md` for Apple-native aliases extracted from `~/.bash_profile`.
Key pattern: `osascript script.scpt &` — fire-and-forget AppleScript from bash (used in `ask()` function).

## Knowledge Files

| File | Purpose |
|------|---------|
| `skill.md` | This file — skill definition + knowledge base (private, gitignored) |
| `apple-automation-atlas.md` | **The Atlas** — complete map of every Apple app's automation capabilities |
| `scripts.md` | Catalog of all AppleScripts |
| `scripts/` | Workflow scripts |
| `scripts/launchers/` | 64 app launcher scripts (every Apple app + utility) |
| `dictionaries/` | **31 app scripting dictionaries** — .yaml, .md, -examples.md per app |
| `dictionaries/_index.yaml` | **Data type chaining index** — cross-app workflow compatibility map |
| `dictionaries/_probe-index.yaml` | **13-layer probe index** — URL schemes, App Intents, frameworks, services across all 66 apps |
| `bin/sdef-extract.py` | Extractor tool — regenerate dictionaries with `python3 bin/sdef-extract.py` |
| `bin/app-probe.py` | **13-layer automation probe** — `python3 bin/app-probe.py` extracts ALL automation knowledge from 66 apps |
| `bin/extract-icons.sh` | Extract 64 Apple app icons as PNG — `./bin/extract-icons.sh` or `--app Photos` |
| `icons/` | **64 app icons** as 256x256 PNG (private, gitignored, regenerable) |
| `sal-soghoian.md` | Sal Soghoian profile, philosophy, "What Would Sal Do" |
| `bash-aliases.md` | macOS-native bash aliases from Esa's profile (private, gitignored) |
| `patents/` | Apple automation patents and analyses |
| `how-it-was-built.md` | Full conversation replay — 22 prompts, 8 phases, how the repo was created |
| `video-script.md` | 10-scene video script with marketing psychology annotations |

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

## Public/Private Split

**Public** (pushed to GitHub `esaruoho/apple`):
- README.md, scripts/, dictionaries/, bin/, patents/, sal-soghoian.md, apple-automation-atlas.md, scripts.md

**Private** (gitignored, local only):
- skill.md, bash-aliases.md, whiteboards/, icons/

## Whiteboards Generated

34 whiteboards across 5 sets in `whiteboards/`:

| Set | Boards | Topic |
|-----|--------|-------|
| `bash-aliases/` | 5 | macOS bash patterns, osascript integration |
| `automation-atlas/` | 5 | Full scriptability map, CLI tools |
| `sal-soghoian/` | 4 | Sal's career, philosophy, WWSD |
| `sdef-deep-dive/` | 10 | Atlas deep dive: all 4 tiers, CLI tools, terminal automation |
| `sdef-understanding/` | 10 | How Sal connected every app: sdef architecture, data type chains, narrative |

## Automation Tiers (from the Atlas)

- **Tier 1 (Fully Scriptable)**: Finder, Mail, Safari, Music, Photos, Notes, Reminders, Calendar, Contacts, Messages, TV, TextEdit, Preview, QuickTime Player, Keynote, Numbers, Pages, Final Cut Pro, Logic Pro, iMovie, Automator, Shortcuts
- **Tier 2 (Scriptable Utilities)**: Terminal, Script Editor, Console, System Information, Screen Sharing, Bluetooth File Exchange
- **Tier 3 (Hidden Powerhouses)**: System Events, Image Events, Finder (CoreServices)
- **Tier 4 (Activate + UI Script)**: Everything else — launchable and controllable via System Events UI scripting

## Whiteboard Integration

The Apple skill uses the **BBS Whiteboard skill** (`~/.claude/skills/whiteboard/`) to generate visual educational whiteboards for any Apple automation topic. When Esa asks for whiteboards in this workspace, generate them using:

```bash
~/.claude/skills/whiteboard/bin/whiteboard-generate.sh --full --count N --text "content"
# or from a file:
~/.claude/skills/whiteboard/bin/whiteboard-generate.sh --full --count N ./file.md
```

Output goes to `/Users/esaruoho/work/apple/whiteboards/`

### When to Whiteboard
- New skill files are created (bash-aliases, atlas, sal profile) → offer whiteboards
- Esa says "board it", "whiteboard this", "visualize" → generate boards
- Complex automation topics benefit from visual explanation

## App Icon Extraction

When Esa says "gimme logo of Photos" or "icon for Mail":

1. **Single icon:** `./bin/extract-icons.sh --app Photos --open` — extracts and opens the folder
2. **All icons:** `./bin/extract-icons.sh --open` — all 64 at once
3. **Custom size:** `./bin/extract-icons.sh --size 512` — for higher-res needs

Icons are 256x256 PNG by default — ideal for Loupedeck Live button icons.

**Two extraction methods** (handled automatically):
- **sips** — for apps with `.icns` files (58 apps)
- **Swift/NSWorkspace** — for apps using Asset Catalogs: Calendar, Photo Booth, System Settings, Voice Memos, Migration Assistant, System Information

Icons are gitignored (`icons/`) — regenerable on any Mac via the script.

## Patterns Catalog

See `scripts.md` for the growing catalog of AppleScripts created for Loupedeck Live buttons.
