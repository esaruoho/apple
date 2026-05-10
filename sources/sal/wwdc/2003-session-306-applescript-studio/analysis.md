# WWDC 2003 Session 306 — AppleScript Studio (Analysis)

**Speakers:** Sal Soghoian (opening), Tim Bumgarner (main, senior engineer for AppleScript Studio), John Coelho (QA, demo partner)
**Duration:** 56:30
**Source:** transcript.md (Whisper, nonstrict.eu)

## Sal's opening framing (the WWSD-relevant minute)

Sal sets context before handing to Tim. Three quotable lines:

1. *"It's an incredible time to be a developer. It's an incredible time to be an Apple employee, and especially for AppleScript. Over the last year, AppleScript has progressed more and more and grown faster and faster. It's just on fire."*
2. *"AppleScript becoming a peer development language with Objective-C and Java and Cocoa, Carbon… we have pushed farther and grown faster… We want to deliver more for you with AppleScript, and we want to be able to be your hands and fingers into the world to get the things done that make you money."* — **"hands and fingers into the world"** is the WWSD-grade metaphor.
3. *"AppleScript Studio can combine disparate parts of code and resources… makes your users and customers satisfied and easy to use, but it can also deliver a lot of power under the hood."*

Tim then runs the rest.

## What Tim covers (the technical substance)

**Studio 1.0 → 1.3 history.** Released Dec 2001 (OS X 10.1.2). 1.1 in April 2002. 1.2 was the big Jaguar release (drag-and-drop, pasteboards, data source enhancements, document-based apps). 1.3 ships with Panther.

**What is AppleScript Studio.** Integrated into Xcode (no longer Project Builder), Interface Builder via a palette, built on Cocoa frameworks. *Both* a dev environment *and* a runtime — the resulting `.app` ships without extra extensions or plug-ins. Native Cocoa app, AppleScript as the dev language.

**What you can do with Studio.**
- Native Mac apps using Cocoa table views, outline views, buttons
- Talk to local + networked + Internet apps + **web services via XML-RPC and SOAP** (just `tell application` with the service)
- `do shell script` to wrap CLI tools in a real UI
- Call C / C++ / Objective-C / Java directly from AppleScript
- Round-trip: Cocoa code can create AppleScript and call back into the Studio app

**Hello World demo.** Three steps: New Project (AppleScript Application), delete the default window, attach `onlaunched` event handler with `display dialog "Hello World"` then `tell application "..." to quit`, Build & Run.

**Studio 1.2 features (the meat).** Tim and John build a full app on stage called **BatchProcessor**:

- **Drag and drop** — 6 new event handlers (drag enter/exit/update/drop/prepare-drop/conclude) + `register drag types` (filenames/string/color/font/etc.). `onAwakeFromNib` registers the table view for filename drops.
- **Pasteboard class** — named pasteboards (general/drag/find/font). Get types, set preferred type, read contents. Sal/Tim demo using Script Editor against the *running* BatchProcessor app to introspect pasteboards live — a debugging-by-scripting pattern.
- **Data source enhancements** — `make new data source`, `make new data column` (must name-match the table column), `append` with a list of records (much faster than row-by-row), sorting support. Two-stage population: `update views` off → loop → `update views` on. `call method` with NSString's `lastPathComponent` / `stringByDeletingLastPathComponent` to parse POSIX paths cleanly.
- **Document-based applications** — high-level handlers (`data representation` returning AppleScript record on save, `load data representation` restoring it). Low-level alternative: POSIX path + write bytes directly. Mutually exclusive — pick one.

**Studio 1.3 features (Panther).** Two big ones:

- **Script property on every Cocoa-NSMASK object.** *"You can have a `foo` property on a script on a button. So now you can say `foo of script of button one`."* Dynamically swap a button's `onClicked` handler at runtime. External apps can reach in and read/set these too — **a Studio app becomes a live scripting target**.
- **Plugin support for Xcode (AppleScript-written plugins).** New `plugin loaded` event handler. `make new menu item` and `make new menu` lets a plug-in insert UI into Xcode. Tim builds a **Settings Viewer plugin** that uses Xcode scriptability to enumerate all build settings across all targets/styles and shows which settings are defined in multiple places. Inverts the normal top-down inspector model.

**Xcode scriptability.** New in Panther. Low-level: projects, targets, file refs, build phases. High-level: documents, windows, views. Tim's plug-in is built on the low-level API.

**Future features (Studio roadmap):** `make new` and `delete` for everything (toolbars, dock menu), enhanced dictionary viewer with search field + inline doc examples.

**Sal's closing flourish.** *"AppleScript Airlines. Welcome to flight 306. On your tour, our final destination is AppleScript Nirvana. If this is not your destination, there are exits fore and after."* — playful WWSD framing of the conference tracks as a journey.

## WWSD-relevant takeaways

- "Hands and fingers into the world" — Sal's clearest 2003-era statement of *why* user automation exists. Not productivity software; **prosthesis for intent**.
- AppleScript as **peer** development language — not a toy, not a glue layer, equal table seat with Objective-C/Java.
- The **debug-by-scripting** pattern (Script Editor against your running Studio app) is reusable today against any sdef-bearing app.
- **Combining disparate parts** is the philosophy — the app is the assembly, the AppleScript is the welding.

## Reusable for the apple repo

- BatchProcessor pattern is directly applicable as a Loupedeck-trigger template: drag files onto a button → run AppleScript per file → status column.
- The Settings Viewer plug-in pattern — inverted inspectors that aggregate properties across hierarchy — is a UX move worth stealing for app-probe browsing.
- "Studio app is a live scripting target" — the `script property` idea is exactly how `ReMCP` thinks about Renoise. The 2003 Studio model is the same architecture pattern.
