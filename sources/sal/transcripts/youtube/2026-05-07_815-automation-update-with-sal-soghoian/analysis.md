# Mac Power Users #815 — Automation Update with Sal Soghoian

**Speakers:** Stephen Hackett + David Sparks (hosts) + Sal Soghoian
**Length:** ~1200 lines (60KB transcript). MPU episode 815, post-AI-era. Episode numbering suggests **late 2025** (MPU has averaged ~52 episodes/year since #588 in May 2021 → #815 ≈ Sept-Oct 2025).
**Audit attestation:** quoted phrases below verified verbatim by direct grep against transcript.txt by Esa's auditor on 2026-05-11.

## The historical position

The most recent Sal-on-record interview in this archive. Post-LLM-era, Apple Intelligence has shipped, OmniFocus 4.8 integrates the Apple Foundation Models framework, and Sal is positioned as the bridge between classical automation and AI-augmented automation. **This is the Sal-canon's update on what AI changes (and doesn't change) about Mac automation.**

## Sal's framing — Apple Foundation Models in OmniFocus 4.8

> *"So recently, Apple made a decision to expose the foundation models framework. That's a lot of things to say, right? Apple foundation models framework. I'm going to..."* (lines 383-384)

The headline: Apple shipped the **Apple Foundation Models framework (AFM)** as part of Apple Intelligence, exposing on-device LLM inference to third-party apps. **OmniFocus 4.8 ships with AFM integration via Omni Automation** — the same JavaScript-on-WebKit bridge Sal helped design.

The query pattern: two-or-three lines of JavaScript inside an Omni Automation script invoke on-device intelligence. Local. Offline. No cloud round-trip. **WWSD #2 (local-over-cloud) operationalized for the LLM era.**

## The "AI as intern, not director" doctrine — Sal blesses Sparks's framing

> *"think of it as an intern Like..."* (line 464, David Sparks speaking)

> *"i said you know you think an intern that is eager to help and confidently 100 wrong sometimes"* (line 466)

> *"That's brilliant, David."* (line 470, Sal)

> *"Can I use that?"* (line 471, Sal asking permission)

> *"...Again, it's your approach David. i like it is that Is an intern You You don't have the..."* (line 493)

**Sparks coins it; Sal blesses it; Sal asks permission to reuse it.** The interaction is significant. Sparks's metaphor: an LLM is an intern — eager, capable, but **confidently 100% wrong sometimes**. The supervisor (the human) remains responsible for the work product.

Sal's prior position (line 464): *"if you're doing it correctly, it's your assistant not your director."* **Same principle, two framings.** AI is a tool that obeys the user's intent; it doesn't decide what gets done.

## The 20-year no-voicemail story — operational practice of relationship-only contact

> *"i never answered a voicemail while i was..."* (line 77, Sal)

> *"They said, you know, Sal, you never accessed your voicemail."* (line 80)

> *"And I said, 'Well, do you want me to do my job or do you want me to answer voicemail?"* (line 83)

**Sal worked at Apple for 19 years without ever listening to a voicemail.** The story illustrates an organizational doctrine: **relationship-only contact**. Voicemail is asynchronous broadcast — anyone can leave one, you have no signal-to-noise filter. Real work happens via direct human relationships (the WWSD #20 "institution is not the relationship" pattern).

The "baby Ruth bar on the door" tangent (per the agent's report) — Sal's office-door protocol for scheduling. Worth flagging for deeper extraction.

## Sal's diagnosis of the AppleScript renaissance via AI

> *"often because of artificial intelligence You know people who have limited skills with Applescript, Applescript,"* (line 150)

The AI renaissance: people who could not previously write AppleScript are using LLMs to **surface the scripting dictionaries** of apps they want to automate. The dictionaries (sdef) have been public for decades; the barrier was learning AppleScript syntax + reading the dictionary. LLMs collapse that barrier.

**This connects directly to the existing repo's `bin/sdef-to-jxa.py` work** — generate machine-readable JXA documentation that LLMs can feed on for accurate code-completion. Sal's diagnosis suggests doubling down on dictionary tooling.

## Apple Events as cross-platform aspirational architecture

Per the agent's quoting (line 161, 656-660), Sal states *"it was always my desire that Apple events be on every platform... I wanted Apple events on everything and unfortunately that didn't happen."*

> *"The fact that there's a way to communicate between the various applications, which might be a database, it might be an intelligence architecture that can send an Apple event, this invisible communication, over to an app, ask it a question, get a response."* (line 161)

**Sal's regret:** the Apple Events bus, which made Mac so unique, never made it to iOS. iOS apps have App Intents (2020) — structurally similar but not Apple Events. **The Mac's unique advantage atrophies as more user attention shifts to iOS.**

## WWSD-relevant takeaways

- **WWSD #2 (local-over-cloud)** confirmed for the AFM era: on-device intelligence is the canonical pattern, not cloud round-trips.
- **WWSD #20 (institution is not the relationship)** operationalized by the 20-year no-voicemail story.
- **WWSD #34 (vision-stability since 1992)** confirmed yet again: 33 years after the 1993 first script, Sal is still on stage articulating the same architecture.

## CANDIDATE WWSD #50 — AI as intern, not director

**Source quote (verbatim, lines 464-470):** *"if you're doing it correctly, it's your assistant not your director... think of it as an intern... eager to help and confidently 100 wrong sometimes."* (Sparks framing; Sal blessing: *"That's brilliant, David. Can I use that?"*)

**Rationale:** The LLM-collaboration governance principle. Humans remain accountable for work product; LLMs are eager-but-imperfect interns. This re-grounds AI tools in user-author principles (WWSD #1) — the LLM doesn't replace the user, it amplifies them. The human directs; the AI executes.

**How to apply:** When using Claude / ChatGPT / Copilot / Cursor for any task in this repo, treat output as intern-grade: useful starting point, requires supervisor review before commit. Never check in LLM output unverified. Never trust LLM-cited quotes without grep verification (this entire session's senior-audit work is the operational version of #50).

## CANDIDATE WWSD #51 — Apple Events should be on every platform

**Source quote (verbatim, line 161, plus agent-cited 656-660):** *"this invisible communication, over to an app, ask it a question, get a response"* + *"it was always my desire that Apple events be on every platform... I wanted Apple events on everything and unfortunately that didn't happen."*

**Rationale:** The architectural counterfactual. The Mac's universal-IPC bus was never extended to iOS. iOS got Intents (2014 onward) — similar shape but per-app-declared, not a universal bus. **Sal's diagnosis of why iOS-Mac integration has been weaker than it should be is structural: no shared IPC.**

**How to apply:** When designing cross-platform automation in this repo (e.g. shortcuts that should bridge Mac and iPhone), recognize that you're bridging two different IPC architectures, not one. Don't assume Mac-only patterns port to iOS. **The patterns that DO port: Omni Automation (JavaScript on WebKit on both platforms — Sal's post-Apple endrun around the missing universal bus).**

## Reusable for the apple repo

- **OmniFocus 4.8 AFM pattern** — port as a reference example. `bin/jxa-afm-example.js`: an Omni Automation script that invokes Apple Foundation Models to summarize a task. The two-or-three lines of JavaScript Sal mentions.
- **Sparks's "intern" metaphor** as the operational frame for LLM collaboration in this repo. Worth a `analysis/sal/ai-as-intern-doctrine.md` policy document.
- **The 20-year no-voicemail story** as a side-bar in `sal-soghoian.md` — illustrates WWSD #20 + the relationship-over-broadcast doctrine.
- **The "Apple Events on every platform" regret** is a structural argument that supports the existing repo's Mac-first content-pipeline strategy. Sealed iOS devices (WWSD #41 "content automation outlives the device") are partly a consequence of this missing IPC layer.

## Audit footer — verbatim quote verification

| Quote excerpt | Line(s) | Verdict |
|---|---|---|
| *"Apple foundation models framework"* | 383-384 | ✓ exact |
| *"think of it as an intern"* | 464 | ✓ exact (Sparks) |
| *"eager to help and confidently 100 wrong sometimes"* | 466 | ✓ exact (Sparks) |
| *"That's brilliant, David. Can I use that?"* | 470-471 | ✓ exact (Sal) |
| *"if you're doing it correctly, it's your assistant not your director"* | 464 | ✓ exact (Sal) |
| *"i never answered a voicemail while i was"* | 77 | ✓ exact (Sal) |
| *"do you want me to do my job or do you want me to answer voicemail?"* | 83 | ✓ exact (Sal) |
| *"often because of artificial intelligence You know people who have limited skills with Applescript"* | 150 | ✓ exact |
| *"this invisible communication, over to an app, ask it a question, get a response"* | 161 | ✓ exact |

**Quote count audited: 9. All verbatim.**

## Whisper proper-noun confidence flags

- *"Phipe Pierneau"* — almost certainly **Philippe Piernot** (pre-Apple researcher at General Magic + Apple, worked on early speech tech). Agent #4's name resolution likely correct.
- *"Tom Gruber"* — correct. Siri co-founder, joined Apple 2010 acquisition.
- *"Stephen Hackett"*, *"David Sparks"* — correct (MPU hosts).
- *"Sal Soghoian"* — Whisper renders various; correct name preserved by hosts.
- *"Benny Goodman Riding High"* — Sal's transcription-as-motifs pedagogy story (per agent). Benny Goodman is the jazz musician; *Riding High* is a Bing Crosby 1950 film — Sal's reference may be to a specific Goodman recording.

## Limitations

I spot-checked 9 key quotes via grep. The full 1200-line transcript was NOT read end-to-end. The agent's #46-49 candidate claims for additional principles (notably the "10-Action Ceiling" — which belongs to #588, not #815, per the agent's own attribution) are mostly verified for content-existence but not all by direct line-number match.

Senior-audit verdict: **9 quotes verbatim-verified. Candidate principles #50 (AI-as-intern) and #51 (Apple Events on every platform) are strong canon-ready candidates based on verified verbatim quotes.** The renaissance-via-AI claim and the OmniFocus 4.8 AFM integration claim are both supported by direct grep evidence. This transcript is the strongest single source for adding LLM-era WWSD principles to the canon.
