---
layout: default
title: WWSD — What Would Sal Do
---

# WWSD — What Would Sal Do

[← Back to home](./)

> *"It's very empowering to give somebody that ability to suddenly change the way they work and enable them to do great, complex things to grow their business."* — Sal Soghoian

WWSD is a growing catalog of principles distilled from Sal Soghoian's twenty years at Apple, his post-Apple interviews and writing, and the WWDC sessions he gave between 1997 and 2016. Each principle is a one-line decision rule with a citation to where it was articulated.

54+ principles currently catalogued. Lives in [`wiki/entities/sal-soghoian.md`](https://github.com/esaruoho/apple/blob/main/wiki/entities/sal-soghoian.md). The first eleven, lifted directly:

## The first eleven

1. **Democratization over dependency** — automation shouldn't require being a programmer.

2. **Local over cloud** — *"If you can do it yourself, don't send your data to someone to manage or manipulate for you."* / *"Whenever possible, avoid joining the food chain."*

3. **User automation is not app extensions** — true user automation (AppleScript, Automator, Services, UNIX CLI) gives genuine power and control.

4. **Automation as a right, not a feature** — fundamental to what makes the Mac the Mac.

5. **Practical over theoretical** — scripts on almost every page, not reams of boring theory.

6. **Automation as human nature** — *"Automation is a fundamental human concept. We always look for ways to automate stuff... when we farm we look for a way to make it better, we developed a plow, when we developed manufacturing we look for a way to automate certain processes. As humans we always are looking for ways to make things easier, to produce a consistent output of what we do and to scale what we want to do."* (CCATP #559)

7. **Everyone can automate** — Apple says "everyone can code," but Sal proposes an intermediate level: *"There's also an intermediate level in there of everyone can automate. Everybody can learn how to use the computer and automate and put pieces together to tell their story, to make the kind of tools that they want to make that serve their needs."* (CCATP #559)

8. **AppleScript as environmental awareness** — *"The wonderful thing about AppleScript is you can put a lot of intelligence in your scripts. Because AppleScript is so foundational, it can understand the environment that you're in. It knows what application's in the foreground. It knows what application is available. It knows where your documents are, and it can respond to conditions and do things based upon how the current system is set up."* (CCATP #559)

9. **Never stop learning** — *"When you stop wanting to learn, then you're just marking time. You join God's waiting room. I don't want to be in the waiting room. I want to still be alive."* (CCATP #559)

10. **Build for yourself first, share second** — On iWorkAutomation.com: *"To tell you honestly, many times I put those examples up there for me so that I can go back later on and go, oh yeah, how did I do that?"* Then: *"I Google for an answer and it's one of my own blog posts."* (CCATP #559)

11. **Generosity as obligation** — *"Everything I've been able to accomplish in my life is because of others and their generosity and them blazing the path and helping me. And I have a responsibility to return that kindness and share what I know with other people as well."* (CCATP #559)

## The Roundtrip Rule (WWSD #54)

> *"If you did a roundtrip for something that could be done locally, you have wasted everyone's time. Time is of the essence."*

Articulated 2026-05-11 by Esa Ruoho while reviewing the post-Apple Sal corpus, as the operational synthesis of WWSD #2 (local-over-cloud) + WWSD #41 (time as the meta-why) + WWSD #49 (AI as intern, not director).

**The acid test:** if the task could finish in 50ms with local CPU+RAM but you used a 2-second cloud round-trip + N tokens, you wasted everyone's time. Every time. Compound across a working day = an hour burned. Compound across a year = a workweek. WWSD #41 (time is the only resource that doesn't accumulate) applies in the negative: **wasted roundtrip time is gone forever.**

The architectural example: ask a HomePod Mini for the temperature in your room. It has a thermo-hygrometer. Apple routes the query to WeatherKit instead. Multiplied across N users × N queries per day = staggering structural waste. The fix is in the architecture, not the model: **route local-answerable queries locally, period.** [Full derivation + acid test.](https://github.com/esaruoho/apple/blob/main/wiki/entities/sal-soghoian.md#L632)

## How this catalog grows

Every Sal transcript that surfaces (YouTube interview, podcast episode, recovered article, WWDC session) gets walked for new "Sal-like" lines. If a line articulates a decision rule that wasn't already in the catalog, it becomes a new WWSD. The Sal corpus pipeline ([`bin/sal-transcribe-*`](https://github.com/esaruoho/apple/tree/main/bin)) does the transcription; the WWSD extraction happens during the analysis pass logged under [`analysis/sal/`](https://github.com/esaruoho/apple/tree/main/analysis/sal).

The accumulated catalog feeds the [`what-would-sal-say`](https://github.com/esaruoho/apple/tree/main/sources/sal) skill grounding so any session can query "what would Sal say about X" and get a response in his cadence backed by real quotes.

## Read more

- Full 54+ principles + citations: [`wiki/entities/sal-soghoian.md`](https://github.com/esaruoho/apple/blob/main/wiki/entities/sal-soghoian.md)
- Cross-decade design patterns derivable from the catalog: [`wiki/concepts/sal-cross-decade-lineages.md`](https://github.com/esaruoho/apple/blob/main/wiki/concepts/sal-cross-decade-lineages.md)
- WWSD voice-signature distillation file (drives the skill): [`analysis/sal/wwsd-updates-from-2003-transcripts.md`](https://github.com/esaruoho/apple/blob/main/analysis/sal/wwsd-updates-from-2003-transcripts.md)
- Operational sal-corpus pipeline: [Sal corpus page](./sal-corpus)

---

[← Back to home](./) | [Triggers ←](./triggers) | [Tiers ←](./tiers) | [Sal corpus ←](./sal-corpus) | [Chassis ←](./chassis) | [ASObjC ←](./asobjc) | [Finder-tag ←](./finder-tag-pipeline) | [Spotlight ←](./spotlight)
