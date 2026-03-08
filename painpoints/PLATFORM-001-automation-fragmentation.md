# PLATFORM-001: macOS Automation Is Splintered Across Five Incompatible Layers

**App:** macOS (platform-wide)
**Intent:** Automate any Apple app through a single, coherent system
**Severity:** Architectural — the automation surface is fractured across five layers built over 40 years, with no unification
**Status:** Open
**Filed:** 2026-03-08

---

## The Friction

There is no single way to automate macOS. Instead, there are five incompatible automation layers, built by different teams across different decades, with different protocols, different access models, and no shared surface.

A user who wants to automate "turn off Wi-Fi, start a playlist, and set Do Not Disturb" must use:
- **System Events** (AppleScript via Apple Events) for Wi-Fi
- **Music.app** (AppleScript via Apple Events) for the playlist
- **Shortcuts** (App Intents via XPC/siriactionsd) for Do Not Disturb

Three actions. Two protocols. Two permission systems. Zero coherence.

---

## The Timeline: How It Got This Way

| Year | Event | Impact |
|------|-------|--------|
| **1993** | Apple Events + AppleScript ship in System 7 | Clean model: one language, one protocol, apps publish sdef dictionaries |
| **2005** | Automator ships in Tiger | Visual wrapper around AppleScript. Still Apple Events. Still clean. |
| **2007** | iPhone ships | Apple's attention shifts to iOS. macOS automation team shrinks. |
| **2012** | App Sandboxing (Mountain Lion) | Apple Events now need TCC permission. Automation starts breaking. |
| **2014** | XPC replaces internal app plumbing | Apps split into thin GUI + background XPC daemon. The sdef talks to the GUI, but the daemon does the work. Automation can't reach the daemon. |
| **2016** | Sal Soghoian's position eliminated | No one champions automation at Apple anymore. The last person whose job was "make sure users can automate everything" is gone. |
| **2018** | Shortcuts arrives from iOS | Completely separate system. Doesn't use Apple Events. Doesn't use sdef. Uses App Intents (Swift) dispatched via siriactionsd over XPC. A parallel universe. |
| **2020+** | New apps skip sdef entirely | System Settings (rewritten in SwiftUI), Freeform, Journal — no scripting dictionary at all. Only App Intents, if anything. The XPC backends exist but are invisible. |
| **2024** | Sequoia hardens XPC further | SIP protects all /System/Applications/ binaries. Audit tokens required for all XPC connections. The "dark" layer gets darker. |

---

## The Five Layers

| Layer | Era | Protocol | Access | Who Maintained It |
|-------|-----|----------|--------|------------------|
| **AppleScript / sdef** | 1993 | Apple Events | Open (TCC since 2012) | Sal Soghoian (fired 2016) |
| **Automator** | 2005 | Apple Events | Open | Sal Soghoian (fired 2016) |
| **XPC daemons** | 2014 | Mach IPC | Entitlement-gated | Internal engineering (not user-facing) |
| **Shortcuts / App Intents** | 2018 | XPC via siriactionsd | Open (limited) | Shortcuts team |
| **Private frameworks** | Various | Objective-C/Swift | SIP-protected | Internal engineering |

### What each layer can and can't do:

**AppleScript (Tier 1):** 31 apps have scripting dictionaries. Can read and write data, trigger commands. But new apps don't add sdef support. System Settings has 3 commands. Preview has zero.

**Automator (Tier 2):** Deprecated. Apple stopped updating it. Still works but receives no new actions. Cannot access App Intents.

**XPC daemons (Tier 5-6):** 2,359 services. This is where the real work happens. System Settings delegates to `systemsettingsagent`. HomeKit runs through `homed.xpc`. Photos uses `photolibraryd`. But these are internal — no public API, no documentation, gated by entitlements.

**Shortcuts / App Intents (Tier 2):** The "replacement" for Automator. But it's Swift-only (no scripting language), actions are developer-opt-in, and it can't do anything the app developer didn't explicitly expose. No "Run AppleScript" equivalent was available until macOS 12+ (and it's hidden behind Advanced > Allow Running Scripts).

**Private frameworks (Tier 7):** The nuclear option. Reverse-engineer the framework, call it from injected code. Requires SIP disable. Not a real automation solution.

---

## The Numbers

| Metric | Count |
|--------|------:|
| Apps with AppleScript sdef | 31 |
| Apps with App Intents | 20 |
| Apps with URL schemes | 35 |
| XPC user-session services | 1,519 |
| XPC system daemons | 840 |
| **Total XPC services** | **2,359** |
| Percentage exposed via sdef | ~5% |
| Percentage exposed via App Intents | ~8% |
| Percentage completely hidden | ~87% |

Apple exposes roughly 13% of macOS automation capability through public APIs. The other 87% is locked in XPC services that have no public interface.

---

## What Sal Would Say

Sal's Principle #1: **"The power of the computer should reside in the hands of the one using it."**

The power is still there — 2,359 XPC services prove it. But it no longer resides in the hands of the user. It resides in five incompatible layers, three of which are invisible, one of which is deprecated, and one of which requires a Swift developer to add support.

Sal's Principle #6: **"Use the whole toolkit."** The toolkit is fractured. AppleScript can't call App Intents. Shortcuts can't read sdef dictionaries. Neither can talk to XPC daemons. Automator is abandoned. There is no whole toolkit anymore.

Sal's Principle #7: **"Think in workflows."** A workflow that spans multiple apps must now span multiple automation layers. Each layer has different permissions, different syntax, different capabilities. The friction isn't in any single step — it's in the seams between layers.

---

## The Bridge This Repo Builds

The [Apple Automation Atlas](../README.md) is an attempt to bridge across all five layers:

| Tool | Layers Covered |
|------|---------------|
| `sdef-extract.py` | Tier 1: AppleScript dictionaries |
| `app-probe.py` | Tiers 1-4: sdef, App Intents, URL schemes, CLI |
| `workflow-gen.py` | Tier 1: AppleScript workflow scripts |
| `spotlight-export.sh` | Bridge: AppleScript → Spotlight |
| `shortcut-gen.py` | Bridge: AppleScript → Shortcuts/Siri |
| `xpc-probe.py` | Tiers 5-6: XPC service enumeration |

The pipeline doesn't fix the fragmentation. It routes around it.

---

## Fix Paths

1. **Apple (ideal):** Unify the automation surface. One protocol, one permission model, one way for apps to declare "here's what I can do." App Intents is the closest candidate, but it needs to subsume AppleScript's power, not replace it with less.

2. **Apple (incremental):** Require sdef or App Intents for every first-party app. Today, System Settings, Preview, Home, and dozens of others ship with no automation surface at all. Apple's own apps don't follow Apple's own guidelines.

3. **Apple (minimum):** Stop deprecating without replacing. Automator is deprecated but Shortcuts can't do everything Automator could. AppleScript is unmaintained but nothing replaces its ability to inspect and modify app state.

4. **Community (workaround):** Build bridges like this repo. Extract what each layer exposes, generate scripts that work across layers, and make them reachable from Spotlight, Siri, and physical controllers.

5. **Research (long-term):** Reverse-engineer XPC protocols for critical services. Build an open-source XPC bridge tool that makes the hidden 87% accessible through a scripting interface.

---

*Part of the [Apple Automation Atlas](../README.md).*

**Filed by [@esaruoho](https://github.com/esaruoho)** — software tester, UI enthusiast, amateur scripter, automation/workflow obsessive, and user experience evaluator.
