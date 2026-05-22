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

## Default tool order (updated 2026-05-22 after Sal's ASObjC pointer)

When a task needs code, pick in this order:

1. **AppleScript + AppleScriptObjective-C (ASObjC)** — `use framework "Foundation"` gives every public Cocoa class from a plain `.applescript` file. No Swift, no compile, runs in `osascript`. This is the default. See [`wiki/concepts/asobjc.md`](wiki/concepts/asobjc.md) for the tier doc; [`wiki/concepts/wwsd-decision-tree.md`](wiki/concepts/wwsd-decision-tree.md) for branching.
2. **Python stdlib** — when no public Cocoa class exists for the domain (verify with `bin/cocoa-class-probe ClassName`), or when stdlib is genuinely cleaner (e.g. plain plist read/write — `NSSavedSearch` doesn't exist as a public class, so `plistlib` wins for Smart Folders).
3. **Swift compile** — only when AS+ASObjC genuinely can't reach (e.g. KVO subclassing for AVFoundation, custom NSWindow subclasses, Carbon hotkeys via menu-bar apps).
4. **Shell** — for orchestration and Apple-shipped CLIs (`mdfind`, `defaults`, `xattr`, etc.). NEVER for third-party CLIs.

**Hard rule:** Before naming any Cocoa class in a proposal, run `bin/cocoa-class-probe NSXxxx`. PUBLIC verdict required. ABSENT means the name is wrong. See project memory `feedback_probe_before_naming_cocoa_classes.md`.

## Boot Protocol

This skill is a thin index. Section bodies live in `wiki/` and are loaded only when relevant.

**Sal-archive refresh** runs only when the user's message mentions Sal, WWSD, archive, transcript, recovery, dashboard, status, or asks "what's left" / "continue" / "boot up Apple skill":

```bash
python3 bin/sal-archive-status.py --write analysis/sal/current-status.md
```

Then read `analysis/sal/current-status.md` and report. **Do not run the refresh for unrelated AppleScript / Loupedeck / image-batch / Finder / Spotlight questions** — it's the wrong dashboard for those.

For everything else, treat this file as a routing table: identify the topic, grep the matching wiki page, answer.

**Tag pipeline + Dock manager (added 2026-05-21):** Two Apple-native control surfaces wired into the skill. When the user says "tag this", "needs-ocr", "send to OCR", "ocr-failed", "Smart Folder", "talkback" → see [`wiki/concepts/finder-tag-pipeline.md`](wiki/concepts/finder-tag-pipeline.md). When the user says "add to Dock", "pin to Dock", "Dock tile" → see [`wiki/concepts/dock-management.md`](wiki/concepts/dock-management.md). Sidebar Favorites is dead on Sequoia — [`wiki/concepts/finder-sidebar-locked.md`](wiki/concepts/finder-sidebar-locked.md) for why.

## Repo layout

`/Users/esaruoho/work/apple/`:

- `bin/` — 65+ CLI tools; slashes in `commands/`
- `commands/` — 30+ zero-roundtrip slash command pointers (install via `commands/install.sh`)
- `scripts/` — 301 launcher + workflow AppleScripts
- `dictionaries/` — 68 scripting-dictionary probe files
- `topbar/`, `homepod/`, `github-watcher/` — entity sub-packages
- `painpoints/`, `patents/` — Apple UX evaluations + automation patents
- `sources/sal/`, `analysis/sal/` — Sal Soghoian primary-source archive + working docs
- `wiki/` — knowledge layer:
  - **`wiki/INDEX.md`** — auto-generated catalog of every page with one-line description. **Read this first for any topical question.** Regenerate with `/wiki-index` or `python3 bin/wiki-index.py`.
  - `wiki/log.md` — append-only chronological record (ingests, lint passes, migrations).
  - `wiki/README.md` — schema and conventions.

## Wiki schema

| Subdir | Purpose |
|---|---|
| `wiki/entities/` | one page per *thing* — person, app, device, package |
| `wiki/concepts/` | one page per *how X works* — atlas, principle, pattern |
| `wiki/lessons/` | didactic / narrative / runbook |
| `wiki/operations/` | active project state — current work, status, plans |
| `wiki/compiled/` | auto-generated, do not hand-edit |

Each page: one H1, optional `description:` frontmatter, ≤250 lines, cross-link to related pages. After adding or editing, run `/wiki-index` then `/wiki-lint` to refresh the index and catch orphans / oversized pages / broken refs.

When you learn something new and durable, write it to the right subdir, then `/wiki-index`. The catalog is the source of truth for the LLM — keep it fresh.
