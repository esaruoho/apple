---
description: Pristine Apple-native backup of a single Mail.app account. Resolves the account UUID via AppleScript, quits Mail for a clean snapshot, rsyncs `~/Library/Mail/V10/<UUID>/` to `~/Backups/mail-<prefix>-YYYY-MM-DD/`, renames the top-level `.mbox` folders with a friendly prefix, and verifies `.emlx` counts source vs backup. Usage `/backup-mailbox --list` or `/backup-mailbox <account> [--prefix <slug>] [--dest <dir>]`.
allowed-tools: Bash
argument-hint: --list | <account> [--prefix <slug>] [--dest <dir>] [--keep-mail-open]
---

Back up a single Mail.app account to a pristine, restorable folder of `.emlx` messages plus mailbox metadata.

Use Bash (one call, then stop):

```
/Users/esaruoho/work/apple/bin/backup-mailbox $ARGUMENTS
```

The script:

1. Launches Mail.app if it isn't running (its scripting suite only responds live).
2. Resolves `<account>` (email, AppleScript name, or V10 UUID) → V10 directory.
3. Quits Mail.app so no `.emlx` is mid-write during the copy.
4. `rsync -a` into `~/Backups/mail-<prefix>-YYYY-MM-DD/`.
5. Renames every top-level `*.mbox` with the prefix (`INBOX.mbox` → `<prefix>-inbox.mbox`, `[Gmail].mbox` → `<prefix>-gmail.mbox`, etc.).
6. Counts `.emlx` files in source vs backup and reports the byte total.

Print the script output verbatim. Do not summarize or moralize.

Apple-native: Python stdlib + `osascript` + `rsync` only. Documented at `wiki/concepts/mail-backup.md`.
