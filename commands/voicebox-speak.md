---
description: Local ON/OFF switch for Claude speaking aloud on THIS Mac. Flips ~/.config/voicebox/speak.state, which the Claude Code Stop hook consults before synthesising speech. Usage `/voicebox-speak`, `/voicebox-speak enable|on`, `/voicebox-speak disable|off`, `/voicebox-speak toggle`.
allowed-tools: Bash
argument-hint: status | enable | on | disable | off | toggle
---

Run the apple-skill `voicebox-speak` switch on `$ARGUMENTS`. This is the simple "let Claude talk to me / don't" toggle — not the server-side speaker-claim gate (`voicebox-on`/`voicebox-off`).

Use Bash to execute (one call, then stop):

```
/Users/esaruoho/work/apple/bin/voicebox-speak $ARGUMENTS
```

Modes:
- **`/voicebox-speak`** or **`/voicebox-speak status`** — print whether Claude speech is ON or OFF.
- **`/voicebox-speak enable`** (or `on`) — allow Claude to speak responses via Voicebox.
- **`/voicebox-speak disable`** (or `off`) — silence Claude and cut any current playback.
- **`/voicebox-speak toggle`** — flip the current state.

State lives in `~/.config/voicebox/speak.state` (missing == ON, preserving the prior always-speak default). The AppleToolbox 🧰 menu also shows a live "Claude Speech: ON/OFF" row that toggles this same file.

After the command completes, report only the line the script printed.
