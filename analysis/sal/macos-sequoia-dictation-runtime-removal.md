---
title: macOS Sequoia removed the Enhanced Dictation Commands runtime
date: 2026-05-07
host: macOS 15.6.1 (Sequoia), Build 24G90
status: Confirmed by direct probe — the legacy plist path is gone
impact: Phase 3 Path A of the session-717 replication plan is broken on Sequoia. Phase 3.5 (Vocal Shortcuts importer) is now the canonical trigger surface.
---

# What changed

Sal's CitrusPeel installer (November 2016) writes a single plist to:

```
~/Library/Preferences/com.apple.speech.recognition.AppleSpeechRecognition.CustomCommands.plist
```

This plist was read by macOS's **Enhanced Dictation Commands** runtime — the engine Sal walks through across the four-tier model in WWDC 717 lines 11–19 (Dictation → Enhanced Dictation → Advanced Commands → User Commands). The runtime matched a spoken phrase to a plist entry and ran the embedded AppleScript text, which dispatched to one of the 18 `.scptd` libraries.

**On macOS 15.6.1 (Sequoia), the plist path does not exist.** Direct probe:

```
$ ls ~/Library/Preferences/com.apple.speech.recognition.AppleSpeechRecognition.CustomCommands.plist
ls: ... No such file or directory
$ ls ~/Library/Preferences/ | grep -iE "speech|dictation"
com.apple.speech.recognition.AppleSpeechRecognition.prefs.plist  ← legacy general dictation prefs only
com.apple.speech.voice.prefs.plist
com.apple.SpeechRecognitionCore.plist
```

The legacy general-dictation prefs survive (mic name, last dictation date, language identifier). The **custom-commands plist is gone**, and the four-tier model Sal teaches in 717 has collapsed:

| Sal's 717 tier (June 2016) | Sequoia state (2026) |
|---|---|
| **Tier 1 — Basic Dictation** | Survived. System Settings → Keyboard → Dictation. Cloud-only at default; on-device for some languages. |
| **Tier 2 — Enhanced Dictation** | **REMOVED.** Sal's offline-continuous-with-edit-suites tier no longer exists as a distinct toggle. Edit-and-navigate-by-voice abilities migrated to Voice Control. |
| **Tier 3 — Advanced (Dictation) Commands** | **REMOVED.** "Show numbers" and Sal's UI-control voice commands migrated to Voice Control (System Settings → Accessibility → Voice Control). |
| **Tier 4 — User Commands** | **REMOVED in form, RESHAPED in function.** The "secret plus button" Sal demonstrated (line 196) is gone. The closest replacement is **Voice Control → Commands…** plus the new **Vocal Shortcuts** (Apple Silicon only). |

# The replacement surface

Apple's current Mac voice-automation surface, post-removal:

1. **Voice Control** (Intel + Apple Silicon) — `System Settings → Accessibility → Voice Control`. Inherits Tier 3 (UI control: "show numbers", "click parchment") plus a custom-command builder that's a slimmed version of Tier 4. Stores config in `com.apple.SpeechRecognitionCore.plist` and elsewhere — not at the legacy CustomCommands.plist path.
2. **Vocal Shortcuts** (Apple Silicon only) — `System Settings → Accessibility → Speech → Vocal Shortcuts`. New in macOS 15. Each entry is `phrase → action`, where action is one of: a Shortcut from Shortcuts.app, a Siri call, or an accessibility primitive. **Audio is processed on-device.** This is closest in spirit to Sal's Tier 4.
3. **Siri Shortcuts phrases** — built into Shortcuts.app since macOS 12. Each Shortcut can have a "Run with Siri" phrase. The Vocal Shortcuts mechanism is a thin wrapper over this.
4. **Siri proper** — Apple Intelligence-enabled in 2024+. Conversational, LLM-routed. Can dispatch to App Intents but is not a user-programmable command surface in Sal's sense.

# What still works from Sal's stack

The 18 `.scptd` AppleScriptObjC libraries (`DC-Keynote.scptd`, `DC-Photos.scptd`, etc.) **still run on Sequoia.** They are ordinary AppleScript libraries — copy them to `~/Library/Script Libraries/`, call `tell script "DC-Keynote" to <handler>()` from any AppleScript context, and they execute against current Keynote / Photos / Numbers (modulo the Phase 2 port-audit drift items). The libraries are the durable layer.

What changed is the **trigger surface** above them. The runtime that turned spoken phrases into AppleScript calls has been redistributed across Voice Control + Vocal Shortcuts + Shortcuts + Siri. To replicate session 717 on Sequoia, you keep Sal's libraries and rewire the trigger surface.

# The replication consequence

The Phase 3 Path A installer (`bin/dictation-commands-install.sh`) writes the legacy `CustomCommands.plist` and is consequently a no-op on Sequoia for the trigger layer. **It still successfully installs the 18 libraries and 5 helpers** — which is real, durable value — but the spoken-phrase wiring it sets up does nothing because no daemon reads that plist anymore.

**Path A is now deprecated as a complete replication path.** It remains useful as a "library installer" (steps 1–3 of the script: copy libraries, copy helpers, build prefs) — but step 4 (install Custom Commands.plist) is a fossil. The marker stays in the script as historical record + a clear warning at runtime.

**Path B (Shortcuts spec generator) is now the canonical trigger surface.** Each of the 588 `shortcut-specs/*.yaml` becomes a `.shortcut` file imported into Shortcuts.app. Each Shortcut's "Run with Siri" phrase is exactly Sal's spoken phrase. On Apple Silicon, that Siri phrase is automatically eligible to be a Vocal Shortcut entry.

**Phase 3.5 — Vocal Shortcuts importer** — bridges Path B's Shortcuts to the Vocal Shortcuts UI. The bridge is unavoidable manual UI work on first import (Apple has not exposed a programmatic API to add Vocal Shortcut entries) — but with a System Events UI-scripting helper, the import can be near-fully automated.

# Reproduction details (for the archive)

```
Probe date:     2026-05-07
Host:           Esa Ruoho's MacBook Pro
macOS:          15.6.1 (24G90)
Architecture:   arm64 / Apple M3 Pro (Vocal Shortcuts available + working — see "where is olga" entry)
```

Apple's Vocal Shortcuts user-guide screenshot (provided by Esa) confirms:

> "Vocal Shortcuts is available only on Mac computers with Apple silicon."
> Path: System Settings → Accessibility → Speech → Vocal Shortcuts
> "Audio is processed on Mac."

# Action items

1. ✅ Document this finding (this file)
2. ✅ Mark Phase 3 Path A as deprecated in the replication plan
3. ✅ Promote Path B (Shortcuts) to canonical trigger surface
4. Build Phase 3.5: `bin/dictation-commands-vocal-shortcuts-import.py` — generates a Shortcuts batch + a System Events UI-scripting helper that walks the Vocal Shortcuts UI to add each phrase
5. Add a runtime warning in `bin/dictation-commands-install.sh` if running on macOS ≥ 15
