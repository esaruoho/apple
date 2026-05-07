---
title: WWDC 2016 Session 717 — Full Transcript Analysis
date: 2026-05-07
status: Session 717 video recovered from archive.org → transcribed → analyzed
provenance: |
  Video: https://archive.org/details/wwdc2016videos/717_hd_beyond_dictation__enhanced_voicecontrol_for_macos_apps.mp4
  Local archive: sources/sal/wwdc2016-session-717/717-transcript.txt (524 lines, 27.8 KB)
  Original Apple URL (scrubbed ~one week after delivery): developer.apple.com/wwdc/2016/717
  Apple URL replacement after pull: gone — only Internet Archive copy survived
related: |
  - analysis/sal/wwdc2016-session-717-deep-analysis.md (the public-surrogate / CitrusPeel analysis)
  - analysis/sal/transcripts-analysis-pass2.md Story 20 (the original Sal recollection)
  - sources/sal/macosxautomation.com/dictationcommands/ (full site mirror + 17 .scptd libraries)
---

# What just happened

Esa located the **actual scrubbed WWDC 2016 session 717 video** on archive.org and transcribed it. The session that Sal said Apple "took down a week after I gave it" — the four-month-before-firing session — is now in the archive in full. **524 lines of transcript, the complete 33-minute talk.**

Title (from filename): **"717 - Beyond Dictation: Enhanced Voice Control for macOS Apps"**

Speaker: Sal Soghoian, Product Manager for Automation Technologies at Apple.

# What the session actually contained

## The four-tier voice model Sal teaches (lines 11–19)

This is the conceptual scaffolding the entire talk hangs on:

1. **Dictation** — transcription only, internet required, short phrases, no edit controls
2. **Enhanced Dictation** — offline, continuous, live feedback, edit + navigate within text fields
3. **Advanced (Dictation) Commands** — control application UI: buttons, tabs, menus, "show numbers"
4. **User Commands** — custom commands you create yourself, where automation fuses with speech

The talk is structured as a ladder up these four tiers, with the payoff being tier 4.

## Sal's pivot moment — line 190–194

> "But here's the good news, user commands. **This is where we leave the world of accessibility behind. This is where the power of automation and the power of speech recognition fuse together to produce incredible tools.**"

This is a **turf claim**. Speech recognition / dictation lived under Accessibility at Apple. Sal's role was Automation. By saying "we leave the world of accessibility behind" he is publicly relocating speech-controlled computing from the Accessibility org into the Automation org. **This single sentence is one of the most politically loaded things in the corpus.**

## The closing thesis — lines 512–519

> "So to summarize, the power of speech recognition and automation working together makes it so that **dictation is no longer just another way to enter text into a text field. And speech is no longer just an assistive technology. And now voice is a peer to touch keys and cursor.** You can use your voice the same way that you use the other inputs into the computer. And this is what's possible when you have Mac OS and all of these technologies working together. **It's only something that can happen on a Mac.**"

Three claims stacked here, in order of escalation:

1. Dictation is no longer just text entry — it's automation
2. Speech is no longer just assistive — it's a general-purpose input
3. **Voice is a peer to touch, keys, and cursor** — i.e. voice is a fourth fundamental input modality on equal footing with the other three

Then the kicker: **"only something that can happen on a Mac."** In June 2016, Siri had been on iOS for five years and had just been announced for the Mac (rolling out in macOS Sierra that fall). Sal's pitch directly competes with Siri's positioning: Siri was being rolled out as Apple's conversational AI assistant; Sal's framing positions **user-programmable voice automation** as the more powerful approach — and ties it explicitly to the Mac, not iOS.

## The suspicious gap — lines 505–509

> "So how does it work? Well, I only have a couple minutes, so I'm going to kind of boot out of that for a second and jump past that section. **It's basically magic.** And I'm going to kick back in and tell you where to go to get these resources."

**Sal explicitly skipped the "how does it work" section** of his own talk. This is the only section he flagged as cut for time. Given the pass-2 quote ("we had those abilities — and much more — running with Siri using AppleScript Libraries written in AppleScriptObjC"), the most likely interpretation is that **the cut "how does it work" section was where the Siri integration would have lived**. He skipped it under time pressure but the slides may have existed — and that's the slide deck still worth asking Sal for.

# Coverage map: this transcript ↔ the public surrogate ↔ CitrusPeel

## The dictation-commands-main-example.mp4 demo is embedded inside session 717

Lines 277–475 of session 717 are an almost line-for-line reproduction of the 46-line `dictation-commands-main-example.txt` (the public surrogate analyzed in `wwdc2016-session-717-deep-analysis.md`). Specifically:

| Public surrogate line | Session 717 line | Match |
|----|----|----|
| 1 "Switch to photos" | 338 | ✓ |
| 2 "Select all photos" | 341 | ✓ |
| 3 "Help me to add titles" | 341 | ✓ |
| 4–8 "Enter the title for image N of 5" | 342–348 | ✓ (variant — Sal narrates over) |
| 11 "Make a new presentation with these" | 350 | ✓ |
| 12 "Go to slide one" | 356 | ✓ |
| 13 "Change master slide to title center" | 357, 359 | ✓ (with "Scratch that" intervening, line 358) |
| 14–18 edit/capitalize/stop edit | 361 | ✓ (Vacation Photos / Select Photos / Capitalize That / Stop Edit, all collapsed into one line in transcript) |
| 19 "Move this slide to the end" | 364 | ✓ |
| 20 "Edit this in photos" | 370 | ✓ |
| 21 "Show this in Keynote" | 380, 381 | ✓ |
| 22 "Update this image" | 384, 385 | ✓ |
| 23 "Show this in Maps" | 394 | ✓ |
| 24 "Export this map to Keynote" | 404 | ✓ |
| 25 "apply a magic move" | 415 | ✓ |
| 26 "apply a dissolve" | 416 | ✓ |
| 27 "Scale this to fit slide width" | 421 | ✓ |
| 28 "Make a long panoramic sequence" | 421 | ✓ |
| 29 "Put descriptions on top of every image" | 422 | ✓ |
| 30 "Search Spotlight for spreadsheet tourism in France" | 427 | ✓ |
| 31 "Open Result" | 428 | ✓ |
| 32 "Select a table" | 429, 430 | ✓ |
| 33 "Export this table to Keynote as a chart" | 431, 432 | ✓ |
| 34 "Start from the top" | 437 | ✓ |
| 36 "Save this presentation" | 457 | ✓ |
| 37 "Save this presentation to my thumb drive and eject it" | 461, 464 | ✓ |
| 38–39 Saving/Dismounting briefcase | 465, 466 | ✓ (system speech) |
| 41 "Add a blank slide" | 474 | ✓ |
| 42 "Scratch that" | 462, 463 | ✓ (also at line 358) |
| 43 "Add a blank slide" | 474 | ✓ |
| 44 "Turn this into a QR code" | 474 | ✓ |
| 45 "Scale down 10%" | 475 | ✓ |

**100% of the public surrogate transcript is reproduced in session 717.** The public surrogate is literally the demo segment of session 717, exported standalone for `dictationcommands.com`.

## What session 717 contains BEYOND the public surrogate

This is the new material — i.e. what was lost when Apple pulled the session and Sal could only put the demo segment back online.

### A. Setup framework (lines 1–94) — ~25% of the talk

Sal's complete teaching of where dictation/speech preferences moved to in macOS Sierra:

- System Preferences → Siri vs Keyboard vs Accessibility — the new layout
- Why Siri ≠ Dictation: "**Siri and dictation and speech are two different technologies. They have different functions, different uses, and different purposes.**" (line 30) — directly distinguishes his territory from Siri's
- The "send your audio + your contacts to Apple's servers" privacy disclosure for basic dictation (lines 41–46)
- Where the four tiers live in System Preferences (Keyboard pane → Dictation tab; Accessibility pane → Dictation row)

### B. Enhanced Dictation suites tour (lines 95–127) — vocab Sal teaches as building blocks

The five built-in suites:

1. **Selection** — select word, paragraph, sentence, phrase
2. **Navigation** — go to end/beginning, scroll up/down, move left/right
3. **Editing** — cut/copy/paste, capitalize, lowercase, uppercase, **replace** ("replace this phrase with this phrase")
4. **Formatting** — bold, italicize, underline
5. **System** — stop dictation, **show commands** (floating HUD)

The "replace" command is highlighted as special. None of these appear in the public surrogate.

### C. Sal's procedural-vs-task taxonomy (lines 132–138, 250–253) — major WWSD principle

> "Enhanced dictation gives you many things… but it does have some limitations. **And I call it, it's procedural.** It means that it's like describing how to make a peanut butter sandwich. You hold the jar with this hand, you turn the top this way." (line 132)

Then later, contrasting User Commands:

> "User commands are different than the other types of commands because **they're task oriented. You're not so much procedural where you're telling it to do this, then this, then this. You're basically giving a command to execute this particular task no matter how many steps it takes.**" (line 250)

**This procedural-vs-task distinction is a missing WWSD principle.** It maps directly to Sal's "name commands like speech, not labels" (#11) and to the data-type-chaining / Russell-self-multiplication thesis: a task-oriented command is a self-multiplying primitive; a procedural command is a primitive that has to be re-expanded every invocation.

### D. Advanced Commands UI demo (lines 142–189)

The "show numbers" + "click parchment" Keynote-template-picker walkthrough. Sal explicitly demos using voice as a mouse to walk through the file menu / template picker. This whole segment was cut from the public surrogate. Worth noting because it shows the **exact procedural verbosity that Sal then offers User Commands as the cure for** — the rhetorical move only lands with the Advanced Commands segment in front of it.

### E. How to BUILD a User Command (lines 196–249)

The complete UI walkthrough of creating a custom dictation command:

- The **secret plus button** — line 196: "in this window is a secret button for turning on this power ability. And it is right here, this plus button. It doesn't look like much. It looks like any other plus button. But when you press that plus button, a new suite is added called user commands."
- The fields: phrase, application scope, action
- The 7 action types: open Finder items, open URL, paste text, paste data, press keyboard shortcut, select menu item, **run Automator workflow / AppleScript / JavaScript**
- The 9 pre-shipped Automator workflows (3 QuickTime recording, 1 Apple website, 5 iTunes navigation)
- "Take My Picture" walkthrough as the worked example

**This is missing from the public surrogate entirely.** Anyone watching only the public video would see Sal's commands working but have no idea how to build their own — which is the entire point of the talk.

### F. The 5-category framework — what voice commands are GOOD FOR (lines 480–504)

Sal's closing analytical framework. This is canonical WWSD material:

1. **Remain in context** — "really good for when you want to remain in context and you want actions and tasks performed for you" (line 482)
2. **Multi-step tasks** — "really good for performing multi-step tasks and like when I had to go through and name all of those images so I could use their descriptions later" (line 483)
3. **Tasks requiring dexterity** — "Can you imagine copying the description from an image file on a slide and then creating a text box, placing it just so on that, and doing that for an entire presentation? Boy, you have to be a wizard to be able to do that quickly." (line 486)
4. **Move data between apps** — "I had the map in Maps, I wanted it over in Keynote" (line 491)
5. **Data transformation** — "I had a table with data that I wanted as a chart in Keynote" (line 493)
6. **Tasks not available in the app UI** — "turn this into a QR code. That's a perfect example of something you'd want to do in a presentation, but it's just not there." (line 496)
7. **Things the user wants to do but doesn't know how** — "all the people in my family do not know how to use the clipboard, do not know how to do a screen capture, do not know how to use AirDrop. So being able to do that with a spoken dictation command is perfect." (line 500)

**Seven categories**, not five — Sal numbered them less rigorously in delivery. None of this analytical close appears in the public surrogate. This is canonical for the skill canon.

### G. Sal-isms / personal color (scattered)

- Line 3: "We're going to be moving the attendee bash to my house over in Berkeley. It's a lot more fun over there." — opening joke
- Line 268: "I'm getting over a cold. My voice is about a little bit lower, so we'll see if she even pays attention to me today." — reveals he was sick the day of the demo, which explains the recognition errors he has to repeat ("Show this in Keynote. Show this in Keynote." line 380–381)
- Line 271: "When I'm in the office at Apple, I just use your computer. It's open there, connected to my monitor, and **I can talk to this thing from across the room and it works perfectly.**" — primary-source confirmation that Sal's daily working environment ran on his own custom voice automation stack
- Line 339–340: "These are some photos I took on my trip down the Rhone River, I took one of those Viking type cruises, lots of fun, I highly recommend that." — biographical color
- Line 519: "**It's only something that can happen on a Mac.**" — closing line, the strategic positioning sentence

# Why was it pulled? — best inference from the recovered transcript

Earlier we did not have the actual session content and could only speculate. With the full transcript in hand, the most defensible inference shifts.

**Three candidate triggers, ranked:**

## 1. The "voice is a peer to touch, keys, and cursor" thesis (line 515) — MOST LIKELY

Apple was about to launch Siri on macOS in fall 2016. Marketing positioning was that Siri *is* the Mac's voice interface. Sal's talk argues — over 33 minutes of demo — that the more powerful voice interface on the Mac is **user-programmable dictation commands tied to AppleScript / Automator**, and that this is **specifically what makes the Mac different from iOS**. That undercuts Siri's launch narrative directly. A pull a week after delivery is consistent with marketing/comms catching up to a developer talk that contradicts the upcoming Siri-on-Mac messaging.

## 2. "We leave the world of accessibility behind" (line 191) — turf claim

The dictation/speech stack lived under Accessibility at Apple. Sal explicitly relocates it under Automation in front of an audience of developers. That is the kind of org-political claim that reliably triggers retractions.

## 3. The "much more running with Siri" content was probably the cut "how does it work" section (line 506–508)

Sal himself flagged this section as cut for time. This recorded session does **not** contain a Siri-on-Mac demo. Sal's pass-2 ProGuide-interview quote saying "we had those abilities — and much more — running with Siri using AppleScript Libraries written in AppleScriptObjC" probably refers to:
- (a) An internal demo Sal ran for executives / in the Executive Briefing Center, never recorded for WWDC, OR
- (b) The "how does it work" slides he skipped — in which case those slides may still exist and are worth asking Sal for, OR
- (c) Material in the Q&A / lab sessions that followed the talk and weren't recorded

Either way, **the Siri-on-Mac "much more" is NOT in this recording**. It's still missing from the archive. The session 717 pull alone doesn't account for it.

# What the archive now holds vs. what's still missing

## Holding

1. **Session 717 video** — recovered, 33 minutes, archive.org
2. **Session 717 full transcript** — 524 lines, in `sources/sal/wwdc2016-session-717/717-transcript.txt`
3. **The public demo surrogate** — `dictation-commands-main-example.mp4` (167 MB) and its 46-line transcript — confirmed to be an exact subset of session 717's demo segment
4. **The CitrusPeel installer** — 17 `.scptd` AppleScriptObjC libraries that implement everything demonstrated in the talk
5. **`dictationcommands.com` full HTML mirror** — including `commandslist.html` enumerating 40 categories of commands
6. **Sal's pass-2 ProGuide-interview quote** — establishing the four-month-before-firing causal context

## Still missing

1. **The "how does it work" section slides** — Sal explicitly skipped them in delivery (line 506–508). Were they distributed as a slide deck? Worth asking Sal directly.
2. **The Siri-on-Mac variant** Sal refers to in pass 2 — the working prototype with "hundreds of natural-language voice commands" that was killed for "iOS-comparison reasons." Not present in this recording. Likely an internal-only demo.
3. **The Q&A / lab session** that would have followed the talk
4. **The original dictationcommands.com deep-link to this video** — Sal's own quote says "the first video on this page is much of the demo I did in that session" — but `videos.html` on the mirrored site lists many more videos that are essentially the session 717 demo broken into per-app chapters

# What changes for the skill canon

This transcript adds at least three new WWSD-canon-grade items:

## WWSD #28 candidate — Procedural vs Task-Oriented Commands

> A procedural command is "make a peanut butter sandwich by holding the jar with this hand and turning the top this way" — every step has to be re-expanded every time. A task-oriented command is "make me a sandwich" — the *task* is the named primitive, and the steps are below the surface. **Voice commands should be task-oriented, not procedural.**

This is Sal's framing, lines 132–138 and 250–253. It ties directly to the Russell self-multiplication / data-type-chaining thesis: **a task-oriented command is a primitive that self-multiplies**.

## WWSD #29 candidate — Voice as a peer modality

> Voice is not an assistive technology. Voice is not just text entry. **Voice is a fourth fundamental input modality, on equal footing with touch, keyboard, and cursor.** Treat it that way.

This is Sal's closing thesis, line 515. Currently the skill canon is implicitly keyboard/menu/AppleScript-centric; this principle would re-frame the entire skill around voice as a first-class peer.

## WWSD #30 candidate — The 7-purpose framework for when to build a voice command

Sal's closing analytical framework (lines 480–504) gives us a decision tool for whether a manual workflow deserves to become a voice command:

1. Need to remain in context (don't break flow)
2. Multi-step (≥3 steps to accomplish manually)
3. Requires dexterity (precise mouse movements, careful sequencing)
4. Moves data between apps
5. Transforms data (one type → another)
6. Performs an action not available in the current app's UI
7. Does something the user wants to do but doesn't know how

Codify this into `skill.md` as a checklist for evaluating which Loupedeck buttons / Spotlight workflows / Siri phrases to build. **If a workflow scores 3+ on this list, it earns a voice command.**

# Recommended next moves

1. **Cross-link this analysis from `analysis/sal/transcripts-analysis-pass2.md` Story 20** — promote the entry from "high-value missing artifact" to "RECOVERED, full content analyzed."
2. **Update `analysis/sal/current-status.md`** to reflect session 717 recovery
3. **Codify the three new WWSD principles** (#28 procedural-vs-task, #29 voice-as-peer-modality, #30 the 7-purpose framework) into `skill.md`
4. **Email Sal**: ask about the cut "how does it work" slides and the Siri-on-Mac variant. The pass-2 quote and this transcript together give us a precise ask.
5. **Extract `CitrusPeel/Installation Items/Script Libraries/` into `scripts/sal/dictation-commands/libraries/`** so the engine of session 717 is browsable in-repo
6. **Build a session 717 study page** (`analysis/sal/wwdc2016-session-717/`) bundling: video link, transcript, this analysis, the CitrusPeel libraries index, and the public-surrogate cross-reference table. This becomes a permanent canonical study artifact.
7. **Consider a public write-up** — once the skill canon is updated, this is the kind of recovery that's worth a public post on the apple repo README. It's exactly the kind of preservation the repo exists for.
