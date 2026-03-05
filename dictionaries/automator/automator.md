# Automator — AppleScript Reference

> Extracted from scripting dictionary via `sdef`
> 16 commands, 17 classes, 5 suites

```applescript
tell application "Automator"
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

## Automator Suite

> Terms and Events for controlling the Automator application

### Commands

#### `add`

Add an Automator action or variable to a workflow

- **Direct parameter**: `any` — The Automator action or variable to add.
- **to**: `workflow` — the workflow to which the Automator action or variable is to be added
- **at index**: `integer` *(optional)* — the index at which the Automator action or variable is to be added

#### `execute`

Execute the workflow

- **Direct parameter**: `workflow` — 
- **Returns**: `any` — 

#### `remove`

Remove an Automator action or variable from a workflow

- **Direct parameter**: `any` — The Automator action or variable to remove.

### Classes

#### `Automator action`

A single step in a workflow

*Inherits from: `item`*

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `bundle id` | `text` | r | The bundle identifier for the action |
| `category` | `list` | r | The category that contains the action |
| `comment` | `text` | rw | The comment for the name of the action |
| `enabled` | `boolean` | rw | Is the action enabled? |
| `execution error message` | `text` | r | The text error message generated by execution of the action |
| `execution error number` | `integer` | r | The numeric error code generated by execution of the action |
| `execution result` | `any` | r | The result of the action, passed as input to the next action |
| `icon name` | `text` | r | The icon name of the action |
| `id` | `text` | r | The unique identifier for the action |
| `ignores input` | `boolean` | rw | Shall the action ignore its input when it is run? |
| `index` | `integer` | rw | The index of the action |
| `input types` | `list` | r | The input types accepted by the action |
| `keywords` | `list` | r | The keywords that describe the action |
| `name` | `text` | r | The localized name of the action |
| `output types` | `list` | r | The output types produced by the action |
| `parent workflow` | `workflow` | r | The workflow that contains the action |
| `path` | `alias` | r | The path of the file that contains the action |
| `show action when run` | `boolean` | rw | Shall the action show its user interface when it is run? |
| `target application` | `list` | r | The application with which the action communicates |
| `version` | `text` | r | The version of the action |
| `warning action` | `text` | r | The action suggested by the warning, if any |
| `warning level` | `wlev` | r | The level of the warning, increasing in likelihood of data loss |
| `warning message` | `text` | r | The message that accompanies the warning, if any |

**Contains**: `required resource`, `setting`

#### `required resource`

A resource required for proper operation of the action

*Inherits from: `item`*

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `kind` | `text` | r | The kind of required resource |
| `name` | `text` | r | The name of the required resource |
| `resource` | `text` | r | The specification of the required resource |
| `version` | `integer` | r | The minimum acceptable version of the required resource |

#### `setting`

A named value

*Inherits from: `item`*

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `default value` | `any` | r | The default value of the setting |
| `name` | `text` | r | The name of the setting |
| `value` | `any` | rw | The value of the setting |

#### `variable`

A variable used by the workflow.

*Inherits from: `item`*

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `name` | `text` | rw | The name of the variable |
| `settable` | `boolean` | r | Are the name and value of the variable settable? |
| `value` | `any` | rw | The value of the variable |

#### `workflow`

A series of actions stored in a file

*Inherits from: `document`*

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `current action` | `Automator action` | r | The current or most recent action of the workflow |
| `execution error message` | `text` | r | The text error message generated by the most recent execution |
| `execution error number` | `integer` | r | The numeric error code generated by the most recent execution |
| `execution id` | `text` | r | The identifier of the current or most recent execution |
| `execution result` | `any` | r | The result of the most recent execution; the output of the last action of that execution |
| `name` | `text` | r | The name of the workflow |

**Contains**: `Automator action`, `variable`

### Enumerations

#### `wlev`

- `irreversible` — irreversible
- `none` — none
- `reversible` — reversible

## Type Definitions

> Records used in scripting Automator

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
