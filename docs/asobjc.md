---
layout: default
title: ASObjC — the missing tier
---

# AppleScriptObjective-C (ASObjC) — the missing tier

[← Back to home](./)

> Sal Soghoian, 2026-05-22 (reply to Esa): *"AppleScriptObjective-C can be used for File Management. It has access to tags as well."*

Two lines at the top of any `.applescript` file unlock the entire Foundation framework:

```applescript
use framework "Foundation"
use scripting additions
```

After that, `current application's NSXxxxx` reaches every public Cocoa class — `NSFileManager`, `NSURL`, `NSMetadataQuery`, `NSWorkspace`, `NSSavedSearch`, `NSPasteboard`, `NSImage`, every Foundation/AppKit class — directly. No Swift compile step. No Xcode. Runs in `osascript` like any other AppleScript.

Shipped in Mac OS X 10.6 (2009). Expanded in 10.10 Yosemite (2014) with library support. **Sixteen years old. Sal's team built it. The macOS automation community has been writing without it.**

## Why this matters for the pattern book

Every place this repo (and most macOS automation in the wild) shells out to a `/usr/bin/*` and parses string output, ASObjC gives a typed, supported Cocoa call from inside AppleScript. A non-exhaustive sample:

| Pain-point | Shell hack | ASObjC-native path |
|---|---|---|
| Read/write Finder tags by name | `xattr -p com.apple.metadata:_kMDItemUserTags` + binary plist decode | `NSURL`'s `NSURLTagNamesKey` resource value |
| Read/write Finder tags with **colors** preserved | xattr + `plutil` (current `bin/tag`) | Raw xattr via `NSPropertyListSerialization` |
| Generate Smart Folders | Hand-rolled `.savedSearch` plist via `plistlib` | `NSSavedSearch` (proper API, validates query strings) |
| Live Spotlight queries | `mdfind` shell-out, parse stdout | `NSMetadataQuery` — observable, live-updating, structured |
| Open URL in default app | `do shell script "open ..."` | `NSWorkspace`'s `openURL:` |
| Copy rich text to clipboard | `pbcopy` + RTF dance | `NSPasteboard` with multiple representations in one shot |
| EXIF / image metadata | `sips -g all` + parse | `CIImage` properties, `CGImageSource` |
| File-system enumeration | `find` shell loop | `NSFileManager`'s `enumeratorAtURL:` with predicates |

## Minimum viable shape

```applescript
use framework "Foundation"
use scripting additions

set theURL to current application's NSURL's fileURLWithPath:"/Users/esaruoho/Desktop/test.txt"
set {ok, tagList, err} to theURL's getResourceValue:(reference) ¬
    forKey:(current application's NSURLTagNamesKey) ¬
    |error|:(reference)
return tagList as list
```

`(reference)` is ASObjC's way of passing an out-parameter (the AppleScript equivalent of `&` in Objective-C).

## What ASObjC does NOT unlock

- **Finder.app internals.** ASObjC does not "break into Finder" — Finder is still bound by its sdef. What ASObjC *does* give you is the ability to write file-management scripts that don't *need* Finder at all (use `NSFileManager` directly).
- **Smart Mailboxes.** Mail's smart-mailbox criteria are written to a binary plist that Mail rewrites on launch (see [`mail-smart-mailboxes-dead.md`](https://github.com/esaruoho/apple/blob/main/wiki/concepts/mail-smart-mailboxes-dead.md)). ASObjC doesn't change that — the lock is in Mail.app, not the language.
- **Anything behind private entitlements.** ASObjC has the same access as any user-level process — it can call public Cocoa, not private SPIs.

## Where ASObjC sits in the tier model

The old tier model was permission-shaped (Tier 1–10 keyed by TCC / entitlement / root). ASObjC is **not a permission tier** — it's a language-surface tier that crosses permission tiers. Slotted as **Tier 1.5** between AppleScript and CLI. See the [tiers atlas](./tiers).

## The lesson

The atlas was 10-tier until 2026-05-22, when Sal pointed it out. ASObjC had been invisible for 17 years because single-axis taxonomies hide entire tiers. **Always classify on both axes: permission shape AND language surface.** Companion memory rule lives in the project's feedback log.

## Pre-flight: probe before you name a class

`bin/cocoa-class-probe NSXxxx` checks whether a Cocoa class is public, deprecated, or private. ASObjC scripts that name a private class fail silently. Probe first.

## Read more

- Source-of-truth: [`wiki/concepts/asobjc.md`](https://github.com/esaruoho/apple/blob/main/wiki/concepts/asobjc.md) — full pilot findings, raw-xattr-with-color round-trip pattern, every gotcha.
- Demo: [`bin/tag-asobjc.applescript`](https://github.com/esaruoho/apple/blob/main/bin/tag-asobjc.applescript), [`bin/asobjc-tag-demo.applescript`](https://github.com/esaruoho/apple/blob/main/bin/asobjc-tag-demo.applescript), [`bin/tag-asobjc-full.applescript`](https://github.com/esaruoho/apple/blob/main/bin/tag-asobjc-full.applescript)
- Sal's bootcamp pointer: [macosxautomation.com/bootcamp/](http://macosxautomation.com/bootcamp/)

---

[← Back to home](./) | [Triggers ←](./triggers) | [Tiers ←](./tiers) | [Sal corpus ←](./sal-corpus) | [Chassis ←](./chassis)
