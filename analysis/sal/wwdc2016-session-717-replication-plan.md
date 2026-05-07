---
title: WWDC 2016 Session 717 — Replication Plan
date: 2026-05-07
goal: Reproduce every capability Sal demonstrated in session 717 on current macOS, fully working, fully documented, and integrated into the apple skill repo.
status: PLANNING — concrete phases, owner steps, blockers, fallbacks
inputs:
  - sources/sal/wwdc2016-session-717/717-transcript.txt (the recovered talk, 524 lines)
  - sources/sal/macosxautomation.com/dictationcommands/CitrusPeel255.zip (the engine — 17 .scptd libraries)
  - sources/sal/macosxautomation.com/dictationcommands/ (full HTML mirror, 33 supporting MP4s)
  - analysis/sal/wwdc2016-session-717-transcript-analysis.md
  - analysis/sal/wwdc2016-session-717-deep-analysis.md
---

# What "replicate ALL OF IT" means

In Sal's June 2016 demo, the user could speak any of these into a Mac with no internet, and the Mac executed the task end-to-end:

| # | Spoken | What happens |
|---|--------|--------------|
| 1 | "Switch to photos" | Photos.app foregrounded |
| 2 | "Select all photos" | Cmd-A in Photos |
| 3 | "Help me to add titles" | Modal walkthrough: prompts user image-by-image, dictation fills the title field |
| 4 | "Make a new presentation with these" | Selected photos exported, Keynote opens with one photo per slide |
| 5 | "Change master slide to title center" | Keynote master-slide template applied |
| 6 | "Edit slide title" / type / "Stop edit" | Title field activated, text spoken in, deactivated |
| 7 | "Move this slide to the end" | Slide reordered |
| 8 | "Edit this in photos" | Round-trip: image opened in Photos editor with edit-context preserved |
| 9 | "Show this in Keynote" | Round-trip back |
| 10 | "Update this image" | Edited image replaces the slide image |
| 11 | "Show this in Maps" | Image's geo-EXIF location opened in Maps |
| 12 | "Export this map to Keynote" | Maps screenshot inserted as new slide |
| 13 | "Apply a magic move" / "Apply a dissolve" | Keynote transitions applied |
| 14 | "Scale this to fit slide width" | Image resized to slide width |
| 15 | "Make a long panoramic sequence" | Multi-image panorama auto-laid-out |
| 16 | "Put descriptions on top of every image" | Each image's description overlaid as text |
| 17 | "Search Spotlight for ${query}" | Spotlight query executed |
| 18 | "Open result" | Top result opened |
| 19 | "Select the table" | Numbers table selected |
| 20 | "Export this table to Keynote as a chart" | Numbers → Keynote chart insert |
| 21 | "Save this presentation to my thumb drive and eject it" | Save + cp + diskutil eject |
| 22 | "Add a blank slide" / "Turn this into a QR code" | New slide + QR code generated from URL |
| 23 | "Scale down 10%" | Selection scaled by 10% |
| 24 | "Scratch that" | Undo last command |
| 25 | "Done" | End assistive session |

**Plus everything in `commandslist.html` we haven't enumerated** — 40 categories total. ~250 distinct phrasings. ~17 scriptable bundles backing them.

# Why this is hard in 2026 (the 10-year drift)

Five things have changed since June 2016:

1. **Dictation Commands UI has been deprecated and folded into Voice Control.** The "secret plus button" Sal demonstrated (line 196) lives in macOS Sequoia at `System Settings → Accessibility → Voice Control → Commands…` instead of `System Preferences → Accessibility → Dictation`. The action selector is similar but renamed.
2. **AppleScriptObjC / `.scptd` Script Libraries still work** but Apple has hardened TCC consent flows; the "Enable Assistive Access for Dictation Commands.app" step Sal shipped in CitrusPeel will need a manual System Settings → Privacy & Security → Accessibility consent today.
3. **iWork apps have evolved.** Keynote/Pages/Numbers scripting dictionaries have changed. Most surface still works (the verbs are remarkably stable) but specifics like master-slide names and chart-export verbs need a re-probe via `bin/app-probe.py`.
4. **Photos.app's AppleScript surface contracted.** Some Sal-era verbs are gone (e.g., direct image-edit context handoff) — Shortcuts is now the primary path for Photos automation.
5. **macOS Sequoia gatekeeper signing.** CitrusPeel's installer applets are signed for a 2016 macOS; some helper apps (PictureTaker, Photos Description Helper) may refuse to launch without resigning. Ad-hoc resign is the fix (we already use `codesign --force --sign -` elsewhere in this repo).

None of these is a hard blocker. They are version-skew issues with known fixes.

# The plan — five phases

## Phase 1 — Make CitrusPeel run on current macOS (the engine test)

**Goal:** prove the 2016 engine still works on today's Mac.

**Steps:**

1. Extract `CitrusPeel255.zip` to `scripts/sal/dictation-commands/citruspeel-extracted/` (gitignore the extracted dir, keep the zip)
2. Inspect each of the 17 `.scptd` libraries with `osadecompile` and document each library's exported handlers in `scripts/sal/dictation-commands/library-index.md`
3. Run `1) Install Automation Tools.app` on a sandbox Mac account (NOT the main user). It installs:
   - The 17 `.scptd` libraries to `~/Library/Script Libraries/`
   - The 5 helper apps to `~/Library/Application Support/Dictation Commands/`
   - The Automator workflow definitions for ~250 user commands
4. Run `4) Enable Assistive Access for Dictation Commands.app` — this is where TCC consent will need manual approval in 2026 macOS
5. Test the **simplest demo command** first: "Take my picture" (Sal's worked example, transcript line 247). Does it run end-to-end? Yes → engine works. No → proceed to Phase 2 with documented failure modes.

**Deliverable:** `analysis/sal/citruspeel-2026-test-report.md` — what works, what's broken, what needs porting.

**Time estimate:** half a session.

## Phase 2 — Port broken commands to current macOS

**Goal:** for every command that Phase 1 found broken, write a 2026-compatible replacement.

**Strategy:** each Sal command lives in a `.scptd` library handler. Replace the broken handler with one of:

- An **AppleScript rewrite** using current scripting dictionaries (cheapest, works for ~70% of commands per app-probe data)
- A **Shortcuts call-out** (`shortcuts run "..."`) — necessary for Photos commands where AppleScript surface contracted
- A **shell + osascript hybrid** for system-level operations like the thumb-drive eject

**Reference inputs:**

- `dictionaries/keynote.sdef`, `dictionaries/pages.sdef`, `dictionaries/numbers.sdef`, `dictionaries/photos.sdef` for current verbs
- `bin/app-probe.py` 13-layer probe results for which commands have current surface
- The recovered transcript lines 277–475 as the test suite — re-run Sal's exact demo flow

**Deliverable:** `scripts/sal/dictation-commands/libraries-2026/` with ported `.scptd` files, each cross-referenced to its CitrusPeel original.

**Time estimate:** 2-3 sessions, depending on how many handlers Phase 1 finds broken.

## Phase 3 — Build the user-command UI (the secret plus button equivalent)

**Goal:** make creating a new voice command as easy in 2026 as Sal's "secret plus button" was in 2016.

**Two paths, build both:**

### Path A — Voice Control native (Apple's officially supported route)

Each ported command becomes a Voice Control custom command (`System Settings → Accessibility → Voice Control → Commands → +`). Action: "Run Workflow" pointing at one of our `.scpt` files. Phrase = exactly what Sal had.

**Build a generator:** `bin/dictation-commands-gen.py` that:
- reads `commandslist.html` (or our re-shaped YAML version)
- emits a Voice Control plist patch for each command
- patches `~/Library/Preferences/com.apple.speech.recognition.AppleSpeechRecognition.CustomCommands.plist`

This bypasses the manual UI step Sal shipped in CitrusPeel — you import 250 commands at once.

### Path B — Shortcuts + Siri phrases (the modern equivalent)

Every dictation command becomes a Shortcut with a Siri phrase. We already have `bin/shortcut-gen.py` for this. Extend it to:
- read the same command catalog as Path A
- emit a `.shortcut` file per command
- batch-import via existing `bin/batch-import.sh`

Path B integrates with the existing 288-workflow Shortcuts pipeline. Path A is closer to the original session 717 spirit.

**Deliverable:** both `bin/dictation-commands-gen.py` (Path A) and an extended `bin/shortcut-gen.py` (Path B). User picks which they want.

**Time estimate:** 1-2 sessions.

## Phase 4 — Loupedeck integration (the Esa-specific multiplication)

**Goal:** map every dictation command to an optional Loupedeck button as well.

Esa's workflow uses Loupedeck Live for hardware triggers. The dictation-commands library is naturally a button library too: each named task becomes a button label, each `.scpt` becomes the action.

**Build:** `bin/loupedeck-import-dictation-commands.py` — emits a Loupedeck profile JSON with all commands grouped by category (the same 40 categories from `commandslist.html`).

This realizes the Sal/Esa multiplication: **the same task primitive, three trigger surfaces — voice, Spotlight, Loupedeck button.** That's WWSD principle #28 (procedural-vs-task) cashed in.

**Deliverable:** `~/Library/Application Support/Loupedeck/profiles/dictation-commands.lpprofile`

**Time estimate:** 1 session.

## Phase 5 — The seven-purpose audit (codify Sal's framework into the skill)

**Goal:** apply WWSD #30 (the seven-purpose framework) to the existing apple-skill workflow catalog.

The apple skill currently has **288 workflows** generated by `bin/workflow-gen.py`. Score each one against Sal's 7-criterion framework:

1. Need to remain in context
2. Multi-step (≥3)
3. Requires dexterity
4. Moves data between apps
5. Transforms data type
6. Does something not in the app's UI
7. User-wants-but-doesn't-know-how

Workflows scoring 3+ earn a Siri phrase + Loupedeck button + dictation command (all three triggers).
Workflows scoring 1-2 stay as scripts only.
Workflows scoring 0 get re-evaluated for whether they should exist at all.

**Build:** `bin/sal-7-purpose-audit.py` — reads the workflow catalog, prompts user to score each (or auto-scores from heuristics like "uses ≥2 tell blocks for different apps" → criterion 4), emits a triage report.

**Deliverable:** `analysis/sal/seven-purpose-audit.md` — the apple-skill workflow catalog re-shaped around Sal's framework.

**Time estimate:** 1 session.

# Sequencing & blockers

```
Phase 1 (engine test)  ──┐
                          │
Phase 2 (port broken) ←───┘   ← blocked by Phase 1 failure modes
        │
        ↓
Phase 3 (user-command UI) ←   ← blocked by Phase 2 — need ported handlers
        │
        ↓
Phase 4 (Loupedeck)   ←──     ← blocked by Phase 3 — needs final command catalog
        │
        ↓
Phase 5 (7-purpose audit) ←   ← can run in parallel with Phase 3 or 4
```

**Realistic timeline:** 5–8 sessions to fully replicate. Phase 1 alone gives a publishable result ("Sal's 2016 voice automation engine still runs in 2026"). Phase 5 alone is publishable as a method paper.

# What we hand back to the world after this is done

1. **A working installer for current macOS** that gives any Mac the dictation-command capabilities Sal showed at WWDC 2016
2. **A documented port** of every CitrusPeel `.scptd` library, version-controlled, ad-hoc-signed, TCC-friendly
3. **An auto-generator** that bootstraps Voice Control / Shortcuts / Loupedeck profiles from a single command catalog
4. **A method paper** showing how Sal's seven-purpose framework reshapes a workflow library
5. **A standing demonstration** — every Mac running this stack is a live answer to "what could the Mac have been if Apple had kept Sal's role"

This is not preservation. This is **resurrection**.

# What I need to start

User decision: do we begin Phase 1 immediately (extract CitrusPeel, run the engine test), or do you want to read the three analysis documents first and call the next move yourself?

Either is fine. Phase 1 is mechanical and I can run it in the next turn — extract zip, decompile libraries, document each one. The failure modes I find determine Phase 2 scope.

If you want a single-line answer to "where do we start": **`unzip CitrusPeel255.zip`, `osadecompile` every `.scpt` and `.scptd/Contents/Resources/Scripts/main.scpt`, write `library-index.md`, and run `Install Automation Tools.app` in a sandbox account.**
