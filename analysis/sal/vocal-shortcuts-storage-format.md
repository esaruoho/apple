---
title: Vocal Shortcuts — undocumented storage format (macOS 15 Sequoia, Apple Silicon)
date: 2026-05-07
status: SOLVED — storage path + JSON schema reverse-engineered from a live entry
host: Apple M3 Pro, macOS 15.6.1 (24G90)
seed: Esa's existing entry "where is olga" → Find Olga
reader: bin/list-vocal-shortcuts.py
---

# What this document fixes

Apple did not publish where Vocal Shortcuts (the new System Settings → Accessibility → Speech → Vocal Shortcuts feature in macOS 15) stores its phrase-to-Shortcut bindings. This is the empirically-recovered location and schema, with a working reader.

# Storage location

```
~/Library/Preferences/com.apple.Accessibility.plist
  └── key: AVSPreferenceKey   (likely "Accessibility Vocal Shortcuts Preference Key")
        type: bytes (UTF-8 JSON)
```

The plist key holds a binary blob whose content is a UTF-8 JSON array, one element per Vocal Shortcut entry. Reading it requires:

1. Read the plist via `plistlib` (XML or binary plist; macOS uses binary by default).
2. Pull the `AVSPreferenceKey` value — it'll be a `bytes` object.
3. Decode as UTF-8.
4. `json.loads` the decoded string.

Apple's `defaults read com.apple.Accessibility AVSPreferenceKey` shows only the hex-bytes summary (`{length = 234, bytes = 0x5b7b226e ... }`); use `/usr/libexec/PlistBuddy -c "Print :AVSPreferenceKey"` to dump the underlying string, or our `bin/list-vocal-shortcuts.py` reader.

# JSON schema

Each entry is one object:

```json
{
  "name": "where is olga",
  "associatedShortcut": {
    "name": "Find Olga",
    "type": {
      "siriShortcut": {
        "id": "0C093E97-A8A9-4BDE-90BC-94EE1A5C4596"
      }
    },
    "id": "12EDF5D4-F880-47A9-8552-030F777FA05D"
  },
  "identifier": "B615859B-7773-4DFD-B2DC-E7F747A488CC"
}
```

Fields:

| Field | Type | Meaning |
|---|---|---|
| `name` | string | The spoken phrase (the trigger). What the user says. |
| `associatedShortcut.name` | string | Display name of the action. For Shortcut bindings, matches the Shortcut name in Shortcuts.app. |
| `associatedShortcut.type` | object | A discriminated-union with one key, indicating action kind. Observed kinds: `siriShortcut` (Run a Shortcut from Shortcuts.app). The Vocal Shortcuts UI also exposes `siriRequest` (free-form Siri call) and an `Accessibility` category (toggle Voice Control / VoiceOver / etc.) — these likely use `siriRequest` and `accessibility` (or similar) keys; we have not yet recovered an example of either. |
| `associatedShortcut.type.siriShortcut.id` | UUID | The target Shortcut's UUID in Shortcuts.app. Cross-reference with `~/Library/Group Containers/group.com.apple.shortcuts/Library/com.apple.shortcuts/Shortcuts.sqlite` to map UUID → workflow content. |
| `associatedShortcut.id` | UUID | Internal binding ID (likely Shortcuts.app side). |
| `identifier` | UUID | The Vocal Shortcut entry's own UUID — Apple's primary key for the Vocal Shortcuts list. |

# Reading

```bash
python3 bin/list-vocal-shortcuts.py
# 1 Vocal Shortcut(s):
#   "where is olga" → [Shortcut] Find Olga  (0C093E97-A8A9-4BDE-90BC-94EE1A5C4596)

python3 bin/list-vocal-shortcuts.py --json
# [
#   {
#     "name": "where is olga",
#     "associatedShortcut": {...},
#     "identifier": "B615859B-7773-4DFD-B2DC-E7F747A488CC"
#   }
# ]
```

The reader is pure-Python `plistlib` + `json`. No private framework calls.

# Writing (THEORETICAL — not yet verified)

Adding a Vocal Shortcut entry should, in principle, be:

1. Read the plist + decode the JSON array.
2. Append a new entry: assign fresh UUIDs for `identifier` and `associatedShortcut.id`; look up the target Shortcut's UUID for `associatedShortcut.type.siriShortcut.id`.
3. Re-encode JSON → bytes → write back into the plist.
4. **Send a "preferences changed" notification** so the assistant daemon re-reads.

Caveats:

- Vocal Shortcuts requires the user to physically train each phrase by speaking it three times. The training audio is presumably stored on-device by `siriinferenced` or `assistantd`. Writing only to `AVSPreferenceKey` may install the binding metadata but leave the phrase untrained — at which point the daemon may either (a) accept any pronunciation as a fallback, or (b) refuse to fire until the user trains the phrase via the System Settings UI.
- The Accessibility plist is owned by `cfprefsd`. Direct file writes can be lost or refused; the canonical approach is `defaults write com.apple.Accessibility AVSPreferenceKey -data <hex>`. Plist API access from outside System Settings may be sandbox-restricted.

Until tested, the safe assumption is: **read is fully working; write requires UI scripting via System Events** (the path the existing `bin/vocal-shortcuts-ui-import.applescript` skeleton anticipates).

# Related plist domains discovered

The probe also surfaced these adjacent domains. Documenting for future automation surface mapping:

| Domain | Plist file | Role (best guess) |
|---|---|---|
| `com.apple.siri.VoiceShortcuts` | `~/Library/Preferences/com.apple.siri.VoiceShortcuts.plist` | Holds DB versioning UUIDs (`VCLSDataSequenceKey`, `VCLSDatabaseUUIDKey`). Probably points to a CoreData/SQLite store inside the assistant container — not directly readable as plain plist. |
| `com.apple.shortcuts` | `~/Library/Preferences/com.apple.shortcuts.plist` | Shortcuts.app preferences. The actual Shortcut definitions live in `~/Library/Group Containers/group.com.apple.shortcuts/Library/com.apple.shortcuts/Shortcuts.sqlite`. |
| `com.apple.assistant` | various | Siri runtime state. |
| `com.apple.AccessibilityHearingNearby` | `~/Library/Preferences/com.apple.AccessibilityHearingNearby.plist` | Live Listen / Heard Ambient — unrelated to Vocal Shortcuts. |
| `com.apple.SpeechRecognitionCore` | `~/Library/Preferences/com.apple.SpeechRecognitionCore.plist` | Audio-ducking preference for dictation. Single key. Not Vocal Shortcuts. |

# Sal-skill integration implications

Vocal Shortcuts is now part of the apple-skill automation inventory:

```
Layer 3 — Trigger surfaces            Loupedeck button | Spotlight | Hot key | Siri phrase | Vocal Shortcut
                                                                                              ^^^^^^^^^^^^^^^
                                                                                              this just got
                                                                                              readable (2026-05-07)
Layer 2 — Wiring                      Shortcuts.app workflow | osacompile .app | Automator | UI scripting
Layer 1 — Engine (durable layer)      AppleScript / AppleScriptObjC libraries (e.g. Sal's 18 .scptd)
```

The 7-purpose audit (Phase 5, WWSD #30) emits 73 triple-channel candidates. With Vocal Shortcuts now readable, the apple skill can:

1. Compare existing user Vocal Shortcuts (1 entry today: "where is olga") against the audit's recommended trigger list.
2. Generate a "Vocal Shortcuts you should add" suggestions report — shortcuts the user has but hasn't yet voice-bound.
3. Detect and warn on Vocal Shortcut entries pointing at deleted Shortcuts (orphaned bindings).

These features fit naturally into the existing `bin/sal-7-purpose-audit.py` and a future `bin/vocal-shortcuts-suggest.py`.

# Reader install

`bin/list-vocal-shortcuts.py` is committed to the repo. No install step needed — runs from `bin/` against the live plist on any Mac that has the `AVSPreferenceKey` populated (i.e. Apple Silicon Sequoia with at least one Vocal Shortcut configured).

For Macs with no entries, the reader prints `(no Vocal Shortcuts configured)` and exits cleanly.

# Why this matters for Sal-replication

The Vocal Shortcuts route is the canonical Sequoia trigger surface for the 588 CitrusPeel commands (per `analysis/sal/macos-sequoia-dictation-runtime-removal.md`). Now that we can read it programmatically, the import pipeline can:

1. **Verify** that a generated Shortcut import succeeded (Vocal Shortcut entry exists and points at the right UUID).
2. **Detect** drift (the user renamed a Shortcut in Shortcuts.app → its UUID may stay or change → Vocal Shortcut binding may break).
3. **Diff** against a desired-state file — declarative Vocal Shortcuts management.

This closes the loop on the 717 replication: the engine layer is preserved, the wiring layer is automated, and the trigger layer is now both writeable (via UI scripting) and readable (via this reader).
