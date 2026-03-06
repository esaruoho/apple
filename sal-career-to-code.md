# From Publishing Consultant to Patent to This Repo

How Sal Soghoian's career arc — publishing automation in the 1990s → Automator at Apple → the patent → departure — directly informs what this repository builds today.

---

## 1. Publishing Origins → The Automation Instinct

In the late 1980s, Sal worked at a digital printshop called "Pixels" in Charlottesville, Virginia. In the 1990s, he became a publishing automation consultant — writing AppleScripts that automated QuarkXPress workflows for the publishing industry. Batch typesetting, automated page layouts, repetitive production tasks that humans shouldn't have to do by hand.

He wrote *The Quark XTensions Book* (1994). He authored "Sal's AppleScript Snippets" — a popular script collection. He built the ShadowCaster Quark XTension. He presented at Quark conferences, Seybold, Macworld.

This is where the instinct was born: **observe a workflow, count the clicks, collapse them into one action.**

When Cal Simone convinced Steve Jobs to keep AppleScript alive, his pitch was that the publishing industry was "utterly dependent on AppleScript." He was describing Sal's client base.

**What this repo inherits:** `bin/app-probe.py` does exactly what Sal did as a consultant — walks into a system, maps every automation surface, and reports what's possible. He did it for publishing houses. We do it for all 66 Apple apps at once.

---

## 2. Automator → The Chaining Pattern

In late 2002, Sal joined an ad hoc team of engineers building an application for creating and running automation workflows. After a year and a half of development, he showed it to Steve Jobs one week before WWDC 2004. Jobs put him on stage.

Automator's core insight: **workflows are chains.** One action produces data, the next consumes it. The user doesn't write code — they arrange blocks. The system handles data type conversion between them invisibly.

This wasn't just an app. It was a philosophy made executable: the power of the computer should reside in the hands of the one using it. You don't need to know AppleScript to automate. You just need to see the chain.

**What this repo inherits:** `dictionaries/_index.yaml` — the data type chaining index. Which apps produce `file`, which consume `document`, which bridge between `alias` and `image`. This is the Automator patent vision realized as a lookup table. The chains Sal built into Automator's UI, we extracted as queryable data.

---

## 3. The Patent → Context-Aware Relevance Filtering

**US 7,428,535 B1** — "Automatic Relevance Filtering" (filed 2004, granted 2008). Co-invented by Sal with Eric S. Peyton, Tim W. Bumgarner, and Todd R. Fernandez.

The patent solves a specific problem: when building a workflow, hundreds of possible next actions exist. Most are irrelevant. The patent describes a system that:

1. Examines what data type the current action outputs
2. Filters the next available actions by what they can accept as input
3. Ranks them by conversion cost (exact match → needs bridging → incompatible)
4. Automatically inserts invisible "bridge" actions when types don't match

Three companion patents filed the same day complete the picture: the visual UI, the runtime flow logic, and the automatic data type conversion engine.

**What this repo inherits:** The 13-layer probe (`bin/app-probe.py`) and the cross-app index (`dictionaries/_probe-index.yaml`) are the raw data that a modern relevance filter would consume. If you wanted to build an Automator for 2026 — one that knows about App Intents, URL schemes, Siri phrases, and scripting dictionaries simultaneously — you'd need exactly this census as your input. The patent describes the intelligence. This repo provides the data it would operate on.

---

## 4. Scripting Dictionaries → The Depth Layer

Sal personally wrote the scripting dictionaries for iWork (Keynote, Numbers, Pages), iPhoto, Aperture, and Photos. He didn't just advocate for AppleScript — he sat down and defined the object models that make apps scriptable. Every command, every class, every property.

This is the deep layer. Shortcuts gives you width (every app, every device). Scripting dictionaries give you depth (every property, every object, every class in a specific app).

**What this repo inherits:** `bin/sdef-extract.py` pulls 31 scripting dictionaries into machine-readable YAML and human-readable markdown. The dictionaries Sal wrote by hand for iWork and Photos — we extract them programmatically alongside every other app that has one. His craft, made queryable.

---

## 5. Music → The Parallel Life

Sal earned a degree in music from Berklee College of Music. He played guitar in Blue Indigo — a Charlottesville band whose other members (Carter Beauford, LeRoi Moore) went on to found the Dave Matthews Band. He released a solo album, *To Be with You* (1992).

At Apple, he championed automation in Logic Pro and GarageBand. Logic Pro has 13 AppleScript commands and 12 classes — a deep scripting dictionary. Music (formerly iTunes) has 31 commands and 26 classes plus 123 Siri phrases and 23 Shortcuts actions. These are Tier 1 and Tier 2 apps in the Atlas because someone at Apple cared about making them scriptable.

**What this repo inherits:** The Atlas doesn't separate "creative" apps from "productivity" apps. Logic Pro sits next to Terminal. Music sits next to Mail. Sal didn't separate his lives — the musician and the automation engineer were the same person. The probe treats every app the same way: what can it do, and how deeply can you control it?

---

## 6. CMD-D → Open Knowledge

After leaving Apple, Sal organized **CMD-D: Masters of Automation Conference** (2017) in Santa Clara. He built **Omni Automation** — a JavaScript-based automation framework for OmniFocus, OmniGraffle, OmniOutliner, and OmniPlan that works on both macOS and iOS. He created hundreds of voice-triggered dictation commands. He kept teaching.

The pattern: when the institution stops supporting the work, you open-source the knowledge. You build it in public. You make it available to anyone who cares.

**What this repo inherits:** This entire repository. The Atlas is a public document. The probe tools are open source. The painpoints are filed publicly. The Sal profile is a historical record. CMD-D was a conference that shared automation knowledge. This repo is a GitHub repository that does the same thing — permanently, forkably, and for free.

Sal built Omni Automation as a JavaScript framework that brings automation to apps whose developers adopt it. The same pattern scales: automator bots that can read scripting dictionaries, understand data type chains, and execute workflows across apps — that's the Automator vision running as software agents instead of drag-and-drop blocks.

---

## The Thread

```
Publishing consultant (1990s)
  → Observed: workflows are repetitive, humans shouldn't do them manually
  → Built: scripts that collapsed multi-step processes into one action

Automator (2002–2004)
  → Observed: non-programmers need automation too
  → Built: visual chaining system where anyone can build workflows

Patent (2004)
  → Observed: too many actions, users get overwhelmed
  → Built: context-aware filtering that shows only relevant next steps

Scripting dictionaries (1997–2016)
  → Observed: apps need deep automation surfaces
  → Built: object models for iWork, Photos, iPhoto, Aperture

Departure (2016)
  → Observed: Apple eliminated the role
  → Built: CMD-D, Omni Automation, continued teaching

This repo (2026)
  → Observed: no one has mapped the full automation surface of macOS
  → Built: 13-layer probe, 66-app census, data type chains, painpoints
  → Continuing: the role Apple eliminated, as open source
```

---

*The credo hasn't changed. The power of the computer should reside in the hands of the one using it. Sal proved it as a consultant, as an Apple employee, and as an independent. This repo is one more proof.*
