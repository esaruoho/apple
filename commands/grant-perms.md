---
description: One-shot pre-prompt for every macOS privacy permission AppleToolbox needs (mic, camera, speech, accessibility, screen recording, calendar, reminders, contacts, photos, Apple Events to Finder/Mail/Music/Safari/etc., Full Disk Access). Fires each privacy API once so all the TCC dialogs queue up at a single known moment instead of ambushing you mid-task later. After you click through once, AppleToolbox stops asking. Usage `/grant-perms`.
allowed-tools: Bash
argument-hint: (no args)
---

Trigger the AppleToolbox permission burst. macOS TCC is user-mediated by
design — no API or signing trick can grant Accessibility / FDA / Screen
Recording silently — so this just queues every dialog at once instead of
ambushing you later. Click through each one; AppleToolbox won't ask again.

Use Bash to execute (one call, then stop):

```
"$(mdfind "kMDItemCFBundleIdentifier == 'com.esaruoho.appletoolbox'" | head -1)/Contents/MacOS/AppleToolbox" --grant-permissions
```

(Resolves the installed app by bundle id — the old `~/work/apple/topbar/AppleToolbox.app`
path is deleted by `build.sh` every build. Fallback path:
`/Applications/AppleToolbox/Apple-Workflows/AppleToolbox.app/Contents/MacOS/AppleToolbox`.)

After the command completes, remind the user to also drag
AppleToolbox.app into System Settings → Privacy & Security → Full Disk
Access (the only one with no programmatic prompt).
