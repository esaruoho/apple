# Reminders — JavaScript for Automation (JXA) Reference

> Rendered from `reminders.yaml` by `bin/sdef-to-jxa.py`. JXA dialect of the AppleScript dictionary in `reminders.md`.
> Translation rules: WWDC 2014 #306 — *JavaScript for Automation* (Sal Soghoian + David Steinberg).

## Get the application

```javascript
var Reminders = Application('Reminders')
Reminders.includeStandardAdditions = true   // if calling beep/say/displayDialog
```

**Commands:** 1  ·  **Classes:** 3  ·  **Suites:** 1

## Suite — Reminders Suite

_Terms and Events for controlling the Reminders application_

### Commands

```javascript
// Show an object in the Reminders UI
Reminders.show(target)

```

### Classes

```javascript
// class: account
// An account in the Reminders application
account.id        // read-only getter (text)
account.lists[0]                   // first list
account.lists.whose({name: 'x'})  // filter

// class: list
// A list in the Reminders application
list.name        // getter (text)
list.name = '...'  // setter
list.id        // read-only getter (text)
list.reminders[0]                   // first reminder
list.reminders.whose({name: 'x'})  // filter

// class: reminder
// A reminder in the Reminders application
reminder.name        // getter (text)
reminder.name = '...'  // setter
reminder.id        // read-only getter (text)

```

## JXA gotchas (apply to every app)

- **Property getters take parens:** `doc.name()` not `doc.name`. `=` setter works without parens.
- **Standard Additions are opt-in:** `app.includeStandardAdditions = true` before `beep` / `say` / `displayDialog`.
- **Paths via `Path()`:** `Path('/Users/.../file.rtf')` — no `POSIX file` / `as alias` coercion needed.
- **`whose(...)` takes a record:** `messages.whose({subject: 'JS'})`; comparators are `_`-prefixed: `{age: {_greaterThan: 30}}`, `{name: {_contains: 'Smith'}}`.
- **Named parameters become record keys:** `msg.reply({replyAll: true, openingWindow: false})`.
- **ID lookup:** `app.windows['#412']` (hash-prefix = ID).
