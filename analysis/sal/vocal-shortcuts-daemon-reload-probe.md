---
title: Vocal Shortcuts — daemon reload probe (runbook)
date: 2026-05-11
status: runbook — not yet executed; results when complete will overwrite this file
related:
  - analysis/sal/vocal-shortcuts-storage-format.md
  - analysis/sal/vocal-shortcuts-plist-write-firing-test.md
---

# Goal

Determine what signal — if any — the System Settings UI sends when the user
adds, edits, or deletes a Vocal Shortcut, that a raw plist write does NOT.

If we can identify and reproduce that signal, we can install Vocal Shortcut
*bindings* purely via `defaults write` and a follow-up nudge, without UI
scripting. Whether the daemon will *fire* such an entry without trained
audio is a separate question handled in
`vocal-shortcuts-plist-write-firing-test.md`.

# Hypothesis

The Add flow in System Settings:
1. Writes the new entry into `AVSPreferenceKey` (binary plist blob).
2. Notifies `assistantd` / `siriinferenced` to reload via either:
   a. a Darwin notification (`notify_post(...)`),
   b. an XPC message to a known service name,
   c. a direct `cfprefsd` cache-flush + filesystem watch,
   d. nothing — the daemon polls on a timer.

Of these, (a) and (b) are interception targets. (c) is invisible to us
(internal to cfprefsd). (d) means we can write the plist and just wait.

# Procedure

Open three terminal windows.

**Terminal 1 — Watch filesystem activity:**

```bash
sudo fs_usage -w -f filesystem assistantd siriinferenced cfprefsd \
  2>/dev/null | grep -i "Accessibility\|VocalShortcut\|AVS"
```

**Terminal 2 — Watch logs (Siri / Accessibility subsystem):**

```bash
log stream --predicate '
  subsystem CONTAINS[c] "siri" OR
  subsystem CONTAINS[c] "assistant" OR
  subsystem CONTAINS[c] "accessibility" OR
  eventMessage CONTAINS[c] "vocalshortcut" OR
  eventMessage CONTAINS[c] "AVSPreference"
' --info --debug
```

**Terminal 3 — Watch Darwin notifications:**

```bash
# Requires installing notifyutil to listen on a wildcard.
# Without it, we can at least confirm specific names if a hypothesis emerges:
notifyutil -1 com.apple.Accessibility.VocalShortcutsDidChange
# (returns immediately if not registered; runs if it IS)
```

If `notifyutil` isn't installed, fall back to:

```bash
# List all Darwin notifications the suspect daemons are subscribed to:
sudo lsof -p $(pgrep -f assistantd) 2>/dev/null | grep -i notify
sudo lsof -p $(pgrep -f siriinferenced) 2>/dev/null | grep -i notify
```

# Acts to perform while watching

1. **Add** a test Vocal Shortcut via System Settings → Accessibility →
   Speech → Vocal Shortcuts → Add.
   - Expected: write to `com.apple.Accessibility.plist`, possibly notify.
2. **Wait 30 seconds** — to detect any polling-driven pickup.
3. **Edit** the entry (change the phrase or action).
   - Expected: similar write + notify pattern.
4. **Delete** the entry.
   - Expected: write + notify.

For each act, snapshot what fires in T1 + T2 + T3 to a per-act log.

# What to look for

- **Notification names** containing "VocalShortcut", "AVS",
  "Accessibility.Speech", or similar. These are reproduction candidates.
- **XPC service names** mentioned in `log` output that the System Settings
  panel talks to. `mach_msg` send/recv pairs in `fs_usage`.
- **`cfprefsd` flush events** on `com.apple.Accessibility.plist` —
  expected, not interesting.
- **Daemon process restarts** (`launchd` respawns) — would indicate the
  reload mechanism is "kill and reread", which we can reproduce with
  `killall -HUP` or `launchctl kickstart`.

# Reproduction test

Once a candidate signal is identified, write a synthetic entry via
`defaults write com.apple.Accessibility AVSPreferenceKey -data <hex>` and
fire only the candidate signal. If the daemon picks up the new entry
without further intervention, the signal is sufficient.

If multiple signals fire on each UI action, bisect: send subsets and find
the minimum required.

# Negative result is also a result

If nothing reasonable fires beyond the plist write, the reload mechanism
is either timer-based (test by waiting 1+ minutes after a `defaults write`
and checking whether the daemon notices) or filesystem-watch-based (test by
verifying the daemon has an open `EVENT` kqueue on the plist directory).

# Write results into

When complete, replace the `status:` line above with `solved:` and append a
"Results" section with: (a) the notification/signal identified, (b) the
minimum reproduction command, (c) any caveats.

# Why this matters

If a signal is identifiable and reproducible, `bin/vocal-shortcuts-install.py`
becomes viable as a non-UI-scripting install path. Combined with the
"does plist-only write produce a fireable trigger" question (separate
runbook), this could collapse the UI-scripting Add-flow code path entirely
— installs would be `defaults write` + `notify_post` and done.
