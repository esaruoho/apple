---
title: Vocal Shortcuts Import Runbook — Sal CitrusPeel commands on Apple Silicon Sequoia
date: 2026-05-07
for: Phase 3.5 of the WWDC 2016 session 717 replication plan
---

# Why this runbook exists

macOS Sequoia replaced the Enhanced Dictation Commands runtime that powered Sal's
CitrusPeel installer with **Vocal Shortcuts** (Apple Silicon only). Vocal Shortcuts
is configured exclusively through System Settings UI; Apple has not exposed a
programmatic API to add entries (as of macOS 15.6.1). This runbook walks the manual
import path with the System Events UI helper as an optional accelerator.

# Pre-requisites

- [ ] **Apple Silicon Mac.** Vocal Shortcuts is unavailable on Intel Macs.
- [ ] **macOS 15.0 or later.**
- [ ] All 588 Sal Shortcuts imported into Shortcuts.app via:
  ```
  python3 bin/dictation-commands-to-shortcuts.py     # writes 588 specs
  python3 bin/shortcut-gen.py shortcuts/sal-dictation/specs/   # signs the .shortcut files
  bash bin/batch-import.sh                            # imports into Shortcuts.app
  ```
- [ ] Sal's 18 `.scptd` libraries installed at `~/Library/Script Libraries/` via
  `bash bin/dictation-commands-install.sh` (the install script's library-copy step
  is still functional on Sequoia; only the legacy plist step is deprecated)
- [ ] TCC consent granted: System Settings → Privacy & Security → Accessibility,
      Automation, Photos, Camera (per app pair as required by the helper apps)

# Manual import (the safe path)

1. **System Settings** → **Accessibility** → **Speech** → **Vocal Shortcuts** → **Set Up**
2. Click **+** (Add Vocal Shortcut)
3. Type the spoken phrase (e.g. `Take my picture`)
4. Train the phrase by saying it three times when prompted
5. Choose **Run Shortcut** as the action, then pick the matching Shortcut from Shortcuts.app
6. Save
7. Repeat for each desired phrase

Total bindings to import (full Sal catalog): **596**.

Most users will not want all 588. Sensible subsets:

- **Demo subset (the WWDC 717 demo flow, ~30 phrases)** — the exact phrases from
  `sources/sal/wwdc2016-session-717/717-transcript.txt` lines 277–475.
- **Top-100 by category** — pick the most-used 10 commands per scope (10 × 10 categories).
- **Triple-channel earners** — the 73 workflows from `analysis/sal/seven-purpose-audit.md` that
  scored 3+ on Sal's seven-purpose framework.

# Accelerated import via UI scripting

`bin/vocal-shortcuts-ui-import.applescript` is a System Events helper that walks the
Vocal Shortcuts UI and clicks through each binding. Caveats:

- Apple changes Accessibility UI element paths between macOS releases. The helper
  contains commented placeholder paths — use Accessibility Inspector to recover the
  correct paths for your macOS version, then uncomment.
- Vocal Shortcuts requires the user to **say the phrase three times** to train
  recognition. UI scripting cannot speak — you still have to physically say each
  phrase. The helper pauses for you between bindings.
- If UI scripting drifts mid-import, abort with **Cmd-.** and fall back to manual.

# What if I'm not on Apple Silicon

Use **Voice Control** instead. Voice Control supports Intel + Apple Silicon. The
trade-off is that Voice Control is a heavier UI mode (it shows numbers / grid /
commands continuously) versus Vocal Shortcuts which is purely on-demand. Path:

- System Settings → Accessibility → Voice Control → ON
- Voice Control Commands… → + → Custom command → Phrase + Action: Run Shortcut

The same 588 Shortcuts catalog applies. The UI helper would need a different element
path tree but the principle is identical.

# Verifying

After importing 1–3 bindings as a smoke test:

- Trigger Vocal Shortcuts (typically the Vocal Shortcuts indicator in the menu bar
  must be active)
- Speak one of the trained phrases
- The bound Shortcut should run; the Shortcut's `Run AppleScript` action should call
  `tell script "DC-XXX" to handlerName()` against the installed library
- The expected app action should occur (e.g. `Take my picture` → camera capture)

If the Shortcut runs but the AppleScript fails with a TCC error, recheck Privacy &
Security → Automation for the offending app pair.

# Status

This is the canonical Phase 3 trigger surface on Sequoia. The legacy Phase 3 Path A
(`bin/dictation-commands-install.sh` plist step) is **deprecated** as a trigger path —
the same script's library-copy and helper-copy steps remain useful as the install
backbone for the Vocal Shortcuts route described above.