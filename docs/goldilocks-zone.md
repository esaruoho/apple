---
layout: default
title: "The Goldilocks Zone — Respect The User's Current State"
---

# The Goldilocks Zone — Respect The User's Current State


[← Back to home](./)
**Universal principle for every action in this skill.** Before any
action mutates macOS state — launching an app, opening a scan dialog,
re-arranging windows, switching audio routing, writing to an exporter
vault — **check the current state first and adapt.** The user has set
their machine up in a specific way right now (windows arranged, apps
scanning data, audio routed, focus on a pane). That arrangement *is*
the user's working state. Re-launching what's running, re-scanning
what's being read, re-arranging what's already positioned, are all
forms of destruction even when the new state is also "valid".

Sal's "the power of the computer should reside in the hands of the one
using it" implies a corollary: **the state of the computer is the
user's state, not ours to reset.** The apple skill *continues* the
user's workflow, never *replaces* it. AppleToolbox, Loupedeck bindings,
Vocal Shortcuts, slash commands — all of them are augmentations to the
goldilocks zone, not resets of it.

**The canonical pattern (encode in helpers, not callers):**

```bash
# Inside topbar/scripts/<app>-scan-folder.sh
if pgrep -x "<AppName>" > /dev/null; then
    # Already running — just bring it to focus; preserve its state.
    osascript -e 'tell application "<AppName>" to activate'
    exit 0
fi
# Cold launch: do the full setup (open + UI-scripted Cmd+Shift+G + path).
```

By encoding the state-check inside the helper, every trigger surface
that calls the helper (AppleToolbox icon, menu-bar item, Loupedeck
key, Vocal Shortcut, slash command) inherits the goldilocks behavior.
Never put `open -a <App>` directly into a button without the pgrep
guard — `open -a` re-fires the app's launch flow (open dialog,
scan-on-open, applicationOpenUntitledFile) even when the app is
already running.

**Apply this to:** launching apps (activate vs open), modal triggers
(don't open Scan/Import on top of an in-progress one), window
arrangement (no-op when already positioned), audio routing (verify
current device before switching), exporter writes (default to
incremental, never overwrite without explicit flag), Mosaic snapping
(filter by current screen — already done), and any future verb.

Codified 2026-05-21 — see `~/.claude/projects/-Users-esaruoho-work-apple/memory/feedback_goldilocks_zone_principle.md`.
