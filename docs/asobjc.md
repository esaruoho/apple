---
layout: default
title: "AppleScriptObjective-C (ASObjC) — The Missing Tier"
---

# AppleScriptObjective-C (ASObjC) — The Missing Tier



[← Back to home](./)
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
| Read/write Finder tags (names only) | `xattr -p com.apple.metadata:_kMDItemUserTags` + binary plist decode | `NSURL`'s `NSURLTagNamesKey` resource value (Apple-supported, APFS-safe — **strips colors**) |
| Read/write Finder tags **with colors preserved** | xattr+plistlib (current `bin/tag`) | Raw xattr via `NSPropertyListSerialization` (binary plist round-trip in ASObjC) — see pilot finding below |
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

## Pilot tools

### 1. `bin/asobjc-tag-demo.applescript` — minimum-viable read

Reads Finder tags via `NSURL`'s `NSURLTagNamesKey` resource value. Demonstrates the minimum viable ASObjC shape on a real skill pain-point.

Run: `osascript bin/asobjc-tag-demo.applescript ~/Desktop/somefile.png`

### 3. `bin/tag-asobjc-full.applescript` — color-preserving pilot

Round-trips the full Finder-tag xattr (`com.apple.metadata:_kMDItemUserTags`) through `NSPropertyListSerialization`. Verified 2026-05-22: writes via this pilot are read back with colors intact by both itself AND `bin/tag` (Python). Inverse also works — Python writes `python:purple,reverse:yellow`, this pilot reads `python:purple` and `reverse:yellow`. Full feature parity for `list`/`set`/`clear` of color-tagged files.

**The recipe whenever ASObjC needs to touch arbitrary xattrs:**

1. `do shell script "xattr -px <key> <path>"` → hex-encoded blob (Apple-shipped CLI)
2. `xxd -r -p` via tempfile → `NSData` (Foundation doesn't expose a hex decoder)
3. `NSPropertyListSerialization propertyListWithData:options:format:error:` → `NSArray`
4. Mutate as AppleScript list
5. `NSPropertyListSerialization dataWithPropertyList:format:options:error:` with `NSPropertyListBinaryFormat_v1_0` → `NSData`
6. `xxd -p` via tempfile → hex string
7. `do shell script "xattr -wx <key> <hex> <path>"`

**Foundation gotcha:** `NSPropertyListSerialization`'s `format:` out-parameter must be passed as `(reference)`, not `(missing value)`. Passing `missing value` returns a 2-tuple instead of the 3-tuple `{plistObj, fmt, err}` that AppleScript destructures. The error is non-obvious (`Can't get item 3 of {...}`).

### 2. `bin/tag-asobjc.applescript` — A/B reimplementation of `bin/tag` core I/O

Reimplements `list`/`add`/`set`/`remove`/`clear` against the same xattr that `bin/tag` (Python) writes. Tested round-trip: Python writes → ASObjC reads, ASObjC writes → Python reads. Same file, same xattr, both tools see each other's writes.

**Pilot finding (2026-05-22):** `NSURLTagNamesKey` is **names-only** in both directions. Setting `"asobjc:red,bridge:orange"` via the ASObjC version produces tags named `asobjc` and `bridge` with **no colors** on disk — confirmed by reading back with the Python tool (which decodes the raw xattr). The color info is silently dropped.

**Implication for production migration:** the "elegant" `NSURL` resource-value path covers the 90% case (names, multi-tag, search) but cannot replace `bin/tag` outright if color preservation matters (it does — Finder's swatch column is one of the main reasons to use tags). For color-preserving I/O via ASObjC, the binary plist must be round-tripped explicitly with `NSPropertyListSerialization`:

```applescript
use framework "Foundation"
-- read
set xattrData to ... -- read via NSTask/xattr or NSFileManager extended-attribute APIs
set {plistObj, fmt, err} to (current application's NSPropertyListSerialization's ¬
	propertyListWithData:xattrData options:0 format:(reference) |error|:(reference))
-- plistObj is now an NSArray of "Name\n<int>" strings — same as Python sees
-- write
set newData to (current application's NSPropertyListSerialization's ¬
	dataWithPropertyList:newArray format:(current application's NSPropertyListBinaryFormat_v1_0) ¬
	options:0 |error|:(reference))
-- then write back via the extended-attribute API
```

The extended-attribute write path from ASObjC needs a wrapper — `NSFileManager` doesn't expose `setxattr` directly to AppleScript. Options: shell out to `xattr -wx`, or write a tiny `bin/xattr-write.swift` helper.

**Lesson for the tier model:** "Apple-supported" ≠ "feature-parity with the underlying syscall." `NSURL` resource values are the *sanctioned* path but they normalize away detail the lower-level xattr preserves. Treat each ASObjC migration as a fidelity audit, not a drop-in replacement.

## Mandatory pre-flight: `bin/cocoa-class-probe`

Before proposing OR writing any ASObjC migration, probe every Cocoa class name against the SDK headers. Do not infer from plausible-sounding names. Run:

```bash
bin/cocoa-class-probe NSSomeClassName AnotherClass [...]
bin/cocoa-class-probe --runtime NSPossiblyPrivateClass     # also check ObjC runtime
bin/cocoa-class-probe --framework Foundation NSFileManager  # narrow scope
```

Verdicts:
- `PUBLIC` — declared in at least one shipped SDK header. Safe to use.
- `RUNTIME-ONLY` — not in headers but resolvable at runtime. Private SPI, will fail App Review, may break across macOS versions.
- `ABSENT` — name is wrong or made up. Stop. Do not migrate.

Exit code 1 if any symbol is `ABSENT`, so this can guard a CI hook for future migrations.

**Why this tool exists:** during the 2026-05-22 pilot pass, I proposed migrating `/smart` and `/show` to `NSSavedSearch`. The class name was pattern-matched from "Saved Search file format" — it does not exist in any public SDK header. I caught it before writing the migration only because I read the existing plist code first. The probe makes this a one-line check instead of a luck-dependent catch.

## Production migrations log

| Date | Tool | What changed | Verified |
|---|---|---|---|
| 2026-05-22 | `bin/build-delete-now-shortcut.py` — embedded AppleScript inside the "Delete Immediately" Finder Quick Action | `do shell script "/bin/rm -rf"` → `NSFileManager removeItemAtURL:error:`. Per-item typed `NSError` reporting, no shell quoting, no `/bin/rm` process spawn. | Smoke-tested on normal, space-bearing, and Unicode-bold (`Ünicode-böld‐文件.txt`) filenames — all deleted cleanly. Non-existent path correctly returns typed error. |

### Idioms learned

- **Destructuring `setResourceValue:error:` and similar dual-returns:** don't write `set {ok, err} to ...` — AppleScript's destructuring infers types ambiguously and can emit `Expected variable name or property but found class name` from positions you can't easily debug. Safer pattern: `set theResult to (...)` then `item 1 of theResult` / `item 2 of theResult`. Verified working on `NSFileManager removeItemAtURL:error:`.

## Findings from the pilot pass (2026-05-22)

Two pilots completed; two "obvious" ASObjC wins evaluated; verdicts honest.

### Finding A — `NSURLTagNamesKey` is names-only

Documented above. The "elegant" ASObjC path drops color info. Color preservation requires the xattr+NSPropertyListSerialization recipe (`bin/tag-asobjc-full.applescript`).

### Finding B — `NSSavedSearch` is not a public class

The originally-planned migration of `/smart` and `/show` from hand-rolled plist to `NSSavedSearch` **cannot happen**. `NSSavedSearch` is a Finder-private class. The `.savedSearch` file IS the API — Finder reads a plain plist with the documented structure (`RawQuery`, `SearchScopes`, `SearchCriteria`, `SearchResultsViewOptions`). Python's `plistlib` (stdlib, Apple-native) is already the optimal implementation. **Do not migrate `bin/smart` or `bin/show`** — there is no ASObjC equivalent that wins on any axis. Leaving them in Python is the correct choice.

### Generalized lesson

When considering an ASObjC migration, ask first: *does a public Cocoa class actually exist for the thing I'm doing?* If the Finder/Cocoa interface is "write this plist shape," then `plistlib` already wins — there's no class to bridge to. ASObjC's value is exclusively when there's a real Foundation/AppKit class that the Python tool currently substitutes for via shell + parsing. Tag I/O has `NSURL` resource values (partial win). SavedSearch does not.

## Next steps for the skill

1. **No production migration of `bin/tag` yet.** Both ASObjC pilots are kept as references. The Python tool stays as the production interface; the pilots demonstrate the pattern for future tools.
2. **No migration of `bin/smart` or `bin/show`** — verdict above.
3. Add an ASObjC branch to [wwsd-decision-tree.md](wwsd-decision-tree.md) — *when sdef is too thin, before reaching for Swift, try ASObjC. Before writing a new ASObjC tool, audit whether a public Cocoa class exists — if not, `plistlib`/`do shell script` is already optimal.*
4. Document the `current application's` idiom + `(reference)` out-param convention in a future `wiki/concepts/asobjc-idioms.md` once we have 3+ pilot tools using them.
5. **New audit candidate:** look for places in `bin/` where we shell out + parse output (`mdfind`, `sips`, `sysctl`, etc.) and check whether a public Cocoa class exists for that domain. `NSMetadataQuery` for `mdfind` is the obvious one — that one IS a real public class, unlike `NSSavedSearch`.

---

*Created 2026-05-22 after Sal's reply to Esa about File Management + tags via ASObjC. Foundation for an entire untapped tier of the skill.*
