# WWDC 2005 #138 — AppleScript for C, C++, and Java Programmers

**Speaker:** Sal Soghoian (solo)
**nonstrict:** https://nonstrict.eu/wwdcindex/wwdc2005/138/

## The pitch

Sal's audience-broadening session: AppleScript as a **complement** (not replacement) for C/C++/Java devs. The frame: you write compiled code that does the heavy lifting; AppleScript glues it to the rest of the user's Mac.

## Why a compiled-language dev should care

Sal's three arguments:

1. **Your app needs to be scriptable.** If users can't drive it from AppleScript, they can't compose it with the other apps on their Mac. Your app becomes a silo. Build scriptability in.

2. **AppleScript is the integration layer of macOS.** Your C++ video processor is great. But the user needs to: get the file from Finder, send it to your processor, attach the result to Mail, log the action in OmniOutliner. That's AppleScript work, and your app needs to participate.

3. **You can write the SDEF — your users will write the workflows.** Ship the dictionary, the community writes the scripts. **Free distribution of integration code.**

## What Sal teaches the C/C++/Java audience

### Tier 1 — making your app scriptable

- **SDEF format** — XML scripting definition. Hand-write or use `sdp` to convert from old-style aete resources.
- **Cocoa Scripting** — `NSScriptCommand`, `NSScriptObjectSpecifier`. Properties marked `scriptable` in the .h auto-generate the AE handlers.
- **`NSAppleScriptEnabled` = YES** in Info.plist — without this your app doesn't show up in Open Dictionary.
- **Standard Suite** — implement the common verbs (open, close, save, count, exists, make, delete) for free integration with Automator + other scripts.

### Tier 2 — calling AppleScript from your compiled app

- `NSAppleScript` — load a .scpt file, execute, get an `NSAppleEventDescriptor` back.
- `OSAScript` framework — older API, more control.
- **Use case:** your C++ app needs to email a result. Don't reimplement SMTP — call a 3-line AppleScript that drives Mail.app.

### Tier 3 — the call-method bridge from AppleScript

If you ship an AppleScript Studio template app, AppleScript can call any C/Obj-C method on any framework class via `call method`. This is what 2014's JXA `$` bridge eventually formalized.

## Sal's voice signature

The "AppleScript Airlines" framing returns — *"we're now boarding compiled-language developers"*. Bilingual integration as the through-line.

## Power features delivered

- **SDEF authoring guidance** for non-AppleScript devs
- **Cocoa Scripting essentials** — what properties to mark scriptable, how the AE handlers auto-generate
- **`NSAppleScript` recipes** for invoking scripts from your compiled app
- **`call method` bridge** — your C functions reachable from any AppleScript Studio app
- **Distribution channel argument** — if your app is scriptable, the user community ships free integration code

## Marketing copy version

**Headline:** Your compiled app is an island until users can drive it from AppleScript. Sal shows the four-step path to make it part of the Mac integration fabric — SDEF, Cocoa Scripting, `NSAppleScript` callbacks, `call method` bridge.

**Audience takeaway:** if you ship a Cocoa/Carbon app and skip scriptability, you're locking your customers out of the workflows that make macOS macOS. The cost to add it is small. The community payback is large.
