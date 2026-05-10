# Safari — JavaScript for Automation (JXA) Reference

> Rendered from `safari.yaml` by `bin/sdef-to-jxa.py`. JXA dialect of the AppleScript dictionary in `safari.md`.
> Translation rules: WWDC 2014 #306 — *JavaScript for Automation* (Sal Soghoian + David Steinberg).

## Get the application

```javascript
var Safari = Application('Safari')
Safari.includeStandardAdditions = true   // if calling beep/say/displayDialog
```

**Commands:** 10  ·  **Classes:** 3  ·  **Suites:** 1

## Suite — Safari suite

_Safari specific classes_

### Commands

```javascript
// Add a new Reading List item with the given URL. Allows a custom title and preview text to be specified.
Safari.addReadingListItem('...', {andPreviewText: '...', withTitle: '...'})

// Applies a string of JavaScript code to a document.
Safari.doJavascript('...', {in: /*  */})

// Emails the contents of a tab.
Safari.emailContents({of: /*  */})

// Searches the web using Safari's current search provider.
Safari.searchTheWeb({in: /*  */, for: '...'})

// Shows Safari's bookmarks.
Safari.showBookmarks()

// Show Safari Extensions preferences.
Safari.showExtensionsPreferences('...')

// Dispatch a message to a Safari Extension.
Safari.dispatchMessageToExtension(/* any */)

// Make sure that all in-memory structures are in-sync with their on-disk counterparts.
Safari.syncAllPlistToDisk()

// Show Safari's Privacy Report
Safari.showPrivacyReport()

// Show Safari Credit Card Settings.
Safari.showCreditCardSettings()

```

### Classes

```javascript
// class: tab
// A Safari window tab.
tab.url        // getter (text)
tab.url = '...'  // setter
tab.source        // read-only getter (text)

// class: sourceProvider

// class: contentsProvider

```

## JXA gotchas (apply to every app)

- **Property getters take parens:** `doc.name()` not `doc.name`. `=` setter works without parens.
- **Standard Additions are opt-in:** `app.includeStandardAdditions = true` before `beep` / `say` / `displayDialog`.
- **Paths via `Path()`:** `Path('/Users/.../file.rtf')` — no `POSIX file` / `as alias` coercion needed.
- **`whose(...)` takes a record:** `messages.whose({subject: 'JS'})`; comparators are `_`-prefixed: `{age: {_greaterThan: 30}}`, `{name: {_contains: 'Smith'}}`.
- **Named parameters become record keys:** `msg.reply({replyAll: true, openingWindow: false})`.
- **ID lookup:** `app.windows['#412']` (hash-prefix = ID).
