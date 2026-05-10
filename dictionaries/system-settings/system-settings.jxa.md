# System Settings — JavaScript for Automation (JXA) Reference

> Rendered from `system-settings.yaml` by `bin/sdef-to-jxa.py`. JXA dialect of the AppleScript dictionary in `system-settings.md`.
> Translation rules: WWDC 2014 #306 — *JavaScript for Automation* (Sal Soghoian + David Steinberg).

## Get the application

```javascript
var SystemSettings = Application('System Settings')
SystemSettings.includeStandardAdditions = true   // if calling beep/say/displayDialog
```

**Commands:** 3  ·  **Classes:** 2  ·  **Suites:** 2

## Suite — Standard Suite

## Suite — System Settings

_Classes and Commands specific to System Settings_

### Commands

```javascript
// Reveals a settings pane or an anchor within a pane.
SystemSettings.reveal(target)

// Prompt for authorization for a settings pane. Deprecated: no longer does anything.
SystemSettings.authorize(/* pane */)

// Times and loads given settings pane and returns load time. Deprecated: no longer does anything.
SystemSettings.timedload(/* pane */)

```

### Classes

```javascript
// class: pane
// A settings pane.
pane.id        // read-only getter (text)
pane.anchors[0]                   // first anchor
pane.anchors.whose({name: 'x'})  // filter

// class: anchor
// An anchor within a settings pane.
anchor.name        // read-only getter (text)

```

## JXA gotchas (apply to every app)

- **Property getters take parens:** `doc.name()` not `doc.name`. `=` setter works without parens.
- **Standard Additions are opt-in:** `app.includeStandardAdditions = true` before `beep` / `say` / `displayDialog`.
- **Paths via `Path()`:** `Path('/Users/.../file.rtf')` — no `POSIX file` / `as alias` coercion needed.
- **`whose(...)` takes a record:** `messages.whose({subject: 'JS'})`; comparators are `_`-prefixed: `{age: {_greaterThan: 30}}`, `{name: {_contains: 'Smith'}}`.
- **Named parameters become record keys:** `msg.reply({replyAll: true, openingWindow: false})`.
- **ID lookup:** `app.windows['#412']` (hash-prefix = ID).
