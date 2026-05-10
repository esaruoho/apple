# Notes — JavaScript for Automation (JXA) Reference

> Rendered from `notes.yaml` by `bin/sdef-to-jxa.py`. JXA dialect of the AppleScript dictionary in `notes.md`.
> Translation rules: WWDC 2014 #306 — *JavaScript for Automation* (Sal Soghoian + David Steinberg).

## Get the application

```javascript
var Notes = Application('Notes')
Notes.includeStandardAdditions = true   // if calling beep/say/displayDialog
```

**Commands:** 2  ·  **Classes:** 4  ·  **Suites:** 1

## Suite — Notes Suite

_Terms and Events for controlling the Notes application_

### Commands

```javascript
// Open a note URL.
Notes.openNoteLocation(target)

// Show an object in the UI
Notes.show(target, {separately: true})

```

### Classes

```javascript
// class: account
// a Notes account
account.defaultFolder        // getter (folder)
account.defaultFolder = /* value */  // setter
account.upgraded        // read-only getter (boolean)
account.folders[0]                   // first folder
account.folders.whose({name: 'x'})  // filter

// class: folder
// a folder containing notes
folder.name        // getter (text)
folder.name = '...'  // setter
folder.id        // read-only getter (text)
folder.folders[0]                   // first folder
folder.folders.whose({name: 'x'})  // filter

// class: note
// a note in the Notes application
note.name        // getter (text)
note.name = '...'  // setter
note.id        // read-only getter (text)
note.attachments[0]                   // first attachment
note.attachments.whose({name: 'x'})  // filter

// class: attachment
// an attachment in a note
attachment.name        // read-only getter (text)

```

## JXA gotchas (apply to every app)

- **Property getters take parens:** `doc.name()` not `doc.name`. `=` setter works without parens.
- **Standard Additions are opt-in:** `app.includeStandardAdditions = true` before `beep` / `say` / `displayDialog`.
- **Paths via `Path()`:** `Path('/Users/.../file.rtf')` — no `POSIX file` / `as alias` coercion needed.
- **`whose(...)` takes a record:** `messages.whose({subject: 'JS'})`; comparators are `_`-prefixed: `{age: {_greaterThan: 30}}`, `{name: {_contains: 'Smith'}}`.
- **Named parameters become record keys:** `msg.reply({replyAll: true, openingWindow: false})`.
- **ID lookup:** `app.windows['#412']` (hash-prefix = ID).
