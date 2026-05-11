# WWDC 2003 #306 — AppleScript Studio

**Speakers:** Sal Soghoian (opening), Tim Bumgarner (main demo), John Coelho (Studio engineering) · **56:30**
**nonstrict:** https://nonstrict.eu/wwdcindex/wwdc2003/306/

## The pitch

> *"We want to deliver more for you with AppleScript, and we want to be able to be your hands and fingers into the world to get the things done that make you money."*

Sal's "hands and fingers" line — automation as a prosthesis for user intent.

## What got introduced — AppleScript Studio 1.3

Real Mac OS X apps written entirely in AppleScript. Studio is bundled into Xcode (just shipped, Project Builder rebranded). Apps look native because they ARE native — they use Cocoa under the hood, you write the glue in AppleScript.

## Sal-grade demo: BatchProcessor

Tim Bumgarner builds a complete drag-and-drop image-processor app live on stage:

- Drag-and-drop targets (folders or files)
- NSDataSource-backed table view of queued items
- Document-based save/load via custom `data representation` handlers
- Pasteboard read/write
- Plug-in support — third parties drop bundles into the app's plugins folder, get loaded as actions
- Xcode is itself scriptable from the Studio code (host self-introspection)

## The Studio 1.3 killer feature

**Every Cocoa object gets a `script` property.** Buttons, table cells, text fields. At runtime you can:
- Read the on-click AppleScript handler
- Swap it for a different handler
- Write a totally new one
- External apps can read/write these scripts via the document data

This is **runtime-mutable UI behavior**. A user can edit your app's button handlers in Script Editor and save the changes back into the .app — without recompiling. Wild for 2003.

## The closer demo — Settings Viewer

Tim shows an Xcode plug-in written entirely in AppleScript that aggregates build settings across all targets and styles in an Xcode project. **AppleScript as an Xcode plug-in language.** Studio is so deeply Cocoa-bridged that it can plug into Xcode itself.

## The Sal close

> *"AppleScript Airlines is now boarding."*

This was Sal's running joke through the 2003 sessions — he framed AppleScript Studio as a flight from "AppleScript user" to "Mac OS X app developer", with Tim and John as flight attendants.

## Power features delivered

- **Studio as a peer dev language** — AppleScript joins Objective-C, Java, C as a tier-1 Xcode language
- **`make new data column` + `append`** on NSDataSource — table views driven from AppleScript
- **`data representation`** handler — document-based-app save/load in 20 lines of AppleScript
- **Cocoa object → script property mapping** — every UI object can carry its own scripts
- **`call method`** — invoke any C/Objective-C method on any framework class from AppleScript
- **Plug-in loading** — `register {handler}` system for runtime-loaded bundles

## Why it matters for your repo

The "script property on every object" idea is the 2003 ancestor of **Hey Sal v1's matcher** — a router script that swaps its target Shortcut based on a phrase match. Same architectural pattern: runtime-mutable behavior tied to a UI surface. Worth re-reading Tim's BatchProcessor demo as a template for any "drop files on a Loupedeck button → process via configurable pipeline" tool.
