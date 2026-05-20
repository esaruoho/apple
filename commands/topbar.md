---
description: Install + launch the SwiftBar Apple Toolbox in the macOS menu bar. One unified status item — HomePod climate + Sal archive + battery + click-to-run actions (Stop Voicebox, Empty Trash, audio, Finder). Usage `/topbar`.
allowed-tools: Bash
argument-hint: (no args)
---

Install + launch the menu-bar toolbox. Idempotent.

Use Bash to execute (one call, then stop):

```
bash /Users/esaruoho/work/apple/topbar/install.sh
```

After the command completes, report only whether SwiftBar is now running
(`pgrep SwiftBar`) and remind the user to look for the 🧰 in the menu bar
(SwiftBar will show a folder picker on first launch — they must choose
`/Users/esaruoho/work/apple/topbar/plugins/`).
