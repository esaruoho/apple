---
layout: default
title: "Hardware Controller Integration"
---

# Hardware Controller Integration


[← Back to home](./)
Any programmable controller (Loupedeck Live, Stream Deck, Contour Shuttle Pro, etc.) that can run shell commands works with these scripts:

```bash
osascript /path/to/script.scpt
# or inline:
osascript -e 'tell application "Finder" to activate'
# or Shortcuts:
shortcuts run "Shortcut Name"
```

For hardware-triggered scripts:
- **Fast** — no unnecessary delays
- **Reliable** — handle edge cases (app not running, etc.)
- **Single-purpose** — one button = one action
