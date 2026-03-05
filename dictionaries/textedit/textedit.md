# TextEdit — AppleScript Reference

> Extracted from scripting dictionary via `sdef`
> 13 commands, 12 classes, 5 suites

```applescript
tell application "TextEdit"
    -- commands go here
end tell
```

## Standard Suite

> Common classes and commands for most applications.

### Commands

#### `close`

Close an object.

- **Direct parameter**: `specifier` — the object for the command
- **saving**: `savo` *(optional)* — Specifies whether changes should be saved before closing.
- **saving in**: `alias` *(optional)* — The file in which to save the object.

#### `count`

Return the number of elements of a particular class within an object.

- **Direct parameter**: `specifier` — the object for the command
- **each**: `type` *(optional)* — The class of objects to be counted.
- **Returns**: `integer` — 

#### `delete`

Delete an object.

- **Direct parameter**: `specifier` — the object for the command

#### `duplicate`

Copy object(s) and put the copies at a new location.

- **Direct parameter**: `specifier` — the object for the command
- **to**: `location specifier` *(optional)* — The location for the new object(s).
- **with properties**: `record` *(optional)* — Properties to be set in the new duplicated object(s).

#### `exists`

Verify if an object exists.

- **Direct parameter**: `specifier` — the object for the command
- **Returns**: `boolean` — 

#### `get`

Get the data for an object.

- **Direct parameter**: `specifier` — the object for the command
- **Returns**: `any` — 

#### `make`

Make a new object.

- **new**: `type` — The class of the new object.
- **at**: `location specifier` *(optional)* — The location at which to insert the object.
- **with data**: `any` *(optional)* — The initial data for the object.
- **with properties**: `record` *(optional)* — The initial values for properties of the object.
- **Returns**: `specifier` — 

#### `move`

Move object(s) to a new location.

- **Direct parameter**: `specifier` — the object for the command
- **to**: `location specifier` — The new location for the object(s).

#### `open`

Open an object.

- **Direct parameter**: `alias` — The file(s) to be opened.
- **Returns**: `document` — 

#### `print`

Print an object.

- **Direct parameter**: `alias` — The file(s) or document(s) to be printed.
- **print dialog**: `boolean` *(optional)* — Should the application show the Print dialog?
- **with properties**: `print settings` *(optional)* — the print settings

#### `quit`

Quit an application.

- **saving**: `savo` *(optional)* — Specifies whether changes should be saved before quitting.

#### `save`

Save an object.

- **Direct parameter**: `specifier` — the object for the command
- **as**: `text` *(optional)* — The file type in which to save the data.
- **in**: `alias` *(optional)* — The file in which to save the object.

#### `set`

Set an object's data.

- **Direct parameter**: `specifier` — the object for the command
- **to**: `any` — The new value.

### Classes

#### `application`

An application's top level scripting object.

*Inherits from: `item`*

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `frontmost` | `boolean` | r | Is this the frontmost (active) application? |
| `name` | `text` | r | The name of the application. |
| `version` | `text` | r | The version of the application. |

**Contains**: `document`, `window`

#### `color`

A color.

*Inherits from: `item`*

#### `document`

A document.

*Inherits from: `item`*

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `modified` | `boolean` | r | Has the document been modified since the last save? |
| `name` | `text` | rw | The document's name. |
| `path` | `text` | rw | The document's path. |

#### `item`

A scriptable object.

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `class` | `type` | r | The class of the object. |
| `properties` | `record` | rw | All of the object's properties. |

#### `window`

A window.

*Inherits from: `item`*

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `bounds` | `rectangle` | rw | The bounding rectangle of the window. |
| `closeable` | `boolean` | r | Whether the window has a close box. |
| `document` | `document` | r | The document whose contents are being displayed in the window. |
| `floating` | `boolean` | r | Whether the window floats. |
| `id` | `integer` | r | The unique identifier of the window. |
| `index` | `integer` | rw | The index of the window, ordered front to back. |
| `miniaturizable` | `boolean` | r | Whether the window can be miniaturized. |
| `miniaturized` | `boolean` | rw | Whether the window is currently miniaturized. |
| `modal` | `boolean` | r | Whether the window is the application's current modal window. |
| `name` | `text` | rw | The full title of the window. |
| `resizable` | `boolean` | r | Whether the window can be resized. |
| `titled` | `boolean` | r | Whether the window has a title bar. |
| `visible` | `boolean` | rw | Whether the window is currently visible. |
| `zoomable` | `boolean` | r | Whether the window can be zoomed. |
| `zoomed` | `boolean` | rw | Whether the window is currently zoomed. |

### Enumerations

#### `savo`

- `ask` — Ask the user whether or not to save the file.
- `no` — Do not save the file.
- `yes` — Save the file.

## Text Suite

> A set of basic classes for text processing.

### Classes

#### `attachment`

Represents an inline text attachment.  This class is used mainly for make commands.

*Inherits from: `text.ctxt`*

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `file name` | `text` | rw | The path to the file for the attachment |

#### `attribute run`

This subdivides the text into chunks that all have the same attributes.

*Inherits from: `item`*

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `color` | `color` | rw | The color of the first character. |
| `font` | `text` | rw | The name of the font of the first character. |
| `size` | `integer` | rw | The size in points of the first character. |

**Contains**: `attachment`, `attribute run`, `character`, `paragraph`, `word`

#### `character`

This subdivides the text into characters.

*Inherits from: `item`*

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `color` | `color` | rw | The color of the first character. |
| `font` | `text` | rw | The name of the font of the first character. |
| `size` | `integer` | rw | The size in points of the first character. |

**Contains**: `attachment`, `attribute run`, `character`, `paragraph`, `word`

#### `paragraph`

This subdivides the text into paragraphs.

*Inherits from: `item`*

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `color` | `color` | rw | The color of the first character. |
| `font` | `text` | rw | The name of the font of the first character. |
| `size` | `integer` | rw | The size in points of the first character. |

**Contains**: `attachment`, `attribute run`, `character`, `paragraph`, `word`

#### `text`

Rich (styled) text

*Inherits from: `item`*

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `color` | `color` | rw | The color of the first character. |
| `font` | `text` | rw | The name of the font of the first character. |
| `size` | `integer` | rw | The size in points of the first character. |

**Contains**: `attachment`, `attribute run`, `character`, `paragraph`, `word`

#### `word`

This subdivides the text into words.

*Inherits from: `item`*

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `color` | `color` | rw | The color of the first character. |
| `font` | `text` | rw | The name of the font of the first character. |
| `size` | `integer` | rw | The size in points of the first character. |

**Contains**: `attachment`, `attribute run`, `character`, `paragraph`, `word`

## TextEdit suite

> TextEdit specific classes.

## Type Definitions

> Records used in scripting TextEdit

### Classes

#### `print settings`
| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `copies` | `integer` | rw | the number of copies of a document to be printed |
| `collating` | `boolean` | rw | Should printed copies be collated? |
| `starting page` | `integer` | rw | the first page of the document to be printed |
| `ending page` | `integer` | rw | the last page of the document to be printed |
| `pages across` | `integer` | rw | number of logical pages laid across a physical page |
| `pages down` | `integer` | rw | number of logical pages laid out down a physical page |
| `requested print time` | `date` | rw | the time at which the desktop printer should print the document |
| `error handling` | `enum` | rw | how errors are handled |
| `fax number` | `text` | rw | for fax number |
| `target printer` | `text` | rw | for target printer |

### Enumerations

#### `enum`

- `standard` — Standard PostScript error handling
- `detailed` — print a detailed report of PostScript errors

## Type Names

> Other classes and commands
