---
description: Open AppleToolbox in --live mode — a borderless always-on-top floating viewport that mirrors the menu's live-status rows (climate, battery, disk, Wi-Fi, Mail, Music, Whisp). Hot-reloads itself when topbar/AppleToolbox.swift is saved: stat-poll → build.sh → execv. The viewport IS the design surface — edit Swift, watch it rebuild in ~1-2 sec. Usage `/topbar-live`.
allowed-tools: Bash
argument-hint: (no args)
---

Launch AppleToolbox in live-viewport mode. Safe to re-run; raises the
existing window if one is already up.

Use Bash to execute (one call, then stop):

```
bash /Users/esaruoho/work/apple/topbar/scripts/live.sh
```

After the command completes, confirm the viewport is up
(`pgrep -f "AppleToolbox --live"`) and remind the user that ANY save to
`topbar/AppleToolbox.swift` will trigger a rebuild + relaunch within
~1-2 sec. No further LLM roundtrip needed during design.
