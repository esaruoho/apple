# notes-process — the append-only Shortcut (one-time setup)

Apple Notes' AppleScript has **no append verb**: the only write is `set body`, which
replaces the whole note — and real Notes tags (orange `#process`) are NOT in the body HTML
(they are inline objects, shown as U+FFFC in `plaintext`), so `set body` silently deletes them.
Shortcuts' **Append to Note** action is the only true append; **Make Rich Text from Markdown**
gives the formatting. `bin/notes-process` uses this Shortcut when it is installed and the
note's title is unique; otherwise it writes a linked note `Re: <title>` via `bin/notes-new`.

## Build it (Shortcuts.app, ~2 minutes)
Name it exactly **`notes-process-append`**.

1. Shortcut details (ⓘ) → enable **Receive input** from **Quick Actions/anywhere**, type **Any**
   (so `shortcuts run … --input-path file.json` delivers the file).
2. **Get Dictionary from** *Shortcut Input*
3. **Get Value for** `markdown` **in** *Dictionary*
4. **Make Rich Text from Markdown** — input: *Dictionary Value*
5. **Get Value for** `title` **in** *Dictionary*
6. **Find Notes** where **Name is** *Dictionary Value* (from step 5), **Limit 1**
7. **Append** *Rich Text from Markdown* **to** *Notes* (from step 6)

Test: `bin/notes-process --once --dry-run` should say `→ append (Shortcut)`.

## How a tag is found (read-only)
`NoteStore.sqlite` opened with `mode=ro`: rows in `ZICCLOUDSYNCINGOBJECT` with
`ZTYPEUTI1='com.apple.notes.inlinetextattachment.hashtag'` and `ZALTTEXT='#process'`;
`ZNOTE1` → the note. Each tag object's `ZIDENTIFIER` keys the ledger, so each tag
occurrence fires once.
