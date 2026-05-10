# Keynote — JavaScript for Automation (JXA) Reference

> Rendered from `keynote.yaml` by `bin/sdef-to-jxa.py`. JXA dialect of the AppleScript dictionary in `keynote.md`.
> Translation rules: WWDC 2014 #306 — *JavaScript for Automation* (Sal Soghoian + David Steinberg).

## Get the application

```javascript
var Keynote = Application('Keynote')
Keynote.includeStandardAdditions = true   // if calling beep/say/displayDialog
```

**Commands:** 28  ·  **Classes:** 22  ·  **Suites:** 4

## Suite — Keynote Suite

_Classes and commands for Keynote._

### Commands

```javascript
// Export a slideshow to another file
Keynote.export(/* document */, {to: Path('/path'), as: /* export format */, withProperties: /* export options */})

// Copy an object.
Keynote.duplicate(target, {to: Path('/path'), withProperties: {}})

// Returns the value of the specified object(s).
Keynote.get(target)

```

### Classes

```javascript
// class: slide layout
// A slide layout in a theme or slideshow document
slidelayout.name        // read-only getter (text)

// class: slide
// A slide in a slideshow document
slide.baseLayout        // getter (slide layout)
slide.baseLayout = /* value */  // setter
slide.slideNumber        // read-only getter (integer)

// class: theme
// A collection of slide layouts, with shared design intents and elements.
theme.id        // read-only getter (text)

```

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
Keynote.set(target, {to: /* any */})

// Delete an object.
Keynote.delete(target)

// Create a new object.
Keynote.make({new: /* type */, at: Path('/path'), withData: /* any */, withProperties: {}})

// Clear the contents of a specified range of cells, including formatting and style.
Keynote.clear(/* range */)

// Merge a specified range of cells.
Keynote.merge(/* range */)

// Sort the rows of the table.
Keynote.sort(/* table */, {by: /* column */, direction: /* NMSD */, inRows: /* range */})

// Unmerge all merged cells in a specified range.
Keynote.unmerge(/* range */)

// Set a password to an unencrypted document.
Keynote.setPassword('...', {to: /* document */, hint: '...', savingInKeychain: true})

// Remove the password from the document.
Keynote.removePassword('...', {from: /* document */})

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

## Suite — Compatibility Suite

_A set of basic classes for compatibility with prior releases._

### Commands

```javascript
// Add a chart to a slide
Keynote.addChart(/* slide */, {rowNames: /*  */, columnNames: /*  */, data: /*  */, type: /* legacy chart type */, groupBy: /* legacy chart grouping */})

// Start playing the presentation.
Keynote.start(/* document */, {from: /* slide */})

// Make a series of slides from a list of files.
Keynote.makeImageSlides(/* document */, {files: /*  */, setTitles: true, slideLayout: /* slide layout */})

// Stop the presentation.
Keynote.stop(/* document */)

// Advance one build or slide.
Keynote.showNext()

// Go to the previous slide.
Keynote.showPrevious()

// Show the slide switcher in play mode
Keynote.showSlideSwitcher(/* document */)

// Hide the slide switcher in play mode
Keynote.hideSlideSwitcher(/* document */)

// Move the slide switcher forward one slide
Keynote.moveSlideSwitcherForward(/* document */)

// Move the slide switcher backward one slide
Keynote.moveSlideSwitcherBackward(/* document */)

// Hide the slide switcher without changing slides
Keynote.cancelSlideSwitcher(/* document */)

// Hide the slide switcher, going to the slide it has selected
Keynote.acceptSlideSwitcher(/* document */)

Keynote.startSlideshow()

Keynote.startFrom(/* slide */)

Keynote.stopSlideshow()

Keynote.show(/* slide */)

```

## JXA gotchas (apply to every app)

- **Property getters take parens:** `doc.name()` not `doc.name`. `=` setter works without parens.
- **Standard Additions are opt-in:** `app.includeStandardAdditions = true` before `beep` / `say` / `displayDialog`.
- **Paths via `Path()`:** `Path('/Users/.../file.rtf')` — no `POSIX file` / `as alias` coercion needed.
- **`whose(...)` takes a record:** `messages.whose({subject: 'JS'})`; comparators are `_`-prefixed: `{age: {_greaterThan: 30}}`, `{name: {_contains: 'Smith'}}`.
- **Named parameters become record keys:** `msg.reply({replyAll: true, openingWindow: false})`.
- **ID lookup:** `app.windows['#412']` (hash-prefix = ID).
