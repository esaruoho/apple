---
description: Build + install + launch AppleToolbox — Apple-native menu-bar app (Swift NSStatusItem, no Homebrew). One 🧰 in the menu bar with live status (HomePod climate, battery, Sal archive, disk, Wi-Fi, Mail, Now Playing, Whisp queue) + click actions (Stop Voicebox, Audio ▸, Finder ▸, System ▸, Slashes ▸). LaunchAgent auto-starts it at login. Usage `/topbar`.
allowed-tools: Bash
argument-hint: (no args)
---

Build, install, and launch AppleToolbox.app. Safe to re-run.

Use Bash to execute (one call, then stop):

```
bash /Users/esaruoho/work/apple/topbar/install.sh
```

After the command completes, report whether AppleToolbox is now running
(`pgrep AppleToolbox`) and remind the user to look for the 🧰 in the
menu bar.
