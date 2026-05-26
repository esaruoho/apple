---
layout: default
title: Trigger surfaces
---

# Seven trigger surfaces

[← Back to home](./)

Every automation needs a trigger. macOS exposes a surprising number of them — most users know one or two. This page maps the seven this repo actively uses, with the trade-off of each.

> *Trigger choice is a first-class design decision. The same action ("tag this file as `process`") feels different from a slash command vs. a Spotlight-launched .app vs. a global hotkey vs. dropping the file on an icon in the Finder toolbar.*

| # | Surface | Latency | Hands-free | Notes |
|---|---|---|---|---|
| 1 | [Slash command in Claude Code](#1-slash-command) | ~0ms after first invocation | No | Fastest path for "I'm at a keyboard with Claude open" |
| 2 | [Spotlight-reachable .app](#2-spotlight-app) | ~200ms | No | ⌘-Space, type, ⏎. Works system-wide. |
| 3 | [AppleToolbox menu-bar item](#3-appletoolbox) | ~100ms | No | Always-visible click target |
| 4 | [Global keyboard shortcut](#4-global-hotkey) | ~0ms | No | Hold ⇧⌥⌘ + key, anywhere |
| 5 | [Vocal Shortcuts](#5-vocal-shortcuts) | ~300ms | **Yes** | On-device, offline, UUID-stable |
| 6 | [Hardware controller (Loupedeck / Stream Deck / Contour)](#6-hardware) | ~0ms | Physical | Tactile, eyes-free, programmable |
| 7 | [Passive watchers (tag / mail-flag / voice-memo / Stickies)](#7-passive) | seconds | n/a | OS notices something, dispatches a worker |

---

## 1. Slash command

`/tag-app`, `/spotlight-export`, `/grand-export`, `/voicebox-submit`, `/hey-sal`, `/whisp-status` — 35 of them, all under [`commands/`](https://github.com/esaruoho/apple/tree/main/commands), installed into `~/.claude/commands/` by `commands/install.sh`.

After Claude reads the slash command's body once, every subsequent invocation is a direct bash exec — zero LLM roundtrip per call. This is the lowest-latency software-only trigger.

## 2. Spotlight .app

`bin/spotlight-export.sh` compiles every workflow script under `scripts/workflows/` into a `.app` bundle under `/Applications/AppleToolbox/Apple-Workflows/`. Spotlight indexes the whole folder automatically. ⌘-Space, type the app's name, ⏎.

304 workflow scripts → 304 spotlight-launchable verbs. See [`wiki/concepts/spotlight-automation.md`](https://github.com/esaruoho/apple/blob/main/wiki/concepts/spotlight-automation.md) for the 5 paths, APFS bug, and TCC fix.

## 3. AppleToolbox

[`topbar/AppleToolbox.swift`](https://github.com/esaruoho/apple/blob/main/topbar/AppleToolbox.swift) — Apple-native menu-bar app (`NSStatusItem` + `NSMenu`, no SwiftBar/xbar). Lives at `/Applications/AppleToolbox/AppleToolbox.app`. Click the 🧰 → see live status (HomePod climate, Mail, Music, Whisp queue) and click-to-fire actions.

Also hosts the global hotkeys and the passive watchers — it's the unified LaunchAgent surface so each subsystem inherits one Full-Disk-Access grant.

## 4. Global hotkey

Carbon `RegisterEventHotKey` registered inside AppleToolbox dispatches to ANY script / Shortcut / Automator / URL scheme. ⇧⌥⌘. → Stop Voicebox is the proof-of-concept. See [`wiki/concepts/global-keyboard-shortcuts.md`](https://github.com/esaruoho/apple/blob/main/wiki/concepts/global-keyboard-shortcuts.md) for the full gotcha set ([@objc required, two registration sites, Process() PATH is minimal, etc.](https://github.com/esaruoho/apple/blob/main/wiki/lessons/global-hotkeys-and-snapengine.md)).

## 5. Vocal Shortcuts

The only Mac surface that is **simultaneously**: hands-free + offline (on-device Neural Engine) + latency-free + UUID-stable across Shortcut renames. Every other voice path fails one of those. See [`wiki/concepts/vocal-shortcuts-trigger.md`](https://github.com/esaruoho/apple/blob/main/wiki/concepts/vocal-shortcuts-trigger.md) and the [11-property comparison matrix](https://github.com/esaruoho/apple/blob/main/analysis/sal/vocal-shortcuts-in-the-trigger-stack.md).

588 phrases registered in the [Hey Sal router](https://github.com/esaruoho/apple/blob/main/wiki/operations/hey-sal-v0.md).

## 6. Hardware

Loupedeck Live + Stream Deck + Contour ShuttlePro — physical buttons bound to `osascript` calls. Tactile, eyes-free, doesn't compete with software focus. See [`wiki/entities/loupedeck-guide.md`](https://github.com/esaruoho/apple/blob/main/wiki/entities/loupedeck-guide.md).

## 7. Passive watchers

The OS notices something, dispatches a worker. Four instances of the same chassis live in this repo:

- **Finder tag** ([`bin/tag-watcher`](https://github.com/esaruoho/apple/blob/main/bin/tag-watcher)) — file tagged `process` → script fires
- **Voice Memo `#process`** — recording with `#process` in title → whisp pipeline + summary
- **Stickies** ([`wiki/concepts/stickies-claude-trigger.md`](https://github.com/esaruoho/apple/blob/main/wiki/concepts/stickies-claude-trigger.md)) — note edited → worker reads it
- **Mail flag** ([`wiki/concepts/mail-flag-pipeline.md`](https://github.com/esaruoho/apple/blob/main/wiki/concepts/mail-flag-pipeline.md)) — message flagged with a color → `.eml` + attachments + body-md fan out per-color

See the [chassis page](./chassis) for the shared pattern.

---

[← Back to home](./) | [Tiers atlas →](./tiers) | [Sal corpus →](./sal-corpus) | [Trigger→worker chassis →](./chassis)
