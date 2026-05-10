# Final Cut Pro — JavaScript for Automation (JXA) Reference

> Rendered from `final-cut-pro.yaml` by `bin/sdef-to-jxa.py`. JXA dialect of the AppleScript dictionary in `final-cut-pro.md`.
> Translation rules: WWDC 2014 #306 — *JavaScript for Automation* (Sal Soghoian + David Steinberg).

## Get the application

```javascript
var FinalCutPro = Application('Final Cut Pro')
FinalCutPro.includeStandardAdditions = true   // if calling beep/say/displayDialog
```

**Commands:** 1  ·  **Classes:** 5  ·  **Suites:** 2

## Suite — Final Cut Pro Library

_Scripting terminology for Final Cut Pro Library Model._

### Classes

```javascript
// class: sequence
// A clip sequence.
sequence.name        // read-only getter (text)

// class: item
// an item
item.name        // getter (text)
item.name = '...'  // setter
item.class        // read-only getter (type)

// class: project
// A project.
project.name        // read-only getter (text)

// class: event
// An event.
event.name        // read-only getter (text)
event.sequences[0]                   // first sequence
event.sequences.whose({name: 'x'})  // filter

// class: library
// A library.
library.name        // read-only getter (text)
library.events[0]                   // first event
library.events.whose({name: 'x'})  // filter

```

## Suite — Final Cut Pro Application

_Scripting terminology for Final Cut Pro application._

### Commands

```javascript
// Get data.
FinalCutPro.get(target)

```

## JXA gotchas (apply to every app)

- **Property getters take parens:** `doc.name()` not `doc.name`. `=` setter works without parens.
- **Standard Additions are opt-in:** `app.includeStandardAdditions = true` before `beep` / `say` / `displayDialog`.
- **Paths via `Path()`:** `Path('/Users/.../file.rtf')` — no `POSIX file` / `as alias` coercion needed.
- **`whose(...)` takes a record:** `messages.whose({subject: 'JS'})`; comparators are `_`-prefixed: `{age: {_greaterThan: 30}}`, `{name: {_contains: 'Smith'}}`.
- **Named parameters become record keys:** `msg.reply({replyAll: true, openingWindow: false})`.
- **ID lookup:** `app.windows['#412']` (hash-prefix = ID).
