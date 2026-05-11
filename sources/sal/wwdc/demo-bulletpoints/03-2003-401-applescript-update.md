# WWDC 2003 #401 — AppleScript Update (Panther)

**Speakers:** Sal (opening + Quark demo), Todd Fernandez (main, new AppleScript Engineering Manager), Tim Bumgarner (Studio demos), Chris Nebel (Carbon/Cocoa Scripting close) · **58:53**
**nonstrict:** https://nonstrict.eu/wwdcindex/wwdc2003/401/

## The founding-vision quote (Sal's 1992 anchor)

> *"I first fell in love with AppleScript back in 1992 when I got the developer CD, and I saw that there was the ability for a normal schmo to be able to make the computer do what I wanted it to do. And the vision I had then was to be able to create automation and workflows where I could take information from one program, manipulate it, move it to another program, take that and move it to another program and build something. And in the decade following, that vision has not dimmed at all."*

**This is the single most quotable WWSD-grade sentence Sal ever said.** Used as the anchor for WWSD #34 (vision-stability since 1992).

## Sal's opening demo — Vanity discography in QuarkXPress 6

1. Pick tracks in iTunes
2. Run "Build Discography" from Quark's script menu
3. Script:
   - Reads selected iTunes tracks
   - Scrapes allmusic.com for the artist bio + photo
   - Creates Quark pages
   - Queries iTunes for owned tracks per artist
   - Lists them under each photo
4. Out comes a personal-data-sheet PDF

**The point isn't the discography.** The point is: a "normal user task" composed across iTunes, the web, and Quark, with AppleScript as the glue. Sal's vision in working form.

## Power features delivered (Todd Fernandez)

### Bundle formats — .scptd and .app
- New OSA bundle format for compiled scripts
- Standard Mac OS X packaging, no resource forks, filesystem-portable
- Persistent script attributes (description, window bounds)
- New APIs: `OSALoadFile` / `OSAStoreFile` + convenience methods
- **Gotcha:** `path to me` in a bundled applet now ends with `:` — old scripts that strip the last element will break unless they also strip the trailing colon

### Script Editor 2 (Cocoa replacement)
- Drag/drop, find/replace, undo, scripts > 32KB
- **Code Assistant** — code completion
- **Library window** — pin scriptable apps globally, double-click to open dictionary, "Make New Script" auto-writes the `tell application` block
- Contextual menu: select a list, choose "process every item" → editor writes the repeat loop for you
- Event log + result history; double-click a past result to recover the script that produced it
- Consolidated single-window event log + result (was two windows)

### Folder Action Setup app
- Contextual-menu Folder Actions return to Finder
- New app for enable/disable/attach/remove/edit globally
- Per-script enable/disable (couldn't before)

### Script Menu enhancements
- Hide library/example scripts to show only your user scripts
- Aliases supported (including remote machines)
- Hold Option on a script → opens in Script Editor for editing
- **Per-app scripts** — `~/Library/Scripts/Applications/<App>/` shows only when that app is frontmost ← still works in 2026

### Standard Additions runtime enhancements
- `choose color` returns RGB list
- New `path to` enumerations (movies folder, music folder, etc.)
- Applets now handle Apple Events FIFO → **AppleScript CGIs** become possible
- Unicode constants easier to use
- Date class: `short date string`, months coerce to numbers, months comparable

### System Events — unified app classes
- All app-style suites merged
- New `disk item` class (file and folder inherit from it)

### GUI Scripting introduced (with strong caveats)
- Two legitimate uses: automated GUI testing AND filling gaps in workflows
- Todd: *"It's not a substitute for object model scriptability. It's not."*
- **Four hard limitations:** disabled by default, fragile to UI changes, can't drive non-Cocoa widgets, broken for non-English keystrokes
- **The prescription:** if you're a scripter, request real scriptability from the developer; if you're a developer, ship real scriptability

### Image Events
- Faceless background app
- Image + ColorSync manipulation, metadata, rotate/crop/scale, format conversion
- New in 10.2.x but unfinished in DP

### PDF Workflow (`~/Library/PDF Services/`)
- Drop in: folder aliases, app aliases, AppleScripts (with `open` handler)
- Save-to-PDF menu in any app shows these as targets
- Sal's demo: save PDF → script asks for filename → Address Book PDF Reviewers group → Mail composes new message with PDF attached, addresses set

### Newly scriptable: iChat AV, Xcode

### Cocoa Scripting enhancements
- Suspend/resume current Apple Event command (no blocking)
- Access to the exact AE being handled (proper error reporting)
- Direct access to `subject` parameter, `considering`/`ignoring`
- Properties handled automatically — no glue code needed

### Breaking changes you have to know
- `path to me` trailing colon in bundled applets
- `offset of` now honors `considering case` / `ignoring diacriticals`
- **Avoid** `«type text»`, `«type C string»`, `«type P string»` — use `«type Unicode text»`
- Open Dictionary only shows apps with `NSAppleScriptEnabled = yes` in Info.plist

## Chris Nebel close — "Carbon Scripting is Cocoa Scripting"

The big plot twist: Carbon apps that want to be scriptable can **link FoundationKit into the Carbon app**, write Objective-C front-end classes that delegate to the Carbon implementation, add one line of init code. Runs on any OS X version (not Panther-only). System Events already works this way.

Caveats:
- Significant launch-time cost (mitigable)
- Glue layer can be hard for old apps
- Cocoa Scripting error handling is "substandard" but improved in Panther

**SDEF (XML scripting definition format) ships.** Internal clients in Panther: Mail, iChat, Xcode. Use `sdp` to convert SDEF to script-suite/script-terminology files for the legacy build chain.

## Why it matters

This is the densest "what's new" session in the entire 2003-era AppleScript archive. If you write AppleScript on macOS in 2026, you're still relying on five things that shipped here: per-app Script Menu folders, the `.scptd` bundle format, `~/Library/PDF Services/`, GUI Scripting via System Events processes suite, and SDEF as the dictionary format.
