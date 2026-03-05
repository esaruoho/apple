# Terminal — AppleScript Reference

> Extracted from scripting dictionary via `sdef`
> 13 commands, 4 classes, 2 suites

```applescript
tell application "Terminal"
    -- commands go here
end tell
```

## Standard Suite

> Common classes and commands for all applications.

### Commands

#### `open`

Open a document.

- **Direct parameter**: `specifier` — The file(s) to be opened.

#### `close`

Close a document.

- **Direct parameter**: `specifier` — the document(s) or window(s) to close.
- **saving**: `save options` *(optional)* — Whether or not changes should be saved before closing.
- **saving in**: `file` *(optional)* — The file in which to save the document.

#### `save`

Save a document.

- **Direct parameter**: `specifier` — The document(s) or window(s) to save.
- **in**: `file` *(optional)* — The file in which to save the document.

#### `print`

Print a document.

- **Direct parameter**: `specifier` — The file(s), document(s), or window(s) to be printed.
- **with properties**: `print settings` *(optional)* — The print settings to use.
- **print dialog**: `boolean` *(optional)* — Should the application show the print dialog?

#### `quit`

Quit the application.

- **saving**: `save options` *(optional)* — Whether or not changed documents should be saved before closing.

#### `count`

Return the number of elements of a particular class within an object.

- **Direct parameter**: `specifier` — the object whose elements are to be counted
- **each**: `type` *(optional)* — The class of objects to be counted.
- **Returns**: `integer` — the number of elements

#### `delete`

Delete an object.

- **Direct parameter**: `specifier` — the object to delete

#### `duplicate`

Copy object(s) and put the copies at a new location.

- **Direct parameter**: `specifier` — the object(s) to duplicate
- **to**: `location specifier` — The location for the new object(s).
- **with properties**: `record` *(optional)* — Properties to be set in the new duplicated object(s).

#### `exists`

Verify if an object exists.

- **Direct parameter**: `specifier` — the object in question
- **Returns**: `boolean` — true if it exists, false if not

#### `make`

Make a new object.

- **new**: `type` — The class of the new object.
- **at**: `location specifier` *(optional)* — The location at which to insert the object.
- **with data**: `any` *(optional)* — The initial contents of the object.
- **with properties**: `record` *(optional)* — The initial values for properties of the object.
- **Returns**: `specifier` — to the new object

#### `move`

Move object(s) to a new location.

- **Direct parameter**: `specifier` — the object(s) to move
- **to**: `location specifier` — The new location for the object(s).

### Classes

#### `application`

The application‘s top-level scripting object.

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `name` | `text` | r | The name of the application. |
| `frontmost` | `boolean` | r | Is this the frontmost (active) application? |
| `version` | `text` | r | The version of the application. |

**Contains**: `window`

#### `window`

A window.

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `name` | `text` | r | The full title of the window. |
| `id` | `integer` | r | The unique identifier of the window. |
| `index` | `integer` | rw | The index of the window, ordered front to back. |
| `bounds` | `rectangle` | rw | The bounding rectangle of the window. |
| `closeable` | `boolean` | r | Whether the window has a close box. |
| `miniaturizable` | `boolean` | r | Whether the window can be minimized. |
| `miniaturized` | `boolean` | rw | Whether the window is currently minimized. |
| `resizable` | `boolean` | r | Whether the window can be resized. |
| `visible` | `boolean` | rw | Whether the window is currently visible. |
| `zoomable` | `boolean` | r | Whether the window can be zoomed. |
| `zoomed` | `boolean` | rw | Whether the window is currently zoomed. |
| `frontmost` | `boolean` | rw | Whether the window is currently the frontmost Terminal window. |
| `position` | `point` | rw | The position of the window, relative to the upper left corner of the screen. |
| `origin` | `point` | rw | The position of the window, relative to the lower left corner of the screen. |
| `size` | `point` | rw | The width and height of the window |
| `frame` | `rectangle` | rw | The bounding rectangle, relative to the lower left corner of the screen. |

**Contains**: `tab`

### Enumerations

#### `save options`

- `yes` — Save the file.
- `no` — Do not save the file.
- `ask` — Ask the user whether or not to save the file.

#### `printing error handling`

- `standard` — Standard PostScript error handling
- `detailed` — print a detailed report of PostScript errors

## Terminal Suite

> Terminal specific classes.

### Commands

#### `do script`

Runs a UNIX shell script or command.

- **Direct parameter**: `text` *(optional)* — The command to execute.
- **with command**: `specifier` *(optional)* — Data to be passed to the Terminal application as the command line. Deprecated; use direct parameter instead.
- **in**: `specifier` *(optional)* — The tab in which to execute the command
- **Returns**: `tab` — The tab the command was executed in.

#### `get URL`

Open a command an ssh, telnet, or x-man-page URL.

- **Direct parameter**: `text` — The URL to open.

### Classes

#### `settings set`

A set of settings.

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `id` | `integer` | r | The unique identifier of the settings set. |
| `name` | `text` | rw | The name of the settings set. |
| `number of rows` | `integer` | rw | The number of rows displayed in the tab. |
| `number of columns` | `integer` | rw | The number of columns displayed in the tab. |
| `cursor color` | `color` | rw | The cursor color for the tab. |
| `background color` | `color` | rw | The background color for the tab. |
| `normal text color` | `color` | rw | The normal text color for the tab. |
| `bold text color` | `color` | rw | The bold text color for the tab. |
| `font name` | `text` | rw | The name of the font used to display the tab’s contents. |
| `font size` | `integer` | rw | The size of the font used to display the tab’s contents. |
| `font antialiasing` | `boolean` | rw | Whether the font used to display the tab’s contents is antialiased. |
| `clean commands` | `` | rw | The processes which will be ignored when checking whether a tab can be closed without showing a prompt. |
| `title displays device name` | `boolean` | rw | Whether the title contains the device name. |
| `title displays shell path` | `boolean` | rw | Whether the title contains the shell path. |
| `title displays window size` | `boolean` | rw | Whether the title contains the tab’s size, in rows and columns. |
| `title displays settings name` | `boolean` | rw | Whether the title contains the settings name. |
| `title displays custom title` | `boolean` | rw | Whether the title contains a custom title. |
| `custom title` | `text` | rw | The tab’s custom title. |

#### `tab`

A tab.

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `number of rows` | `integer` | rw | The number of rows displayed in the tab. |
| `number of columns` | `integer` | rw | The number of columns displayed in the tab. |
| `contents` | `text` | r | The currently visible contents of the tab. |
| `history` | `text` | r | The contents of the entire scrolling buffer of the tab. |
| `busy` | `boolean` | r | Whether the tab is busy running a process. |
| `processes` | `` | r | The processes currently running in the tab. |
| `selected` | `boolean` | rw | Whether the tab is selected. |
| `title displays custom title` | `boolean` | rw | Whether the title contains a custom title. |
| `custom title` | `text` | rw | The tab’s custom title. |
| `tty` | `text` | r | The tab’s TTY device. |
| `current settings` | `settings set` | rw | The set of settings which control the tab’s behavior and appearance. |
| `cursor color` | `color` | rw | The cursor color for the tab. |
| `background color` | `color` | rw | The background color for the tab. |
| `normal text color` | `color` | rw | The normal text color for the tab. |
| `bold text color` | `color` | rw | The bold text color for the tab. |
| `clean commands` | `` | rw | The processes which will be ignored when checking whether a tab can be closed without showing a prompt. |
| `title displays device name` | `boolean` | rw | Whether the title contains the device name. |
| `title displays shell path` | `boolean` | rw | Whether the title contains the shell path. |
| `title displays window size` | `boolean` | rw | Whether the title contains the tab’s size, in rows and columns. |
| `title displays file name` | `boolean` | rw | Whether the title contains the file name. |
| `font name` | `text` | rw | The name of the font used to display the tab’s contents. |
| `font size` | `integer` | rw | The size of the font used to display the tab’s contents. |
| `font antialiasing` | `boolean` | rw | Whether the font used to display the tab’s contents is antialiased. |
