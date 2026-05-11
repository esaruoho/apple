# What the post-Apple Sal corpus added to our understanding

> 10 transcripts (2017-2025) from after the October 2016 elimination from Apple. Senior-audited against verbatim quotes during 2026-05-11. This document synthesizes what these podcasts, interviews, and conference endnotes ADD to the Sal Soghoian / WWSD picture beyond what the 17-session WWDC corpus already covered.

## Headline findings

1. **The "fired in 2016" narrative is incomplete.** Sal continued contracting with Apple's Professional Services team through at least late 2018, working on the never-publicly-released Apple Provisioning Utility (MTC2018 line 588).
2. **Omni Automation began before the firing.** Mid-2015 — a year before Apple eliminated Sal. The post-Apple infrastructure pre-dates the termination (MacVoices 17148 line 111).
3. **The WWSD canon extends to 53 principles.** Tier 5 (#46-53) sourced verbatim to the post-Apple corpus. Eight new principles validated.
4. **Sal's AI-era position is articulated for the first time on the record (2025).** OmniFocus 4.8 integrates Apple Foundation Models via Omni Automation. The "AI as intern, not director" doctrine (Sparks coined, Sal blessed) becomes WWSD #49.
5. **The 20-year arc from QuickTime droplets (2003) → Vocal Shortcuts (2024) is now end-to-end documented.** Same architectural pattern (single phrase → matcher → handler library) Sal demonstrated in 2003 #718 droplets, taught in 2011 #133 `listen for`, sold via TWiT Dictation Commands segment, and underlies Hey Sal v1 in this repo (2026).

## What was added — by document

### WWDC 2017 interview (Jeff Gamet / Mac Observer, Alt Conf)
- **Post-Apple Sal exists and is doing real work, 8 months after the firing.** First confirmed post-Apple primary source.
- **Omni Automation pitched as cross-platform** (Mac + iOS via JavaScriptCore). Same script runs both platforms.
- **Plugin-via-URL distribution model:** tap a webpage link → Omni Automation script installs into the host app. The 2017 incarnation of the 2003 droplet-with-preferences pattern + the 2013 AppleScript Libraries pattern.

### MacVoices 17148 (Chuck Joiner interviews Ken Case + Sal)
- **Timeline correction:** Ken Case states *"Really, this project started about two years ago"* (line 111). Omni Automation began ~mid-2015, **a year before the firing**.
- The implication: Sal had a personal-relationship-based parallel-track ready before Apple cut him. This refines WWSD #20 (institution is not the relationship) — Sal didn't pivot post-firing; he had already cultivated the next stage of his work.

### MTC 2017 — Cross-Platform Automation Magic
- **"Swimming with the whale"** parable (lines 21-31) — Sal's most quotable on-stage framing of leaving Apple. *"For many years, I swam with the whale, and everything kept going forward and kept advancing. And then one day, probably by accident, I got hit by a fin or the tail, and I found myself on the shore. And that's okay because my feet are in the ocean. I'm still part of the ocean."*
- **Surfing-the-wave metaphor:** *"You get your board and you look out on the ocean for where the wave is going to be — not where the wave has been or is but where the wave is going to be — and then you paddle out to that place and you ride the wave that comes."*
- Operationally: Sal saw the iOS-Mac convergence wave coming, paddled out, found the Omni Group already there.

### MTC 2018 endnote — Auto-Managing iDevices
- **BOMBSHELL: Sal contracts with Apple Professional Services.** Line 588: *"services group professional services team at Apple which I do contract with."* The 2016-firing narrative is incomplete. Sal was building the Apple Provisioning Utility (line 583: *"And it's called the Apple Provisioning Utility. This hasn't been shown."*) under contract at Apple two years after termination.
- **"Accidental administrator"** doctrine elaborated — non-IT people who get handed IT responsibilities at small organizations. The design target. *"They simply plug in"* — the trigger is the only user action.
- **Tether Response Chain (TRC)** pattern coined live on stage (lines 206-209) — Sal's framework for plug-in-and-automation cascades.

### MTC 2019 endnote — Ultimate Set of Control Panels
- **Hidden Apple capability surfaced:** the Panel Editor in `/System/Library/Input Methods/AssistiveControl.app`. Shipping in Mojave + Catalina; Apple never marketed it.
- **Sal's signature talk-line:** *"I don't think Apple knows that it's possible"* (line 16). Sourced WWSD #51.
- **Touch control panels via Luna Display + iPad Pro + AppleScript libraries.** The direct architectural ancestor of any Loupedeck/Stream Deck setup. Panels are XML bundle exports — portable across machines.
- **Muscle-memory design rule:** *"Each panel has the same set in the same location"* (lines 241-243). Sourced WWSD #52.
- **Magic Duplicate compound-verb pattern** (lines 277-279). Sourced WWSD #53.

### Triangulation #359 (Leo Laporte, 2018)
- **The canonical biographical anchor.** Sal's pre-Apple jazz-musician life, Pixels print bureau, the 1993 $15 floppy AppleScript developer disk, the first-script moment (*"set the color of the current box to blue"* + *"at that point I let go all my clients"*), the recruitment by *"Shafas Syed, Bamandara, and Guy Kawasaki, and a couple other people, and Chris Espinosa"* (Whisper proper-noun problem — first two names unresolved, recommend Sal-direct outreach).
- **The Town Hall confrontation with Steve Jobs** verbatim — sourced WWSD #25 (speak the receiver's language). *"My first words to Steve were, no, you're wrong."*
- **Verbatim text of the firing:** *"the position that I had wasn't being supported anymore"* (line 490). Sal's only public statement; measured, no personal blame.

### Triangulation #360 (Leo Laporte, 2018, part 2)
- **The Patton email story** verbatim (lines 50-67). *"I said, I'm just a soldier... but you got me out here with no supply line."* Sourced WWSD #25's specific Patton-themed embodiment.
- **The "paragraph with three reference links" formula** (lines 94, 96). Sal's stated rule for executive communication. Sourced WWSD #46.

### MPU #588 — macOS Services with Sal (2021)
- **Host-identity resolution:** Mac Power Users (Stephen Hackett + David Sparks) — **NOT** CCATP #559 (Daniel Jalkut). Existing canon's CCATP attributions stand untouched.
- **Sort Paragraphs live build** — four letters of shell (`sort`) wrapped in an Automator workflow → universal text-sort Service across every Cocoa app. WWSD #1 (democratization) at its lowest possible bar.
- **The 10-action ceiling** (lines 378-381). Sourced WWSD #48.
- Sal extends his 2003 four-whys framework with operational Services-architecture detail at podcast length.

### MPU #815 — Automation Update (2025, post-AI era)
- **The most recent Sal-on-record interview.**
- **OmniFocus 4.8 ships Apple Foundation Models (AFM) integration** via Omni Automation (lines 383-384). Two-or-three lines of JavaScript → on-device LLM query. WWSD #2 (local-over-cloud) operationalized for AI era.
- **"AI as intern, not director"** doctrine (lines 464-471). David Sparks coins it: *"think of it as an intern that is eager to help and confidently 100% wrong sometimes."* Sal blesses: *"That's brilliant, David. Can I use that?"* Sourced WWSD #49.
- **Apple Events on every platform regret** (line 161 + surrounding). Sourced WWSD #50.
- **The 20-year no-voicemail story** (lines 77-83). Sal worked at Apple 19 years without ever listening to a voicemail. Operationalizes WWSD #20 — relationships beat broadcasts.

### Sal Dictation Commands (TWiT segment, Leo Laporte)
- **The canonical Sal demo of dictation-commands-as-voice-automation.**
- 400-command iWork+Finder+Photos library at DictationCommands.com.
- "30 variations of what you say. It does not have to match the code. It does not have to match." — operational source for WWSD #11 (name commands like speech).
- *"This is not Siri. We're not looking at Siri here."* — strongest verbatim source for WWSD #2 (local-over-cloud).
- **Direct architectural ancestor of Hey Sal v1.** Same matcher pattern: spoken phrase → dictation engine matches → AppleScript library handler.

## What we now understand about Sal

### As a craftsman
The corpus shows Sal as a **research-driven craftsman, not a marketer**. He probes /System/Library/ for hidden capabilities (MTC2019). He partners with Omni Group on JavaScript bridges (post-2016). He builds control panels in his own time and shows them at small conferences. **The technology comes first; the audience finds him.**

### As an organizational operator
- **Horizontal relationships beat vertical hierarchy.** As Apple product manager (1997-2016), Sal worked horizontally across retail, iTunes, engineering — never reporting up a single chain. The Town Hall confrontation with Jobs and the 20-year-no-voicemail story are both expressions of this.
- **He had executive-communication rules:** the "paragraph with three reference links" formula (WWSD #46). The Patton email to Jobs (WWSD #25). Speak the receiver's language; respect their attention.
- **Management's importance/role framing (WWSD #47)** explains both his Apple tenure AND the firing. Jobs+Federighi era execs grasped Sal's importance and role; post-2016 leadership grasped neither.

### As a long-term-vision keeper
- **34-year vision stability** (1992 first AppleScript brochure → 2025 MPU #815). Same five pillars (AppleScript + Automator + Services + Terminal + JXA). Same WWSD #1 (democratization). Same WWSD #2 (local-over-cloud, now re-confirmed for AI). **The vision survived the firing, the cloud era, the iOS pivot, and the LLM wave.**
- **Post-Apple Sal is the same Sal as 2003 Sal.** He hasn't pivoted, hasn't compromised, hasn't reframed for marketability. The work continues at Omni, MacTech, DictationCommands.com, and via Apple Professional Services contracts.

### As an AI-era guide
- The AFM integration in OmniFocus (2025) shows Sal embracing AI in a specific, principled way: **on-device, scoped, intern-not-director**. Same WWSD #2 (local) principles applied to a new technology.
- His diagnosis of the AppleScript renaissance — *"people who have limited skills with AppleScript"* using LLMs to surface scripting dictionaries — points the apple repo toward dictionary-tooling investment (the JXA renderer is already there; richer documentation is the next pass).

### As a continuing collaborator with Apple
- Despite the firing, Sal **kept working with Apple via contract relationships** at least through late 2018. The Apple Provisioning Utility never publicly shipped — but Sal worked on it. United Airlines pilots (per the third agent's MTC2018 audit) used it.
- The narrative "Apple kicked Sal out and lost everything" is partially true but oversimplified. **Apple kept Sal close as a contractor on specific projects.** The institutional connection survived; only the staff position ended.

## How this changes the repo

### Hey Sal v1 is in a 23-year lineage
The Hey Sal v1 matcher in this repo (`applets/hey-sal.scpt`) is the **2026 implementation of the architecture Sal demonstrated in 2003 #718 (droplet-with-prefs), taught in 2011 #133 (`listen for`), and showed Leo Laporte via Dictation Commands.** Not a new invention — the latest incarnation of a documented Sal pattern.

### WWSD canon grew 27 → 53
- Tier 0-2 was 27 principles (pre-this-session)
- Tier 3 (2003 WWDC) added 8 → 35
- Tier 4 (2007-2015 WWDC) added 7 → 42
- Tier 4 also re-numbered Tier 0+ #12 → kept at 42 (was 45 in last commit, math reconciled to 45 then 53)
- Tier 5 (post-Apple 2017-2025) added 8 → 53

(Note: small principle-counting drift between previous commit and this one — the final integration uses 53. Audit footer in this document supersedes earlier mismatched counts.)

### New repo work surfaced by the corpus
- **OmniFocus 4.8 AFM JavaScript pattern** → port as `bin/jxa-afm-example.js`
- **MTC2019 Panel Editor + Luna pattern** → `bin/install-assistive-panels.py` + Luna config
- **MPU #588 10-action ceiling audit** → audit `scripts/workflows/` for over-10-action chains
- **Sparks intern doctrine** → `analysis/sal/ai-as-intern-doctrine.md` policy document
- **20-year no-voicemail** → sidebar in `sal-soghoian.md` (or this file) as WWSD #20 embodiment

## Bottom line

**The 10 post-Apple transcripts confirm that Sal is the same Sal he was at Apple.** Same principles, expanded examples, more honesty about institutional dynamics, deeper integration with the OmniGroup, ongoing (but quiet) Apple contract relationships. The corpus extends the WWSD canon by 8 principles (Tier 5 #46-53). The canon now stands at 53 principles spanning 1992-2025 — a 33-year vision-stability arc.

Sal's post-Apple work is not a coda. It's continuation by other means.
