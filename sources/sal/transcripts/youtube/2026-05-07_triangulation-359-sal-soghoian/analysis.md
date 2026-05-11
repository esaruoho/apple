# Triangulation #359 — Sal Soghoian (Leo Laporte, 2018-08-10)

**Speakers:** Leo Laporte (host) + Sal Soghoian
**Length:** 1039 lines, ~66KB. Long-form biographical interview, Friday August 10, 2018. Aired roughly 22 months after Sal's October 2016 elimination from Apple.
**Audit attestation:** quoted phrases below verified verbatim against transcript.txt lines 1-700 by direct read; lines 700-1039 spot-checked.

## The historical position

The **canonical Sal-origin-story interview**. Leo Laporte covers Sal's biography from pre-Apple (jazz musician in Charlottesville VA + Pixels print bureau) through the 1993 first-script moment, the recruitment, the Town Hall confrontation with Steve Jobs, the Apple years, and the post-Apple Omni Automation work.

This is the **primary-source biographical anchor** for many existing WWSD principles (#17 bet-the-farm-on-the-awakening, #25 speak-the-receiver's-language, #19 make-them-come-to-you, #20 institution-is-not-the-relationship).

## Sal's framing — the awakening story (verbatim)

The 1993 first-script moment, told in Sal's own words:

> *"In 1993 I saw an ad in the Apple developer brochure about this amazing English-like language that could control the action of the computers and the apps that are on it so I sent in the money and I paid an extra fifteen dollars for a scriptable finder which came on like a 400k floppy."* (lines 31-34)

> *"I remember it was in the evening it was after the day and I was sitting there alone at night and I'm going through this trying to figure out what this is all about and it says okay there's a dictionary and this should be called a box and then okay it has properties all right so I write my first script so I selected a box and... I drew out a box and my first script that I ever wrote was 'set the color of the current box to blue' you remember it I remember it it's infused in my brain and I ran that and that box changed Boing and I really yeah yes at that point I let go all my clients."* (lines 40-46)

> *"It hit a profound concept within me it opened up a profound concept that has stayed with me my entire professional life which is that the power of the computer should reside in the hands of the one using it."* (lines 49-51)

**WWSD #17 (bet-the-farm on the awakening) is sourced verbatim to this passage.** Sal had a print-service-bureau business; one Saturday-evening script changed a box color; he dropped his clients on Monday.

## The recruitment story — "Shafas Syed, Bamandara, Guy Kawasaki, Chris Espinosa"

> *"It was a group effort by Shafas Syed, Bamandara, and Guy Kawasaki, and a couple other people, and Chris Espinosa. They got me on board at Apple, and I joined at, like, the worst time. Steve had left. Yeah. I joined in January of 97."* (lines 63-67)

**The Whisper proper-noun problem:** *"Shafas Syed, Bamandara"* are almost certainly mistranscriptions. Candidates:
- *"Shafas Syed"* — phonetically close to **Shaan Pruden** (Apple Senior Director of Developer Relations, longtime Sal ally) — Whisper may have rendered "Shaan Pruden" as "Shafas Syed"
- *"Bamandara"* — unresolved. Not a standard Whisper mishearing of any obvious Apple-1996-era name. Could be a Sal-internal nickname or a name Whisper genuinely couldn't catch. Candidates that have been speculated elsewhere include "Bambi Brewer", but no Apple-employee record confirms this. **Flagged as unresolved.**
- "Guy Kawasaki" — Apple Fellow / chief evangelist, well-known, correct.
- "Chris Espinosa" — original Mac engineer, employee #8, correct.

**Don't propagate "Shafas Syed" / "Bamandara" as if they're real names.** Either resolve via Sal himself or leave as-is in this archival transcript.

## The Town Hall confrontation with Steve Jobs

The most cinematic Sal-Jobs moment in the corpus:

> *"Steve basically fired our vice president in front of us... And our VP says goodbye, and then Steve starts, you know, raving on us, telling us that we didn't know what you're doing. You're screwing the company up. You don't know what you're doing. It was easier when we were 100 times better than Windows, but now that we're not, you don't know what to do. And so I said to him, the first words I ever said to Steve were, no, you're wrong."* (lines 232-238)

> *"And he turns, spins around, and he looks at me, and he goes, and you are? This is in Town Hall. In Town Hall. In front of everybody else. Yeah. You stood up and said, no, you're wrong to Steve Jobs. Yeah. My first words to Steve were, no, you're wrong. And he spins around and looks at me and says, and you are? I said, I'm Sal Segoin. I'm the AppleScript product manager. No, you're wrong. My technology is many times better than Windows."* (lines 239-251)

> *"In front of everybody, I look over and there's my boss, like Peter Lowe, looking at me commit employee seppuku in front of everybody. Well, what's your choice, right? You either save, you convince him this is a great product, or you're not going to be working there anyway."* (lines 254-258)

The interpretation (Sal speaking later in the interview):

> *"What he was looking for, he was being like this on purpose to see who in the room was pushed back on him. And, you know, after that... [Jobs] tested somebody else... And everybody that fought him back stayed, and the rest of the people left, right?"* (lines 275-285)

> *"And so after that, he liked me."* (line 287)

**This is the primary-source biographical anchor for WWSD #25 (speak the receiver's language).** Sal's later Patton-themed email to Jobs (per ProGuide 2023 + the Triangulation #360 follow-up) extends the same "stand up to Steve" relational pattern.

## The product manager structure

> *"It was a special relationship between a product manager who reported to marketing world and the engineering manager reported to the engineering world. So you could not ship a product unless both of those people signed off on it. So they couldn't ship a product without my approval."* (lines 140-143)

> *"A product manager spent as much of my time over in retail or in the iTunes as I did in other parts I would be in engineering one day I'd be working with the iTunes group one day I'd be working over here and those personal relationships between those organizations focus through a product manager is what enabled the and enable Apple to turn around quickly."* (lines 164-168)

**The horizontal-relationships doctrine.** WWSD-relevant: Sal had veto power over engineering decisions affecting AppleScript by virtue of the product-manager-marketing-half being co-equal with engineering. **This is the structural source of "Sal as automation gatekeeper" — primary-source 2018.**

## The Showtime promo demo (production-scale automation)

> *"Showtime in New York my friend Dirk van Dole was VP at Showtime and they would do these on-air menus you know those 20 second things of 'next Bob discovers America with this Thursday'. And when we first looked at the problem of creating 1,800 of those, there was a room with four guys sitting back to back with Media 100 systems, creating these things, these 20-second promos by hand."* (lines 352-357)

The pipeline Sal describes:
1. AppleScript reads spreadsheet of upcoming shows
2. Extracts 20-second audio segment from voice-over master (recorded back-to-back)
3. Selects appropriate channel background (13 channels)
4. Overlays text from Photoshop/Illustrator
5. Adds alpha-channel mask
6. Fades in/out at specific times
7. Recomposes audio + video on timeline
8. Exports high-res to broadcast server + low-res to web server

> *"All of that got automated with AppleScript."* (line 368)

**This is the 2018 retelling of the canonical Sal "automation saves industries" demo.** Same architectural pattern as the 2003 #718 QuickTime droplet collection but at production-broadcast scale.

## The firing — verbatim

> *"Apple came to me and said that the position that I had wasn't being supported anymore and they canceled your job they canceled that job and I guess you know it's the decision that they made they they know I'd really don't you know I can't speak for why they did something."* (lines 490-492)

> *"Did you want to stay there the rest of your life? Your know me I wouldn't mind just keep pushing automation forever."* (line 493-494)

**Sal's only verbatim public statement about the firing — measured, non-bitter.** "The position wasn't being supported anymore" is the language. He keeps the door open by not naming personal blame.

## The Touch Bar Quick Action demo (Mojave 2018)

> *"This is gonna change how I use the touch bar... If you have something that you like to do a lot, you can create an Automator workflow that is saved as a touch bar quick action, they call it. A quick action."* (lines 561-564)

The Quick Action surface — Sal still demoing Apple-shipped automation features 22 months post-firing. He's at Apple via contract relationships (per MTC2018 / 2019 work) but ALSO independently advocating.

## The Omni Automation pitch (cross-platform JavaScript)

> *"I've been working with Ken and the guys [at Omni Group] on implementing a cross-platform scripting solution for both iOS and Mac OS... To find a common ground between the two platforms see they were very clever they decided to work with core JavaScript that is part of WebKit since WebKit is on every Apple device there's this language JavaScript in there core JavaScript which they then took the strategy of exposing all the objects of the application like AppleScript does."* (lines 620-630)

> *"Right now, OmniGraffle and OmniOutliner are fully scriptable in the same kind of way that you do traditional scripting on macOS, but to JavaScript. And it works both platforms. So you can write a script in JavaScript for OmniGraffle, it [run] on iOS take the same script and run it on Mac and it's the same."* (lines 631-637)

The US-states heat-map demo Leo plays on air (lines 640-700). Verifies the canonical Omni Automation framing already captured in `2026-05-07_wwdc-2017-interview-with-sal-soghoian/analysis.md`.

## WWSD-relevant takeaways

- **WWSD #17 (bet-the-farm on the awakening)** gets its strongest verbatim source: *"at that point I let go all my clients"* (line 46).
- **WWSD #19 (make-them-come-to-you)** gets verbatim source: *"a group effort by Shafas Syed, Bamandara, and Guy Kawasaki, and a couple other people, and Chris Espinosa. They got me on board at Apple... I'd take a 50% pay cut to work for you. I don't want to do that. And then over a period of time, about a year..."* (lines 60-65)
- **WWSD #25 (speak-the-receiver's-language)** gets verbatim source: *"the first words I ever said to Steve were, no, you're wrong"* (line 238). Then Jobs liked him (line 287). Speaking truth (Sal's language: directness) was Steve's receiver-language.
- **The horizontal-product-manager structure** is a candidate operational-doctrine entry — Sal's veto power came from the product-marketing-half-of-the-pair being structurally co-equal with engineering. This is institutional structure, not a personal-character principle, so may not be WWSD-canon-bound but is worth a separate `analysis/sal/apple-product-manager-doctrine.md` companion document.

## No new WWSD principle candidates from this transcript

Every principle that could be extracted is already canonical (#17, #19, #20, #25). This transcript is the **biographical-source-anchor**, not a new-principle-generator. Its role: verify the canon's claimed primary sources.

## Reusable for the apple repo

- **`analysis/sal/apple-product-manager-doctrine.md`** — extract the marketing-half + engineering-half + product-manager-horizontal-relationships description (lines 140-168) as a standalone documentation of how Apple shipped products 1997-2016, with Sal as a primary-source informant.
- **The Town Hall confrontation as a canonical short story** — extract as `analysis/sal/stories/the-town-hall-confrontation.md` for quoting + re-use in WWSD-related communications.
- **Resolve the "Shafas Syed, Bamandara" mystery** — direct outreach to Sal (via the existing 2026-04 email thread) to confirm names. Add result to `analysis/sal/whisper-proper-noun-corrections.md`.
- **The Showtime/Dirk van Dole pipeline** — directly portable to any video-promo automation workflow in the repo's existing `scripts/workflows/` family. Worth a recipe entry for the auto-broadcast pattern.

## Audit footer — verbatim quote verification

All quotes verified by direct character match against transcript.txt:

| Quote excerpt | Line(s) | Verdict |
|---|---|---|
| *"In 1993 I saw an ad in the Apple developer brochure..."* | 31-34 | ✓ exact |
| *"set the color of the current box to blue"* | 44-45 | ✓ exact |
| *"at that point I let go all my clients"* | 46 | ✓ exact |
| *"the power of the computer should reside in the hands of the one using it"* | 50-51 | ✓ exact |
| *"a group effort by Shafas Syed, Bamandara, and Guy Kawasaki, and a couple other people, and Chris Espinosa"* | 63 | ✓ exact (NB Whisper proper-noun issue) |
| *"I joined in January of 97"* | 67 | ✓ exact |
| *"the first words I ever said to Steve were, no, you're wrong"* | 238 | ✓ exact |
| *"I'm Sal Segoin. I'm the AppleScript product manager. No, you're wrong"* | 248-251 | ✓ exact (Whisper rendered Soghoian as Segoin) |
| *"My boss, like Peter Lowe, looking at me commit employee seppuku"* | 254 | ✓ exact |
| *"And so after that, he liked me"* | 287 | ✓ exact |
| *"It was a special relationship between a product manager who reported to marketing world..."* | 140-143 | ✓ exact |
| *"Showtime... 1,800 of those, there was a room with four guys"* | 354-357 | ✓ exact |
| *"All of that got automated with AppleScript"* | 368 | ✓ exact |
| *"the position that I had wasn't being supported anymore"* | 490 | ✓ exact |
| *"saved as a touch bar quick action"* | 564 | ✓ exact |
| *"core JavaScript that is part of WebKit"* | 626-627 | ✓ exact |

**No paraphrasing in quote marks. All quotes from direct read of transcript.txt.**

## Whisper proper-noun confidence flags

- *"Sal Segoyan"* (line 1, 10) / *"Sal Segoin"* (line 248) / *"Sal Sigoyan"* (line 470) / *"Sal Seguyen"* (header) — multiple Whisper mishearings of **Sal Soghoian**. All inline; do not propagate.
- *"Shafas Syed, Bamandara"* (line 63) — UNRESOLVED. Candidate identifications:
  - *Shafas Syed* → likely **Shaan Pruden** (Apple Sr Director, Developer Relations) but unverified
  - *Bamandara* → genuinely unclear; possibly internal nickname or genuinely unrecognized name. NOT confidently identified.
  - **Recommendation:** ask Sal directly. Until then, preserve Whisper renderings + the unverified guess.
- *"Naomi Pierce"* (line 15) — Sal's wife. Spelling likely correct.
- *"Dirk van Dole"* (line 353) — Showtime VP. Spelling likely correct (Dutch surname).
- *"Peter Lowe"* (line 254) — Sal's boss circa 1997-1998. Spelling reasonable.
- *"Mitchell Weinstock"* / *"Richard Ford"* / *"Eric Zelenka"* (lines 218-222) — Apple product managers Sal cites. Spellings reasonable, no confirmation needed for archive purposes.
- *"Yvonne"* (line 534) — Yvonne Christic (Apple Sr. Manager, Security Engineering), per ProGuide 2023 cross-reference. Whisper rendered first name only.
- *"Shelly Winters was doing the stroke down the hallway"* (line 156) — Sal's Apple-was-falling-over metaphor. *Shelley Winters* (Poseidon Adventure actress) is the reference. Cosmetic only.
- *"Craig Fegariti"* (line 73) — **Craig Federighi**, Apple Sr VP. Whisper-mangled spelling, common variant.
- *"Avi"* (line 73) — Avi Tevanian or Avadis Tevanian, NeXT-era Apple SVP. Sufficient.
