# WWDC 2003 Session 401 — AppleScript Update (Analysis)

**Speakers:** Sal Soghoian (opening), Todd Fernandez (new AppleScript Engineering Manager, main), Tim Bumgarner (demos), Chris Nebel (Cocoa/Carbon Scripting close)
**Duration:** 58:53
**Track:** Application Frameworks

## Sal's opening — the **founding vision quote**

The most WWSD-significant minute in the entire 2003 archive:

> *"I first fell in love with AppleScript back in 1992 when I got the developer CD, and I saw that there was the ability for a normal schmo to be able to make the computer do what I wanted it to do. And the vision I had then was to be able to create automation and workflows where I could take information from one program, manipulate it, move it to another program, take that and move it to another program and build something. And in the decade following, that vision has not dimmed at all."*

Then the QuarkXPress 6 + iTunes + allmusic.com discography demo — Sal builds a personal data sheet by:
1. Picking iTunes tracks
2. Running a Build Discography script from Quark's script menu
3. Script reads iTunes selection → scrapes allmusic.com for artist bio + photo → creates Quark pages → re-queries iTunes for owned tracks → lists them under the photos

Sal's payoff line: *"This has always been the vision of AppleScript and this will continue to be the vision of AppleScript, whether it's a big multipurpose workflow for a big company or something small and simple like this."*

## Todd Fernandez's main content

**Version history through Panther.** AppleScript 1.6 (10.0) → 1.7 (10.1) → 1.8 (Dec 2001 dev tools) → 1.8.3 (software update for OS 9 and X) → 1.9 (Jaguar) → 1.9.1 (10.2.3) → ScriptEditor 2 + System Events betas (Dec 2002) → **1.9.2 ships in Panther**. AppleScript 10 was the planned major rev — *did not ship*.

**Four work areas for Panther:** new bundle formats, scriptability enhancements, breaking changes, AppleScript Studio.

### New bundle formats
- `.scptd` for compiled scripts, `.app` bundles for applets/droplets
- Standard Mac OS X packaging, no resource forks, file-system portable
- Allows persistent script attributes (description, window bounds)
- New OSA APIs: `OSALoadFile` / `OSAStoreFile` + convenience methods
- **Caveat**: requires Panther. Old formats remain supported for back-compat.
- `path to me` in a bundled applet returns a path ending in `:` — old scripts that strip the last element break unless they also strip the trailing colon.

### Scriptability enhancements (the long list)

**Script Editor 2** (Cocoa replacement, ships beta on Panther DP + back-ported beta for 10.2):
- Drag/drop, find/replace, undo, scripts > 32 KB
- Adopts Xcode UI elements (nav bar, code completion called "Code Assistant", library window)
- `make new document` / `set contents of front document` / `execute front document` — Script Editor scripting itself
- Library window — global pinned scriptable apps. Double-click to open dictionary, "Make New Script" auto-writes `tell application` block.
- Contextual menus inside the editor: select a list, choose "process every item" → editor writes the repeat loop for you
- Result history + event log history; double-click a past result to recover the script that produced it (even after closing without saving)
- Consolidated single-window event log + result (was two windows)

**Folder Actions** — contextual menu back in Finder. **Folder Action Setup app** is new: enable/disable/attach/remove/edit globally, see all attached folder actions on the system. Per-script enable/disable now possible (couldn't before).

**Script Menu** — system-wide menu bar item, install by double-clicking ScriptMenu in `/Applications/AppleScript/`. New features:
- Hide library/example scripts to show only your user scripts
- Aliases supported (including to remote machines)
- Hold Option on a script → opens in Script Editor for editing
- Select a folder → opens in Finder
- **Per-app scripts** — drop a folder named after the app's bundle inside `~/Library/Scripts/Applications/`, those scripts show up when that app is frontmost (Sal repeatedly notes how important this is)

**Standard Additions runtime enhancements:**
- `choose color` returns a list of RGB values
- New `path to` enumerations (movies folder, music folder, many more) for portable scripts
- Applets now handle Apple Events FIFO → can write **AppleScript CGIs**
- Unicode constants easier to use
- Date class: `short date string` (international panel controls format), months coerce to numbers, months comparable

**System Events** — application classes merged into one suite. New `disk item` class that file and folder inherit from. `path to` enumerations added here too so it doesn't matter whether you script Standard Additions or System Events.

**GUI Scripting** (System Events processes suite) — **introduced with strong caveats**:
- Two legitimate uses: automated GUI testing (see session 311) AND filling gaps in a workflow where one app has one un-scriptable alert.
- *"It's not a substitute for object model scriptability. It's not."* — Todd's flat statement, repeated.
- Four hard limitations: disabled by default (resolvable with a user prompt), fragile to UI changes (breaks on every new release), can't drive non-standard widgets (only Cocoa AX-compliant), broken for non-English keystrokes.
- The prescription: **if you're a scripter, request real scriptability from the developer; if you're a developer, ship real scriptability — your customers deserve it**.

**Image Events** — new faceless background app. Manipulate images and ColorSync profiles, access metadata, add/change profiles, rotate/crop/scale, translate file formats. *Dictionary is in the DP but not functional yet — final in Panther shipping release.*

**PDF Workflow** — actually shipped in 10.2.4. `~/Library/PDF Services/` (or `/Library/` or `/Network/Library/`) folder. Drop in:
- Aliases to folders → "Copy PDF to here" appears in the Save-as-PDF menu
- Aliases to apps → "Open with Preview" etc.
- AppleScripts (with `open` handler that receives file refs) → run any script against the saved PDF
- Demo: save to PDF → script prompts for filename → Address Book gives PDF Reviewers group → Mail composes new message with the PDF attached and addresses set

**Newly scriptable apps:** iChat AV, Xcode (Tim's session 306 covered the latter).

**Cocoa Scripting enhancements:**
- Suspend/resume current Apple Event command — avoid blocking the scripter on long ops
- API to access the exact Apple Event being handled → set return codes for proper error reporting
- Direct access to `subject` parameter and `considering`/`ignoring`
- Properties handled completely automatically — no code needed

### Breaking changes to know
- `path to me` in bundled applet ends with `:` (described above)
- `offset of` now honors `considering case` / `ignoring diacriticals` — previously always considered case, ignored diacriticals (backwards from defaults). Add explicit considering/ignoring blocks if you depended on old behavior.
- Avoid `«type text»`, `«type C string»`, `«type P string»` — deprecated, will be removed. Use `«type Unicode text»`.
- `Open Dictionary` is much faster in SE2 but only shows apps with `NSAppleScriptEnabled = yes` in Info.plist. Add the key or your app vanishes from the list.

### Chris Nebel's close — "Carbon Scripting is Cocoa Scripting"

Three buckets from last year's promises:
- **SDEF (XML scripting definition)** — *shipped*. Internal clients in Panther: Mail, iChat, Xcode. Direct Cocoa support still coming; for now use `sdp` to convert SDEF to script-suite/script-terminology files.
- **Codeless terminology and AppleScript 10** — *did not ship*. Still planned but not ready.
- **Carbon Scripting** — *converged with Cocoa Scripting*. Plot twist: link FoundationKit into your Carbon app, write Objective-C front-end classes that talk to your real Carbon implementation, one line of init, done. System Events already works this way. Runs on any OS X version, no need for Panther. Caveats: significant launch-time cost (mitigable), glue layer can be hard for old apps, Cocoa Scripting error handling is "substandard" (improved in Panther via back-door access).

### Sal's QuarkXPress demo philosophy

The Quark demo is more important than it looks. Sal is showing that:
1. **A normal user task** (vanity discography) is worth automating
2. The **building blocks are already scriptable** apps (Quark, iTunes, Safari/web)
3. **Workflow = composition** — the script is the glue, not the destination
4. The vision from 1992 hasn't dimmed in 2003 — *or 2026, where it still drives the WWSD principles*

## WWSD-relevant takeaways

- **Vision-stability quote** — strongest primary source for the timelessness of the WWSD vision. Sal will repeat this idea in 2018, 2019, 2023 interviews — and here it is in 2003, already a decade old at that point.
- **GUI Scripting is a last resort** — explicit, repeated, with a four-bullet rationale. This is operational WWSD: when you can't avoid GUI scripting, pressure the developer for real scriptability.
- **Per-app Script Menu folders** — the user-facing organization model. `~/Library/Scripts/Applications/<Bundle Name>/` is the standard pattern for "scripts that show up only when this app is frontmost." Still works in 2026.
- **PDF Workflow / dropped-script folders** — a recurring Sal pattern. Drop a script in a magic folder, it joins a menu. We see this same pattern with Folder Actions, Image Events workflows, and (post-Sal) with Shortcuts and Mail Rules.

## Reusable for the apple repo

- The `path to` enumeration list (Panther additions) is a good cheat-sheet for portable script writing.
- The `~/Library/PDF Services/` pattern is *still* a live extension surface on Sequoia — worth a painpoint check.
- Library window of pinned scriptable apps is a UX model worth mirroring in `bin/sal-grand-search` and friends.
- "Per-app Script Menu" is a candidate for a Loupedeck-context-aware launcher: when Renoise is frontmost, show Renoise scripts; when Logic is frontmost, show Logic scripts.
