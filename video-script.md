# Video Script: "186 Workflows, One Pipeline"

> How I built a complete macOS automation arsenal — 186 workflow scripts across 16 apps, searchable from Spotlight and speakable via Siri.

## Video Format
- **Duration:** 3-4 minutes
- **Style:** Screen recording + narrated walkthrough, showing the actual conversation and results side by side
- **Tone:** Conversational, confident, technical-but-accessible
- **Audience:** Developers, power users, Loupedeck owners, AppleScript curious, AI-assisted workflow enthusiasts

---

## Scene 1: THE HOOK (0:00 - 0:12)

**Visual:** Black screen. A single Loupedeck Live button glows. A finger presses it. Finder instantly appears.

**Narration:**
"One button. One press. Finder's in front. No Dock hunting. No Cmd-Tab. No friction."

**Text overlay:** `tell application "Finder" to activate`

**On screen:** The script is 3 lines long.

**Psychology:** *Anchoring Effect* — start with the simplest possible example. Viewers anchor on "this is easy." *Contrast Effect* — the old way (hunting through Dock) vs the new way (one press).

---

## Scene 2: THE PROBLEM (0:12 - 0:30)

**Visual:** Loupedeck Live software open. Scrolling through app list. Finder isn't there. Frustration.

**Narration:**
"Here's the thing — Loupedeck Live doesn't list every app. Finder? Not there. Half the utilities? Missing. So I had a choice: live with the gaps, or fill them myself."

**Text overlay:** `64 Apple apps. 0 listed in Loupedeck.`

**Psychology:** *Loss Aversion* — you're losing time every day you don't fix this. *Present Bias* — emphasize the immediate frustration, not abstract future benefits.

---

## Scene 3: THE CONVERSATION BEGINS (0:30 - 1:00)

**Visual:** Split screen. Left: Claude Code terminal with the first prompt. Right: Files appearing in Finder.

**Narration:**
"I opened Claude Code and typed one sentence."

**Show the actual prompt on screen:**
```
make me a global Apple skill that writes perfect AppleScript.
the first errand: bring Finder.app to the forefront.
```

**Narration continues:**
"Three minutes later, I had a working script. I tested it. Finder popped to front. Done."

**Visual:** osascript running, Finder appearing.

**Narration:**
"But then I thought — if one script solves one problem... what about all 64 Apple apps?"

**Text overlay:** `Prompt 1 of 22.`

**Psychology:** *Foot-in-the-Door* — start small, then escalate. Viewer thinks "that's manageable" before seeing the full scope. *Goal-Gradient* — "1 of 22" creates pull to see the rest.

---

## Scene 4: SAL SOGHOIAN — THE PHILOSOPHY (1:00 - 1:30)

**Visual:** Sal Soghoian photo/name. Apple logo. Patent document.

**Narration:**
"I didn't want to just write scripts. I wanted to understand how Apple designed automation in the first place. So I brought in Sal Soghoian."

**Text overlay:** `Apple's Product Manager of Automation Technologies, 1997-2016`

**Narration:**
"Sal co-invented Automator. He championed one idea for 19 years:"

**Text overlay (large, centered):**
> "The power of the computer should reside in the hands of the one using it."

**Narration:**
"I fed Claude his patent — US 7,428,535 — and asked it to analyze how apps pass data between each other. The answer changed everything."

**Psychology:** *Authority Bias* — Sal's credentials make the project feel legitimate, not hobbyist. *Unity Principle* — "one of us" — Sal fought for user empowerment, and so does this project.

---

## Scene 5: THE EXPLOSION — 64 LAUNCHERS (1:30 - 1:55)

**Visual:** File tree expanding. 64 `.applescript` files appearing in rapid succession. Grid of app icons.

**Narration:**
"One prompt:"

**Show prompt on screen:**
```
use all the Apple apps in /Applications and all the Utilities.
make App Launches for each of them.
```

**Narration:**
"64 launcher scripts. Every Apple app. Every utility. Each one, three lines of AppleScript. Each one, a button on my Loupedeck."

**Visual:** Quick montage of pressing different Loupedeck buttons — Calculator appears, Notes appears, Music appears.

**Text overlay:** `40 System Apps. 16 Utilities. 8 Pro Apps. 64 buttons. Zero friction.`

**Psychology:** *Bandwagon/Social Proof* — the sheer number creates credibility. *Zeigarnik Effect* — showing rapid creation leaves viewers wanting to see the finished system.

---

## Scene 6: THE DEEP CUT — 31 SCRIPTING DICTIONARIES (1:55 - 2:30)

**Visual:** Terminal running `bin/sdef-extract.py`. YAML and Markdown files generating. The `_index.yaml` data type chaining map.

**Narration:**
"But launchers are just the start. Every Apple app has a hidden API — a scripting dictionary that tells you exactly what it can do. How many commands it has. What data it accepts. What it produces."

**Show prompt:**
```
present to me a method for automating every single apple app
and passing information across them.
```

**Narration:**
"I built a Python tool that extracts these dictionaries from all 31 scriptable apps. 347 commands. 408 classes. All indexed. All queryable."

**Visual:** Animated diagram showing data flowing between apps — Image Events producing files that feed into 7 other apps. System Events as the central hub connecting to everything.

**Narration:**
"And here's what Sal knew all along — System Events is the universal bridge. 89 classes, 31 commands. It can control any app on your Mac. Even apps with no scripting dictionary at all."

**Text overlay:** `System Events → controls ANY app's UI`

**Psychology:** *Flywheel Effect* — each app feeds the next, creating a self-reinforcing system. *Peak-End Rule* — the System Events revelation is the "peak" — the moment that reframes everything.

---

## Scene 7: THE NUMBERS (2:30 - 2:45)

**Visual:** Two-column stats layout, numbers counting up.

| Built | Count |
|-------|-------|
| Launcher scripts | 64 |
| Workflow scripts | 186 |
| Apps covered | 16 |
| Apps with extracted dictionaries | 31 |
| Commands indexed | 347 |
| Classes documented | 408 |
| Spotlight-searchable apps | 186 |
| Siri Shortcuts generated | 186 |
| Total files pushed to GitHub | 250+ |

**Narration:**
"22 prompts. 75 minutes. 167 files. One conversation."

**Psychology:** *Anchoring* — the big numbers (347 commands, 408 classes) anchor the perceived scale. *Contrast Effect* — 75 minutes vs 167 files makes the efficiency feel dramatic.

---

## Scene 8: THE ERRORS (2:45 - 3:05)

**Visual:** Terminal showing the bash heredoc bug — files named `activate-.applescript`. Then the fix.

**Narration:**
"It wasn't perfect. Bash heredocs ate my variables — every script was named `activate-dash-dot-applescript`. Finder wasn't where I expected it — turns out it lives in CoreServices, not Applications. Safari's help flag just... launches Safari."

**Visual:** Quick cuts of each error and fix.

**Narration:**
"Every bug taught me something about macOS that no documentation covers. The errors were features."

**Psychology:** *Pratfall Effect* — showing mistakes makes the project more credible and relatable. Perfection is suspicious; honest struggle is trustworthy.

---

## Scene 9: THE RESULT (3:05 - 3:25)

**Visual:** GitHub repo page. Star count. File tree. README with badges.

**Narration:**
"The whole thing is open source. Clone it, run any script with osascript, wire it to your Loupedeck or Stream Deck or any automation tool."

**Show command:**
```bash
git clone https://github.com/esaruoho/apple.git
osascript scripts/activate-finder.applescript
```

**Narration:**
"The scripting dictionaries are there too. Every Apple app's full API, extracted as YAML and Markdown. Copy the examples. Chain the data types. Build workflows Sal would be proud of."

**Psychology:** *Activation Energy* — two commands to start. Minimal friction. *Reciprocity* — it's free and open source; viewers feel compelled to engage.

---

## Scene 10: THE CLOSE (3:25 - 3:40)

**Visual:** Back to the Loupedeck Live. A hand pressing a button. An app appears instantly.

**Narration:**
"Sal spent 19 years making sure the power of the computer stays in your hands. This repo is 167 files that prove the idea still works."

**Text overlay (final frame):**

> One button. One action. Zero wasted time.

`github.com/esaruoho/apple`

**Psychology:** *Peak-End Rule* — the ending echoes the opening (button press), creating a satisfying loop. The Sal callback adds emotional weight. The tagline is the last thing they see.

---

## Copy-Editing Notes (Seven Sweeps Applied)

### Sweep 1 — Clarity
- Every sentence has one job. No compound explanations.
- Technical terms (sdef, scripting dictionary) are explained inline on first use.
- "Data type chaining" is shown visually, not just described.

### Sweep 2 — Voice & Tone
- Consistent throughout: conversational, confident, zero corporate speak.
- Technical credibility without jargon walls.
- Matches the README tone ("No hunting through the Dock. No Cmd-Tab cycling. No friction.").

### Sweep 3 — So What
- Every technical claim connects to a benefit:
  - 31 dictionaries → "all indexed, all queryable"
  - System Events → "controls ANY app's UI"
  - 64 launchers → "64 buttons, zero friction"

### Sweep 4 — Prove It
- Real prompts shown on screen (proof of process)
- Real errors shown (proof of authenticity)
- Real numbers (167 files, 347 commands — verifiable on GitHub)
- Sal Soghoian's credentials and patent number (verifiable)

### Sweep 5 — Specificity
- "75 minutes" not "about an hour"
- "347 commands, 408 classes" not "hundreds of commands"
- "22 prompts" not "a conversation"
- "3 lines of AppleScript" not "a short script"

### Sweep 6 — Heightened Emotion
- Scene 2: frustration of missing apps (pain)
- Scene 4: Sal's quote (inspiration)
- Scene 6: "what Sal knew all along" (revelation)
- Scene 8: "the errors were features" (reframing)
- Scene 10: "the idea still works" (validation)

### Sweep 7 — Zero Risk
- Open source (free)
- Two commands to start (easy)
- Clone and run (no dependencies, no build step)
- "Copy the examples" (no expertise needed to begin)

---

## Production Notes

- **Screen recordings needed:** Claude Code terminal session, Loupedeck software, Finder/apps activating, GitHub repo page, `sdef-extract.py` running
- **Assets:** Loupedeck Live close-up, Sal Soghoian photo (check licensing), patent PDF page
- **Music:** Minimal, ambient electronic. Build subtly through scenes 5-6, peak at scene 9.
- **Text rendering:** Monospace for code/prompts, clean sans-serif for overlays
- **Timing:** Each scene has a natural cut point. Can be shortened by cutting scenes 4 or 8 for a 2-minute version.
