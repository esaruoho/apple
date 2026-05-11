# Sal's cross-decade automation lineages

> Patterns Sal demoed at WWDC that are still alive — sometimes under different names — in macOS Sequoia 2026 and in this repo. Each lineage is traced from its primary-source WWDC introduction to its current incarnation, with the architectural pattern that survived the rename intact.

## Why this document exists

Reading the 17 archived WWDC sessions chronologically (2003-2015), the same architectural patterns recur — sometimes as direct continuations, sometimes as rebrandings, sometimes as user-community resurrections after Apple dropped the surface. This document is the **connection map**.

Each lineage is named by the architectural pattern, not by any single product. The point is to recognize that when you ship a feature in 2026 (a voice trigger, a config-via-filesystem pattern, a workflow exporter), you are extending Sal's primary-source lineage — and the right reference material is sometimes 23 years old.

---

## Lineage 1 — Voice trigger as offline-local primitive

| Year | Surface | Source |
|------|---------|--------|
| 2011 | `listen for` AppleScript command | WWDC 2011 #133 |
| 2013 | Speakable Workflows (filename = trigger phrase) | WWDC 2013 #417 |
| 2024 | Vocal Shortcuts (Apple Silicon, on-device matcher) | macOS Sequoia |
| 2026 | Hey Sal v1 + matcher | `applets/hey-sal.scpt` + memory `vocal_shortcuts_trigger_position.md` |

**The architectural pattern:** voice-as-trigger should be **offline, local, latency-free, deterministic**. Apple has shipped at least three named products in this lineage; each one solved the same problem from a different angle.

**The 13-year continuity:** Sal demoed `listen for` in 2011 specifically because he did not want a cloud round-trip. In 2024, Vocal Shortcuts reclaims the exact same position in the trigger-surface matrix (the only surface that is simultaneously hands-free, offline, latency-free, AND UUID-stable across Shortcut renames).

**For the repo:** any future voice-trigger work should look at `listen for` first — it may still work on Sequoia, in which case it's a second offline-local voice surface beside Vocal Shortcuts.

---

## Lineage 2 — The "framework bridge" from a scripting language

| Year | Surface | Source |
|------|---------|--------|
| 2003 | `call method` from AppleScript Studio | WWDC 2003 #718 (Movie Player project) |
| 2007 | Scripting Bridge (sdp-generated headers for ObjC/Ruby/Python) | WWDC 2007 #224 |
| 2009 | AppleScript-ObjC (ASOC) | WWDC 2009 #607 |
| 2011 | Cocoa AppleScript Applets — ASOC on desktop without Xcode | WWDC 2011 #133 |
| 2014 | JXA `$` ObjC bridge with `ObjC.registerSubclass` | WWDC 2014 #306 |
| 2026 | `osascript -l JavaScript` + `$.NSClassName` still works in Sequoia | shell |

**The architectural pattern:** when a scripting language's verb set is incomplete, **bridge to the native framework runtime** rather than wait for sdef coverage to catch up. Sal articulated this in 2003 (*"all the commands that you wanted but you couldn't get to, you can now make yourself"*) and the pattern got steadily more ergonomic across eleven years.

**The 11-year payoff:** 2003's `call method` required AppleScript Studio + Xcode + a frameworks folder. 2014's JXA `$` bridge requires only a JavaScript file run via `osascript -l JavaScript`. Same architectural delta — invoke native APIs from a script — collapsed to one syntactic character.

**For the repo:** when an Apple sdef is missing a verb you need, the bridge is usually two lines via `$.NSWhatever.alloc.init` in JXA, or `current application's NSWhatever's alloc()` in ASOC. Don't wait for Apple to ship the verb.

---

## Lineage 3 — Config-via-filesystem (the user-placed-file pattern)

| Year | Surface | Source |
|------|---------|--------|
| 2003 | Droplet preferences in Finder comment field | WWDC 2003 #718 (WWSD #38) |
| 2003 | PDF Workflow: drop scripts in `~/Library/PDF Services/` | WWDC 2003 #401 |
| 2007 | Workflows-as-Services in `~/Library/Services/` | WWDC 2007 #224 |
| 2012 | `NSUserScriptTask` + `~/Library/Application Scripts/<bundle-id>/` | WWDC 2012 #206 (WWSD #39) |
| 2013 | AppleScript Libraries in `~/Library/Script Libraries/` | WWDC 2013 #416 |
| 2014 | JXA libraries via `Library('toolbox')` reading `~/Library/Script Libraries/` | WWDC 2014 #306 |

**The architectural pattern:** the filesystem is the UI. User-placed files convey user intent — for configuration, for consent, for capability extension. Sal applies the same shape across a decade with different magic folders for different purposes.

**The two faces:** 2003-2007 era is **user-empowerment** (drop a script, gain a verb). 2012 era is **user-consent** (drop a script, grant a capability across a security boundary). Same filesystem mechanism, different policy meaning. The 2012 #206 NSUserScriptTask innovation is recognizing that the same user-place-the-file gesture from 2003 can serve as the consent surface under sandboxing.

**For the repo:** any new automation surface should ask "what magic folder should host this?" before asking "what UI should host this?" Sal's pattern is that the filesystem itself is the discovery + consent + configuration UI.

---

## Lineage 4 — Workflow as a host-app-embedded engine

| Year | Surface | Source |
|------|---------|--------|
| 2007 | `AMWorkflow` / `AMWorkflowController` / `AMWorkflowView` introduced | WWDC 2007 #224 |
| 2008 | Savant Systems commercial validation: home automation runs on AMWorkflow | WWDC 2008 #547 |
| 2014 | App Extensions framework | WWDC 2014 keynote |
| 2020 | App Intents framework | iOS 14 / macOS 11 |
| 2026 | Shortcuts.app on macOS continues the pattern with `intentbuilder`-style integration | Sequoia |

**The architectural pattern:** an **app should be able to host the automation engine in-process**, ship pre-baked workflows as user-selectable presets, optionally let the user edit them via an embedded editor. The workflow becomes the smallest plug-in unit.

**The 13-year arc:** Sal demoed `AMWorkflow` in 2007 as "the hidden feature of this release." Apple eventually rebranded the same pattern as App Extensions (2014), then App Intents (2020). The Automator app got de-emphasized in favor of Shortcuts. **The architecture survived; only the branding changed.**

**For the repo:** an app shipping pre-baked workflows should look at whether `AMWorkflow` is still callable from JXA in 2026 — it likely is, and it would let bin tools accept user-supplied .workflow files as configuration.

---

## Lineage 5 — Content pipeline upstream of sealed device

| Year | Surface | Source |
|------|---------|--------|
| 2010 | HTML5 Web-App folders + EPUB workflows for iPad | WWDC 2010 #302 |
| 2014 | Books / Markdown content pipelines | Sal post-Apple |
| 2019 | Tools Conference content-automation focus | MTC 2019 |
| 2023 | CCATP #559 framework | Daniel Jalkut interview |
| 2026 | apple-grand-export Markdown/HTML pipelines | `bin/apple-grand-export` |

**The architectural pattern:** when the consumer device is sealed (iPad, AppleTV, Vision Pro), **the automation lives upstream on the Mac that produces the content**. The pipeline is what gets automated, not the device.

**The 16-year continuity:** Sal articulated the content-pipeline doctrine in 2010 weeks after iPad shipped. He kept refining it across 2014, 2019, 2023 — all in different contexts, all reaching the same conclusion: the Mac is the content factory; sealed devices are consumption surfaces.

**For the repo:** the existing bulk-exporter family (notes/imessage/safari/voice-memos/etc.) is **directly in this lineage**. Sal would recognize the pattern instantly. The Mac is producing content that downstream tools (Obsidian, iPad reading apps, BBSes, web shares) consume.

---

## Lineage 6 — Filename-as-trigger-phrase (route by intent, not by handler name)

| Year | Surface | Source |
|------|---------|--------|
| 2013 | Speakable Workflows: workflow filename = speech trigger | WWDC 2013 #417 |
| 2024 | Vocal Shortcuts: phrase string maps to Shortcut UUID | Sequoia |
| 2026 | Hey Sal v1: single Vocal trigger → matcher → ~32 Shortcut UUIDs | `applets/hey-sal.scpt` |

**The architectural pattern:** the user types/speaks **what they want done**, not **how to do it**. The system routes the intent string to the right handler. The handler can be renamed without breaking the binding (UUID-stable).

**The 13-year arc:** Sal demoed this in 2013 as "save workflow with the phrase you want to say as the filename." 13 years later, Vocal Shortcuts uses the same architectural shape but with explicit phrase-to-UUID binding instead of filename-as-phrase. Hey Sal v1 then collapses 32 Vocal Shortcuts into 1 by adding a matcher layer.

**For the repo:** any voice/typed/scripted trigger surface should follow this pattern — the user expresses intent, the system routes. Hey Sal's matcher pattern is portable to typed input, Spotlight, anywhere a free-text-to-action mapping needs to be UUID-stable.

---

## Lineage 7 — Auto-conversation hosts (the iChat responder template)

| Year | Surface | Source |
|------|---------|--------|
| 2011 | iChat responder New-From-Template script — auto-respond based on incoming-message conditions | WWDC 2011 #133 |
| 2012 | Messages.app handlers — same pattern, new app | WWDC 2012 #206 |
| 2026 | pakettibot cloudcity agent — Claude Code running headless via Discord+IRC bridge | `~/work/pakettibot-agent/src/agents/cloudcity.js` |

**The architectural pattern:** an automation **listens for incoming messages on a chat surface and replies autonomously based on programmable conditions**. The host app provides the message-routing; the user's script provides the response logic.

**The 15-year arc:** Sal demoed iChat responders in 2011 (with the famous *"the computers were talking to each other and there was no humans involved"* aside). Sequoia 2026's pakettibot is the production-scale version — Claude Code runs on CloudcityMacMini, receives messages from Discord and IRC bridges, executes whatever the human types as if running in a terminal. **Same architectural pattern, scaled to AI-as-responder.**

**For the repo:** the iChat responder template (`~/Library/Application Support/Script Editor/Templates/`) — if it still ships in Sequoia — is the canonical reference for the response-loop pattern. Worth a probe.

---

## Lineage 8 — Configurator as drag-drop fleet operator

| Year | Surface | Source |
|------|---------|--------|
| 2009 | Hayman's ARD-Services demo (right-click → run shell on N machines) | WWDC 2009 #607 |
| 2015 | Apple Configurator 2 with Automator action support | WWDC 2015 #306 |
| 2026 | Apple Configurator still ships; Automator actions retained | macOS Sequoia |

**The architectural pattern:** fleet management should be drag-and-drop. The IT person assembling a workflow ("install app → restore from backup → assign to MDM group → email receipt") is doing the same thing the user is doing in Automator — composing pre-built actions, just with fleet semantics.

**The 17-year continuity:** Hayman demoed it in 2009 as a Services pattern (one Service runs across all selected machines). Sal's 2015 talk shows the same pattern formalized in Apple Configurator 2 with Automator-style actions specifically for iOS provisioning. **Same pattern, 6 years apart, formalized into a shipping enterprise product.**

**For the repo:** Apple Configurator 2 is still shipping on macOS Sequoia. The Automator-action surface inside it is the canonical "fleet ops as drag-and-drop" pattern in 2026.

---

## What this map is for

When designing any new automation in this repo, consult this map first. If the pattern you're about to invent already has a 10-25 year Sal lineage, you should:

1. **Read the primary source** — Sal explained the architectural reasons on a WWDC stage; those reasons are usually still valid
2. **Probe the current surface** — does the named API still work in Sequoia 2026? Often yes, just undocumented
3. **Inherit the architectural shape** — even if you have to rebuild the implementation, keep Sal's structural choices

The lineages above aren't trivia. They're load-bearing architecture, all sourced to specific WWDC sessions in `sources/sal/wwdc/`.

## Where each lineage is documented

- Per-session analyses under `sources/sal/wwdc/<session>/analysis.md`
- WWSD principles in `sal-soghoian.md` (Tier 3 + Tier 4 sections after this integration pass)
- WWSD source quotes in `analysis/sal/wwsd-updates-from-2003-transcripts.md` (Tier 3) + `analysis/sal/wwsd-updates-from-2007-2015-transcripts.md` (Tier 4)
- WWDC master index in `sources/sal/wwdc/README.md`
