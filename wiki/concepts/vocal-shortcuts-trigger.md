# Vocal Shortcuts — trigger surface position

> 📖 **Public:** [Trigger surfaces (public)](https://esaruoho.github.io/apple/triggers)

Vocal Shortcuts (macOS 15 Sequoia, **Apple Silicon only**) is the **only** Mac trigger surface that is simultaneously:

- hands-free (no button, no wake-word, just speak)
- offline (on-device Neural Engine matching)
- latency-free (~instant)
- UUID-stable across Shortcut renames

Every other voice path fails one of those: "Hey Siri" needs the wake-word and matches by Shortcut **name** (fragile to rename); manual Siri invoke isn't hands-free; Spotlight / hotkey / Loupedeck aren't voice.

## Historical placement

This is the succession of Sal's removed Custom Commands plist runtime (WWDC 2016 session 717, deleted ~10.13/10.14). It's been the missing voice layer for ~5 years; Sequoia reintroduced it under Accessibility branding.

## Storage & schema

**Location** (reverse-engineered 2026-05-07): `~/Library/Preferences/com.apple.Accessibility.plist` → key `AVSPreferenceKey` → bytes containing UTF-8 JSON array.

**Each entry shape:**
```json
{"name": "where is olga",
 "associatedShortcut": {"name": "Find Olga",
   "type": {"siriShortcut": {"id": "<Shortcut UUID from Shortcuts.app>"}},
   "id": "<internal id>"},
 "identifier": "<entry UUID>"}
```

**Three action kinds** the schema supports:
- `siriShortcut` — verified live
- `siriRequest` — free-form Siri call, inferred from UI, not yet captured
- `accessibility` — toggle Voice Control / VoiceOver / Zoom, inferred from UI, not yet captured

Vocal Shortcuts can ONLY trigger Shortcuts (or Siri Requests / Accessibility primitives), not arbitrary AppleScript. The full wiring is always: **spoken phrase → Vocal Shortcut → Shortcut → Run AppleScript action → DC-XXX library handler**.

## Read vs write

- **Read** is verified working (`bin/list-vocal-shortcuts.py`).
- **Write** programmatically is theoretical — the daemon reads the plist but each phrase requires manual user training (saying it 3×). UI scripting via `bin/vocal-shortcuts-ui-import.applescript` is the practical write path.

## The training bottleneck — and the project ceiling

Each phrase must be trained by speaking it three times via System Settings UI. There is no public API to install trained-audio models programmatically. **This is the only hard wall in the stack** — read, coverage, schema, plist-write are all solved or solvable; training is not. Every architectural decision should be evaluated against *"does this reduce the training-utterance count?"*

## Router-pattern math — 588×

Direct binding of Sal's 588 CitrusPeel phrasings would require 588 × 3 = **1,764 manual training utterances**. The single-phrase router (`"Hey Sal"` → matcher → N targets) collapses this to 1 × 3 = **3 utterances**. Three orders of magnitude. This is why the router is not a polish item — it's the only path that scales. The 2026-05-08 Hey Sal v1 deployment is the working implementation; matcher at `bin/sal-siri-match.py`.

## Tooling

- **`bin/list-vocal-shortcuts.py`** — read the current entries.
- **`bin/vocal-shortcuts-suggest.py`** — joins `AVSPreferenceKey` ↔ `~/Library/Shortcuts/Shortcuts.sqlite` (`ZSHORTCUT.ZWORKFLOWID` is the UUID match) ↔ `analysis/sal/seven-purpose-audit.md`. Reports orphans (binding points at missing Shortcut), drift (cached name ≠ live name; cosmetic only since binding is UUID-stable), and suggestions (Shortcuts with no Vocal binding). `--audit-only` fuzzy-filters to triple-channel audit candidates. `--write` emits markdown to `analysis/sal/vocal-shortcuts-coverage.md`. `--fix-drift` rewrites `AVSPreferenceKey` to repair cached names. Coverage as of 2026-05-11: **2/278 Shortcuts bound**, 0 orphans, 0 drift, 39 audit-matched candidates ready for binding.
- **`bin/vocal-shortcuts-router-verify.py`** — runs the 39 audit-matched candidates through `bin/sal-siri-match.py` to confirm the Hey Sal router resolves each one without retraining. First run (2026-05-11): **38/39 full-match**, 1 partial (`system-events-hide-dock` — matcher quirk where the prefix "show me" outweighs the antonym "hide").
- **`bin/capture-vocal-shortcut-schemas.py`** — walks the user through adding one test entry of each unobserved action kind via System Settings, captures Apple's JSON output via plist polling, writes shapes to `analysis/sal/vocal-shortcuts-captured-schemas.json`.

## How to apply

- When planning Sequoia-era voice triggers for the 588 CitrusPeel commands or the 73 triple-channel audit candidates, default to Vocal Shortcuts — NOT "Hey Siri + Shortcut name match", which breaks on rename and needs the wake-word.
- Capture an example of the latter two action kinds when the opportunity arises to lock down the schema.
- Apple Silicon only — Intel Macs have no Vocal Shortcuts surface; pipeline must noop or substitute Spotlight / hotkey on Intel.

## Open experiments

- `analysis/sal/vocal-shortcuts-daemon-reload-probe.md` — what signal does the System Settings UI fire on add/edit/delete?
- `analysis/sal/vocal-shortcuts-plist-write-firing-test.md` — does a plist-only write produce a fireable trigger, or just orphaned metadata?

## See also

- Comparative matrix: `analysis/sal/vocal-shortcuts-in-the-trigger-stack.md`
- Schema reference: `analysis/sal/vocal-shortcuts-storage-format.md`
