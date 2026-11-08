# notes-process — in-note append via a HAND-BUILT Shortcut (optional)

**Status 2026-11-08:** OFF. `bin/notes-process` replies with a linked note `Re: <title>`
(via `bin/notes-new`) — additive, no dialogs. The generated Shortcut
(`bin/notes-process-shortcut-gen`) FAILED: Shortcuts dropped its variable bindings and
popped a text dialog, then a "which note?" picker of all notes. Never re-enable a Shortcut
until it appends to a probe note with ZERO dialogs.

## Why a Shortcut at all
Notes' AppleScript has no append — only `set body` (replace everything), which deletes real
orange #tags (they're inline objects, absent from body HTML). Shortcuts' **Append to Note** is
the only true append, and **Make Rich Text from Markdown** keeps formatting.

## Not hardcoded to a note
The Shortcut never names a note. `notes-process` hands it a small JSON file each run:

```json
{"title": "<the note's exact title>", "markdown": "<reply, incl. ---, **bold**, #done>"}
```

The Shortcut finds the note by that title at run time. `notes-process` only calls it when the
title is **unique** (checked read-only in NoteStore.sqlite), otherwise it falls back to a linked note,
so it can never append to the wrong note.

## The 3 steps (build by hand in Shortcuts.app, name: `notes-process-append`)
Shortcut settings (ⓘ): **Receive Any input**; if there's no input → **Stop and respond** (never "Ask").

1. **Read the request** — *Get Dictionary from* **Shortcut Input**.
2. **Find the note** — *Find Notes* where **Name is** → tap the field → *Select Variable* →
   **Dictionary** → type key `title`. *Limit* on, **1**.
3. **Append the reply** — *Make Rich Text from Markdown* with **Dictionary** → key `markdown`,
   then *Append* **Rich Text from Markdown** **to** → *Select Variable* → **Notes** (from step 2).

The failure last time was exactly steps 2–3: the Note / Text fields were left on
"Ask Each Time", so Shortcuts prompted. In a hand-built Shortcut both fields must show a blue
variable pill — no field may say *Ask Each Time* or be empty.

## Acceptance test before switching it on
```
printf '{"title":"append-probe-7731 (safe to delete)","markdown":"**ok** #done"}' > /tmp/p.json
shortcuts run notes-process-append --input-path /tmp/p.json   # must return in seconds, NO dialog
```
Then `bin/notes-process --once --shortcut notes-process-append` on a test note. notes-process
also reads each note back after appending and logs `APPEND NOT VERIFIED` (no retry) if the reply
isn't there; each run is capped at 45s.
