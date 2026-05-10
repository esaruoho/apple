---
title: Vocal Shortcuts in the Apple trigger-surface stack
date: 2026-05-11
status: analysis — comparative placement against the other voice/trigger paths
host: macOS 15 Sequoia, Apple Silicon (M3 Pro)
related:
  - analysis/sal/vocal-shortcuts-storage-format.md
  - analysis/sal/sal-siri-on-mac-theory.md
  - analysis/sal/macos-sequoia-dictation-runtime-removal.md
  - skill.md (Vocal Shortcuts section, line ~599)
---

# What Vocal Shortcuts actually is

Vocal Shortcuts is the **on-device, user-trained, no-Siri-required** speech trigger
surface introduced in macOS 15 Sequoia (Apple Silicon only). It lives in
*System Settings → Accessibility → Speech → Vocal Shortcuts*, is implemented by
the assistant daemon family (`siriinferenced`, `assistantd`), and stores its
phrase-to-action bindings as a JSON blob inside `com.apple.Accessibility.plist`
under `AVSPreferenceKey` (full schema in
`vocal-shortcuts-storage-format.md`).

Each entry binds **one spoken phrase** (which the user must train by speaking it
three times) to **one of three action kinds**:

1. `siriShortcut` — runs a named Shortcut in Shortcuts.app
2. `siriRequest` — fires a free-form Siri command (no "Hey Siri" wake-word required)
3. `accessibility` — toggles a system Accessibility primitive (Voice Control, VoiceOver, Zoom, etc.)

Once a phrase is trained, **no wake-word is needed**. The user simply speaks the
phrase and the bound action fires. The matching runs locally on the Neural Engine.

# Why it exists — Apple's reframing of WWDC 2016 Session 717

Sal Soghoian's Session 717 demoed dictation-driven Mac automation built on the
**Custom Commands plist runtime** (`~/Library/Application Support/com.apple.speech.DictationIKHCommands`).
That runtime quietly disappeared from macOS around 10.13/10.14 (full timeline in
`macos-sequoia-dictation-runtime-removal.md`). For roughly five years there was
**no public, non-Siri voice trigger surface on the Mac**. Vocal Shortcuts is its
return — under Accessibility branding, with a fixed wiring shape (must go through
a Shortcut), and Apple Silicon-gated.

This is the practical succession line:

```
2016  Custom Commands plist  →  arbitrary AppleScript / shell        (removed)
2024  Vocal Shortcuts        →  Shortcut → Run AppleScript action    (current)
```

The engine layer (AppleScript / `.scptd` libraries) is preserved. The wiring
layer changed: instead of plist → command, it's now phrase → Shortcut → script.

# Where it sits in the 13-layer probe

In the apple skill's automation inventory, Vocal Shortcuts is unambiguously
**Layer 3 — Trigger surfaces**. It sits alongside, not above or below, the other
ways a workflow can be invoked. The engine (Layer 1) and wiring (Layer 2) are
independent of whether the trigger is a Loupedeck key or a spoken phrase.

```
Layer 3 — Trigger        Loupedeck | Spotlight | hotkey | menu bar | Siri | Hey Siri |
                         Vocal Shortcut | Shortcuts.app click | URL scheme | cron/launchd
Layer 2 — Wiring         Shortcuts.app workflow | osacompile .app | Automator | UI scripting
Layer 1 — Engine         AppleScript / AppleScriptObjC / .scptd libraries (DC-XXX, CitrusPeel)
```

# Comparison matrix — voice and quick-trigger surfaces

This is the table that was missing from the repo. It is the strategic point of
Vocal Shortcuts: it occupies a specific niche that none of the other surfaces
fill simultaneously.

| Property | Vocal Shortcut | "Hey Siri" + Shortcut name | Siri (manual invoke) | Spotlight | Global hotkey | Loupedeck button |
|---|---|---|---|---|---|---|
| **Wake-word required** | No | Yes ("Hey Siri") | No (button/menu) | No | No | No |
| **Network required** | No (on-device) | Often yes (cloud NLU) | Often yes | No | No | No |
| **Hand-trained phrase** | Yes (3 reps) | No (NLU match) | No | n/a | n/a | n/a |
| **Arbitrary phrasing** | Exact trained phrase only | Loose match to Shortcut name | Free-form | n/a | n/a | n/a |
| **Latency** | ~instant | 1-3 s | 1-3 s | <1 s | instant | instant |
| **Fires non-Shortcut actions** | Limited (Siri Request / a11y) | Limited | Yes | Apps & files | Anything bindable | Anything bindable |
| **Available offline** | Yes | Limited | Limited | Yes | Yes | Yes |
| **Apple Silicon required** | Yes | No | No | No | No | No |
| **Visible/searchable** | List in System Settings | Shortcuts list | n/a | Yes | Hidden | Loupedeck UI |
| **Survives Shortcut rename** | Yes (UUID-bound) | No (name match) | n/a | n/a | n/a | n/a |
| **Hands-free** | Yes | Yes | No (mostly) | No | No | No |

**The unique cell** is the diagonal: Vocal Shortcuts is the **only** trigger
surface that is *simultaneously* hands-free, offline, latency-free, and bound by
stable UUID rather than fragile name-matching. Every other voice path either
requires the wake-word, hits the cloud, or breaks when the target gets renamed.

# Strategic implications for the apple skill

## 1. Vocal Shortcuts is the canonical Sequoia voice route for the Sal corpus

The 588 CitrusPeel commands and the 73 triple-channel-eligible workflows from
the seven-purpose audit (WWSD #30) all need a Sequoia-era trigger. Vocal
Shortcuts is it. The wiring is fixed:

```
spoken phrase  →  Vocal Shortcut entry
                       ↓
                  Shortcut in Shortcuts.app (UUID-stable binding)
                       ↓
                  Run AppleScript action
                       ↓
                  DC-XXX handler in a .scptd library
```

This is the four-hop pattern that the import pipeline must produce per
candidate. `bin/dictation-commands-vocal-shortcuts-import.py` and
`bin/vocal-shortcuts-ui-import.applescript` are the existing scaffolding for
this; the audit-to-import wiring is the live work front.

## 2. Read is solved; write is constrained

`bin/list-vocal-shortcuts.py` reads `AVSPreferenceKey` cleanly. Writing the
plist directly would install a binding but **not the trained-audio model** —
the daemon may refuse to fire until the phrase is trained via the System
Settings UI (three repetitions per phrase, by hand). This is the bottleneck
that prevents a fully-automated "add 588 Vocal Shortcuts at once" pipeline.
Practical options:

- **UI scripting** through System Settings (slow, fragile, but real). The
  `vocal-shortcuts-ui-import.applescript` skeleton anticipates this.
- **A "Hey Sal" router** that takes one trained phrase ("Hey Sal") and
  routes free-form follow-up speech to the right Shortcut via a matcher.
  This is the path already in use (live entry: `"Hey Sal" → Shortcut Hey Sal`)
  and is documented in `sal-session-717-replication-state.md`. It bypasses the
  N-phrases-each-trained-3-times bottleneck by collapsing N trainings into 1.

## 3. The audit surfaces a "you should bind this" report

`bin/vocal-shortcuts-suggest.py` (built 2026-05-11) joins all three sources
— `AVSPreferenceKey`, `~/Library/Shortcuts/Shortcuts.sqlite` (table `ZSHORTCUT`,
column `ZWORKFLOWID` is the UUID that matches `associatedShortcut.type.siriShortcut.id`),
and `seven-purpose-audit.md` — and reports:

- **Orphans** — Vocal Shortcut points at a UUID no longer in `Shortcuts.sqlite`
  (or tombstoned). Binding will silently fail.
- **Drift** — Vocal Shortcut's cached `associatedShortcut.name` differs from
  the live `ZNAME`. Cosmetic only (binding is UUID-stable) but confuses the user.
- **Suggestions** — Shortcuts that exist with no Vocal Shortcut bound. With
  `--audit-only`, restrict to fuzzy-matches against triple-channel audit
  candidates.

Modes: default text, `--json`, `--write [PATH]` (markdown). Snapshots
`Shortcuts.sqlite` to a temp file before opening read-only, so the running
Shortcuts.app doesn't fight for the WAL.

**First-run reading (2026-05-11):** 2 / 277 live Shortcuts have a Vocal
binding (0.7% coverage). 0 orphans, 0 drift, 39 audit-matched suggestions.
Live report: `analysis/sal/vocal-shortcuts-coverage.md`.

## 4. Sal Hand-Crafted Conformance applies

Per skill.md's Sal Hand-Crafted Conformance rules, Vocal Shortcut **phrases**
should be hand-written speech-shaped commands, not derived from filenames or
Shortcut names. The eight patterns (verb-first, no jargon, present tense,
etc.) all apply. The 588 CitrusPeel commands have hand-crafted phrases
already; the audit-driven candidates need pass-through review before they
get bound.

# Limits and gotchas

- **Apple Silicon only.** Intel Macs have no Vocal Shortcuts surface at all.
  The reader exits cleanly on Intel (no `AVSPreferenceKey`); the import
  pipeline must noop or substitute Spotlight/hotkey paths.
- **No public API.** `AVSPreferenceKey` is undocumented. Any pipeline relying
  on it is implicitly version-locked to current Sequoia behavior; a future
  macOS could change the schema.
- **Training is not automatable.** This is the structural constraint that
  motivates the "Hey Sal" single-phrase router approach.
- **`siriRequest` and `accessibility` kinds are not yet observed in the wild.**
  The schema doc lists them as inferred-from-UI but we have no example JSON.
  Need to record a Voice-Control-toggle Vocal Shortcut to capture the
  `accessibility` shape.
- **No notification API.** Writing the plist does not by itself signal the
  daemon to reload. `defaults` and `cfprefsd` interact here in
  not-yet-fully-mapped ways.

# Live state (as of 2026-05-11)

```
2 Vocal Shortcut(s):
  "Hey Sal"     → [Shortcut] Hey Sal     (A2496D32-0570-4059-A5D8-A44CBE36CF4C)
  "wheres olga" → [Shortcut] Find Olga   (0C093E97-A8A9-4BDE-90BC-94EE1A5C4596)
```

The "Hey Sal" entry is the active voice-route into the matcher; "wheres olga"
is the original seed entry from 2026-05-07 (note the trained phrase drifted from
"where is olga" to "wheres olga" — Vocal Shortcuts records exactly the trained
utterance).

# One-line summary

Vocal Shortcuts is **Sal's Custom Commands plist runtime, reborn under
Accessibility, gated to Apple Silicon, and forced through Shortcuts.app**. It
restores hands-free, offline, latency-free voice triggers to the Mac for the
first time since macOS 10.13, and it is the canonical Sequoia trigger surface
for the entire Sal corpus.
