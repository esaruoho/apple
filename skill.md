---
name: apple
description: Product Manager of Automation Technologies — the role Apple eliminated, continued as open-source
domain: global
version: 3.5.0
generated: 2026-04-02T00:00:00Z
tags: [applescript, macos, automation, hardware-controllers, finder, system-events, workflow, sdef, scripting-dictionary, sal-soghoian, data-type-chaining, app-intents, shortcuts, url-schemes, painpoints, thought-multiplier, bbs, ray-browser]
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

## Boot Protocol

This skill is a thin index. Section bodies live in `wiki/` and are loaded only when relevant.

**Sal-archive refresh** runs only when the user's message mentions Sal, WWSD, archive, transcript, recovery, dashboard, status, or asks "what's left" / "continue" / "boot up Apple skill":

```bash
python3 bin/sal-archive-status.py --write analysis/sal/current-status.md
```

Then read `analysis/sal/current-status.md` and report. **Do not run the refresh for unrelated AppleScript / Loupedeck / image-batch / Finder / Spotlight questions** — it's the wrong dashboard for those.

For everything else, treat this file as a routing table: identify the topic, grep the matching wiki page, answer.

## Where things live

**Repo layout** (`/Users/esaruoho/work/apple/`):

- `bin/` — 65 CLI tools (executing layer); slashes in `commands/`
- `commands/` — 21 zero-roundtrip slash command pointers (install via `commands/install.sh`)
- `scripts/` — 301 launcher + workflow AppleScripts
- `dictionaries/` — 68 scripting-dictionary probe files
- `topbar/` — AppleToolbox menu-bar app (Apple-native Swift, no Homebrew)
- `homepod/` — HomePod climate sensor bridge
- `github-watcher/` — PR + CI awareness bot
- `painpoints/` — Apple UX evaluations
- `patents/` — automation patents + analyses
- `sources/sal/` — Sal Soghoian primary-source archive (transcripts, articles, media)
- `analysis/sal/` — Sal-specific working docs (status, discoveries, runbooks)
- `wiki/` — entity / concept / lesson / operations / compiled knowledge pages

## Wiki index (load on demand)

### Entities
- AppleToolbox menu-bar app → `wiki/entities/appletoolbox.md`
- Sal Soghoian (person, philosophy, WWSD) → `wiki/entities/sal-soghoian.md`
- Sal-like tools (one verb, one result) → `wiki/entities/sal-like.md`
- Loupedeck Live setup → `wiki/entities/loupedeck-guide.md`
- Loupedeck window management → `wiki/entities/loupedeck-window-management.md`
- Whiteboard Knob → `wiki/entities/whiteboard-knob.md`
- HomePod climate → `wiki/entities/homepod.md`
- GitHub Watcher + props + prbuild → `wiki/entities/github-watcher.md`
- Thought Multiplier → `wiki/entities/thought-multiplier.md`
- Bash aliases → `wiki/entities/bash-aliases.md`

### Concepts (how X works)
- Goldilocks Zone (respect user state) → `wiki/concepts/goldilocks-zone.md`
- Hardware controllers → `wiki/concepts/hardware-controllers.md`
- Apple-Native Only rule → `wiki/concepts/apple-native-only.md`
- Apple bundle ID drift (post-2016) → `wiki/concepts/apple-bundle-id-drift.md`
- PictureTaker broken on Sequoia → `wiki/concepts/picturetaker-sequoia.md`
- Mail smart-mailboxes dead → `wiki/concepts/mail-smart-mailboxes-dead.md`
- AppleScript best practices → `wiki/concepts/applescript-best-practices.md`
- Automation tiers (10-tier atlas) → `wiki/concepts/automation-tiers.md`
- Automator vs Shortcuts → `wiki/concepts/automator-vs-shortcuts.md`
- Scripting dictionaries → `wiki/concepts/scripting-dictionaries.md`
- App probe (13 layers) → `wiki/concepts/app-probe.md`
- App plist probe (1,934 plists) → `wiki/concepts/app-plist-probe.md`
- Apple's 7-layer automation architecture → `wiki/concepts/automation-architecture-7-layers.md`
- Sal Hand-Crafted Conformance → `wiki/concepts/sal-hand-crafted-conformance.md`
- CLI tool intelligence → `wiki/concepts/cli-tool-intelligence.md`
- Messages / iMessage automation → `wiki/concepts/messages-automation.md`
- Bulk exporters overview → `wiki/concepts/bulk-exporters.md`
- Vocal Shortcuts trigger surface → `wiki/concepts/vocal-shortcuts-trigger.md`
- Whiteboards (generated) → `wiki/concepts/whiteboards.md`
- Slideshow (folder → fullscreen) → `wiki/concepts/slideshow.md`
- Spotlight automation (5 paths + APFS bug + TCC fix) → `wiki/concepts/spotlight-automation.md`
- Self-learning behavior → `wiki/concepts/self-learning.md`
- Whiteboard integration → `wiki/concepts/whiteboard-integration.md`
- App icon extraction → `wiki/concepts/app-icon-extraction.md`
- iCloud.com URL shortcuts → `wiki/concepts/icloud-url-shortcuts.md`
- Pattern Reusability (the core principle) → `wiki/concepts/pattern-reusability.md`
- XPC atlas (2,359 services) → `wiki/concepts/xpc-atlas.md`
- Data type chaining → `wiki/concepts/data-type-chaining.md`
- WWSD decision tree → `wiki/concepts/wwsd-decision-tree.md`
- Script generators (workflow-gen, shortcut-gen, batch-import) → `wiki/concepts/script-generators.md`
- Tier-5-dark three-backdoor pattern → `wiki/concepts/tier-5-backdoor.md`
- Safari export schema gotchas → `wiki/concepts/safari-export-schema.md`
- Voice Memos `tsrp` atom → `wiki/concepts/voice-memos-tsrp-atom.md`
- QuickTime Pro scriptability cliff → `wiki/concepts/quicktime-pro-cliff.md`
- Rich-text clipboard recipe → `wiki/concepts/clipboard-rich-text.md`
- Sal cross-decade lineages → `wiki/concepts/sal-cross-decade-lineages.md`
- Steve Jobs as RBI practitioner → `wiki/concepts/steve-jobs-rbi.md`
- Compatibility (Apple Silicon, Sequoia) → `wiki/concepts/compatibility.md`
- Patents catalog → `wiki/concepts/patents.md`

### Lessons (runbooks / didactic)
- macOS installer + bootable USB → `wiki/lessons/macos-installer-bootable-usb.md`
- Apple ID credential recovery → `wiki/lessons/apple-id-recovery.md`
- Apple Driver's License + quiz → `wiki/lessons/apple-drivers-license.md`
- How this repo was built → `wiki/lessons/how-it-was-built.md`
- Sal: career to code → `wiki/lessons/sal-career-to-code.md`
- App-probe Sal pitch → `wiki/lessons/app-probe-sal-pitch.md`
- Video script → `wiki/lessons/video-script.md`

### Operations (active project state)
- Sal Session 717 replication → `wiki/operations/session-717-replication.md`
- WWDC Sal archive → `wiki/operations/wwdc-archive.md`
- Hey Sal v0 (seven layers) → `wiki/operations/hey-sal-v0.md`
- Sal archive operations runbook → `wiki/operations/sal-archive.md`

### Compiled (auto-regen, do not hand-edit)
- Scripts catalog → `wiki/compiled/scripts.md` (`bin/workflow-gen.py --catalog`)
- Siri phrases → `wiki/compiled/siri-phrases.md`
- Exporters index → `wiki/compiled/EXPORTERS.md` (`bin/gen-skill-indexes.py`)

