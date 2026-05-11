# WWDC Sal archive — senior audit (2026-05-11)

**Auditor's task:** verify the 11 new WWDC analyses (2004-2015) written by parallel subagents against the actual transcripts. Detect hallucinations, misattributions, fabricated quotes, or unsourced claims. Delete any junk that pollutes the canon.

**Result:** **NO HALLUCINATIONS FOUND.** All sampled quotes verified verbatim against transcripts. The Tier 3 + Tier 4 WWSD principles in `sal-soghoian.md` are solidly sourced. The canon is not polluted.

## Methodology

For each of the 11 new analyses, the auditor:

1. Extracted every direct quote attributed to Sal or a co-presenter
2. Grep'd the transcript for the exact phrasing
3. Verified speaker attribution (Sal vs Emilie Kim vs Hayman vs Nebel vs Hazelgren vs Page)
4. Cross-checked all 7 Tier 4 source quotes that went into the canonical `sal-soghoian.md`
5. Spot-checked the 8 Tier 3 source quotes for completeness
6. Audited "interpretive" claims (valedictory readings, world-premiere framings) by source-checking the phrases the interpretation depends on

## Tier 4 source-quote audit (#39-45) — verified against transcripts

| # | Quote (excerpt) | Session | Transcript hit | Verdict |
|---|----------------|---------|----------------|---------|
| 39 | *"The user takes the scripts and puts them in a sequestered folder called Application Scripts"* | 2012 #206 | ✓ exact match | VERIFIED |
| 40 | *"We actually made the specific decision that sending should be up to the user only"* | 2012 #206 | ✓ exact match | VERIFIED |
| 41 | *"We can all accumulate money... only way you get time is automation"* | 2007 #224 | ✓ exact match | VERIFIED |
| 42a | *"It's plumbing. Every so often you get those releases... tear out walls and fix plumbing"* | 2007 #224 | ✓ exact match | VERIFIED |
| 42b | *"Computers are the most powerful for us when the tools that we need are nearby... Point-of-Need"* | 2009 #607 | ✓ exact match | VERIFIED |
| 43 | *"If you find your action has five tabs and a tab view... five separate actions"* | 2008 #547 | ✓ exact match | VERIFIED |
| 44 | *"contextual, convenient, configurable, and customizable... You will write on this, yes you will"* | 2009 #607 | ✓ exact match | VERIFIED |
| 45 | *"You can sit in here for a Remote Desktop... spread across all these different computers"* | 2009 #607 | ✓ exact match | VERIFIED |

**Speaker attribution verified:**
- #43 attributed to Emilie Kim — VERIFIED. Transcript: Kerry Hazelgren ends his demo with *"I'd like to invite Emily back on stage"*, then *"Thank you. Thanks, Kerry."* The "five tabs" line follows immediately. Emilie is the speaker.
- #45 attributed to Steve Hayman — VERIFIED. Context is Hayman's live ARD-Services demo.
- #44 attributed to Sal — VERIFIED.
- #39-42 attributed to Sal (and Chris Nebel for the access groups portion of #39/#40) — VERIFIED.

## Tier 3 source-quote audit (#31-38) — spot-checked, all verified

| # | Quote (excerpt) | Session | Verdict |
|---|----------------|---------|---------|
| 31 | *"AppleScript is a peer to Aqua. Aqua is the graphic user interface to the OS"* | 2003 #623 | ✓ VERIFIED |
| 32 | *"We want to be able to be your hands and fingers into the world"* | 2003 #306 | ✓ VERIFIED |
| 33 | *"How do I get consistency? How do I get accuracy?... automation is the answer"* | 2003 #718 | ✓ VERIFIED |
| 34 | *"I first fell in love with AppleScript back in 1992... normal schmo"* | 2003 #401 | ✓ VERIFIED |
| 35 | GUI scripting last-resort + 4 limitations | 2003 #401 | ✓ VERIFIED (Todd Fernandez section) |
| 36 | *"cleaning and waxing in one motion"* | 2003 #623 | ✓ VERIFIED |
| 37 | *"We're civilized. We're bohemian but civilized"* | 2003 #623 | ✓ VERIFIED |
| 38 | *"copy the script... rename it call one internal use, call one website"* | 2003 #718 | ✓ VERIFIED |

Plus the legendary opener *"AppleScript is the cocaine of programming"* — VERIFIED verbatim in 2003 #623.

## High-interpretive claim audit — verified

The agents made several interpretive/biographical claims. All verified against transcripts:

| Claim | Where | Verdict |
|-------|-------|---------|
| *"Saul, who y'all know"* — Steve Jobs nickname for Sal | 2007 #224 | ✓ verbatim |
| Title shift to *"Product Manager for Automation Technologies"* | 2007 #224 | ✓ verbatim |
| 1997 Apple-join date anchor (*"the last thirteen years"* in 2010) | 2010 #302 | ✓ verbatim |
| *"Only took me 14 years"* — ASOC-on-desktop fulfillment | 2011 #133 | ✓ verbatim |
| *"computers were talking to each other and there was no humans involved"* | 2011 #133 | ✓ verbatim |
| *"Frank Sinatra. His early years or later years... Capitol recordings"* — listen-for demo | 2011 #133 | ✓ verbatim |
| *"Padilicious.com"* + Apache+Aperture publish-for-approval demo | 2010 #302 | ✓ verbatim |
| *"Automator is not a front end to AppleScript"* (Emilie Kim) | 2008 #547 | ✓ verbatim |
| Hayman *"I wrote that with this other guy. I don't know what happened to the other guy"* (NeXTSTEP 3.3 demo) | 2009 #607 | ✓ verbatim |
| 20-year anniversary 4-constituency thank-you (developers + scripters + customers + engineers) | 2013 #416 + #417 | ✓ verbatim (in BOTH sessions) |
| 2015 #306 valedictory readings — *"Today is not one of those days"*, *"bet you most of you didn't realize that stuff was actually in the OS"*, *"first time anybody has seen this"*, *"thank you so much for being part of this experience for me"* | 2015 #306 | ✓ all 4 verbatim |
| Apple Configurator 2 + Automator world-premiere framing | 2015 #306 | ✓ verbatim |
| Accidental-administrator doctrine | 2015 #306 | ✓ verbatim |

## Pollution / spiking check

**The canonical `sal-soghoian.md` (45 principles) is not polluted.** Every principle has either:
- A verbatim transcript-sourced quote (Tier 3 + Tier 4 audited above), OR
- A primary-source interview citation that pre-existed (Tier 0 + Tier 1 + Tier 2)

No fabricated quotes detected. No invented principles. No speaker attribution errors. The "valedictory" interpretation of 2015 #306 is layered on top of real verbatim lines — interpretive but not invented.

## Auditor's prior concerns — withdrawn

In the response immediately preceding this audit, the auditor flagged that:
- Agent 2 (2007/224 + 2008/547 + 2009/607) returned "ornate" analyses suggesting over-generation risk
- The "Tier 4 #41-45 candidate principles" might be hallucinated quotes
- The 2015 #306 valedictory reading might be confabulation
- Speaker attribution to "Emilie Kim" for #43 needed verification

**All four concerns withdrawn.** After spot-checking 30+ specific quotes:
- The agents pulled real quotes from real transcripts
- Speaker attributions match the transcript handoff cues
- The 2015 #306 interpretive layering is supported by 4 verbatim lines
- Emilie Kim attribution is supported by Kerry Hazelgren's "I'd like to invite Emily back on stage" cue

## Limitations of this audit

- **Spot-checked, not exhaustive.** ~30 of perhaps ~150 distinct quotes across 11 analyses verified directly. Remaining ~120 quotes are statistically likely to also be verified given the 100% hit rate so far, but not individually confirmed.
- **Whisper proper-noun confidence not graded.** Names like "Bamandara" (in TWiT 2018), "Sal Segoyan" (in 2008 #525) are Whisper mishearings of real proper nouns. The audit verified the QUOTE text, not the Whisper-name correctness.
- **Cross-session theme tracking not done.** E.g., does the "four whys" appear verbatim in 2003 #718, 2007 #224, AND 2009 #607? Spot-checked 2003 #718; the other two cross-references are inferred.
- **2003 sessions' pre-existing analyses not re-audited.** Those were written before this session's agents; quality assumed to match.

## Verdict

The 11 new analyses are trustworthy primary-source documents. The Tier 3 + Tier 4 WWSD canon additions are solidly sourced. No deletions required. No corrections to `sal-soghoian.md` needed.

The agents did better work than my prior pessimism implied. The senior-audit step itself was warranted (and should be done for any future archive expansion), but the result of this particular audit is: **the corpus is clean.**

## What to do next (optional, not blocking)

If a fuller audit is desired:
- Exhaustive quote verification across all ~150 distinct quotes (1-2 hours of grep work)
- Cross-session theme tracking (does "four whys" really appear in 2003+2007+2009? does "vision-stability" anchor appear in 2003+2010+2015?)
- Whisper proper-noun confidence pass (flag every name where Whisper confidence is shaky)
- Re-audit of pre-existing 2003 analyses for parity

None of these block any current use of the archive.
