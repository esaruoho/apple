# WWDC 2007 #206 — Building Automator Actions

**Speaker:** Sal Soghoian (solo) · **1:09:29** · Track: Leopard Innovations
**nonstrict:** https://nonstrict.eu/wwdcindex/wwdc2007/206/

## The pitch

> *"Automator actions are the foundation of creating workflows that use your application."*

Hands-on session — Sal walks the audience through building actions live, in multiple languages (AppleScript Studio, Cocoa Objective-C, scripting languages).

## What's covered — anatomy of an Automator action

### Three flavors of action

1. **AppleScript Studio action** — Xcode template, write the work in AppleScript
2. **Cocoa Objective-C action** — Xcode template, write in Obj-C
3. **Scripting language action** (new for Leopard) — Ruby, Python, Perl, shell

### The action's three required things

- **`Info.plist`** — declares input type, output type, category, keywords, icon, description
- **`main.scpt` / `main.command` / etc.** — the actual work
- **`infoPlist.strings`** — localized strings for the UI

### Input/Output type matching

Automator chains actions by matching outputs to inputs. Sal walks through the type system:
- `com.apple.cocoa.string`
- `com.apple.cocoa.url`
- `com.apple.cocoa.file-system-object`
- `com.apple.cocoa.image`
- `com.apple.cocoa.application`
- `public.tag` types for files

**Tip:** declare the most specific input type your action handles. Generic actions (accept "any") are the silent productivity killer — they break in unexpected ways when chained.

### The UI

- Pre-built UI templates: textfield, popup, slider, checkbox, file picker, folder picker
- Bound to AppleScript variables via the `parameters` dictionary
- `__NSDictionary__` access from AppleScript: `value of parameter "foo" of parameters`

### Universal action variables

- `input` — the previous action's output
- `parameters` — the UI configuration
- `result` — what you pass to the next action

### Best practices Sal hammers

- **Idempotent actions** — running twice should be safe (no side-effects beyond the obvious)
- **Cancel handling** — check `should cancel` regularly during long loops
- **Progress reporting** — `update progress` for the spinner UI
- **Helpful error messages** — display dialog with the failing item if you bail

## Sal-style demos

- Live builds a "Set Movie Annotations" action (callback to his 2003/2004 QT work)
- Live builds a "Add to PDF Reviewers" action that wraps the 2003 PDF Workflow trick
- Live builds a shell-script action that calls `mdfind` and pipes results forward

## Power features delivered

- **Scripting-language actions** (Ruby, Python, Perl, shell) — new for Leopard
- **Standardized input/output type system** for chain compatibility
- **UI binding** — parameters dict drives both UI and code, in sync
- **Progress + cancel handling APIs** that integrate with Automator's chrome
- **Action localization** via infoPlist.strings — ship your action in 30 languages without code changes

## Marketing copy version

**Headline:** Ship one Automator action. Reach every Mac. No App Store, no installer — drop the bundle into `~/Library/Automator/`, and users see it in the Automator action library next time they open the app.

**Audience takeaway:** writing Automator actions in 2007 is the closest macOS has had to "app extensions" before that name existed. If your tool does one thing well and accepts one type, you should ship an Automator action. It's smaller than an app, integrates everywhere, and your users compose it with the 100+ other actions already on their Mac.
