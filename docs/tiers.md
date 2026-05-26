---
layout: default
title: Eleven-tier automation atlas
---

# Eleven-tier automation atlas

[← Back to home](./)

macOS exposes a stack of automation layers — most users know one or two. This atlas walks all eleven, top of stack (Shortcuts / Siri-shaped, simplest) to bottom (IOKit, what the kernel actually lets you do).

> *The atlas was 10-tier until 2026-05-22, when Sal pointed out the missing **ASObjC** tier — a plain `.applescript` file calling any public Cocoa class. It had been invisible for 17 years because single-axis taxonomies hide entire tiers. See the [postmortem](https://github.com/esaruoho/apple/blob/main/wiki/concepts/asobjc.md).*

The canonical source is [`wiki/concepts/automation-tiers.md`](https://github.com/esaruoho/apple/blob/main/wiki/concepts/automation-tiers.md). This page is the orientation; that page has the full coverage matrix.

| Tier | Layer | Permission shape | Language surface |
|---|---|---|---|
| 0 | Shortcuts.app / App Intents | User-launched, sandboxed | Shortcuts editor, Swift `AppIntent` |
| 1 | AppleScript / JXA | Apple Events + Automation TCC per target app | `.applescript`, `.scpt`, JXA |
| **1.5** | **[ASObjC](https://github.com/esaruoho/apple/blob/main/wiki/concepts/asobjc.md)** | Same as AppleScript | `.applescript` that calls Cocoa classes |
| 2 | Automator | Same as #1, GUI wrapper | `.workflow` |
| 3 | NSUserScriptTask | Sandboxed app dispatching a script | Swift / ObjC |
| 4 | XPC services | Per-service entitlement | [2,359 services mapped](https://github.com/esaruoho/apple/blob/main/wiki/concepts/xpc-atlas.md) |
| 5 | Tier-5-dark apps | No public scripting interface | [3 backdoors](https://github.com/esaruoho/apple/blob/main/wiki/concepts/tier-5-backdoor.md) |
| 6 | sdef parsing | Read app's own scripting dictionary | YAML extraction → [68 dictionaries](https://github.com/esaruoho/apple/blob/main/dictionaries/INDEX.md) |
| 7 | Accessibility (AX) | Accessibility TCC | `AXUIElement`, System Events |
| 8 | Carbon Event Manager | None for global hotkeys | `RegisterEventHotKey` |
| 9 | IOKit | Kernel | C |
| 10 | Apple Foundation Models | On-device, no TCC | Swift `LanguageModelSession` |

[Full coverage matrix + the missing-tier postmortem in `wiki/concepts/automation-tiers.md`](https://github.com/esaruoho/apple/blob/main/wiki/concepts/automation-tiers.md).

## Why ASObjC matters

Most macOS automation guides skip ASObjC because it has no distinct permission boundary (it runs as `osascript`, same TCC entitlements as a plain AppleScript). But it changes what you can *write* — suddenly your `.applescript` file can call `NSFileManager`, `NSURL`, `NSMetadataQuery`, `NSAppleScript`, any public Cocoa class. The [`tag-asobjc.applescript`](https://github.com/esaruoho/apple/blob/main/bin/tag-asobjc.applescript) demo shows it tagging files via direct xattr writes, no shell-out.

If you've been writing AppleScript for years and never touched ASObjC, [read this](https://github.com/esaruoho/apple/blob/main/wiki/concepts/asobjc.md) before your next script.

## Pre-flight: probe before you name a class

[`bin/cocoa-class-probe NSXxxx`](https://github.com/esaruoho/apple/blob/main/bin/) checks whether a Cocoa class is public, deprecated, or private. ASObjC scripts that name a private class will fail silently. Always probe first. ([Why this rule exists.](https://github.com/esaruoho/apple/blob/main/wiki/concepts/asobjc.md))

---

[← Back to home](./) | [Triggers ←](./triggers) | [Sal corpus →](./sal-corpus) | [Trigger→worker chassis →](./chassis)
