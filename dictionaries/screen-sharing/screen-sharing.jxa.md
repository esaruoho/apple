# Screen Sharing — JavaScript for Automation (JXA) Reference

> Rendered from `screen-sharing.yaml` by `bin/sdef-to-jxa.py`. JXA dialect of the AppleScript dictionary in `screen-sharing.md`.
> Translation rules: WWDC 2014 #306 — *JavaScript for Automation* (Sal Soghoian + David Steinberg).

## Get the application

```javascript
var ScreenSharing = Application('Screen Sharing')
ScreenSharing.includeStandardAdditions = true   // if calling beep/say/displayDialog
```

**Commands:** 1  ·  **Classes:** 0  ·  **Suites:** 1

## Suite — Screen Sharing Suite

_Terms and Events for controlling the Screen Sharing application._

### Commands

```javascript
// Open a vnc URL
ScreenSharing.geturl('...')

```

## JXA gotchas (apply to every app)

- **Property getters take parens:** `doc.name()` not `doc.name`. `=` setter works without parens.
- **Standard Additions are opt-in:** `app.includeStandardAdditions = true` before `beep` / `say` / `displayDialog`.
- **Paths via `Path()`:** `Path('/Users/.../file.rtf')` — no `POSIX file` / `as alias` coercion needed.
- **`whose(...)` takes a record:** `messages.whose({subject: 'JS'})`; comparators are `_`-prefixed: `{age: {_greaterThan: 30}}`, `{name: {_contains: 'Smith'}}`.
- **Named parameters become record keys:** `msg.reply({replyAll: true, openingWindow: false})`.
- **ID lookup:** `app.windows['#412']` (hash-prefix = ID).
