---
title: Vocal Shortcuts — does plist-only write produce a fireable trigger? (runbook)
date: 2026-05-11
status: runbook — not yet executed
related:
  - analysis/sal/vocal-shortcuts-storage-format.md
  - analysis/sal/vocal-shortcuts-daemon-reload-probe.md
---

# Goal

Answer the single biggest unknown in the Vocal Shortcuts stack:

**If we write a new entry into `AVSPreferenceKey` via `defaults write` —
binding metadata only, with no trained-audio model — will the assistant
daemon fire the spoken phrase, or will it refuse?**

Three possible outcomes:

1. **Refuse.** Daemon requires a matching trained-audio fingerprint and
   silently drops phrases it can't match. Plist-only install is metadata
   only; the user must still train.
2. **Fire loosely.** Daemon falls back to generic on-device speech
   recognition when no fingerprint is registered. Plist-only install
   works, possibly with worse recognition accuracy.
3. **Fire identically.** The trained-audio model is not actually required
   for matching — the phrase string in `AVSPreferenceKey` is enough.
   (Unlikely but possible if Apple uses on-device ASR universally.)

If (3) — Vocal Shortcuts installs become trivial scripting.
If (2) — installs work but with degraded accuracy. Still huge.
If (1) — back to UI scripting / router pattern.

# Procedure

## Step 1 — Establish a working baseline

Manually train one phrase (call it phrase X) bound to Shortcut Y via System
Settings. Verify it fires: speak the phrase, confirm Shortcut Y runs.

## Step 2 — Snapshot AVSPreferenceKey

```bash
python3 bin/list-vocal-shortcuts.py --json > /tmp/vs-baseline.json
```

Identify the new entry's `identifier` UUID. Call it `ENTRY_ID_X`.

## Step 3 — Delete only the entry, keep the trained audio in place

Edit the plist JSON to remove the entry with `identifier == ENTRY_ID_X`,
re-encode as bytes, write back via:

```bash
# (helper script — write_avs_preference_key.py — to be added)
python3 bin/avs-prefs-write.py --remove-id ENTRY_ID_X
```

(The script doesn't exist yet — building it is part of this experiment.
It must encode the JSON as UTF-8 bytes and inject via the plistlib +
`defaults import` path, then `killall -HUP cfprefsd` to flush.)

After the write, confirm:
```bash
python3 bin/list-vocal-shortcuts.py | grep -v "phrase X"
```

The entry is gone. **Speak phrase X.** Does it still fire?

- **Yes** → trained audio alone is sufficient; plist entry is just metadata
  the daemon doesn't need to match. Interesting and unexpected.
- **No** → daemon consults `AVSPreferenceKey` at recognition time, not just
  at training time. Confirms binding metadata is load-bearing.

## Step 4 — Reinsert the entry by plist write only

Without retraining: write the original entry back to `AVSPreferenceKey` via
the helper script. The trained-audio model from step 1 is still on disk
(in `siriinferenced`'s container, untouched). The binding metadata is
restored.

**Speak phrase X.** Does it fire?

- **Yes** → result is (3) or (2): plist + existing trained audio is enough.
  This is the "trained audio is universal — it doesn't need a fresh binding
  to be re-installed" outcome.
- **No** → daemon needs more than the plist write to reload its binding
  state. Try `killall -HUP assistantd siriinferenced` between write and
  speech. If that makes it fire, the daemon-reload-probe runbook gives us
  the production signal.

## Step 5 — Try a NEW phrase that was never trained

Use the helper to inject a new entry into `AVSPreferenceKey` for phrase Z
(never spoken before) → some other Shortcut. **Speak phrase Z.**

- **Fires** → outcome (2) or (3). Generic on-device ASR is the matcher.
  This is the big win — installs need only a plist write.
- **Doesn't fire** → outcome (1). The trained-audio fingerprint is
  mandatory and unavailable for unspoken phrases. Router pattern remains
  the only scaling path.

## Step 6 — Test with a near-homophone

If Step 5 succeeds (any outcome with firing): try a phrase Z that is close
to but not identical to phrase X — does the matcher tolerate variation, or
require exact transcription match?

This calibrates how "loose" the fallback recognition is. Loose = easier
authoring; strict = phrasings must be exact.

# What to do with each outcome

| Outcome | Project consequence |
|---|---|
| 1. Refuse | Router pattern is the only scaling path. UI scripting for any direct binding. Status quo. |
| 2. Fire loosely | New tool: `bin/install-vocal-shortcut.py` that does `defaults write` + `killall -HUP` and warns about accuracy. |
| 3. Fire identically | Same tool, but no accuracy caveat. Vocal Shortcuts installs become a build-time concern, no user training needed. |

# Why this is in a runbook, not a script

The experiment must be performed by hand (someone has to speak phrases X
and Z) and observed live. Encoding it as a script would be over-engineering.

A helper — `bin/avs-prefs-write.py` — IS worth scripting because the binary
plist round-trip is fiddly. That helper does not exist yet; building it is
the first non-trivial work item if you decide to run this experiment.
