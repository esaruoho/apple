---
title: Getting started with Sal's Siri — minimal first-time path
date: 2026-05-07
audience: Esa, on a current macOS Sequoia Apple Silicon Mac, who has seen the
  Vocal Shortcuts pane and not known what to put there
---

# Stop. Forget the 588.

The big architecture I built (588 commands, 18 libraries, foundation models
router, multi-turn deixis) is the **finished destination**. Trying to install
all of it as your first move is like trying to build IKEA furniture by
emptying the box on the floor. Don't.

This document is the **minimal first-time path**. Get ONE command working.
Then we add more.

# Concept check (plain language)

Sal's stack has three layers. Confusing them is the source of most pain.

```
  Layer 3:  Trigger        — what makes the command fire
                              ("Take my picture", spoken or typed)
  Layer 2:  Wiring         — what connects trigger to action
                              (Vocal Shortcut → Shortcut → Run AppleScript)
  Layer 1:  Engine         — what actually does the thing
                              (Sal's 18 .scptd AppleScript libraries)
```

You install Layer 1 once. Layer 2 you build per-command in Shortcuts.app.
Layer 3 is the cherry on top — Vocal Shortcuts adds voice triggering to
Shortcuts you've already wired.

**On Sequoia, Layer 1 still works. Layer 2 has changed (Custom Commands plist
is gone, replaced by Shortcuts.app). Layer 3 is new (Vocal Shortcuts only
exists on Sequoia Apple Silicon).**

# What "staleness window" means (the question you asked)

It's a parameter for the multi-turn memory. The router remembers what you
just told it for **30 minutes**. After that, it forgets. So if you say
"now scale them down" the router knows what "them" is *if* you said
something matching in the last 30 minutes. After 30 minutes it's stale and
the router asks you to be explicit.

You don't configure this. It's a default in the multi-turn reader. Ignore
it for now.

# Step 1 — Get ONE command working from Terminal

This proves the engine (Layer 1) works on your Mac. No Vocal Shortcuts, no
Shortcuts.app, just Terminal.

```bash
cd /Users/esaruoho/work/apple
bash bin/dictation-commands-install.sh
```

You'll see a warning that Step 3 is skipped on macOS 15+. That's expected —
the legacy plist runtime is gone, but the library copy step still works.

After it finishes, the 18 `.scptd` files are at `~/Library/Script Libraries/`.

Now test directly:

```bash
osascript -e 'use script "DC-Workspace"' -e 'tell script "DC-Workspace" to takeMyPicture()'
```

Three things can happen:

| What you see | What it means | What to do |
|---|---|---|
| Camera opens, takes picture | Engine works | Move to Step 2 |
| Dialog asking for Accessibility permission | TCC consent needed | Click Allow, run again |
| Error like "Can't find script DC-Workspace" | Library not at expected path | `ls ~/Library/Script\ Libraries/` and tell me what's there |
| Error like "no handler for takeMyPicture" | Sal renamed something OR my decompile has a different name | Tell me the exact error |

**If Step 1 fails, stop. Tell me the error. Don't go to Step 2.**

The whole rest of the system depends on Step 1 working.

# Step 2 — Wire ONE command to a Shortcut (no voice yet)

Now the same command, callable from Shortcuts.app:

1. Open **Shortcuts.app**
2. **File → New Shortcut**
3. Name it: **Take My Picture**
4. Add ONE action: search for "Run AppleScript", drag it in
5. In the action body, replace the placeholder with:
   ```applescript
   use script "DC-Workspace"
   tell script "DC-Workspace" to takeMyPicture()
   ```
6. Save
7. Click the play button (▶) at the top of the Shortcut

If your camera opens → Step 2 works. You now have a Shortcut named
"Take My Picture" that runs Sal's 2016 code.

# Step 3 — Add voice (Vocal Shortcuts)

Now we wire the trigger:

1. **System Settings → Accessibility → Speech → Vocal Shortcuts**
2. Click **Set Up** (first time only)
3. Click **+**
4. Phrase: **Take My Picture**
5. When prompted, **say "Take My Picture" three times** (Vocal Shortcuts trains
   on YOUR voice — UI scripting can't bypass this; you have to actually speak)
6. For the action, choose **Run Shortcut** → pick **Take My Picture** (the
   Shortcut you made in Step 2)
7. Save

Now say "Take My Picture" out loud. Camera should open.

**If yes — congratulations, ONE command of Sal's WWDC 717 demo runs on your
2026 Mac, voice-triggered, exactly like the one Sal pulled.**

# Step 4 — Add a few more, the easy way

Once Step 3 works, the same pattern adds any of the 588 commands. Pick
something from `sources/sal/wwdc2016-session-717/717-transcript.txt` lines
277–475 (the demo Sal did on stage). For example:

| Phrase | AppleScript body for the Shortcut |
|---|---|
| "Switch to photos" | `tell application "Photos" to activate` |
| "Make a new presentation" | `use script "DC-Keynote"` then `tell script "DC-Keynote" to makeNewPresentation()` |
| "Apply a magic move" | `use script "DC-Keynote"` then `tell script "DC-Keynote" to applyMagicMoveTransition()` |

The exact handler names live in `scripts/sal/dictation-commands/decompiled/<library>.applescript` —
search for `^on ` or `^to ` lines.

Repeat Steps 2 + 3 for each command. Each new command takes ~2 minutes.

# When to come back to me

- After Step 1: tell me "engine works" or paste the error
- After Step 4 if you've done 5+ commands: I'll batch-build the rest from
  the 588 specs we already have, with a different generator that's less
  ambitious than the foundation-model router

The big router (`bin/sal-siri-on-mac-rebuild.py`) is real but it's the LAST
step, not the first. It only makes sense after you have ~50 commands
working through the simple Vocal Shortcut path. Then "Hey Sal" can route
free-form English to whichever of the 50 you want, instead of you saying
the exact phrase yourself.

# What screenshots help

When you describe trouble, screenshots that help:

- The error dialog (with the entire wording)
- `ls ~/Library/Script\ Libraries/` output (text is fine, no screenshot
  needed for this)
- Vocal Shortcuts pane after clicking Set Up
- Shortcuts.app sidebar showing your Shortcuts list
- The Run AppleScript action's body when you hit run

Anything else: ask. I'd rather you ask than try to follow instructions
that don't match what you see.
