# Terminal — JavaScript for Automation (JXA) Reference

> Rendered from `terminal.yaml` by `bin/sdef-to-jxa.py`. JXA dialect of the AppleScript dictionary in `terminal.md`.
> Translation rules: WWDC 2014 #306 — *JavaScript for Automation* (Sal Soghoian + David Steinberg).

## Get the application

```javascript
var Terminal = Application('Terminal')
Terminal.includeStandardAdditions = true   // if calling beep/say/displayDialog
```

**Commands:** 13  ·  **Classes:** 4  ·  **Suites:** 2

## Suite — Standard Suite

_Common classes and commands for all applications._

### Commands

```javascript
// Open a document.
Terminal.open(target)

// Close a document.
Terminal.close(target, {saving: /* save options */, savingIn: Path('/path')})

// Save a document.
Terminal.save(target, {in: Path('/path')})

// Print a document.
Terminal.print(target, {withProperties: /* print settings */, printDialog: true})

// Quit the application.
Terminal.quit({saving: /* save options */})

// Return the number of elements of a particular class within an object.
Terminal.count(target, {each: /* type */})

// Delete an object.
Terminal.delete(target)

// Copy object(s) and put the copies at a new location.
Terminal.duplicate(target, {to: Path('/path'), withProperties: {}})

// Verify if an object exists.
Terminal.exists(target)

// Make a new object.
Terminal.make({new: /* type */, at: Path('/path'), withData: /* any */, withProperties: {}})

// Move object(s) to a new location.
Terminal.move(target, {to: Path('/path')})

```

### Classes

```javascript
// class: application
// The application‘s top-level scripting object.
application.name        // read-only getter (text)
application.windows[0]                   // first window
application.windows.whose({name: 'x'})  // filter

// class: window
// A window.
window.index        // getter (integer)
window.index = /* value */  // setter
window.name        // read-only getter (text)
window.tabs[0]                   // first tab
window.tabs.whose({name: 'x'})  // filter

```

## Suite — Terminal Suite

_Terminal specific classes._

### Commands

```javascript
// Runs a UNIX shell script or command.
Terminal.doScript('...', {withCommand: /*  */, in: /*  */})

// Open a command an ssh, telnet, or x-man-page URL.
Terminal.getUrl('...')

```

### Classes

```javascript
// class: settings set
// A set of settings.
settingsset.name        // getter (text)
settingsset.name = '...'  // setter
settingsset.id        // read-only getter (integer)

// class: tab
// A tab.
tab.numberOfRows        // getter (integer)
tab.numberOfRows = /* value */  // setter
tab.contents        // read-only getter (text)

```

## JXA gotchas (apply to every app)

- **Property getters take parens:** `doc.name()` not `doc.name`. `=` setter works without parens.
- **Standard Additions are opt-in:** `app.includeStandardAdditions = true` before `beep` / `say` / `displayDialog`.
- **Paths via `Path()`:** `Path('/Users/.../file.rtf')` — no `POSIX file` / `as alias` coercion needed.
- **`whose(...)` takes a record:** `messages.whose({subject: 'JS'})`; comparators are `_`-prefixed: `{age: {_greaterThan: 30}}`, `{name: {_contains: 'Smith'}}`.
- **Named parameters become record keys:** `msg.reply({replyAll: true, openingWindow: false})`.
- **ID lookup:** `app.windows['#412']` (hash-prefix = ID).
