# WWDC 2013 Session 417 — OS X Automation Update (Analysis)

**Speakers:** Sal Soghoian (framing, libraries, notifications, Speakable Workflows, AppleScript-20-anniversary toast) + Chris Nebel (code-signing demo, `use`-clause demo, sudo-via-notifications demo)
**Duration:** ~50 min · **Year:** 2013 (Mavericks / 10.9)
**Source:** Whisper-generated transcript from nonstrict.eu (machine-transcribed; expect proper-noun and homophone errors — "Trudy Anchover", "Pseudo" = `sudo`, "Pearl" = Perl, "Speakable Workflows.com" = speakableworkflows.com)

## The historical position

Session 417 is **the sister/overview talk to 2013 #416** (AppleScript Libraries deep-dive). It's the *state-of-automation address* for Mavericks — a tour-of-five-features rather than a single deep technical dive. It also opens with a sequel beat to 2012 #206's code-signing thread (the Gatekeeper-broke-my-droplet pain that Chris Nebel demoed a year earlier in Terminal is now a one-click Export menu item), and closes with an explicit **20th-anniversary toast to AppleScript** (released at WWDC 1993). The session sits exactly halfway between the 2003 AppleScript-Studio era and Sal's 2016 firing — peak-Sal, with the new JXA still a year out and the security regime now domesticated.

## Sal's framing — the casual state-of-the-union

> *"What's new in the world of automation? Well, without actually just bullet pointing the whole list, we're going to be talking about Automator and AppleScript. Especially we're going to introduce some new features. They're very powerful. Some of them are pretty dramatic. I think you're going to find that they become your favorite things to work with."*

No grand thesis at the open — Sal explicitly *refuses* the bullet-point list. The architecture is *here are five things, each gets a vignette and a demo*. Five things: iCloud-sync for scripts, code-signing built into the editor, AppleScript Libraries (+ `use` clause), Notification Center support, Speakable Workflows. Plus a closing 20-year toast.

## What Sal covers (the substance)

### 1. iCloud Documents for Script Editor + Automator

Scripts and workflows now have a Documents-in-the-Cloud window like Pages/Numbers/Keynote. Drag scripts into the iCloud viewer → they sync to all Macs. Tag-based search. AirDrop / iMessage sharing from the viewer.

> *"Being a script hoarder like me, I'm actually starting to like having one place that I can go to where I know I'll find what I'm looking for and copy it to the machine."*

**The "script hoarder" self-identification is load-bearing** — Sal positions cloud sync as *solving a problem he personally has*. The product-manager-as-his-own-power-user framing. (This is the same "I have hundreds of routines" persona that motivates the Libraries pitch later in the session.)

### 2. Code signing — Trudy from Bay Area Forest Scouts

Sal opens with a story: friend Trudy (Director, Bay Area Forest Scouts) saw him demo a photo droplet at a conference. He emails her the droplet. She drags it to her desktop, drops an image on it — *unidentified developer, blocked*. Sal's verdict: **"it's really my fault because I forgot a very important thing — Automator and AppleScript droplets and applets ARE applications."**

This is the same point Chris Nebel made architecturally in 2012 #206, now delivered as a one-year-later social parable. The remediation, however, is new:

- **In Mavericks: code-sign in the Script Editor `File → Export` sheet.** New pop-up at the bottom of the Save sheet: *Code Sign*. Lists every Developer ID in your keychain. Pick one, click Save. Done.
- **Same UI in Automator's Export sheet.** Same dropdown, same one-click flow.
- The 2012 Terminal recipe (`codesign --sign 'Developer ID Application: ...' --identifier <bundle-id>`) is now a menu item.

Chris's demo plays the "I sent my friend a broken applet" beat for the audience — Gatekeeper's first dialog says *"OK"* but **"OK doesn't mean OK go ahead and run it. It means OK we're done. There's nothing to do here."** Signed copy reverses this — the dialog becomes *Cancel / Open*.

This is **the productization of the 2012 #206 distribution scenario**. WWSD #38 (droplet-with-preferences) still requires `chmod a-w` on the script, but the signing step itself is now first-class UI.

### 3. AppleScript Libraries + the `use` clause (the headline)

Sal's motivating story: *"I assume that many of you are like me. You're the kind of person has hundreds and hundreds of your favorite routines that you've written over and over and over for lots of different situations and scenarios."* Pasting routines at the bottom of every script, then editing one of them, then losing track of which copy is canonical.

**AppleScript Libraries** — new plug-in architecture:
- Write in **AppleScript** (not C/C++ like the old OSAX scripting additions)
- **Loaded only when your script calls them** (no global terminology conflicts)
- **Run in the calling process** (no IPC weirdness)
- **Can use AppleScript-ObjC** → Cocoa frameworks from inside libraries
- **Can publish their own terminology** — custom sdef, custom verbs

Installation: drop the `.scpt` into `~/Library/Script Libraries/`. Reference: `script "MyLibrary"`. The compiler resolves the identifier automatically.

The `use` clause is the syntax-sugar layer on top:

```applescript
use scripting additions
use AppleMail : application "Mail"
use application "Contacts"
use textUtils : script "AppleScript Text Utilities"
```

Chris Nebel's "team mom for neighborhood soccer team" demo: he wrote a Mail forwarding script that mixes Mail + Contacts terminology. **Before `use`:** nested `tell application "Mail" / tell application "Contacts"` blocks, with a variable shuttling values across the boundary. **After `use`:** zero tell blocks. The compiler dispatches each verb to the right app based on terminology origin. *"AppleScript should be able to do that for you. Now it can."*

Chris's line: *"This is, like, my favorite AppleScript feature in a long time. It's one of those ones that makes you wonder why it didn't always work this way."*

**Sal lobs the deep-dive to the afternoon's #416 session**: *"for the first time anywhere in the world, we will show you how to write a scripting dictionary file or an sdef. It is sick, sick, sick. You can't miss it."*

### 4. Notification Center support

Sal frames it with a fake quote-from-a-blog: notifications are *"designed not to annoy you or get in the way. And they should never, ever leap, jump, or hop, and definitely not bounce."* The punchline: *"for many, many years, this is the way that scripts tried to notify you until now"* — i.e. `display dialog` (modal Aqua dialog with the bouncing-genie alert icon).

The Mavericks fix:
- **Automator:** new *Display Notification* action, supports workflow variables in title/subtitle/body, drop it anywhere (start, midpoints, end)
- **AppleScript:** new standard-additions verb `display notification "msg" with title "..." subtitle "..." sound name "..."`
- Applets/droplets show up in **System Preferences → Notifications** alongside real apps — banner vs alert vs none, sound on/off

Chris's bonus demo: a Perl one-liner that tails `syslog`, filters `sudo` invocations, builds a `display notification` AppleScript per line, and pipes it through `osascript`. **Real-time sudo monitoring as a desktop notification stream.** *"I want total awareness through notifications."* (Sal, immediately after.)

> *"Now you can be 100 percent bounce-free."*

### 5. Speakable Workflows (Mavericks accessibility integration)

Speakable Items (Apple's 1990s-vintage speech-recognition layer in the Accessibility framework) gains a new file type: **Speakable Workflow**. Automator's Save dialog gets a new format pick when Speakable Items is enabled in Accessibility prefs. The file lands in `~/Library/Speech/Speakable Items/` automatically — **the filename IS the trigger phrase.**

Sal's demo: workflow named *Eject Digital Briefcase.workflow* → Find Finder Items (volume name = "Digital Briefcase") → Eject Disk → Speak text "Done!" → saves as Speakable Workflow. Then live, on-stage: hold Escape, "Eject Digital Briefcase" — the USB drive ejects, the Mac speaks "Done!" back.

**This is the architectural ancestor of every vocal-trigger workflow Sal builds over the next decade**, all the way to the 2024 Vocal Shortcuts era. Filename = phrase. Workflow = action. No central registry, no app-bundle entitlements — the filesystem is the trigger registry. Same logic as 2012 #206's `~/Library/Application Scripts/<bundle-id>/` (user-placed-file = consent), but extended to the *voice* surface: **user-placed-file = vocal command**.

The promised `speakableworkflows.com` companion site ("hundreds of examples", "feedback mechanism") is the recurring Sal-companion-site pattern (`iworkautomation.com`, `photosautomation.com`, `configautomation.com`, `macosxautomation.com`) — Sal's personal documentation/sample-library shadow infrastructure beside Apple's official docs.

### 6. The 20th-anniversary toast

> *"This is a special day for us because, 20 years ago at WWDC, AppleScript was released to the world."*

Released WWDC 1993 → 2013 = 20 years. Sal closes with four explicit thank-yous: *developers who made their apps scriptable / scripters who wrote and shared scripts / customers who use and rely on AppleScript / engineers at Apple who implemented it.* This is **Sal-as-community-steward**, the closing-the-loop pattern he uses whenever a milestone permits.

## WWSD-relevant takeaways

- **Four whys re-stated in passing** across the 2013-2015 arc — confirms 2013→2015 vision-stability (WWSD #34).
- **The product-manager-as-his-own-power-user persona** — Sal sells iCloud sync, Libraries, and the script menu by describing his own pain ("script hoarder", "hundreds and hundreds of routines", "I would just copy this thing from a clipping"). The PM eats his own automation. This is the dogfooding stance — belongs in the WWSD catalog as an *operational* principle: **build for the user you actually are**.
- **Trudy story is a Sal teaching device** — when a real user fails, Sal accepts the blame and rebuilds the path. "It's really my fault because I forgot…" — not a deflection to "users should know about Gatekeeper", but a self-correction to "the tool should make this trivial". WWSD-grade ownership.
- **Filename-as-trigger** (Speakable Workflows) — same data structure as 2012 `~/Library/Application Scripts/<bundle-id>/`. The filesystem is the registry. **Candidate WWSD principle: filename IS the API.** Extends WWSD #39 (user-placed-file = consent) into the voice surface.
- **20-year toast = vision stability across a generation.** AppleScript 1993→2013 still has the same architecture, same `tell application` model, same dictionary metaphor. Sal's "the language is constantly growing, expanding" is the inverse framing of "stable enough to bet a career on". WWSD #34 (vision-stability) is operationalized in this session by *celebrating it explicitly*.
- **`use` clause = the dictionary-router pattern.** The compiler picks which app gets which verb. This is the seed of every later "ambient routing" idea — Hey Sal's matcher / `bin/sal-grand-search` / `apple-bootstrap` all dispatch verbs to apps by name, not by `tell` blocks.

## Reusable for the apple repo

- **`bin/sal-export-signed.sh`** — productize the Mavericks `File → Export → Code Sign` flow as a CLI: take a `.scpt`/`.app`, run `chmod a-w` on the embedded script, `codesign --sign 'Developer ID Application: …' --identifier <bundle-id>`. Already partially in the Spotlight TCC tooling — generalize.
- **Notification-driven workflow status** — every long-running exporter in `notes-exporter/`, `imessage-exporter/`, `voice-memos-exporter/`, etc. should emit `display notification` at start + midpoints + end. The Perl-syslog-to-notification recipe is directly portable to `whisp-worker` queue status (notify when transcription finishes).
- **Filename-as-trigger** is exactly the architecture of `~/Library/Application Scripts/com.apple.Shortcuts/` for Vocal Shortcuts in 2024. The 2013 Speakable Workflow ancestry should be documented in `analysis/sal/transcription-pipeline.md` as the historical anchor — Vocal Shortcuts is Speakable Workflows reborn.
- **AppleScript Library as a packaging target** — `bin/applescript-libraries-export.py` could bundle every reusable handler in `scripts/` into versioned `.scpt` files under `~/Library/Script Libraries/com.esaruoho.apple/`, each with its own sdef advertising terminology like `transform text`, `eject volume named`, `say done`. Replaces the current copy-paste-into-each-script pattern that Sal himself diagnosed in 2013.
- **`speakableworkflows.com` recovery** — almost certainly Wayback-archived; worth a discovery pass via `bin/sal-discover-interviews.py`. Sal's promised sample library belongs in the Sal archive.
- **20-year toast as documentation pattern** — when the apple repo hits any anniversary, follow Sal's four-thank-yous template in the README. Recognize the layered community: tool builders, scripters, daily users, framework engineers.

## Verbatim Sal-voice signatures

- *"I'm being people-oriented here."*
- *"Yeah. It's going to take me a while to wrap my head around all the different places I can use the use clause."*
- *"It is sick, sick, sick. You can't miss it."*
- *"I want total awareness through notifications."*
- *"Now you can be 100 percent bounce-free."*
- *"It's really my fault because I forgot a very important thing."*
- *"This is a special day for us because, 20 years ago at WWDC, AppleScript was released to the world."*
