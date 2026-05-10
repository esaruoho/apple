# Numbers — JavaScript for Automation (JXA) Reference

> Rendered from `numbers.yaml` by `bin/sdef-to-jxa.py`. JXA dialect of the AppleScript dictionary in `numbers.md`.
> Translation rules: WWDC 2014 #306 — *JavaScript for Automation* (Sal Soghoian + David Steinberg).

## Get the application

```javascript
var Numbers = Application('Numbers')
Numbers.includeStandardAdditions = true   // if calling beep/say/displayDialog
```

**Commands:** 16  ·  **Classes:** 21  ·  **Suites:** 4

## Suite — iWork Text Suite

_Classes and commands for iWorks text objects._

### Classes

```javascript
// class: rich text
// This provides the base rich text class for all iWork applications.
richtext.color        // getter (color)
richtext.color = /* value */  // setter
richtext.characters[0]                   // first character
richtext.characters.whose({name: 'x'})  // filter

// class: character
// One of some text's characters.

// class: paragraph
// One of some text's paragraphs.
paragraph.characters[0]                   // first character
paragraph.characters.whose({name: 'x'})  // filter

// class: word
// One of some text's words.
word.characters[0]                   // first character
word.characters.whose({name: 'x'})  // filter

```

## Suite — iWork Suite

_A set of basic classes for iWork applications._

### Commands

```javascript
// Sets the value of the specified object(s).
Numbers.set(target, {to: /* any */})

// Delete an object.
Numbers.delete(target)

// Create a new object.
Numbers.make({new: /* type */, at: Path('/path'), withData: /* any */, withProperties: {}})

// Clear the contents of a specified range of cells, including formatting and style.
Numbers.clear(/* range */)

// Merge a specified range of cells.
Numbers.merge(/* range */)

// Sort the rows of the table.
Numbers.sort(/* table */, {by: /* column */, direction: /* NMSD */, inRows: /* range */})

// Unmerge all merged cells in a specified range.
Numbers.unmerge(/* range */)

// Set a password to an unencrypted document.
Numbers.setPassword('...', {to: /* document */, hint: '...', savingInKeychain: true})

// Remove the password from the document.
Numbers.removePassword('...', {from: /* document */})

```

### Classes

```javascript
// class: iWork container
// A container for iWork items
iWorkcontainer.audioClips[0]                   // first audio clip
iWorkcontainer.audioClips.whose({name: 'x'})  // filter

// class: iWork item
// An item which supports formatting
iWorkitem.height        // getter (integer)
iWorkitem.height = /* value */  // setter
iWorkitem.parent        // read-only getter (iWork container)

// class: audio clip
// An audio clip
audioclip.fileName        // getter ()
audioclip.fileName = /* value */  // setter

// class: shape
// A shape container
shape.objectText        // getter (rich text)
shape.objectText = /* value */  // setter
shape.backgroundFillType        // read-only getter (item fill options)

// class: chart
// A chart

// class: image
// An image container
image.description        // getter (text)
image.description = '...'  // setter
image.file        // read-only getter (file)

// class: group
// A group container
group.height        // getter (integer)
group.height = /* value */  // setter
group.parent        // read-only getter (iWork container)

// class: line
// A line
line.endPoint        // getter (point)
line.endPoint = /* value */  // setter

// class: movie
// A movie container
movie.fileName        // getter ()
movie.fileName = /* value */  // setter

// class: table
// A table
table.name        // getter (text)
table.name = '...'  // setter
table.cellRange        // read-only getter (range)
table.cells[0]                   // first cell
table.cells.whose({name: 'x'})  // filter

// class: text item
// A text container
textitem.objectText        // getter (rich text)
textitem.objectText = /* value */  // setter
textitem.backgroundFillType        // read-only getter (item fill options)

// class: range
// A range of cells in a table
range.fontName        // getter (text)
range.fontName = '...'  // setter
range.name        // read-only getter (text)
range.cells[0]                   // first cell
range.cells.whose({name: 'x'})  // filter

// class: cell
// A cell in a table
cell.value        // getter ()
cell.value = /* value */  // setter
cell.column        // read-only getter (column)

// class: row
// A row of cells in a table
row.height        // getter (real)
row.height = /* value */  // setter
row.address        // read-only getter (integer)

// class: column
// A column of cells in a table
column.width        // getter (real)
column.width = /* value */  // setter
column.address        // read-only getter (integer)

```

## Suite — Numbers Suite

_Classes and commands for Numbers._

### Commands

```javascript
// Transpose the rows and columns of the table.
Numbers.transpose(/* table */)

// Export a document to another file
Numbers.export(/* document */, {to: Path('/path'), as: /* export format */, withProperties: /* export options */})

```

### Classes

```javascript
// class: sheet
// A sheet in a document
sheet.name        // getter (text)
sheet.name = '...'  // setter

// class: template
// A styled document layout.
template.id        // read-only getter (text)

```

## Suite — Compatibility Suite

_A set of basic classes for compatibility with prior releases._

### Commands

```javascript
// Add a column to the table after a specified range of cells.
Numbers.addColumnAfter(/* range */)

// Add a column to the table before a specified range of cells.
Numbers.addColumnBefore(/* range */)

// Add a row to the table below a specified range of cells.
Numbers.addRowAbove(/* range */)

// Add a row to the table below a specified range of cells.
Numbers.addRowBelow(/* range */)

// Remove specified rows or columns from a table.
Numbers.remove(/* range */)

```

## JXA gotchas (apply to every app)

- **Property getters take parens:** `doc.name()` not `doc.name`. `=` setter works without parens.
- **Standard Additions are opt-in:** `app.includeStandardAdditions = true` before `beep` / `say` / `displayDialog`.
- **Paths via `Path()`:** `Path('/Users/.../file.rtf')` — no `POSIX file` / `as alias` coercion needed.
- **`whose(...)` takes a record:** `messages.whose({subject: 'JS'})`; comparators are `_`-prefixed: `{age: {_greaterThan: 30}}`, `{name: {_contains: 'Smith'}}`.
- **Named parameters become record keys:** `msg.reply({replyAll: true, openingWindow: false})`.
- **ID lookup:** `app.windows['#412']` (hash-prefix = ID).
