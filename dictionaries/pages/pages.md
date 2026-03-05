# Pages — AppleScript Reference

> Extracted from scripting dictionary via `sdef`
> 11 commands, 23 classes, 3 suites

```applescript
tell application "Pages"
    -- commands go here
end tell
```

## iWork Text Suite

> Classes and commands for iWorks text objects.

### Classes

#### `rich text`

This provides the base rich text class for all iWork applications.

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `color` | `color` | rw | The color of the font. Expressed as an RGB value consisting of a list of three color values from 0 to 65535. ex: Blue = {0, 0, 65535}. |
| `font` | `text` | rw | The name of the font.  Can be the PostScript name, such as: “TimesNewRomanPS-ItalicMT”, or display name: “Times New Roman Italic”. TIP: Use the Font Book application get the information about a typeface. |
| `size` | `real` | rw | The size of the font. |

**Contains**: `character`, `paragraph`, `word`

#### `character`

One of some text's characters.

*Inherits from: `rich text`*

#### `paragraph`

One of some text's paragraphs.

*Inherits from: `rich text`*

**Contains**: `character`, `word`

#### `word`

One of some text's words.

*Inherits from: `rich text`*

**Contains**: `character`

## iWork Suite

> A set of basic classes for iWork applications.

### Commands

#### `set`

Sets the value of the specified object(s).

- **Direct parameter**: `specifier` — 
- **to**: `any` — The new value.

#### `delete`

Delete an object.

- **Direct parameter**: `specifier` — 

#### `make`

Create a new object.

- **new**: `type` — The class of the new object.
- **at**: `location specifier` *(optional)* — The location at which to insert the object.
- **with data**: `any` *(optional)* — The initial contents of the object.
- **with properties**: `record` *(optional)* — The initial values for properties of the object.
- **Returns**: `specifier` — The new object.

#### `clear`

Clear the contents of a specified range of cells, including formatting and style.

- **Direct parameter**: `range` — 

#### `merge`

Merge a specified range of cells.

- **Direct parameter**: `range` — 

#### `sort`

Sort the rows of the table.

- **Direct parameter**: `table` — 
- **by**: `column` — The column to sort by.
- **direction**: `NMSD` *(optional)* — 
- **in rows**: `range` *(optional)* — Limit the sort to the specified rows.

#### `unmerge`

Unmerge all merged cells in a specified range.

- **Direct parameter**: `range` — 

#### `set password`

Set a password to an unencrypted document.

- **Direct parameter**: `text` — 
- **to**: `document` *(optional)* — The document to set a password to. If unspecified, the current target is assumed.
- **hint**: `text` *(optional)* — A hint for the password.
- **saving in keychain**: `boolean` *(optional)* — Whether to save the password in keychain or not. By default, the password is not saved in the keychain.

#### `remove password`

Remove the password from the document.

- **Direct parameter**: `text` — The current password of the document.
- **from**: `document` *(optional)* — The document from which to remove the password. If unspecified, the current target is assumed.

### Classes

#### `iWork container`

A container for iWork items

**Contains**: `audio clip`, `chart`, `image`, `iWork item`, `group`, `line`, `movie`, `shape`, `table`, `text item`

#### `iWork item`

An item which supports formatting

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `height` | `integer` | rw | The height of the iWork item. |
| `locked` | `boolean` | rw | Whether the object is locked. |
| `parent` | `iWork container` | r | The iWork container containing this iWork item. |
| `position` | `point` | rw | The horizontal and vertical coordinates of the top left point of the iWork item. |
| `width` | `integer` | rw | The width of the iWork item. |

#### `audio clip`

An audio clip

*Inherits from: `iWork item`*

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `file name` | `` | rw | The name of the audio file. |
| `clip volume` | `integer` | rw | The volume setting for the audio clip, from 0 (none) to 100 (full volume). |
| `repetition method` | `playback repetition method` | rw | If or how the audio clip repeats. |

#### `shape`

A shape container

*Inherits from: `iWork item`*

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `background fill type` | `item fill options` | r | The background, if any, for the shape. |
| `object text` | `rich text` | rw | The text contained within the shape. |
| `reflection showing` | `boolean` | rw | Is the iWork item displaying a reflection? |
| `reflection value` | `integer` | rw | The percentage of reflection of the iWork item, from 0 (none) to 100 (full). |
| `rotation` | `integer` | rw | The rotation of the iWork item, in degrees from 0 to 359. |
| `opacity` | `integer` | rw | The opacity of the object, in percent. |

#### `chart`

A chart

*Inherits from: `iWork item`*

#### `image`

An image container

*Inherits from: `iWork item`*

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `description` | `text` | rw | Text associated with the image, read aloud by VoiceOver. |
| `file` | `file` | r | The image file. |
| `file name` | `` | rw | The name of the image file. |
| `opacity` | `integer` | rw | The opacity of the object, in percent. |
| `reflection showing` | `boolean` | rw | Is the iWork item displaying a reflection? |
| `reflection value` | `integer` | rw | The percentage of reflection of the iWork item, from 0 (none) to 100 (full). |
| `rotation` | `integer` | rw | The rotation of the iWork item, in degrees from 0 to 359. |

#### `group`

A group container

*Inherits from: `iWork container`*

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `height` | `integer` | rw | The height of the iWork item. |
| `parent` | `iWork container` | r | The iWork container containing this iWork item. |
| `position` | `point` | rw | The horizontal and vertical coordinates of the top left point of the iWork item. |
| `width` | `integer` | rw | The width of the iWork item. |
| `rotation` | `integer` | rw | The rotation of the iWork item, in degrees from 0 to 359. |

#### `line`

A line

*Inherits from: `iWork item`*

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `end point` | `point` | rw | A list of two numbers indicating the horizontal and vertical position of the line ending point. |
| `reflection showing` | `boolean` | rw | Is the iWork item displaying a reflection? |
| `reflection value` | `integer` | rw | The percentage of reflection of the iWork item, from 0 (none) to 100 (full). |
| `rotation` | `integer` | rw | The rotation of the iWork item, in degrees from 0 to 359. |
| `start point` | `point` | rw | A list of two numbers indicating the horizontal and vertical position of the line starting point. |

#### `movie`

A movie container

*Inherits from: `iWork item`*

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `file name` | `` | rw | The name of the movie file. |
| `movie volume` | `integer` | rw | The volume setting for the movie, from 0 (none) to 100 (full volume). |
| `opacity` | `integer` | rw | The opacity of the object, in percent. |
| `reflection showing` | `boolean` | rw | Is the iWork item displaying a reflection? |
| `reflection value` | `integer` | rw | The percentage of reflection of the iWork item, from 0 (none) to 100 (full). |
| `repetition method` | `playback repetition method` | rw | If or how the movie repeats. |
| `rotation` | `integer` | rw | The rotation of the iWork item, in degrees from 0 to 359. |

#### `table`

A table

*Inherits from: `iWork item`*

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `name` | `text` | rw | The item's name. |
| `cell range` | `range` | r | The range describing every cell in the table. |
| `selection range` | `range` | rw | The cells currently selected in the table. |
| `row count` | `integer` | rw | The number of rows in the table. |
| `column count` | `integer` | rw | The number of columns in the table. |
| `header row count` | `integer` | rw | The number of header rows in the table. |
| `header column count` | `integer` | rw | The number of header columns in the table. |
| `footer row count` | `integer` | rw | The number of footer rows in the table. |

**Contains**: `cell`, `row`, `column`, `range`

#### `text item`

A text container

*Inherits from: `iWork item`*

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `background fill type` | `item fill options` | r | The background, if any, for the text item. |
| `object text` | `rich text` | rw | The text contained within the text item. |
| `opacity` | `integer` | rw | The opacity of the object, in percent. |
| `reflection showing` | `boolean` | rw | Is the iWork item displaying a reflection? |
| `reflection value` | `integer` | rw | The percentage of reflection of the iWork item, from 0 (none) to 100 (full). |
| `rotation` | `integer` | rw | The rotation of the iWork item, in degrees from 0 to 359. |

#### `range`

A range of cells in a table

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `font name` | `text` | rw | The font of the range's cells. |
| `font size` | `real` | rw | The font size of the range's cells. |
| `format` | `` | rw | The format of the range's cells. |
| `alignment` | `tAHT` | rw | The horizontal alignment of content in the range's cells. |
| `name` | `text` | r | The range's coordinates. |
| `text color` | `color` | rw | The text color of the range's cells. |
| `text wrap` | `boolean` | rw | Whether text should wrap in the range's cells. |
| `background color` | `color` | rw | The background color of the range's cells. |
| `vertical alignment` | `tAVT` | rw | The vertical alignment of content in the range's cells. |

**Contains**: `cell`, `column`, `row`

#### `cell`

A cell in a table

*Inherits from: `range`*

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `column` | `column` | r | The cell's column. |
| `row` | `row` | r | The cell's row. |
| `value` | `` | rw | The actual value in the cell, or missing value if the cell is empty. |
| `formatted value` | `text` | r | The formatted value in the cell, or missing value if the cell is empty. |
| `formula` | `text` | r | The formula in the cell, as text, e.g. =SUM(40+2). If the cell does not contain a formula, returns missing value. To set the value of a cell to a formula as text, use the value property. |

#### `row`

A row of cells in a table

*Inherits from: `range`*

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `address` | `integer` | r | The row's index in the table (e.g., the second row has address 2). |
| `height` | `real` | rw | The height of the row. |

#### `column`

A column of cells in a table

*Inherits from: `range`*

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `address` | `integer` | r | The column's index in the table (e.g., the second column has address 2). |
| `width` | `real` | rw | The width of the column. |

### Enumerations

#### `tAVT`

- `bottom` — Right-align content.
- `center` — Center-align content.
- `top` — Top-align content.

#### `tAHT`

- `auto align` — Auto-align based on content type.
- `center` — Center-align content.
- `justify` — Fully justify (left and right) content.
- `left` — Left-align content.
- `right` — Right-align content.

#### `NMSD`

- `ascending` — Sort in increasing value order
- `descending` — Sort in decreasing value order

#### `NMCT`

- `automatic` — Automatic format
- `checkbox` — Checkbox control format (Numbers only)
- `currency` — Currency number format
- `date and time` — Date and time format
- `fraction` — Fraction number format
- `number` — Decimal number format
- `percent` — Percentage number format
- `pop up menu` — Pop-up menu control format (Numbers only)
- `scientific` — Scientific notation format
- `slider` — Slider control format (Numbers only)
- `stepper` — Stepper control format (Numbers only)
- `text` — Text format
- `duration` — Duration format
- `rating` — Rating format. (Numbers only)
- `numeral system` — Numeral System

#### `item fill options`

- `no fill`
- `color fill`
- `gradient fill`
- `advanced gradient fill`
- `image fill`
- `advanced image fill`

#### `playback repetition method`

- `none`
- `loop`
- `loop back and forth`

## Pages Suite

> Classes and commands for Pages.

### Commands

#### `make`

Create a new object.

- **new**: `type` — The class of the new object.
- **at**: `location specifier` *(optional)* — The location at which to insert the object.
- **with data**: `any` *(optional)* — The initial contents of the object.
- **with properties**: `record` *(optional)* — The initial values for properties of the object.
- **Returns**: `specifier` — The new object.

#### `export`

Export a document to another file

- **Direct parameter**: `document` — The document to export
- **to**: `file` — the destination file
- **as**: `export format` — The format to use.
- **with properties**: `export options` *(optional)* — Optional export settings.

### Classes

#### `template`

A styled document layout.

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `id` | `text` | r | The identifier used by the application. |
| `name` | `text` | r | The localized name displayed to the user. |

#### `section`

A section within a document.

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `body text` | `rich text` | rw | The section body text. |

**Contains**: `audio clip`, `chart`, `group`, `image`, `iWork item`, `line`, `movie`, `page`, `shape`, `table`, `text item`

#### `page`

A page of the document.

*Inherits from: `iWork container`*

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `body text` | `rich text` | rw | The page body text. |

#### `placeholder text`

One of some text's placeholders.

*Inherits from: `rich text`*

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `tag` | `text` | rw | Its script tag. |

### Enumerations

#### `saveable file format`

- `Pages Format` — The Pages native file format

#### `export format`

- `EPUB` — EPUB
- `unformatted text` — Plain text
- `PDF` — PDF
- `Microsoft Word` — Microsoft Word
- `Pages 09` — Pages 09
- `formatted text` — RTF

#### `image quality`

- `Good` — good quality
- `Better` — better quality
- `Best` — best quality
