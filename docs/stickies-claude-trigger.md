---
layout: default
title: "Stickies → Claude Trigger — Notes as a Launch Surface"
---

# Stickies → Claude Trigger — Notes as a Launch Surface



[← Back to home](./)
Built 2026-05-24. Companion to the `finder-tag-pipeline.md` pattern: same shape (LaunchAgent watcher → dispatcher), different trigger surface (Stickies notes instead of Finder tags).

## The principle

A Stickies note becomes a Claude launch. Write a note that starts with `#claude` and one skill tag, save the sticky, and within seconds a new Terminal window opens, `cd`s to the matching project directory, and runs `claude` with a natural-language skill invocation followed by the rest of the note body.

The point isn't Stickies specifically — it's that any persistent text surface on macOS can be a Claude launcher if the loop is `surface → watcher → dispatcher`. Stickies is convenient: ⌘N from anywhere, free-form text, no app to open, no project to choose. Write the thought, save, walk away.

## What lives where

| Path | What it is |
|---|---|
| `bin/stickies-claude-watcher` | The worker. Scans every `.rtfd` bundle in the Stickies container, extracts text via `textutil`, detects `#claude` + a skill tag, hashes the cleaned body, dispatches on change. |
| `topbar/AppleToolbox.swift` (`startStickiesClaudeTimer`) | The ticker. `Timer.scheduledTimer` fires the watcher every 3 sec from inside AppleToolbox.app. This is the production path — see "Why AppleToolbox runs it, not launchd" below. |
| `etc/stickies-claude-tagmap.txt` | Tag → cwd map. `apple=/Users/esaruoho/work/apple` style. Unknown tags fall back to `$HOME`. |
| `state/stickies-claude/<uuid>.sha` | Per-note content hash. Re-fires only when the cleaned body changes. **Gitignored.** |
| `~/work/comms/queue/stickies-claude.log` | Activity log: every dispatch, with UUID + skill + cwd. |
| `bin/com.esa.stickies-claude.plist` + `bin/stickies-claude-install.sh` | Standalone LaunchAgent path. **Does not work without granting Full Disk Access to `/bin/bash`** — see below. Kept for installations that can't ride AppleToolbox. |

## The sticky format

```
#claude #apple
audit the wiki for broken cross-refs and tell me what's stale
```

Rules the watcher applies:

1. **`#claude` must be present** (case-insensitive). Without it, the note is ignored — write anything else in Stickies without fear of triggering.
2. **The first other `#<tag>`** selects (a) the skill name to invoke and (b) the working directory from `etc/stickies-claude-tagmap.txt`. Unknown tags still fire; they just default cwd to `$HOME`.
3. **All `#tag` tokens are stripped** from the body before it becomes the prompt. Tags are routing metadata, not part of what Claude reads.
4. **Empty body after stripping** → skipped. Tags alone do nothing.

## What gets executed

The watcher opens a new terminal window via `osascript` and runs, in a login shell. **iTerm.app is preferred if installed (`/Applications/iTerm.app`); otherwise Terminal.app is used.** Switch is one `[[ -d ... ]]` check in `dispatch()`.

```bash
cd /Users/esaruoho/work/apple && claude "Use Apple skill.

audit the wiki for broken cross-refs and tell me what's stale"
```

The natural-language `Use <Skill> skill.` prefix is deliberate — Claude reads it on session start and invokes the skill via the Skill tool. This works for every skill regardless of whether it has a session-start hook (slash-command invocation `/apple <args>` does not always parse `<args>` cleanly across skills).

## Why AppleToolbox runs it, not launchd

**TCC (macOS privacy) blocks launchd-spawned bash from enumerating the Stickies app-container directory.** Even though the directory is `-r` readable and the file count is correct from an interactive shell, the same bash glob expanded inside a LaunchAgent-spawned process returns zero matches. The interactive shell sees the files because Terminal/iTerm have Full Disk Access (granted at some point in the past). The launchd-spawned bash inherits nothing — it has no "responsible app" with FDA, so TCC silently filters the directory listing.

The fix is to put the timer inside a process that DOES have a TCC identity Esa can grant FDA to: **AppleToolbox.app**. Three-second `Timer.scheduledTimer` in `applicationDidFinishLaunching` spawns `/bin/bash -c stickies-claude-watcher`. Because AppleToolbox is the responsible parent process, the spawned bash inherits AppleToolbox's TCC grants — once Esa grants AppleToolbox Full Disk Access (System Settings → Privacy & Security → Full Disk Access → "+" → AppleToolbox.app), the watcher can finally see every .rtfd bundle.

This pattern generalises: **any LaunchAgent script that reads from `~/Library/Containers/*/Data/` will hit the same TCC wall**. If the data has to flow through bash, host the timer in a Swift app you control, not a bare LaunchAgent.

The legacy `bin/com.esa.stickies-claude.plist` LaunchAgent is preserved for non-AppleToolbox installations. It will only work if the user explicitly grants `/bin/bash` Full Disk Access — invasive, and not recommended.

## State semantics — when does it re-fire

The hash key is `sha256(skill + cleaned_prompt)`. Re-fires happen when:

- A new sticky appears with a matching `#claude #<tag>` shape.
- An existing sticky's body changes after stripping tags (typo fix, new instruction).
- A sticky's tag changes (`#apple` → `#paketti`).

The watcher does **not** re-fire on:

- Sticky window move / resize / color change (rewrites .rtfd metadata but not body text).
- Reboot or LaunchAgent reload (state survives because hashes are on disk).
- Deleting a sticky (state file lingers; harmless — orphan hashes are never matched).

To force a re-fire of a sticky you've already triggered: edit the body (even a trailing space + delete the space + save works) or `rm ~/work/apple/state/stickies-claude/<uuid>.sha`.

## Install / uninstall / debug

```bash
# Install (copies plist to ~/Library/LaunchAgents/, loads it, runs once)
~/work/apple/bin/stickies-claude-install.sh

# Sub-commands
~/work/apple/bin/stickies-claude-install.sh status     # is it loaded?
~/work/apple/bin/stickies-claude-install.sh tail       # live log
~/work/apple/bin/stickies-claude-install.sh run        # one-shot, no agent
~/work/apple/bin/stickies-claude-install.sh uninstall  # remove + unload
```

On first run macOS will prompt once for **Automation → Terminal** (so the watcher can `do script`). Grant it. There's no other permission needed — the Stickies container is readable by the user already.

## Stickies storage facts (for the curious)

- Notes live at `~/Library/Containers/com.apple.Stickies/Data/Library/Stickies/<UUID>.rtfd`. One RTFD bundle per note. Containing `TXT.rtf` is the actual content.
- Stickies has **no AppleScript dictionary** (`sdef` returns error -192) and **no Shortcuts/App Intents**. Tier-5-Dark in the [automation tiers atlas](automation-tiers.md). The watcher reaches Stickies the only way available: read the .rtfd directly.
- Notes are **local-only** on this Mac. Stickies has no built-in iCloud sync (the empty `~/Library/Mobile Documents/com~apple~CloudDocs/Stickies/` folder is stray, not a sync target).
- `textutil -convert txt -encoding UTF-8 -stdout <bundle.rtfd>` is the canonical extractor. Apple-native, ships with macOS.

## Extension points

The dispatcher is one shell command. To change what happens on trigger, edit `dispatch()` in `bin/stickies-claude-watcher`. Examples a future change could enable:

- Use iTerm instead of Terminal (swap the `osascript` block).
- Append the dispatched note's UUID + body to a separate log for audit.
- Route some tags to a non-Claude command (e.g. `#shortcut #foo` → `shortcuts run "foo"` with the body as input).

The watcher is intentionally a single bash file. Keep it that way unless the matrix of dispatch targets grows beyond what a `case` statement can express cleanly.

## Why this matters

Sal Soghoian's automation thesis: every persistent surface on the Mac should be wirable. Stickies is the most diffuse capture surface macOS has — ⌘N from anywhere, no opening of any app, no choosing a destination. Wiring it to Claude turns it into the lowest-friction prompt-queue available. Write the thought when it strikes; the system picks it up.

Pairs naturally with the [Finder Tag Pipeline](finder-tag-pipeline.md): tags route files, Stickies route prompts. Same dispatch shape.
