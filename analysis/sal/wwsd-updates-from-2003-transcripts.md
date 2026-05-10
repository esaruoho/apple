# WWSD updates from the 2003 WWDC transcripts

Four newly-archived 2003 transcripts (sessions 306, 401, 623, 718) extend the WWSD principle list with **primary-source spoken Sal from 2003** — predating every existing primary-source interview (which range 2012–2023) by 9 years.

The existing WWSD canon (in `sal-soghoian.md` lines 125–134 + 441–463 + Tier 1/2/3 expansions) is structured as:
- Tier 0 (#1–11): philosophy, paraphrased + biographical
- Tier 0+ (#12): hallway-pitch lesson
- Tier 1 (#13–27): primary-source spoken Sal 2012–2023
- Tier 2 (#28–30): WWDC 2016 session 717 transcript

This document proposes **Tier 3 (#31–38): primary-source spoken Sal 2003**, sourced exclusively to the four WWDC 2003 transcripts.

---

## Proposed additions

### 31. AppleScript is the *language UI* — peer to Aqua, peer to shell

**Source:** Session 623 (AppleScript for SysAdmins), 2003

> *"AppleScript is a peer to Aqua. Aqua is the graphic user interface to the OS, and AppleScript is the language user interface to the OS. I like to think about it in those terms. There's also another language interface that's really low level, which is the Unix interface that you're familiar with."*

**Why it matters:** Cleanest single-sentence statement of macOS's three-peer UI structure. AppleScript isn't *on top of* Aqua, it's *next to* it. This framing is what makes "user automation as a right, not a feature" (existing #4) structurally defensible.

**How to apply:** When designing or critiquing an automation surface, ask: does this serve the *language UI peer* or is it just bolted on top of the graphic UI? Shortcuts on macOS in 2026 sits between the two — that's its strength and its weakness.

---

### 32. You are the user's hands and fingers into the world

**Source:** Session 306 (AppleScript Studio), 2003

> *"We want to deliver more for you with AppleScript, and we want to be able to be your hands and fingers into the world to get the things done that make you money."*

**Why it matters:** Sal's clearest metaphor for *what* automation is — prosthesis for intent, not productivity software. The script extends the user's reach beyond keyboard-and-mouse range. Pairs with existing #1 (democratization) — democratization is the goal; "hands and fingers" is the mechanism.

**How to apply:** When evaluating a script or workflow, ask: does this extend the user's reach, or does it abstract them away from the action? A "hands and fingers" automation keeps the user in command.

---

### 33. The four whys — consistency, accuracy, speed, scale

**Source:** Session 718 (AppleScript and QuickTime), 2003

> *"It basically came down to the same idea that affects every business is how do I get consistency? How do I get accuracy? How do I get speed? How can I scale what I do and make more money and stay competitive? And the answer in any business, whether it's in multimedia or whether it's print or whatever kind of business it is, it's automation is the answer."*

**Why it matters:** Sal's operational answer to "why automate?" — and it's nearly identical to his 2019 MTC framing and his 2023 CCATP #559 framing. **The four whys are stable across 20 years of Sal's public speaking.**

**How to apply:** When justifying an automation effort, name which of the four it serves. A script that serves none of them is a candidate for deletion.

---

### 34. The vision has not dimmed in a decade (now two decades)

**Source:** Session 401 (AppleScript Update), 2003

> *"I first fell in love with AppleScript back in 1992 when I got the developer CD, and I saw that there was the ability for a normal schmo to be able to make the computer do what I wanted it to do. And the vision I had then was to be able to create automation and workflows where I could take information from one program, manipulate it, move it to another program, take that and move it to another program and build something. And in the decade following, that vision has not dimmed at all."*

**Why it matters:** The 1992-vision quote is the deepest primary-source biographical anchor in the WWSD canon. Sal will repeat this idea in 2018, 2019, 2023 — but here it is in 2003, already a decade old at that point. By 2026 it's a 34-year vision. **WWSD is not a 2010s phenomenon; it's a vision that survived 9 OS X releases and one defenestration.**

**How to apply:** When deciding whether to invest in something WWSD-adjacent, remember that the vision has 34+ years of survival behind it. Bet long.

---

### 35. GUI Scripting is a last resort, not a substitute

**Source:** Session 401 (AppleScript Update), 2003

> *"It's not a substitute for object model scriptability. It's not."* (Todd Fernandez, then echoed by Sal)

Four hard limitations from the same session: disabled by default; fragile to UI changes; can't drive non-Cocoa widgets; broken for non-English keystrokes.

The prescription: *if you're a scripter, request real scriptability from the developer; if you're a developer, ship real scriptability — your customers deserve it.*

**Why it matters:** GUI Scripting (System Events `process` suite) is structural duct-tape. In 2026 it's still the same: useful for filling gaps in an otherwise-scriptable workflow, dangerous as a primary surface.

**How to apply:** When a workflow requires GUI Scripting, file a painpoint against the un-scriptable app. Use GUI Scripting only where the alternative is the workflow breaking entirely.

---

### 36. Cleaning and waxing in one motion — find AND act in one line

**Source:** Session 623 (AppleScript for SysAdmins), 2003

> *"In one motion I find the stuff, the other one I actually do something with it. In one line of AppleScript, we are able to clean and wax together."*

**Why it matters:** The signature move of AppleScript — `every X whose Y contains Z` is both a query AND an action target. Most other languages force you to find-then-loop-then-act in three statements. AppleScript collapses them.

**How to apply:** When writing a script, ask: can this be one line that both queries and acts? If yes, do that. Separating the query from the action is a code smell unless you need the intermediate list for something else.

---

### 37. Recurse with `entire contents`, not with for-loops — "we're civilized"

**Source:** Session 623 (AppleScript for SysAdmins), 2003

> *"How do you get down through a directory, a hierarchy? Well, you go to JavaScript and you write `for if and and`, and then you start doing a recursive loop that recalls itself back up at the top again when you get down to here. No, we don't do that in AppleScript. We're civilized. We're bohemian but civilized."*

The pattern: `every X of the entire contents of <container> whose <predicate>`. Finder walks the tree for you.

**Why it matters:** AppleScript was designed for tree-walking as a language primitive. Hand-written recursion in AppleScript is almost always a sign you're fighting the language.

**How to apply:** When a script needs to walk a directory or object tree, use `entire contents` first. Hand-roll recursion only when the structure isn't a Finder/System Events tree.

---

### 38. Configuration via Finder comment + duplicate-and-rename

**Source:** Session 718 (AppleScript and QuickTime), 2003

> *"Each of these droplets are designed to be double-clicked, and you get a preference dialog… you can copy the script to keep a couple copies, rename it call one 'internal use,' call one 'website,' call one 'CD use'."*

The pattern:
1. Droplet has a double-click handler that shows a preferences dialog
2. Preferences stored in the droplet's `description` property or in the Finder comment field
3. To get a different preset, duplicate the droplet and rename it
4. The user's preset library = a folder of duplicated droplets

**Why it matters:** Zero preferences-pane overhead. Zero plist files. The Finder *is* the preferences UI. Discoverable and self-documenting (the droplet's name *is* the preset name). In 2026 we still see this pattern in macOS Shortcuts (Shortcut name = preset name).

**How to apply:** When designing a tool with configurable behavior, ask: can the preferences be embedded in the tool itself and shown on double-click? If yes, do that, and let users duplicate-and-rename for variants instead of building a preference UI.

---

## Bonus principle candidate — not added, but noted

### Optional 39. "Free, free, free" — Mac automation costs zero

**Source:** Session 623 (AppleScript for SysAdmins), 2003

> *"All of this is free, by the way. Did I say free? I meant to say free. Did I say free? Free, free, free. You don't have to pay for AppleScript. You don't have to pay for this incredible ability. It's part of every computer that Apple Computer sells."*

**Why not added as a numbered principle:** Already implicit in existing #1 (democratization over dependency). But the *three-in-a-row "free, free, free"* is a Sal-voice signature worth preserving in the canon for tone, even if it's not a separate operational rule.

---

## Where to integrate

Suggested edits to `sal-soghoian.md`:

1. Add a **Tier 3** heading after the existing Tier 2 block (after line ~520 or wherever Tier 2 ends)
2. Add principles #31–38 with the source quotes verbatim, citing `sources/sal/wwdc/2003-session-{306,401,623,718}-*/transcript.md` for provenance
3. Optionally add the "free, free, free" passage as a sidebar/footnote under #1

Suggested edits to `skill.md`:

- Update line 205 ("WWSD Principle 11") and line 550 ("30 Principles") to reflect 38 principles
- Update memory `feedback_codify_sal_rules.md` to note that primary-source 2003 transcripts are now archived

## Why this matters for the Sal archive

The 2003 transcripts are **the earliest primary-source spoken Sal** we have. Every WWSD principle previously sourced from a 2012+ interview can now be cross-checked against a 2003 statement of the same idea. Where they align, the principle is **two-decade stable**. Where they diverge, it's worth tracing the evolution.

Initial alignment check:
- **Existing #6 ("automation as human nature")** — aligns with new #33 (four whys): both frame automation as a universal answer to a universal question.
- **Existing #2 ("local over cloud")** — implicit in 2003 ("we are your hands and fingers into the world") but not stated as cloud-vs-local since the cloud wasn't yet a target.
- **Existing #1 ("democratization over dependency")** — aligns with new #34 (the 1992 vision: "a normal schmo to be able to make the computer do what I wanted it to do").
- **Existing #11 ("name commands like speech")** — anticipated by 2003-era Script Editor's conversational support (`22nd item` vs `item 22`, etc.) but not yet articulated as a principle.

**The 2003 archive doesn't contradict a single existing WWSD principle**, which is the strongest possible validation that the canon is correctly derived.
