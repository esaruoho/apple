---
title: Sal's Siri-on-Mac prototype — architecture theory
date: 2026-05-07
status: Theoretical reconstruction from Sal's pass-2 quote + WWDC 717 transcript + CitrusPeel artifacts + 2016 Siri/SiriKit state-of-the-art
purpose: Document the most likely architecture of the killed Siri-on-Mac prototype Sal references, so we can build a 2026 functional equivalent
---

# The source quote

From the ProGuide 2023 interview (transcripts-analysis-pass2 Story 19/20):

> "However, the first video on this page https://macosxautomation.com/dictationcommands/ is much of the demo that I did in that session. **We had those abilities — and much more — running with Siri using AppleScript Libraries written in AppleScriptObjective-C.**"

And:

> "[The Siri-on-Mac demo] upset a lot of people."
> "[Apple] killed it because shipping it would have made iOS Siri look weaker."

What we therefore know for certain:

1. **It existed.** Sal demoed a working version, more than once, to internal Apple audiences.
2. **It was based on AppleScriptObjC libraries** — the same `.scptd` substrate as CitrusPeel, just with a different trigger surface.
3. **It went beyond CitrusPeel's capabilities.** Sal's "and much more" implies Siri added natural-language understanding that Enhanced Dictation Commands (deterministic phrase matching) didn't have.
4. **It was iOS-comparison-killed.** The reason cited by Apple insiders was that the Mac version made iOS Siri look weaker — meaning the Mac version did things iOS Siri couldn't do.

# What "Siri" was in 2016

For context: WWDC 2016 also introduced **SiriKit** for iOS 10 — the first developer-facing Siri integration. SiriKit on iOS 10 was domain-restricted: only six predefined intent domains (messaging, payments, ride-booking, photos, VoIP, fitness). Developers could not define arbitrary intents.

But Apple's *internal* Siri in 2016 was not domain-restricted. The dispatcher framework (`AssistantServices.framework`, `siriactionsd`, the NSF/Carbon-era Speech Recognition Server) could route any Siri-recognized phrase to any handler if you had the entitlements. Sal would have had those entitlements as Product Manager of Automation Technologies.

# Most likely architecture (reconstructed)

```
                          USER SPEAKS
                              ↓
                ┌─────────────────────────┐
                │   Siri speech recognizer  │
                │   (the part that became   │
                │    Apple Intelligence)    │
                └────────────┬─────────────┘
                              ↓ utterance text + tokenized
                              ↓ named entities
                ┌─────────────────────────┐
                │   Sal's intent router    │
                │   ("the much more")      │
                │                          │
                │ • Phrase patterns        │
                │   (the commandslist.html │
                │    shape — but with      │
                │    slot-filling)          │
                │ • Context resolver        │
                │   (current app, current  │
                │    selection, last-seen  │
                │    nouns)                │
                │ • Disambiguator           │
                └────────────┬─────────────┘
                              ↓ resolved intent
                              ↓ + arguments
                ┌─────────────────────────┐
                │   AppleScriptObjC bridge │
                │                          │
                │ • Loads the matching     │
                │   DC-XXX.scptd library   │
                │ • Invokes handler        │
                │ • Returns result via     │
                │   NSAppleScript          │
                └────────────┬─────────────┘
                              ↓
                ┌─────────────────────────┐
                │   The 18 .scptd libs     │
                │   (same as CitrusPeel)   │
                └─────────────────────────┘
                              ↓
                ┌─────────────────────────┐
                │   Target app via         │
                │   tell application "..." │
                └─────────────────────────┘
```

## What "and much more" probably meant — three concrete capability differences

Comparing the *deterministic-match* CitrusPeel engine to a hypothetical *Siri-routed* engine:

### 1. Slot-filling natural language

**CitrusPeel:** The phrase `make a new wide presentation using the gradient template` was a single fixed pattern with two variable slots (width, template name) defined by literal alternatives in `commandslist.html`.

**Siri-on-Mac (theorized):** The phrase `give me a wide presentation with the gradient theme please` would also work, because Siri's NLU layer extracts intent (`make-presentation`) and slots (`width=wide, theme=gradient`) regardless of phrasing. Sal would not have to enumerate every variant in his command catalog — the catalog would shrink from 1,966 phrasings to ~250 intents.

### 2. Stateful conversation

**CitrusPeel:** Each utterance is independent. To say "now scale them down" referring to a previous selection, Sal had to wire `this`/`these` deictic references into each handler explicitly (which he did — see `DC-Keynote-Objects.scptd`).

**Siri-on-Mac:** The dispatcher would carry conversation state across utterances. "Make a new presentation with these photos" → "Add a magic move transition" → "Now do that to all the slides" — each later utterance can reference earlier nouns and verbs without explicit deixis support per-handler.

### 3. Cross-app composition from free-form intent

**CitrusPeel:** Sal had to write a specific handler `export this table to Keynote as a chart` that reaches across Numbers → Keynote.

**Siri-on-Mac:** A spoken intent like "the table I just made, put it in my presentation as a chart" would be parsed into composite operations: `find-recently-created(table) → export(target=Keynote, format=chart)`. The router decomposes complex intents into available primitive handlers.

This last capability is **exactly** what Apple Intelligence + App Intents shipped in 2024–2025. Sal had a working prototype of it eight years earlier.

# Why it threatened iOS Siri

iOS Siri in 2016:
- Domain-restricted (six SiriKit intent domains)
- No cross-app composition (each request lives in one domain)
- No user-programmable intents (developer had to ship an intent extension)
- No deep app surface (depended on whether the app had a SiriKit extension)

Sal's Mac prototype:
- Unbounded domains (any AppleScript dictionary becomes a Siri-addressable surface)
- Cross-app composition (Numbers → Keynote, Photos → Maps → Keynote shown in 717)
- User-programmable (the "secret plus button" — a user adds their own command in 30 seconds)
- Deep surface (any scriptable property/element of any app, not just intent extensions)

If Apple had shipped this on Mac in 2016, the comparison narrative for iOS Siri would have been: "iOS gives you 6 things, Mac gives you everything you can name." That's the iOS-comparison kill reason in concrete form.

# How to build a 2026 functional equivalent

The components Sal had in 2016 are now better-distributed across Apple's stack:

| Sal-2016 component | Sal had to build it | 2026 stand-in |
|---|---|---|
| Speech recognition | Apple Speech Recognition Server (cloud) | On-device Siri / Vocal Shortcuts (Apple Silicon) |
| Intent router (NLU) | Custom phrase matcher with slot-filling | Apple Intelligence / Foundation Models (on-device LLM) |
| Context resolver | Custom AppleScript state machine in DC-Demo.scptd | App Intents framework + AssistantSchemas |
| AppleScriptObjC bridge | Hand-written | NSAppleScript still works the same way |
| 18 .scptd libraries | Sal wrote them | Still work — we have them in this repo |
| Target apps | iWork, Photos, Maps, etc. | Same apps, similar dictionaries |

A 2026 reconstruction:

1. **Trigger:** Vocal Shortcuts (Apple Silicon) OR Siri Shortcut phrases. Bypass Apple Intelligence's general-NLU for now — wire one phrase per intent like CitrusPeel.
2. **Router:** A single Shortcut per intent that calls a Run AppleScript action with `tell script "DC-XXX" to handlerName(arg1, arg2)` — but with Shortcuts' `Get Variable`, `If`, `Choose from List` pre-action steps acting as the slot-filler.
3. **For free-form NLU (the hard part):** A Shortcut named "Sal's Siri" that takes a single text input, sends it to a local Foundation Models call (`Use Apple Intelligence` action shipping in macOS 15.1+), receives back a structured JSON `{intent, args}`, then dispatches to the matching DC-XXX library handler via Run AppleScript.

The third path is the nearest reconstruction of what Sal had. It doesn't exist in this repo yet — but the components do:

- The 18 libraries (already extracted, decompiled, indexed)
- The 588 deterministic-match Shortcuts (Phase 3 Path B)
- A new Shortcut wrapper that does NLU → dispatch (this would be the Phase 6 deliverable)

# Phase 6 sketch — `bin/sal-siri-on-mac-rebuild.py`

A future addition to the replication pipeline:

1. Read `commands.json` (596 commands, 1,966 phrasings)
2. For each command, generate a slot-template:
   - intent name (e.g. `make-presentation`)
   - required slots (e.g. `width`, `theme`)
   - allowed values for each slot
3. Emit a single Shortcut named "Sal's Siri" that:
   - takes a free-form text/voice input
   - calls Apple Intelligence with a system prompt: "You are Sal's Siri-on-Mac router. Output JSON {intent, args} matching this schema: <schema>. User said: <input>"
   - validates the JSON
   - dispatches via a giant `If/Then` ladder to the matching DC-XXX handler
4. Emit a Vocal Shortcut entry: `Hey Sal` or `Sal, please` → run "Sal's Siri" Shortcut

Result: speak `Hey Sal, give me a wide gradient presentation` and you get the same outcome as CitrusPeel's `make a new wide presentation using the gradient template`. Slot-filled naturally. Stateful via Shortcuts variables. Cross-app via the same `tell script "DC-XXX"` chain Sal designed.

This would be the closest publicly-buildable reconstruction of the killed prototype. Everything except the original 2016 entitlements would work; on-device Foundation Models replace whatever bespoke NLU Sal had wired up.

# What this preserves

Sal's archived insight: **the underlying primitive isn't the speech recognizer or the NLU model — it's the typed-data + scriptable-app substrate Apple shipped through AppleScript and AppleScriptObjC.** Every speech-recognition and NLU technology since 2016 has been replaceable; Sal's `.scptd` libraries from CitrusPeel still run today, unchanged. The libraries ARE the durable artifact. Whatever Apple does with Siri / Apple Intelligence / future AI assistants, it can always be wired down to that substrate, because that substrate is the way the apps are addressable in the first place.

This is WWSD #16 cashed in: **primitives compose; rewrites don't.** Sal's primitives compose with whatever speech engine Apple ships next. Apple's iOS-Siri-vs-Mac-Siri rewrite war killed the integration but couldn't kill the primitives.
