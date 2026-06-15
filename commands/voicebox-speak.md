---
description: The one switch for "Claude talks to me" on THIS Mac. Enabling guarantees BOTH that the Voicebox server is up (starts it if down) AND that Claude is set to speak — you never think about whether the server is running. Usage `/voicebox-speak`, `/voicebox-speak enable|on`, `/voicebox-speak disable|off`, `/voicebox-speak toggle`.
allowed-tools: Bash
argument-hint: status | enable | on | disable | off | toggle
---

Run the apple-skill `voicebox-speak` switch on `$ARGUMENTS`. This is the end-to-end "let Claude talk to me / don't" control — not the server-side speaker-claim gate (`voicebox-on`/`voicebox-off`).

Use Bash to execute (one call, then stop):

```
/Users/esaruoho/work/apple/bin/voicebox-speak $ARGUMENTS
```

Modes:
- **`/voicebox-speak`** or **`/voicebox-speak status`** — report the flag, whether the Voicebox server is up, and whether Claude will actually speak (`WILL SPEAK` / `SILENT`).
- **`/voicebox-speak enable`** (or `on`) — set Claude talking AND start the Voicebox server if it's down (waits for health). One source of truth: ON means it works.
- **`/voicebox-speak disable`** (or `off`) — silence Claude and cut any current playback (server left running so re-enabling is instant).
- **`/voicebox-speak toggle`** — if speech is effectively ON, disable; otherwise enable (flips flag on + boots the server if needed).

Two things gate speech: the Voicebox server being up, and the intent flag `~/.config/voicebox/speak.state` (missing == ON). The AppleToolbox 🧰 menu shows a live 3-state "Claude Speech" row driving this same control.

After the command completes, report only the line the script printed.
