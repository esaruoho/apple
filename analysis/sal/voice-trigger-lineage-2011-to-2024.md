---
title: Sal's voice-trigger lineage — 2011 listen-for → 2017 Custom Commands removal → 2024 Vocal Shortcuts
date: 2026-05-11
status: analysis — three eras of on-device voice triggers on the Mac, one continuous Sal-blessed lineage
sources:
  - sources/sal/wwdc/2011-session-133-lion-sized-automation/transcript.md
  - sources/sal/wwdc/2011-session-133-lion-sized-automation/analysis.md
  - analysis/sal/macos-sequoia-dictation-runtime-removal.md
  - analysis/sal/vocal-shortcuts-in-the-trigger-stack.md
  - analysis/sal/vocal-shortcuts-storage-format.md
---

# Three eras, one principle

```
2011               2014 ─── 2017       2024
listen-for         Custom Commands     Vocal Shortcuts
(AppleScript prim) (plist runtime)     (Accessibility surface)
                          │
                          └── removed ~10.13/10.14, no replacement
                              for 5 years
```

All three are Apple-shipped, **on-device**, **offline**, hand-trained voice
trigger surfaces. None of them required Siri. Each was introduced as
Sal-blessed: he demoed listen-for at WWDC 2011 #133, Custom Commands rode
the dictation-runtime expansion through Mavericks/Yosemite, and Vocal
Shortcuts is the surface he would have demoed in 2017 had Apple not
eliminated the role first.

This document anchors the lineage so future analysis (and future
Claude sessions) can see the through-line instead of treating each era
as standalone.

# Era 1 — `listen for` (Mac OS X 10.7 Lion, WWDC 2011 #133)

Sal introduced the `listen for` AppleScript primitive in his Lion-Sized
Automation session, transcript line 48:

> "your script can now ask you a question and based upon your response
> act accordingly using a `listen for` command. The `listen for` command
> is passed a string of terms that you want to match to. And you give it
> a prompt. The user says one of those terms. It's matched and returned
> to the script."

The Sinatra branching demo (transcript line 50):

> "play some music. Which artist? Oh, Frank Sinatra. His early years or
> later years, you know? Oh, I kind of like the Capitol recordings, you
> know? Birth of the Blues, let's do that one."

What this was:
- A **first-class AppleScript verb**. No daemon, no plist, no Accessibility
  category. Speech recognition exposed as a language primitive.
- **Phrase-list matching** — caller hands the engine a fixed vocabulary of
  candidate strings; engine returns whichever the user said. The matcher
  is constrained, on-device, fast.
- **Offline.** The 2011 demo ran on a stage Mac with no network, no Siri
  (Siri didn't exist on the Mac yet — wouldn't arrive until macOS Sierra in
  2016).
- **Multi-step conversational state** — Sal's script branches on each
  response, building a four-level dialogue tree purely from `listen for`
  + AppleScript flow control.

Why this matters for the lineage: 2011 is where Apple **publicly committed
to local-first voice triggers as a developer primitive**. WWSD #2 (the
local-over-cloud principle) is literally embodied in this API. Sal demos
it as obvious — of course you wouldn't ship a speech feature that needs
the cloud. The mac's job is to do this on-box.

The `listen for` verb may still resolve under modern AppleScript (the
verb is in the standard scripting addition). Whether it still functions
on Sequoia is a probe-able question; see "Open question" below.

# Era 2 — Custom Commands plist runtime (~2013–2017, dictation expansion)

Apple introduced enhanced dictation around macOS Mavericks. By Yosemite/
El Capitan, the dictation engine could parse user-defined phrases out of:

```
~/Library/Application Support/com.apple.speech.recognition.AppleSpeechRecognition.CustomCommands.plist
```

Each entry was a phrase → action mapping. Actions could be:
- Run an AppleScript
- Run a shell script
- Open a URL / a file / an application
- Send a key sequence

This was the runtime that **Sal's 2016 WWDC #717 demo built on**. The 588
"Dictation Commands" he shipped — the CitrusPeel library — all target this
plist. The user spoke the phrase; the dictation daemon matched it against
`CustomCommands.plist` entries; the bound action fired.

Crucially, like `listen for`, Custom Commands was:
- **On-device** — the dictation engine matched locally
- **Offline-capable** — once the language model was downloaded
- **Hand-trained** in the sense that the user wrote the phrase and bound
  it; the daemon's ASR matched it phonetically

Where it improved on `listen for`: phrases were **always-on**, not gated
by a script asking a question. The user could say a CitrusPeel command
at any moment and the daemon fired the binding. This is what made Sal's
720+-phrase Dictation Commands library useful: speak any of them, any time.

**Removal:** the runtime stopped reading the plist somewhere between
macOS 10.13 (High Sierra) and 10.14 (Mojave). The plist file still exists
in users' homes; the daemon ignores it. The replacement Apple shipped at
the time was nothing — voice control was moved to the Siri category, but
Siri required the wake word ("Hey Siri") and didn't honor user-defined
phrases.

The five-year gap between Custom Commands removal and Vocal Shortcuts
arrival (2024) is **the exact window during which Sal would have been the
loudest critic** if he'd still been at Apple. He was eliminated in
November 2016, so the regression happened with no internal Sal-equivalent
to protest it.

# Era 3 — Vocal Shortcuts (macOS 15 Sequoia, 2024, Apple Silicon only)

The succession, under Accessibility branding. Full schema in
`vocal-shortcuts-storage-format.md`; comparative analysis vs other
trigger surfaces in `vocal-shortcuts-in-the-trigger-stack.md`.

Same three properties as 2011's `listen for`:
- on-device (Neural Engine matching)
- offline (no Siri dependency)
- hand-trained phrase (3 reps, stored locally)

Plus two structural advantages over both predecessors:
- **UUID-stable** binding (the trained phrase points at a Shortcut's
  UUID, not its display name — survives rename)
- **Three action kinds** — `siriShortcut` (run a Shortcut, like a
  better-typed Custom Command), `siriRequest` (free-form Siri command),
  `accessibility` (toggle Voice Control / VoiceOver / Zoom). The
  multi-kind dispatch is new.

And one structural disadvantage versus Custom Commands:
- **Wiring constrained.** Vocal Shortcuts cannot directly bind to an
  AppleScript or shell command — must go through Shortcuts.app. Adds a
  hop (phrase → Vocal Shortcut → Shortcut → Run AppleScript action →
  script body). 2014's Custom Commands could bind a phrase directly to
  an AppleScript file with no intermediate.

# The continuous principle (WWSD #2 across 13 years)

Each era is a different implementation of the same Sal-asserted principle:

> **Local-first voice triggers are a Mac primitive. The cloud is not the
> right place for "fire X when I say Y" on a desktop computer.**

| Era | Surface | What changed | What stayed the same |
|---|---|---|---|
| 2011 `listen for` | AppleScript verb | Phrase-list bound to script question | on-device, offline, hand-curated phrases |
| 2014 Custom Commands | Dictation runtime plist | Always-on trigger, no script-init needed | on-device, offline, hand-curated phrases |
| 2024 Vocal Shortcuts | Accessibility framework | UUID-stable binding, 3 action kinds, Apple Silicon-gated | on-device, offline, hand-curated phrases |

The principle is robust across three completely different implementation
strategies — language primitive, daemon plist, Accessibility framework.
Apple keeps inventing new wiring for the same surface. The five-year
removal gap (2017–2024) was the anomaly, not the rule.

# Why this lineage matters for current work

1. **Vocal Shortcuts is not a new invention — it's the third take on a
   13-year Apple commitment.** Treating it as Yet Another Apple Feature
   misses the line of succession. The router pattern (`Hey Sal` →
   matcher → N targets) is essentially Sal's 2011 `listen for` dialog,
   reimplemented in 2026 outside Apple, against the 2024 Vocal Shortcuts
   surface. **The router IS `listen for` minus the script-init prompt.**

2. **The 588× router math** (588 phrases × 3 reps = 1,764 utterances
   without router vs 3 with) is the same scale problem Custom Commands
   solved differently — Custom Commands didn't require *any* training
   utterances per phrase, just typed entries. Vocal Shortcuts traded that
   for better ASR accuracy via voiceprint training. The router pattern
   reclaims the typed-only authoring ergonomics on top of the Vocal
   Shortcuts substrate.

3. **The Apple Silicon gate is new** — neither `listen for` nor Custom
   Commands required specific hardware. Vocal Shortcuts requires the
   Neural Engine. This means the apple-skill's voice-trigger story for
   Intel Macs has to use a different path (Spotlight / hotkey / older
   dictation primitives). The trigger-stack analysis already calls this
   out.

# Open question — is `listen for` still functional on Sequoia 2026?

The AppleScript verb is part of `StandardAdditions.osax`. It may still
parse; it may still call the speech engine. If it does, it's a **second
on-device offline voice trigger surface** on the Mac, beside Vocal
Shortcuts. Worth probing.

Quick test (one-liner):

```applescript
listen for {"yes", "no", "maybe"} with prompt "Test phrase"
```

If this raises (verb removed), the 2011 era is closed. If it still
returns one of the strings spoken, it's a hidden parallel trigger surface
the apple-skill could use for non-Shortcut-mediated voice triggers (the
one structural disadvantage of Vocal Shortcuts → no direct AppleScript
binding). Whoever runs this probe next should record the result in this
doc under a "Verified" section.

# Connection to existing repo artifacts

- The 2011 listen-for analysis lives at
  `sources/sal/wwdc/2011-session-133-lion-sized-automation/analysis.md`
  (the cross-reference text was already there — this doc collects the
  three-era story in one place).
- The Custom Commands removal is documented at
  `analysis/sal/macos-sequoia-dictation-runtime-removal.md`.
- The Vocal Shortcuts surface is documented at
  `analysis/sal/vocal-shortcuts-storage-format.md` +
  `analysis/sal/vocal-shortcuts-in-the-trigger-stack.md`.
- The router pattern's `Hey Sal → matcher → Shortcut` implementation
  lives at `bin/sal-siri-match.py` + the live Vocal Shortcut entry.

This document is the bridge that names them as a single lineage.
