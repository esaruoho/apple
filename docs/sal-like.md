---
layout: default
title: "Sal-Like Tools"
---

# Sal-Like Tools


[← Back to home](./)
Tools that follow Sal Soghoian's automation philosophy: **one action, one result.** No intermediate steps, no configuration dialogs. The power of the computer resides in the hands of the one using it.

## Criteria

A tool is "Sal-like" when it:
- Collapses multiple manual steps into a single verb
- Produces **durable** results (not ephemeral — teaches the machine, builds lasting context)
- Requires zero configuration at invocation time
- Works from wherever you are (no "first cd to..." prerequisites)

## Catalog

| Tool | Command | What it does |
|------|---------|-------------|
| `ghc` | `ghc owner/repo` | Clone a GitHub repo + launch Claude Code + generate a permanent project skill. 7 steps → 1. |
| `ask` | `ask` | Launch Claude Code + trigger macOS dictation simultaneously. AppleScript + CLI fusion. |
| `app-probe` | `python3 bin/app-probe.py` | Extract 13 automation layers from 66 apps in 60 seconds. |
| `sdef-extract` | `python3 bin/sdef-extract.py` | Extract scripting dictionaries for 31 apps. |
| `workflow-gen` | `python3 bin/workflow-gen.py` | Generate 301 workflow scripts from curated recipes. |
| `spotlight-export` | `./bin/spotlight-export.sh` | Compile workflows to `.app` bundles in `/Applications/` — Spotlight-reachable. |
| `shortcut-gen` | `python3 bin/shortcut-gen.py` | Generate signed `.shortcut` files for Siri / Spotlight / Shortcuts.app. |
| `auto-gen` | `python3 bin/auto-gen.py` | Auto-generate 121 scripts from YAML dictionaries. |
| `batch-import` | `bin/batch-import.sh` | Import all shortcuts into Shortcuts.app with folder organization. |
| `extract-icons` | `./bin/extract-icons.sh` | Extract 64 app icons as PNG for Loupedeck buttons. |
| `github-watcher` | `github-watcher.sh` | PR & CI awareness bot — polls repos, macOS notifications. LaunchAgent. |
| `prwhy` | `prwhy.py` | Strategic PR viewer — PRs grouped by project pillar with the WHY. |
| `props` | `props` / `props 2373` | PR Operations TUI — curses triage with CI polling, rebase, build, conflict → Claude handoff. |
| `prbuild` | `prbuild` / `prbuild 2373` | Trigger Mac DMG builds, watch progress, download when done. 9 steps → 1. |
| `ghd` | `ghd` | Open GitHub Watcher dashboard (`localhost:3008`). |
| `slideshow` | `python3 bin/slideshow.py /path` | Fullscreen slideshow on any screen. Folder → presentation. One command. |
| `invert-images` | `swift bin/invert-images.swift <inDir> <outDir>` | Dark-mode screenshots → light-mode. Apple-native CoreImage (`CIColorInvert` + `CIGammaAdjust` + `CIColorControls`, defaults gamma 6 + contrast 2). |

## Deep dives

### `ghc` — GitHub Clone + Claude

Replaces 7 manual steps with 1: browse README, clone, open Claude, explain project, study conventions, build context, forget half of it next time.

Clones into the current directory, launches Claude Code, triggers the `github-cloner` skill which analyzes commits / PRs / issues / contributors / code structure / conventions. Generates a permanent skill at `~/.claude/skills/<repo-name>/SKILL.md` that persists across all future Claude sessions, on any project, forever.

**Why it's Sal-like:** one verb, permanent result. It doesn't just do a thing and throw away the context — it *teaches Claude the project*. Sal always hated ephemeral automation. His Automator workflows, his AppleScript dictionaries — they built up a machine's understanding of what you do. `ghc` does the same for AI-assisted development.

**The final Sal mile:** should eventually work from Spotlight. Type `ghc paketti`, hit enter, done.

- **Lives at:** `bin/ghc`, installed to `~/bin/ghc`
- **Skill source:** [esaruoho/github-cloner](https://github.com/esaruoho/github-cloner) (public)
- **Skills backup:** `esaruoho/esa-skills` (private)

### `ask` — Voice Dictation + Claude

Replaces 3 manual steps with 1: open terminal, type `claude`, click Edit → Start Dictation, wait, then speak.

Launches Claude Code and triggers macOS dictation simultaneously. The AppleScript waits 1.5 s for Claude to initialize, then activates Start Dictation via the Edit menu. Fire and forget — `osascript` runs in the background, Claude takes the foreground.

**Why it's Sal-like:** combining AppleScript with a CLI tool to create something neither could do alone. AppleScript handles the GUI automation (menu clicks), the shell handles the tool launch. The computer adapts to how you want to work (voice), not the other way around.

**The final Sal mile:** should be a Loupedeck Live button. One physical press, voice + AI, no screen interaction at all.

- **Lives at:** `bin/ask` + `scripts/start_dictation.scpt`, installed to `~/bin/ask`
