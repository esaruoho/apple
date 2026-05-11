# WWSD updates from the 2007-2015 WWDC transcripts (Tier 4)

Eight newly-archived WWDC sessions (2007-2015) extend the WWSD canon with **primary-source spoken Sal from his "Product Manager, Automation Technologies" era** — Leopard through El Capitan. Companion to `wwsd-updates-from-2003-transcripts.md` (Tier 3, sessions 2003 #306/#401/#623/#718).

Sessions sourced:
- WWDC 2007 #224 — Next Generation Automation (Sal solo, Leopard preview)
- WWDC 2008 #547 — Building and Leveraging Automator Actions (Sal third presenter)
- WWDC 2009 #607 — Using Services in Snow Leopard for Scripting IT Tasks (Sal + Hayman)
- WWDC 2010 #302 — Automating the Creation of iPad Content (Sal + Jouaux)
- WWDC 2011 #133 — Lion-Sized Automation (Sal + Chris Page)
- WWDC 2012 #206 — Secure Automation Techniques in OS X (Sal + Chris Nebel)
- WWDC 2013 #416/#417 — AppleScript Libraries + Mavericks Automation Update (Sal + Page + Nebel)
- WWDC 2015 #306 — Supporting the Enterprise with OS X Automation (Sal solo, his last WWDC)

The existing WWSD canon is structured as:
- Tier 0 (#1–11): philosophy + biographical, paraphrased
- Tier 0+ (#12): hallway-pitch lesson
- Tier 1 (#13–27): primary-source spoken Sal 2012–2023 interviews
- Tier 2 (#28–30): WWDC 2016 session 717 transcript
- Tier 3 (#31–38): primary-source spoken Sal 2003 WWDC

This document proposes **Tier 4 (#39–45): primary-source spoken Sal 2007-2015 WWDC**.

---

## Proposed additions

### 39. User-placed-file = consent

**Source:** WWDC 2012 #206 (Secure Automation Techniques in OS X), Sal

> *"The solution to this scenario… is to involve the user. The user takes the scripts and puts them in a sequestered folder that the system's aware of called Application Scripts. And then the application, when the user selects a script from the menu, the application requests the system to execute it. And because scripts written by you and executed by the system run without restrictions, the script runs without restrictions."*

**Why it matters:** When the sandbox cannot decide for the user, the user decides for the sandbox. The act of placing a file in `~/Library/Application Scripts/<host-app-bundle-id>/` IS the entitlement. The app can read/enumerate/create the folder but **cannot write to it** — only the user can place scripts. This invariant is what makes the consent valid.

**How to apply:** Whenever a security boundary needs a per-case decision, use **user-controlled filesystem placement** as the consent surface. Same logic as Sal's 2003 droplet-with-preferences (config in Finder comment, WWSD #38) — both treat the filesystem as a UI for user intent.

---

### 40. Some powers belong to the user, period

**Source:** WWDC 2012 #206, Chris Nebel speaking in Sal's session

> *"We actually made the specific decision that sending should be up to the user only. A sandboxed application really should not have permission to do this ever. So if it's not an access group, then you cannot use it with the new entitlement."*

The `send` Apple Event in Mail is **deliberately in no access group**. There is no entitlement an app can request to send mail. Only user-driven scripts can.

**Why it matters:** Certain operations are not requestable. The decision to send mail, launch a subprocess, talk to Terminal — these aren't operations the app should be entitled to. They're operations the user-via-script can perform. **Some powers belong to the human at the keyboard, period.**

**How to apply:** When designing an automation API or capability boundary, ask: is this an operation an app could safely request? Or is it one that should require explicit user invocation? If the latter, deny it to apps entirely — don't expose it via entitlement.

---

### 41. Automation buys back time — the meta-why

**Source:** WWDC 2007 #224 (Next Generation Automation), Sal

> *"We can all accumulate money, we can accumulate all kinds of things. But we can't accumulate more time. And the only way you get time is automation."*

**Why it matters:** The 2003 four whys (consistency, accuracy, speed, scale) are the *operational* whys. **Time** is the *meta-why* — what those four collectively buy back. Sal explicitly elevates time above the other four as the resource that doesn't accumulate. This is the strongest single-sentence economic argument for automation Sal ever made.

**How to apply:** When evaluating an automation effort, the question isn't "does this save N hours per week." The question is "does this give the user back time they could not otherwise accumulate." If yes, the work is justified at any near-cost.

---

### 42. Index by data type, not by app — Point-of-Need spatial geometry

**Source:** WWDC 2007 #224 (Starting Points UI reform) + WWDC 2009 #607 (Point-of-Need doctrine), Sal

> *"Computers are the most powerful for us when the tools that we need are nearby the things that we have selected, and are pertinent to the items that we have selected, so that they work on that kind of data and we're not bothered with other choices and other options that get in the way of our flow of thought. And we call this Point-of-Need."* (2009 #607)

Sal's Starting Points UX reform (2007) categorizes automations **by the data type the user has selected** — files, images, URLs, text — not by which app provides them. The 2009 Services redesign applies the same principle to the Services menu: filter by selected data type via Data Detectors.

**Why it matters:** Failure mode is the menu-bar dumping ground — automations indexed by app name in alphabetical order. The user has to know which app provides the verb they want. Sal's reform: **the automation comes to the selection**, not the other way around. Spatial geometry: automation must live within reach of the cursor.

**How to apply:** When designing any automation surface, ask: how does the user discover the verbs that apply to what they've selected? If they have to know the source app first, the architecture is wrong. Index by data type.

---

### 43. One verb per action — decompose composite UIs

**Source:** WWDC 2008 #547, Emilie Kim speaking in Sal's session

> *"If you find your action has five tabs and a tab view, and each tab has its own functionality and its own set of controls, maybe that means your action should actually be five separate actions."*

**Why it matters:** Tabs in an action UI are a code smell. Each tab is a separate verb hiding inside a composite. The user can't compose them; the user has to learn the tab discipline. **Decompose: one action per verb.**

The principle generalizes beyond Automator: applies to AppleScript handlers, Shortcuts actions, Hey Sal verbs, Loupedeck button assignments. If the unit has a tab view, it's actually N units.

**How to apply:** When designing an automation primitive, ask: does this UI have tabs? If yes, you have N actions, not one. Ship them separately. The user composes; you decompose.

---

### 44. Point-of-Need — the four C's evaluation rubric

**Source:** WWDC 2009 #607, Sal

> *"They are **contextual, convenient, configurable, and customizable**. You will write on this, yes you will."*

| C | Definition |
|---|-----------|
| **Contextual** | Filters by the user's current selection / data type |
| **Convenient** | Reachable from where the cursor already is |
| **Configurable** | User can enable / disable / shortcut-bind individual items |
| **Customizable** | User can author new items without leaving the host environment |

**Why it matters:** The four C's are the **evaluation rubric** for any automation UI. Sal originally articulated them about Services (Snow Leopard redesign), but they grade every automation surface: Spotlight, Shortcuts, Automator workflows, Loupedeck, Vocal Shortcuts.

**How to apply:** Score any automation UI yes/no/partial across the four Cs. A surface that fails three of four is broken-by-design. A surface that fails one is fixable. **Use in `painpoints/` write-ups** as the standard evaluation header.

---

### 45. One mechanism scales from one selection to a fleet

**Source:** WWDC 2009 #607, Steve Hayman speaking in Sal's session

Same Services architecture sorts selected text in TextEdit *or* runs a shell command as root across 8 remote machines via ARD. **One mechanism, two scales.**

> *"You can sit in here for a Remote Desktop and just type commands all the time and they're suddenly being spread across all these different computers."*

**Why it matters:** Personal automation and fleet management are not separate disciplines. A well-designed Services action that takes a selection and runs a transformation should work identically whether the selection is one item or 800 items across N machines. The fleet case is just the personal case repeated. **Architecturally homogeneous.**

**How to apply:** When designing an automation primitive, test it at both scales. If the personal-scale verb breaks at fleet-scale, the architecture is wrong. Same `whose ... entire contents` (WWSD #37) recursion principle applied across machines, not just files.

---

## Notes for integration into `sal-soghoian.md`

Suggested edits:

1. After the existing "Tier 2" block (last principle #30), add a **Tier 3** heading and the seven principles #31-38 from `wwsd-updates-from-2003-transcripts.md`
2. Then a **Tier 4** heading and the seven principles #39-45 from this document
3. Update the principles-count header at the top of `sal-soghoian.md` from "27 principles" / "30 principles" to **45 principles**
4. Cross-link Tier 3 + Tier 4 source documents

## Cross-references

- **Tier 3 (2003) proposal:** `analysis/sal/wwsd-updates-from-2003-transcripts.md`
- **2012 #206 analysis:** `sources/sal/wwdc/2012-session-206/analysis.md`
- **2009 #607 analysis:** `sources/sal/wwdc/2009-session-607-services-for-it-snow-leopard/analysis.md`
- **2007 #224 analysis:** `sources/sal/wwdc/2007-session-224-next-generation-automation/analysis.md`
- **WWDC master index:** `sources/sal/wwdc/README.md`

## Why this matters for the Sal archive

The 2007-2015 WWDC transcripts close a 9-year gap between the existing interview-based WWSD canon (2012-2023) and the foundational 2003 sessions. Every principle in this Tier 4 document is sourced to **Sal speaking on Apple's own stage** while he held the position he was eventually fired from. The 2015 #306 transcript is the **last primary-source on-stage Sal** before the October 2016 elimination — making it a closing bracket on the corpus.

When merged into `sal-soghoian.md`, the canon becomes:
- 27 principles → 45 principles
- 1992-2023 vision-stability arc, verified across 30+ years
- Sal's structural canon (the five-pillar automation model) explicitly named
- Tier 4 #39-40 (consent + user-only powers) provides the **security-era extension** Sal taught at WWDC 2012 — the architectural answer to sandboxing
