# Logic Pro — JavaScript for Automation (JXA) Reference

> Rendered from `logic-pro.yaml` by `bin/sdef-to-jxa.py`. JXA dialect of the AppleScript dictionary in `logic-pro.md`.
> Translation rules: WWDC 2014 #306 — *JavaScript for Automation* (Sal Soghoian + David Steinberg).

## Get the application

```javascript
var LogicPro = Application('Logic Pro')
LogicPro.includeStandardAdditions = true   // if calling beep/say/displayDialog
```

**Commands:** 13  ·  **Classes:** 12  ·  **Suites:** 4

## Suite — Standard Suite

_Common classes and commands for most applications._

### Commands

```javascript
// Close an object.
LogicPro.close(target, {saving: /* savo */, savingIn: /* alias */})

// Return the number of elements of a particular class within an object.
LogicPro.count(target, {each: /* type */})

// Delete an object.
LogicPro.delete(target)

// Copy object(s) and put the copies at a new location.
LogicPro.duplicate(target, {to: Path('/path'), withProperties: {}})

// Verify if an object exists.
LogicPro.exists(target)

// Get the data for an object.
LogicPro.get(target)

// Make a new object.
LogicPro.make({new: /* type */, at: Path('/path'), withData: /* any */, withProperties: {}})

// Move object(s) to a new location.
LogicPro.move(target, {to: Path('/path')})

// Open an object.
LogicPro.open(/* alias */)

// Print an object.
LogicPro.print(/* alias */, {printDialog: true, withProperties: /* print settings */})

// Quit an application.
LogicPro.quit({saving: /* savo */})

// Save an object.
LogicPro.save(target, {as: '...', in: /* alias */})

// Set an object's data.
LogicPro.set(target, {to: /* any */})

```

### Classes

```javascript
// class: application
// An application's top level scripting object.
application.frontmost        // read-only getter (boolean)
application.documents[0]                   // first document
application.documents.whose({name: 'x'})  // filter

// class: color
// A color.

// class: document
// A document.
document.name        // getter (text)
document.name = '...'  // setter
document.modified        // read-only getter (boolean)

// class: item
// A scriptable object.
item.properties        // getter (record)
item.properties = /* value */  // setter
item.class        // read-only getter (type)

// class: window
// A window.
window.bounds        // getter (rectangle)
window.bounds = /* value */  // setter
window.closeable        // read-only getter (boolean)

```

## Suite — Text Suite

_A set of basic classes for text processing._

### Classes

```javascript
// class: attachment
// Represents an inline text attachment.  This class is used mainly for make commands.
attachment.fileName        // getter (text)
attachment.fileName = '...'  // setter

// class: attribute run
// This subdivides the text into chunks that all have the same attributes.
attributerun.color        // getter (color)
attributerun.color = /* value */  // setter
attributerun.attachments[0]                   // first attachment
attributerun.attachments.whose({name: 'x'})  // filter

// class: character
// This subdivides the text into characters.
character.color        // getter (color)
character.color = /* value */  // setter
character.attachments[0]                   // first attachment
character.attachments.whose({name: 'x'})  // filter

// class: paragraph
// This subdivides the text into paragraphs.
paragraph.color        // getter (color)
paragraph.color = /* value */  // setter
paragraph.attachments[0]                   // first attachment
paragraph.attachments.whose({name: 'x'})  // filter

// class: text
// Rich (styled) text
text.color        // getter (color)
text.color = /* value */  // setter
text.attachments[0]                   // first attachment
text.attachments.whose({name: 'x'})  // filter

// class: word
// This subdivides the text into words.
word.color        // getter (color)
word.color = /* value */  // setter
word.attachments[0]                   // first attachment
word.attachments.whose({name: 'x'})  // filter

```

## Suite — Type Definitions

_Records used in scripting Logic Pro_

### Classes

```javascript
// class: print settings
printsettings.copies        // getter (integer)
printsettings.copies = /* value */  // setter

```

## Suite — Type Names

_Other classes and commands_

## JXA gotchas (apply to every app)

- **Property getters take parens:** `doc.name()` not `doc.name`. `=` setter works without parens.
- **Standard Additions are opt-in:** `app.includeStandardAdditions = true` before `beep` / `say` / `displayDialog`.
- **Paths via `Path()`:** `Path('/Users/.../file.rtf')` — no `POSIX file` / `as alias` coercion needed.
- **`whose(...)` takes a record:** `messages.whose({subject: 'JS'})`; comparators are `_`-prefixed: `{age: {_greaterThan: 30}}`, `{name: {_contains: 'Smith'}}`.
- **Named parameters become record keys:** `msg.reply({replyAll: true, openingWindow: false})`.
- **ID lookup:** `app.windows['#412']` (hash-prefix = ID).
