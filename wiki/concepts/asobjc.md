# AppleScriptObjective-C (ASObjC) — The Missing Tier

> Sal Soghoian, 2026-05-22 (reply to Esa): *"AppleScriptObjective-C can be used for File Management. It has access to tags as well."* — pointer to [macosxautomation.com/bootcamp/](http://macosxautomation.com/bootcamp/)

## What it is

ASObjC is the bridge that lets a plain AppleScript script call **any Cocoa class** — `NSFileManager`, `NSURL`, `NSMetadataQuery`, `NSWorkspace`, `NSSavedSearch`, `NSPasteboard`, `NSImage`, every Foundation/AppKit class — directly. No Swift compile step. No Xcode. Runs in `osascript` like any other AppleScript.

Shipped in Mac OS X 10.6 (2009). Expanded in Mac OS X 10.10 (Yosemite) with library support. Sal's team built it. It is the most powerful Apple-native automation tier on the system, and we missed it.

## Minimum viable shape

```applescript
use framework "Foundation"
use scripting additions

set theURL to current application's NSURL's fileURLWithPath:"/Users/esaruoho/Desktop/test.txt"
set {ok, tagList, err} to theURL's getResourceValue:(reference) forKey:(current application's NSURLTagNamesKey) |error|:(reference)
return tagList as list
```

Two lines unlock the entire Foundation framework:

```applescript
use framework "Foundation"
use scripting additions
```

After that, `current application's NSXxxxx` reaches every Cocoa class. `(reference)` is ASObjC's way of passing an out-parameter (the AppleScript equivalent of `&` in Objective-C).

## What it unlocks for THIS skill

| Pain-point in current skill | xattr / shell hack | ASObjC-native path |
|---|---|---|
| Read/write Finder tags | `xattr -p com.apple.metadata:_kMDItemUserTags` + binary plist decode | `NSURL`'s `NSURLTagNamesKey` resource value (Apple-supported, APFS-safe) |
| Generate Smart Folders | Hand-rolled `.savedSearch` plist via `plistlib` | `NSSavedSearch` (proper API, validates query strings) |
| Live Spotlight queries from a script | `mdfind` shell out, parse stdout | `NSMetadataQuery` — observable, live-updating, structured results |
| Open URL in default app | `do shell script "open ..."` | `NSWorkspace`'s `openURL:` |
| Copy rich text to clipboard | `pbcopy` + RTF dance | `NSPasteboard` with multiple representations in one shot |
| Read EXIF / image metadata | `sips -g all` + parse | `CIImage` properties, `CGImageSource` |
| File-system enumeration | `find` shell loop | `NSFileManager`'s `enumeratorAtURL:` with predicates |

The pattern: every place we shell out to a `/usr/bin/*` and parse string output, ASObjC gives us a typed, supported Cocoa call from inside AppleScript.

## What it does NOT unlock

- **Finder.app internals.** ASObjC does not "break into Finder" — Finder is still bound by its sdef. What ASObjC *does* give you is the ability to write file-management scripts that don't *need* Finder at all (use `NSFileManager` directly).
- **Smart Mailboxes.** Mail's smart-mailbox criteria are written to a binary plist that Mail rewrites on launch. See [mail-smart-mailboxes-dead.md](mail-smart-mailboxes-dead.md). ASObjC doesn't change that — the lock is in `Mail.app`, not in the language.
- **Things behind entitlements** (Tier 5-7 XPC, private frameworks). ASObjC has the same access as any user-level process — it can call public Cocoa, not private SPIs.

## Where ASObjC sits in the tier model

Old tier model was permission-shaped (Tier 1-10 keyed by TCC / entitlement / root). ASObjC is **not a permission tier** — it's a language-surface tier that crosses permission tiers. Add it as **Tier 1.5** (between AppleScript and CLI):

| Tier | Surface | What it adds |
|---|---|---|
| 1 | AppleScript sdef | App-specific verbs |
| **1.5** | **ASObjC bridge** | **Full Cocoa API from inside AppleScript** |
| 2 | App Intents (Shortcuts) | Modern intents |
| 3 | URL Schemes | Cross-app deep links |
| 4 | CLI tools | Anything in `/usr/bin` |

See [automation-tiers.md](automation-tiers.md) for the full atlas.

## Why this tier was missed (meta)

Documented in this file so it doesn't happen again to another tier:

1. **Taxonomy was permission-shaped, not language-shaped.** Every tier slot was differentiated by TCC gate. ASObjC has no distinct permission — it just runs as osascript — so it had no row.
2. **Probing bias.** Every `bin/` probe enumerates *external surfaces* (sdef, app probes, xpc probes). ASObjC isn't probable — it's a dialect. Discovery method was blind.
3. **Veteran-tech blind spot.** ASObjC has shipped since 2009. New shiny things (App Intents, Apple Intelligence) got concept pages because they were being discovered. ASObjC got assumed-into-the-background.
4. **"Cocoa via Swift" silently absorbed it.** Layer 1 of the 7-layer architecture lists `osascript, OSAKit, ScriptingBridge` — ScriptingBridge is Cocoa→AppleScript (Swift calling AS), not AS calling Cocoa. The names rhyme; we conflated them.
5. **No failure forced discovery.** Smart Mailboxes got a dead-end doc because they failed. Tags worked via xattr — working code doesn't trigger reinvestigation.
6. **Entity→concept link missing.** [sal-soghoian.md:121](../entities/sal-soghoian.md) lists ASObjC as a one-line historical credit. Never promoted to a concept page.

**The lesson:** a tier model keyed on access permissions misses tiers keyed on language surfaces. Both axes must be checked.

## Reference learning material

- **Sal's Down Home Scripting Boot Camp** — [macosxautomation.com/bootcamp/](http://macosxautomation.com/bootcamp/). This is what Sal pointed Esa to on 2026-05-22. Sal's own teaching curriculum, post-Apple.
- **Shane Stanley's books** — `Everyday AppleScriptObjC` and `Myriad Tables` — the canonical ASObjC references. Not Apple-published; Stanley is a contemporary of Sal's.
- **Apple's official guide** — [Mac Automation Scripting Guide: AppleScriptObjC](https://developer.apple.com/library/archive/documentation/AppleScript/Conceptual/AppleScriptObjC/) (archived but still authoritative).

## Pilot tool

[`bin/asobjc-tag-demo.applescript`](../../bin/asobjc-tag-demo.applescript) — reads Finder tags via `NSURL`'s `NSURLTagNamesKey` resource value. Demonstrates the minimum viable ASObjC shape on a real skill pain-point.

Run: `osascript bin/asobjc-tag-demo.applescript ~/Desktop/somefile.png`

## Next steps for the skill

1. Migrate `bin/tag*` (the `/tag` skill backend) from xattr+plistlib to ASObjC-native NSURL resource values. Compare line count + edge cases.
2. Replace hand-rolled `.savedSearch` plist generation in `/smart` and `/show` with `NSSavedSearch`.
3. Add an ASObjC section to [wwsd-decision-tree.md](wwsd-decision-tree.md) — when sdef is too thin, before reaching for Swift, try ASObjC.
4. Document the `current application's` idiom + `(reference)` out-param convention in a future `wiki/concepts/asobjc-idioms.md` once we have 3+ pilot tools using them.

---

*Created 2026-05-22 after Sal's reply to Esa about File Management + tags via ASObjC. Foundation for an entire untapped tier of the skill.*
