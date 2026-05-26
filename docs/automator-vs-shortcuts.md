---
layout: default
title: Automator vs Shortcuts — the gap analysis
---

# Automator vs Shortcuts — the gap analysis

[← Back to home](./)

What Automator can do that Shortcuts can't. What Shortcuts can do that Automator can't. And what neither can do that someone at Apple should be thinking about.

## By the numbers

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

## What Automator has that Shortcuts doesn't

### 1. Scripting escape hatches

Automator's killer feature: when the built-in actions aren't enough, drop to code.

- **Run AppleScript** — full AppleScript with access to every scripting dictionary
- **Run Shell Script** — bash, zsh, python, ruby, perl, any CLI tool
- **Run JavaScript** — JXA with Cocoa bridge

Shortcuts has none of these. If a Shortcuts action doesn't exist for what you want, you're stuck. There's no escape hatch to raw code.

### 2. Save As Anything

Automator workflows can become:

| Output | What it means |
|---|---|
| **Application** (`.app`) | Double-click to run. Drag files onto it. Put it in the Dock. |
| **Quick Action / Service** | Right-click context menu, Services menu, Touch Bar |
| **Folder Action** | Triggers automatically when files are added to a folder |
| **Calendar Alarm** | Triggers at a scheduled time via Calendar |
| **Print Plugin** | Appears in the Print dialog |
| **Dictation Command** | Triggers by voice (Sal's addition) |
| **Image Capture Plugin** | Triggers when importing from scanner/camera |

A Shortcut can be: a Shortcut. That's it.

### 3. Watch Me Do

Automator records UI actions and plays them back. Crude but unmatched for apps with no scripting interface. Shortcuts has no equivalent.

## What Shortcuts has that Automator doesn't

### 1. Cross-device

Shortcuts run on Mac + iPhone + iPad + Watch. Automator is Mac-only.

### 2. Siri integration

Shortcuts can be voice-triggered via Siri or [Vocal Shortcuts](./triggers#5-vocal-shortcuts) (the only Mac surface that is hands-free + offline + latency-free + UUID-stable). Automator workflows cannot.

### 3. URL scheme + CLI

`shortcuts://run-shortcut?name=Foo` works from any app or browser. `shortcuts run Foo` works from any shell. Automator workflows have no URL scheme and no CLI shipping with macOS.

### 4. App Intents (the modern bridge)

App Intents is the framework Apple has actually invested in. Any modern app exposing automation does it through App Intents → Shortcuts → Siri. Automator's path is dormant.

## Status

**Automator is deprecated.** Still ships on every Mac, still works, but receives no updates. Shortcuts is the actively-developed path.

**That doesn't mean Automator is obsolete.** For Mac-only workflows that need scripting escape hatches OR need to live as a Quick Action / Folder Action / Calendar Alarm — Automator is still the right tool. For cross-device, Siri-callable, App-Intents-leveraging work, Shortcuts is the right tool.

## What neither can do (Apple, take note)

- **AppleScript / shell-script escape hatch *inside* Shortcuts.** Removed circa Shortcuts-for-Mac launch. Apple's reasoning was sandboxing; the user-author cost has been enormous. The closest workaround is a Run Shortcut action that wraps an Automator workflow that calls AppleScript — three levels deep.
- **CLI to compile Automator workflows.** `osacompile` does it for AppleScript. There's no `automatorcompile`. You have to launch Automator.app.
- **A unified action library.** Automator's 227 actions and Shortcuts' 246 actions are separate catalogs. The user has to know which app to launch before they can see what's possible.
- **First-class CLI invocation of Automator outputs.** `open -a` works but you can't pass arguments cleanly.

## Read more

- Source-of-truth: [`wiki/concepts/automator-vs-shortcuts.md`](https://github.com/esaruoho/apple/blob/main/wiki/concepts/automator-vs-shortcuts.md) — full gap analysis with action-by-action coverage table.
- The decision tree: [`wiki/concepts/wwsd-decision-tree.md`](https://github.com/esaruoho/apple/blob/main/wiki/concepts/wwsd-decision-tree.md) — when to reach for which.
- Pattern-reusability principle: [`wiki/concepts/pattern-reusability.md`](https://github.com/esaruoho/apple/blob/main/wiki/concepts/pattern-reusability.md) — why neither tool alone is sufficient.

---

[← Back to home](./) | [Triggers ←](./triggers) | [Tiers ←](./tiers) | [Sal corpus ←](./sal-corpus) | [Chassis ←](./chassis) | [ASObjC ←](./asobjc) | [Finder-tag ←](./finder-tag-pipeline) | [Spotlight ←](./spotlight) | [WWSD ←](./wwsd)
