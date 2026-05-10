# WWDC 2014 Session 306 — JavaScript for Automation (Analysis)

**Speakers:** Sal Soghoian, David Steinberg
**Duration:** 52:33
**Track:** Services
**Source PDF:** `306_javascript_for_automation.pdf` (204 pages, 2.9 MB)
**Index:** https://nonstrict.eu/wwdcindex/wwdc2014/306/

## What this session announces

OS X Yosemite (10.10) introduced **JavaScript for Automation (JXA)** — JavaScript becomes a peer to AppleScript inside the Open Scripting Architecture. The same Apple Event bus, same scriptable apps (Pages, Keynote, Numbers, Finder, Mail, every sdef-bearing app), but with JavaScript syntax via JavaScriptCore. Sal frames it as "JavaScript joins the scripting ecosystem" — not a replacement for AppleScript, a sibling.

## Two-year automation arc (slides 3–5)

Sal sets context by walking from Mavericks → Yosemite to show automation got serious investment two releases in a row:

| Mavericks (10.9) | Yosemite (10.10) |
|------------------|------------------|
| Notifications from scripts | Code-signed Automator workflows |
| Code signing | Enhanced script libraries |
| `use` statements | Script progress indicators |
| Script libraries | **Dictation commands** |
| Speakable workflows | **JavaScript for Automation** |

The Yosemite list is the spine of Sal's WWSD philosophy — speakable workflows + dictation commands + JXA is the trajectory toward "automation as conversation" that culminates in Siri Shortcuts (2016, session 717).

## Script Editor walkthrough (slides 7–25)

Sal does a deliberate tour of the Script Editor UI — Record / Stop / Run / Compile buttons, Language popup (now showing **AppleScript / JavaScript**), Bundle Contents toggle, Events / Replies / Result tabs, the Script pane / Slider / Event Log split. The pedagogical point: **the editor is identical regardless of language**. Both compile to OSA components; both produce the same Apple Events at the wire level.

Preferences (`⌘,`) → General gains a **Default Language** popup with two choices: AppleScript (2.4) or JavaScript (1.0). Default Script Editor is now 2.7. Show Script menu in menu bar gets a dedicated callout — Sal still treats the global Script menu as the canonical user-facing surface for "I made a thing, I want to run it."

## The flagship example (slides 22–27): Keynote batch export

```javascript
Keynote = Application('Keynote')
documents = Keynote.documents

progress = $.NSProgress.currentProgress
progress.totalUnitCount = documents.length

destinationPath = $('~/Movies').stringByExpandingTildeInPath

for (i in documents) {
    document = documents[i]
    exportName = document.name().replace('.key','.m4v')
    document.export({
        to: Path(destinationPath.js + '/' + exportName),
        as: 'QuickTime movie'
    })
    progress.completedUnitCount = i
}

progress.completedUnitCount = documents.length
```

Eight ideas packed into one script:

1. **`Application('Keynote')`** — JXA's app-handle constructor. No `tell` block; the app is just a JS object.
2. **`.documents` collection access** — index, length, iteration with `for…in`. Object specifiers under the hood.
3. **`$.NSProgress.currentProgress`** — `$` is the JXA Objective-C bridge. Foundation classes are first-class. This wires script progress into the Script Editor's progress bar (a Mavericks feature now consumable from JS).
4. **`stringByExpandingTildeInPath`** — direct NSString method call on a JS string wrapped via `$()`.
5. **`.name().replace('.key','.m4v')`** — chaining a Cocoa-returned string into a native JS String method. Round-tripping ObjC ↔ JS.
6. **`Path(…)`** — JXA's first-class file/folder type; the AppleScript equivalent of `POSIX file …`.
7. **Record-syntax parameters** — `{to: …, as: 'QuickTime movie'}` is how named AppleScript parameters land in JXA.
8. **Progress as a side channel** — `Event Log` panel shows `/* Progress: 33% completed (1 of 3) */` interleaved with `Application("Keynote").export(…)`. The script editor doubles as a debugger.

The Event Log output is the punchline: AppleScript-style stringified events appear in real time even though the source is JavaScript — proving "same Apple Event bus" not just claimed but demonstrated.

## Dictionary Viewer becomes tri-lingual (slides 28–37)

`File → Open Dictionary…` shows Keynote's sdef. The **Language popup** now offers three views: AppleScript / **JavaScript** / Objective-C. Same dictionary, three renderings. JS view shows:

- Suites (Standard, Keynote, iWork Text, iWork, Compatibility)
- Classes (Application, Document, MasterSlide, Slide, Theme) with `export`, `duplicate` as methods at suite level
- Document's properties as JS-style camelCase: `slideNumbersShowing`, `documentTheme`, `autoLoop`, `autoPlay`, `autoRestart`, `maximumIdleDuration`, `currentSlide`, `height`, `width`
- Methods: `export`, `start`, `stop`, `showNext`, `showPrevious`, `showSlideSwitcher`, `cancelSlideSwitcher`, `acceptSlideSwitcher`

Sal labels the regions explicitly with green callouts: **Suite / Class / Methods / Elements / Properties / Model Viewer / Definition Viewer**. This is teaching, not just showing — naming the parts of the sdef so the audience can navigate any app's dictionary in JXA terms.

The Objective-C view (third option) is the under-discussed feature: it shows how a scriptable app's terminology maps to its actual Cocoa classes. This is the bridge that lets `$.NSAppleEventDescriptor` and friends interoperate with JXA-targeted apps.

## Why this session matters for the Sal archive

1. **It's the first ever WWDC session announcing a new automation language for OS X** — JXA in 2014 is parallel to AppleScript's introduction in System 7 (1993). The "second native language" is a real thing.
2. **Sal co-presents with David Steinberg** (likely the JXA engineer). Pattern repeats: Sal as PM does the why/when, engineer does the how. Same pattern as Chris Nebel pairing in 2012 #206 (security), Todd Fernandez / Chris Nebel / Tim Bumgarner pairings in 2003 #401 (AppleScript Update).
3. **JXA never got the user mindshare AppleScript did**, but it survives in `osascript -l JavaScript` to this day on Sequoia 15.6.1 — every script in `dictionaries/all-apps-plist-survey.md` could be re-expressed in JXA. It's a latent automation surface in the apple repo.
4. **The Keynote export example is reusable verbatim** — Sal's "batch export all open Keynote docs to .m4v" maps directly onto the workflow generator in `bin/workflow-gen.py`. Worth adding as a JXA recipe alongside the AppleScript ones.

## Remaining PDF content (pages 56–204, not yet extracted)

- Likely deeper dives into: `Application.currentApplication()`, `includeStandardAdditions`, ObjC bridge `$()`, `ObjC.import`, `Ref()` for by-reference parameters, error handling (`try`/`catch`), the `Library('name')` script libraries import
- Probably more examples: Finder operations, Mail composition, Calendar events, image processing
- Q&A / wrap slides at the end

## Follow-ups worth doing

- Extract pages 56–204 in batches and append concrete examples to this file
- Cross-link the JXA Keynote export into `scripts.md` as a JavaScript-language variant
- Run `bin/app-probe.py` against `osascript -l JavaScript` to verify which apps' sdefs render cleanly in JS (some have keyword collisions with JS reserved words)
- Add to `indexes/sal-lessons.yaml` once that file gets updated
