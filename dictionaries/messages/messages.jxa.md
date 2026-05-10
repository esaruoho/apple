# Messages — JavaScript for Automation (JXA) Reference

> Rendered from `messages.yaml` by `bin/sdef-to-jxa.py`. JXA dialect of the AppleScript dictionary in `messages.md`.
> Translation rules: WWDC 2014 #306 — *JavaScript for Automation* (Sal Soghoian + David Steinberg).

## Get the application

```javascript
var Messages = Application('Messages')
Messages.includeStandardAdditions = true   // if calling beep/say/displayDialog
```

**Commands:** 3  ·  **Classes:** 4  ·  **Suites:** 1

## Suite — Messages Suite

_commands and classes for Messages scripting._

### Commands

```javascript
// Sends a message to a participant or to a chat.
Messages.send(target, {to: /*  */})

// Login to all accounts.
Messages.login()

// Logout of all accounts.
Messages.logout()

```

### Classes

```javascript
// class: participant
// A participant for an account.
participant.id        // read-only getter (text)

// class: account
// An account that can be logged in to from this system
account.enabled        // getter (boolean)
account.enabled = /* value */  // setter
account.id        // read-only getter (text)
account.chats[0]                   // first chat
account.chats.whose({name: 'x'})  // filter

// class: chat
// An SMS or iMessage chat.
chat.id        // read-only getter (text)
chat.participants[0]                   // first participant
chat.participants.whose({name: 'x'})  // filter

// class: file transfer
// A file being sent or received
filetransfer.id        // read-only getter (text)

```

## JXA gotchas (apply to every app)

- **Property getters take parens:** `doc.name()` not `doc.name`. `=` setter works without parens.
- **Standard Additions are opt-in:** `app.includeStandardAdditions = true` before `beep` / `say` / `displayDialog`.
- **Paths via `Path()`:** `Path('/Users/.../file.rtf')` — no `POSIX file` / `as alias` coercion needed.
- **`whose(...)` takes a record:** `messages.whose({subject: 'JS'})`; comparators are `_`-prefixed: `{age: {_greaterThan: 30}}`, `{name: {_contains: 'Smith'}}`.
- **Named parameters become record keys:** `msg.reply({replyAll: true, openingWindow: false})`.
- **ID lookup:** `app.windows['#412']` (hash-prefix = ID).
