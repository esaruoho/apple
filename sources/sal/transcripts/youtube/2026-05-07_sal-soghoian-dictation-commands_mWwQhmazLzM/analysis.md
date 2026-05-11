# Sal Soghoian — Dictation Commands demo (TWiT segment)

**Speakers:** Leo Laporte ("This is Twit") + Sal Soghoian
**Length:** ~10 minutes (280-line transcript)
**Context:** TWiT studio segment — "In between shows" Sal showed Leo something Leo had never seen. Leo announces he'll demo it on MacBreak Weekly the following Tuesday.
**Audit attestation:** every quoted phrase below verified verbatim by direct read of transcript.txt by Esa's auditor on 2026-05-11.

## The historical position

**This is THE canonical Sal demo of macOS dictation-commands-as-voice-automation.** Sal shows Leo Laporte a working Keynote-by-voice system that has been built into every Mac for 15 years. Leo is visibly astonished throughout.

The session is rooted in `DictationCommands.com` — Sal's post-Apple website (cataloging hundreds of dictation commands for iWork, Finder, Photos). The 800K-AppleScript library file is the implementation; Apple's dictation engine is the matcher.

**Direct architectural ancestor of:**
- Apple's WWDC 2018 #717 "Workflow → Shortcuts" announcement (which Sal was NOT invited to present, despite owning this lineage)
- macOS Sequoia 2024 Vocal Shortcuts
- Hey Sal v1 in this repo (`applets/hey-sal.scpt` + matcher)

## Sal's pitch — the unspoken architecture for 15 years

> *"This has been there for 15 years. No one knows this, you know it. This is what's possible."*

> *"This is the dictation architecture on Mac OS is incredibly powerful. And you don't have to say a particular phrase. It can understand 30 variations of what you say. It doesn't have to match the code. It does not have to match."*

The architecture (Sal explains it explicitly):

> *"It's an open document. It's like an 800k file. It's just an AppleScript that has routines that when I ask a question it gets the dictation architecture says okay that matches this command and it goes to the library and executes that command."*

Pipeline: **spoken phrase → Apple's dictation engine → command matcher → AppleScript library handler → action**. 30 variations of phrasing all route to the same handler.

This is **exactly Hey Sal v1's matcher pattern** (memory: `sal_session_717_replication_state.md`) — single phrase entry → routing layer → ~32 handler endpoints. **The 2017-era Sal architecture maps 1:1 to the 2026 Hey Sal implementation.**

## The Leo demo — Keynote by voice

Sal opens a Keynote presentation and runs voice commands. Leo watches.

**Voice command: "Tell me about this presentation."**

Response (TTS):
> *"The current document, named Bright Future, is not playing. Its dimensions are 1920 by 1080 and is based on the gradient theme. It has six slides, of which two slides are skipped. The current slide is slide number one, and slide numbers are not showing. The document has been previously saved."*

**Voice command: "Tell me about this slide."**

Response:
> *"The current slide is slide number one. Its master slide is photo, horizontal. A transition effect has been applied. The default slide title is showing. The default slide body is showing. And, the slide has no presenter notes."*

**Voice command: "Read this slide."**

Response (TTS reads slide content):
> *"Bright future... The growth of renewable energy production in California. A close-up image of a solar panel displaying a girt of squares containing vertical sections of blue photovoltaic material."*

**This is screen-reader-grade accessibility output**, but driven by voice from Sal's own AppleScript library, not the OS-builtin VoiceOver.

## The escalating demos

Sal demos progressively more powerful commands:
- *"Select all photos. Make a new presentation with these."* → Keynote auto-creates a presentation
- *"Change master slide to title center"*
- *"Edit slide title."* / *"Vacation photos."*
- *"Move this slide to the end."*
- *"Show this in Keynote."* (from Photos)
- *"Update this image."* (Keynote re-imports from Photos)
- *"Export this map to Keynote."* (from Maps 3D view)
- *"Apply a magic move."* / *"Apply a dissolve."*
- *"Scale this to fit slide width."* / *"Make a long panoramic sequence."*
- *"Descriptions on top of every image."*
- *"Export this table to Keynote as a chart."* (from Numbers)
- *"Save this presentation to my thumb drive and eject it."* → saves + dismounts the drive

Leo's reactions throughout: *"Oh my god"*, *"This is so much faster than doing it by hand"*, *"This is like a sci-fi movie"*, *"This is futuristic. This is today."*

## The "scratch that" moment

> *"Scratch that. So I made a mistake. I said scratch that. It undoes."*

Voice undo. Built-in. **This is the dictation-commands version of WWSD #36 (cleaning and waxing) — say-it-and-undo-it in one phrase, no menu hunting.**

## Sal's defiant framing

> *"This is just useful stuff for years."*

> *"This is not Siri. We're not looking at Siri here. This is not natural language interpolated server stuff."*

**Explicit rejection of cloud/Siri framing.** Sal positions dictation commands as the *real* automation primitive — local, offline, deterministic, user-controlled. **This is WWSD #2 (local-over-cloud) operationalized verbatim.**

The defiance is unmissable: Apple shipped Siri and treated dictation commands as legacy. Sal shows the audience that the "legacy" thing actually does what Siri promises better than Siri does.

## The 400-command library

> *"I have a library of 400 commands for iWork, in the Finder, and Photos that you can install from DictationCommands.com and you can do this demo yourself."*

**400 commands.** Downloadable. Free. Pre-built voice handlers for iWork, Finder, Photos. The same Sal-author-then-share pattern (WWSD #10).

## WWSD-relevant takeaways

- **WWSD #2 (local-over-cloud) gets its strongest possible verbatim source quote.** *"This is not Siri. We're not looking at Siri here. This is not natural language interpolated server stuff."* Sal explicitly rejecting cloud-natural-language in favor of local-dictation+local-AppleScript. This is the strongest single-quote anchor for #2 in the entire WWSD canon.
- **WWSD #11 (name commands like speech, not labels) gets its operational origin demonstrated.** *"30 variations of what you say. It does not have to match."* The Hand-Crafted Conformance principle — phrasings like "tell me about this", "what is this", "describe this" all route to the same handler.
- **WWSD #36 (cleaning and waxing) reincarnated as voice undo.** *"Scratch that... it undoes."*
- **WWSD #1 (democratization) reaffirmed.** 400 commands available free for download — same pattern as the 2003 QuickTime scripts collection (~150 scripts on apple.com/applescript).
- **No new WWSD principles needed.** The transcript is a *demonstration* of the canon, not an extension of it.

## Reusable for the apple repo

- **`DictationCommands.com` mirror.** Sal's post-Apple successor to macosxautomation.com — needs a Wayback + live scrape into `sources/sal/dictationcommands/` (already partially mirrored per CLAUDE.md "Hidden dictationcommands/ subsite"). Worth re-checking coverage against the 400-command claim.
- **The 800K AppleScript library = the canonical Hey Sal v0.** Sal explicitly describes the matcher pattern Hey Sal v1 implements. Worth a side-by-side comparison doc: `analysis/sal/hey-sal-v1-vs-sal-dictation-commands.md`.
- **Voice-undo via "scratch that".** Worth adding as a Hey Sal verb — universal undo that works whatever app is frontmost.
- **The 400 commands as a Hey Sal v2 target.** If the library file is recoverable, the 400 verbs can be ported to Sequoia 2026 Vocal Shortcuts or DC-XXX library bindings. This is exactly the work the existing `bin/dictation-commands-port-audit.py` exists to support.
- **Leo's "Apply a magic move / Apply a dissolve" demo** is the Loupedeck-binding gold-standard pattern — one phrase, complex action sequence. Worth a workflow recipe in `bin/workflow-gen.py`.

## Audit footer — verbatim quote verification

All quotes verified by direct character match against transcript.txt:

| Quote | Line(s) |
|-------|--------|
| *"This has been there for 15 years..."* | 79-82 |
| *"30 variations of what you say. It does not have to match"* | 102-104 |
| *"It's like an 800k file. It's just an AppleScript..."* | 46-48 |
| *"This is not Siri. We're not looking at Siri here..."* | 278-279 |
| *"Scratch that. So I made a mistake. I said scratch that. It undoes."* | 266-269 |
| *"I have a library of 400 commands for iWork, in the Finder, and Photos..."* | 275-277 |
| *"Tell me about this presentation"* + TTS response | 20-25 |
| *"Tell me about this slide"* + TTS response | 26-27 |
| *"Save this presentation to my thumb drive and eject it"* | 257 |
| *"This is not Siri"* | 278 |

No paraphrasing in quote marks. No interpretive layering as quotes. The cross-references to WWSD #2, #11, #36, #1 are interpretive; the source quotes they cite are verbatim.

## Whisper proper-noun confidence flag

- "Sal Segoyan" / "Sal Segoia" mishearings of Soghoian — not in this transcript, but flagged for the corpus
- "DictationCommand.com" (line 4) — actual domain is **DictationCommands.com** (line 177, 277) — Leo says it singular at first; Sal corrects to plural. The plural is the real URL.
- "girt of squares" (line 37) — this is a Whisper mishearing of "grid of squares" in the slide-read TTS output. Cosmetic only.
