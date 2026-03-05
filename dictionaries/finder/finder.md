# Finder — AppleScript Reference

> Extracted from scripting dictionary via `sdef`
> 25 commands, 32 classes, 9 suites

```applescript
tell application "Finder"
    -- commands go here
end tell
```

## Standard Suite

> Common terms that most applications should support

### Commands

#### `open`

Open the specified object(s)

- **Direct parameter**: `specifier` — list of objects to open
- **using**: `specifier` *(optional)* — the application file to open the object with
- **with properties**: `record` *(optional)* — the initial values for the properties, to be included with the open command sent to the application that opens the direct object

#### `print`

Print the specified object(s)

- **Direct parameter**: `specifier` — list of objects to print
- **with properties**: `record` *(optional)* — optional properties to be included with the print command sent to the application that prints the direct object

#### `quit`

Quit the Finder


#### `activate`

Activate the specified window (or the Finder)

- **Direct parameter**: `specifier` *(optional)* — the window to activate (if not specified, activates the Finder)

#### `close`

Close an object

- **Direct parameter**: `specifier` — the object to close

#### `count`

Return the number of elements of a particular class within an object

- **Direct parameter**: `specifier` — the object whose elements are to be counted
- **each**: `type` — the class of the elements to be counted
- **Returns**: `integer` — the number of elements

#### `data size`

Return the size in bytes of an object

- **Direct parameter**: `specifier` — the object whose data size is to be returned
- **as**: `type` *(optional)* — the data type for which the size is calculated
- **Returns**: `integer` — the size of the object in bytes

#### `delete`

Move an item from its container to the trash

- **Direct parameter**: `specifier` — the item to delete
- **Returns**: `specifier` — to the item that was just deleted

#### `duplicate`

Duplicate one or more object(s)

- **Direct parameter**: `specifier` — the object(s) to duplicate
- **to**: `location specifier` *(optional)* — the new location for the object(s)
- **replacing**: `boolean` *(optional)* — Specifies whether or not to replace items in the destination that have the same name as items being duplicated
- **routing suppressed**: `boolean` *(optional)* — Specifies whether or not to autoroute items (default is false). Only applies when copying to the system folder.
- **exact copy**: `boolean` *(optional)* — Specifies whether or not to copy permissions/ownership as is
- **Returns**: `specifier` — to the duplicated object(s)

#### `exists`

Verify if an object exists

- **Direct parameter**: `specifier` — the object in question
- **Returns**: `boolean` — true if it exists, false if not

#### `make`

Make a new element

- **new**: `type` — the class of the new element
- **at**: `location specifier` — the location at which to insert the element
- **to**: `specifier` *(optional)* — when creating an alias file, the original item to create an alias to or when creating a file viewer window, the target of the window
- **with properties**: `record` *(optional)* — the initial values for the properties of the element
- **Returns**: `specifier` — to the new object(s)

#### `move`

Move object(s) to a new location

- **Direct parameter**: `specifier` — the object(s) to move
- **to**: `location specifier` — the new location for the object(s)
- **replacing**: `boolean` *(optional)* — Specifies whether or not to replace items in the destination that have the same name as items being moved
- **positioned at**: `list` *(optional)* — Gives a list (in local window coordinates) of positions for the destination items
- **routing suppressed**: `boolean` *(optional)* — Specifies whether or not to autoroute items (default is false). Only applies when moving to the system folder.
- **Returns**: `specifier` — to the object(s) after they have been moved

#### `select`

Select the specified object(s)

- **Direct parameter**: `specifier` — the object to select

## Finder Basics

> Commonly-used Finder commands and object classes

### Commands

#### `openVirtualLocation`

Private event to open a virtual location

- **Direct parameter**: `text` — the location to open

#### `copy`

(NOT AVAILABLE YET) Copy the selected items to the clipboard (the Finder must be the front application)


#### `sort`

Return the specified object(s) in a sorted list

- **Direct parameter**: `specifier` — a list of finder objects to sort
- **by**: `property` — the property to sort the items by (name, index, date, etc.)
- **Returns**: `specifier` — the sorted items in their new order

### Classes

#### `application`

The Finder

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `clipboard` | `specifier` | r | (NOT AVAILABLE YET) the Finder’s clipboard window |
| `name` | `text` | r | the Finder’s name |
| `visible` | `boolean` | rw | Is the Finder’s layer visible? |
| `frontmost` | `boolean` | rw | Is the Finder the frontmost process? |
| `selection` | `specifier` | rw | the selection in the frontmost Finder window |
| `insertion location` | `specifier` | r | the container in which a new folder would appear if “New Folder” was selected |
| `product version` | `text` | r | the version of the System software running on this computer |
| `version` | `text` | r | the version of the Finder |
| `startup disk` | `disk` | r | the startup disk |
| `desktop` | `desktop-object` | r | the desktop |
| `trash` | `trash-object` | r | the trash |
| `home` | `folder` | r | the home directory |
| `computer container` | `computer-object` | r | the computer location (as in Go > Computer) |
| `Finder preferences` | `preferences` | r | Various preferences that apply to the Finder as a whole |

**Contains**: `item`, `container`, `disk`, `folder`, `file`, `alias file`, `application file`, `document file`, `internet location file`, `clipping`, `package`, `window`, `Finder window`, `clipping window`

## Finder items

> Commands used with file system items, and basic item definition

### Commands

#### `clean up`

Arrange items in window nicely (only applies to open windows in icon view that are not kept arranged)

- **Direct parameter**: `specifier` — the window to clean up
- **by**: `property` *(optional)* — the order in which to clean up the objects (name, index, date, etc.)

#### `eject`

Eject the specified disk(s)

- **Direct parameter**: `specifier` *(optional)* — the disk(s) to eject

#### `empty`

Empty the trash

- **Direct parameter**: `specifier` *(optional)* — “empty” and “empty trash” both do the same thing
- **security**: `boolean` *(optional)* — (obsolete)

#### `erase`

(NOT AVAILABLE) Erase the specified disk(s)

- **Direct parameter**: `specifier` — the items to erase

#### `reveal`

Bring the specified object(s) into view

- **Direct parameter**: `specifier` — the object to be made visible

#### `update`

Update the display of the specified object(s) to match their on-disk representation

- **Direct parameter**: `specifier` — the item to update
- **necessity**: `boolean` *(optional)* — only update if necessary (i.e. a finder window is open). default is false
- **registering applications**: `boolean` *(optional)* — register applications. default is true

### Classes

#### `item`

An item

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `name` | `text` | rw | the name of the item |
| `displayed name` | `text` | r | the user-visible name of the item |
| `name extension` | `text` | rw | the name extension of the item (such as “txt”) |
| `extension hidden` | `boolean` | rw | Is the item's extension hidden from the user? |
| `index` | `integer` | r | the index in the front-to-back ordering within its container |
| `container` | `specifier` | r | the container of the item |
| `disk` | `specifier` | r | the disk on which the item is stored |
| `position` | `point` | rw | the position of the item within its parent window (can only be set for an item in a window viewed as icons or buttons) |
| `desktop position` | `point` | rw | the position of the item on the desktop |
| `bounds` | `rectangle` | rw | the bounding rectangle of the item (can only be set for an item in a window viewed as icons or buttons) |
| `label index` | `integer` | rw | the label of the item |
| `locked` | `boolean` | rw | Is the file locked? |
| `kind` | `text` | r | the kind of the item |
| `description` | `text` | r | a description of the item |
| `comment` | `text` | rw | the comment of the item, displayed in the “Get Info” window |
| `size` | `double integer` | r | the logical size of the item |
| `physical size` | `double integer` | r | the actual space used by the item on disk |
| `creation date` | `date` | r | the date on which the item was created |
| `modification date` | `date` | rw | the date on which the item was last modified |
| `icon` | `icon family` | rw | the icon bitmap of the item |
| `URL` | `text` | r | the URL of the item |
| `owner` | `text` | rw | the user that owns the container |
| `group` | `text` | rw | the user or group that has special access to the container |
| `owner privileges` | `priv` | rw |  |
| `group privileges` | `priv` | rw |  |
| `everyones privileges` | `priv` | rw |  |
| `information window` | `specifier` | r | the information window for the item |
| `properties` | `record` | rw | every property of an item |
| `class` | `type` | r | the class of the item |

### Enumerations

#### `priv`

- `read only`
- `read write`
- `write only`
- `none`

## Containers and folders

> Classes that can contain other file system items

### Classes

#### `container`

An item that contains other items

*Inherits from: `item`*

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `entire contents` | `specifier` | r | the entire contents of the container, including the contents of its children |
| `expandable` | `boolean` | r | (NOT AVAILABLE YET) Is the container capable of being expanded as an outline? |
| `expanded` | `boolean` | rw | (NOT AVAILABLE YET) Is the container opened as an outline? (can only be set for containers viewed as lists) |
| `completely expanded` | `boolean` | rw | (NOT AVAILABLE YET) Are the container and all of its children opened as outlines? (can only be set for containers viewed as lists) |
| `container window` | `specifier` | r | the container window for this folder |

**Contains**: `item`, `container`, `folder`, `file`, `alias file`, `application file`, `document file`, `internet location file`, `clipping`, `package`

#### `computer-object`

the Computer location (as in Go > Computer)

*Inherits from: `item`*

#### `disk`

A disk

*Inherits from: `container`*

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `id` | `integer` | r | the unique id for this disk (unchanged while disk remains connected and Finder remains running) |
| `capacity` | `double integer` | r | the total number of bytes (free or used) on the disk |
| `free space` | `double integer` | r | the number of free bytes left on the disk |
| `ejectable` | `boolean` | r | Can the media be ejected (floppies, CDs, and so on)? |
| `local volume` | `boolean` | r | Is the media a local volume (as opposed to a file server)? |
| `startup` | `boolean` | r | Is this disk the boot disk? |
| `format` | `edfm` | r | the filesystem format of this disk |
| `journaling enabled` | `boolean` | r | Does this disk do file system journaling? |
| `ignore privileges` | `boolean` | rw | Ignore permissions on this disk? |

**Contains**: `item`, `container`, `folder`, `file`, `alias file`, `application file`, `document file`, `internet location file`, `clipping`, `package`

#### `folder`

A folder

*Inherits from: `container`*

**Contains**: `item`, `container`, `folder`, `file`, `alias file`, `application file`, `document file`, `internet location file`, `clipping`, `package`

#### `desktop-object`

Desktop-object is the class of the “desktop” object

*Inherits from: `container`*

**Contains**: `item`, `container`, `disk`, `folder`, `file`, `alias file`, `application file`, `document file`, `internet location file`, `clipping`, `package`

#### `trash-object`

Trash-object is the class of the “trash” object

*Inherits from: `container`*

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `warns before emptying` | `boolean` | rw | Display a dialog when emptying the trash? |

**Contains**: `item`, `container`, `folder`, `file`, `alias file`, `application file`, `document file`, `internet location file`, `clipping`, `package`

### Enumerations

#### `edfm`

- `Mac OS format`
- `Mac OS Extended format`
- `UFS format`
- `NFS format`
- `audio format`
- `ProDOS format`
- `MSDOS format`
- `NTFS format`
- `ISO 9660 format`
- `High Sierra format`
- `QuickTake format`
- `Apple Photo format`
- `AppleShare format`
- `UDF format`
- `WebDAV format`
- `FTP format`
- `Packet written UDF format`
- `Xsan format`
- `APFS format`
- `ExFAT format`
- `SMB format`
- `unknown format`

## Files

> Classes representing files

### Classes

#### `file`

A file

*Inherits from: `item`*

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `file type` | `type` | rw | the OSType identifying the type of data contained in the item |
| `creator type` | `type` | rw | the OSType identifying the application that created the item |
| `stationery` | `boolean` | rw | Is the file a stationery pad? |
| `product version` | `text` | r | the version of the product (visible at the top of the “Get Info” window) |
| `version` | `text` | r | the version of the file (visible at the bottom of the “Get Info” window) |

#### `alias file`

An alias file (created with “Make Alias”)

*Inherits from: `file`*

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `original item` | `specifier` | rw | the original item pointed to by the alias |

#### `application file`

An application's file on disk

*Inherits from: `file`*

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `id` | `text` | r | the bundle identifier or creator type of the application |
| `suggested size` | `integer` | r | (AVAILABLE IN 10.1 TO 10.4) the memory size with which the developer recommends the application be launched |
| `minimum size` | `integer` | rw | (AVAILABLE IN 10.1 TO 10.4) the smallest memory size with which the application can be launched |
| `preferred size` | `integer` | rw | (AVAILABLE IN 10.1 TO 10.4) the memory size with which the application will be launched |
| `accepts high level events` | `boolean` | r | Is the application high-level event aware? (OBSOLETE: always returns true) |
| `has scripting terminology` | `boolean` | r | Does the process have a scripting terminology, i.e., can it be scripted? |
| `opens in Classic` | `boolean` | rw | (AVAILABLE IN 10.1 TO 10.4) Should the application launch in the Classic environment? |

#### `document file`

A document file

*Inherits from: `file`*

#### `internet location file`

A file containing an internet location

*Inherits from: `file`*

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `location` | `text` | r | the internet location |

#### `clipping`

A clipping

*Inherits from: `file`*

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `clipping window` | `specifier` | r | (NOT AVAILABLE YET) the clipping window for this clipping |

#### `package`

A package

*Inherits from: `item`*

## Window classes

> Classes representing windows

### Classes

#### `window`

A window

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `id` | `integer` | r | the unique id for this window |
| `position` | `point` | rw | the upper left position of the window |
| `bounds` | `rectangle` | rw | the boundary rectangle for the window |
| `titled` | `boolean` | r | Does the window have a title bar? |
| `name` | `text` | r | the name of the window |
| `index` | `integer` | rw | the number of the window in the front-to-back layer ordering |
| `closeable` | `boolean` | r | Does the window have a close box? |
| `floating` | `boolean` | r | Does the window have a title bar? |
| `modal` | `boolean` | r | Is the window modal? |
| `resizable` | `boolean` | r | Is the window resizable? |
| `zoomable` | `boolean` | r | Is the window zoomable? |
| `zoomed` | `boolean` | rw | Is the window zoomed? |
| `visible` | `boolean` | r | Is the window visible (always true for open Finder windows)? |
| `collapsed` | `boolean` | rw | Is the window collapsed |
| `properties` | `record` | rw | every property of a window |

#### `Finder window`

A file viewer window

*Inherits from: `window`*

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `target` | `specifier` | rw | the container at which this file viewer is targeted |
| `current view` | `ecvw` | rw | the current view for the container window |
| `icon view options` | `icon view options` | r | the icon view options for the container window |
| `list view options` | `list view options` | r | the list view options for the container window |
| `column view options` | `column view options` | r | the column view options for the container window |
| `toolbar visible` | `boolean` | rw | Is the window's toolbar visible? |
| `statusbar visible` | `boolean` | rw | Is the window's status bar visible? |
| `pathbar visible` | `boolean` | rw | Is the window's path bar visible? |
| `sidebar width` | `integer` | rw | the width of the sidebar for the container window |

#### `desktop window`

the desktop window

*Inherits from: `Finder window`*

#### `information window`

An inspector window (opened by “Show Info”)

*Inherits from: `window`*

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `item` | `specifier` | r | the item from which this window was opened |
| `current panel` | `ipnl` | rw | the current panel in the information window |

#### `preferences window`

The Finder Preferences window

*Inherits from: `window`*

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `current panel` | `pple` | rw | The current panel in the Finder preferences window |

#### `clipping window`

The window containing a clipping

*Inherits from: `window`*

### Enumerations

#### `ipnl`

- `General Information panel`
- `Sharing panel`
- `Memory panel`
- `Preview panel`
- `Application panel`
- `Languages panel`
- `Plugins panel`
- `Name & Extension panel`
- `Comments panel`
- `Content Index panel`
- `Burning panel`
- `More Info panel`
- `Simple Header panel`

#### `pple`

- `General Preferences panel`
- `Label Preferences panel`
- `Sidebar Preferences panel`
- `Advanced Preferences panel`

#### `ecvw`

- `icon view`
- `list view`
- `column view`
- `group view`
- `flow view`

## Legacy suite

> Operations formerly handled by the Finder, but now automatically delegated to other applications

### Commands

#### `restart`

Restart the computer


#### `shut down`

Shut Down the computer


#### `sleep`

Put the computer to sleep


### Classes

#### `process`

A process running on this computer

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `name` | `text` | r | the name of the process |
| `visible` | `boolean` | rw | Is the process' layer visible? |
| `frontmost` | `boolean` | rw | Is the process the frontmost process? |
| `file` | `specifier` | r | the file from which the process was launched |
| `file type` | `type` | r | the OSType of the file type of the process |
| `creator type` | `type` | r | the OSType of the creator of the process (the signature) |
| `accepts high level events` | `boolean` | r | Is the process high-level event aware (accepts open application, open document, print document, and quit)? |
| `accepts remote events` | `boolean` | r | Does the process accept remote events? |
| `has scripting terminology` | `boolean` | r | Does the process have a scripting terminology, i.e., can it be scripted? |
| `total partition size` | `integer` | r | the size of the partition with which the process was launched |
| `partition space used` | `integer` | r | the number of bytes currently used in the process' partition |

#### `application process`

A process launched from an application file

*Inherits from: `process`*

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `application file` | `application file` | r | the application file from which this process was launched |

#### `desk accessory process`

A process launched from a desk accessory file

*Inherits from: `process`*

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `desk accessory file` | `specifier` | r | the desk accessory file from which this process was launched |

## Type Definitions

> Definitions of records used in scripting the Finder

### Classes

#### `preferences`

The Finder Preferences

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `window` | `preferences window` | r | the window that would open if Finder preferences was opened |
| `icon view options` | `icon view options` | r | the default icon view options |
| `list view options` | `list view options` | r | the default list view options |
| `column view options` | `column view options` | r | the column view options for all windows |
| `folders spring open` | `boolean` | rw | Spring open folders after the specified delay? |
| `delay before springing` | `real` | rw | the delay before springing open a container in seconds (from 0.167 to 1.169) |
| `desktop shows hard disks` | `boolean` | rw | Hard disks appear on the desktop? |
| `desktop shows external hard disks` | `boolean` | rw | External hard disks appear on the desktop? |
| `desktop shows removable media` | `boolean` | rw | CDs, DVDs, and iPods appear on the desktop? |
| `desktop shows connected servers` | `boolean` | rw | Connected servers appear on the desktop? |
| `new window target` | `specifier` | rw | target location for a newly-opened Finder window |
| `folders open in new windows` | `boolean` | rw | Folders open into new windows? |
| `folders open in new tabs` | `boolean` | rw | Folders open into new tabs? |
| `new windows open in column view` | `boolean` | rw | Open new windows in column view? |
| `all name extensions showing` | `boolean` | rw | Show name extensions, even for items whose “extension hidden” is true? |

#### `label`

(NOT AVAILABLE YET) A Finder label (name and color)

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `name` | `text` | rw | the name associated with the label |
| `index` | `integer` | rw | the index in the front-to-back ordering within its container |
| `color` | `RGB color` | rw | the color associated with the label |

#### `icon family`

(NOT AVAILABLE YET) A family of icons

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `large monochrome icon and mask` | `ICN#` | r | the large black-and-white icon and the mask for large icons |
| `large 8 bit mask` | `l8mk` | r | the large 8-bit mask for large 32-bit icons |
| `large 32 bit icon` | `il32` | r | the large 32-bit color icon |
| `large 8 bit icon` | `icl8` | r | the large 8-bit color icon |
| `large 4 bit icon` | `icl4` | r | the large 4-bit color icon |
| `small monochrome icon and mask` | `ics#` | r | the small black-and-white icon and the mask for small icons |
| `small 8 bit mask` | `s8mk` | r | the small 8-bit mask for small 32-bit icons |
| `small 32 bit icon` | `is32` | r | the small 32-bit color icon |
| `small 8 bit icon` | `ics8` | r | the small 8-bit color icon |
| `small 4 bit icon` | `ics4` | r | the small 4-bit color icon |

#### `icon view options`

the icon view options

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `arrangement` | `earr` | rw | the property by which to keep icons arranged |
| `icon size` | `integer` | rw | the size of icons displayed in the icon view |
| `shows item info` | `boolean` | rw | additional info about an item displayed in icon view |
| `shows icon preview` | `boolean` | rw | displays a preview of the item in icon view |
| `text size` | `integer` | rw | the size of the text displayed in the icon view |
| `label position` | `epos` | rw | the location of the label in reference to the icon |
| `background picture` | `file` | rw | the background picture of the icon view |
| `background color` | `RGB color` | rw | the background color of the icon view |

#### `column view options`

the column view options

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `text size` | `integer` | rw | the size of the text displayed in the column view |
| `shows icon` | `boolean` | rw | displays an icon next to the label in column view |
| `shows icon preview` | `boolean` | rw | displays a preview of the item in column view |
| `shows preview column` | `boolean` | rw | displays the preview column in column view |
| `discloses preview pane` | `boolean` | rw | discloses the preview pane of the preview column in column view |

#### `list view options`

the list view options

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `calculates folder sizes` | `boolean` | rw | Are folder sizes calculated and displayed in the window? |
| `shows icon preview` | `boolean` | rw | displays a preview of the item in list view |
| `icon size` | `lvic` | rw | the size of icons displayed in the list view |
| `text size` | `integer` | rw | the size of the text displayed in the list view |
| `sort column` | `column` | rw | the column that the list view is sorted on |
| `uses relative dates` | `boolean` | rw | Are relative dates (e.g., today, yesterday) shown in the list view? |

**Contains**: `column`

#### `column`

a column of a list view

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `index` | `integer` | rw | the index in the front-to-back ordering within its container |
| `name` | `elsv` | r | the column name |
| `sort direction` | `sodr` | rw | The direction in which the window is sorted |
| `width` | `integer` | rw | the width of this column |
| `minimum width` | `integer` | r | the minimum allowed width of this column |
| `maximum width` | `integer` | r | the maximum allowed width of this column |
| `visible` | `boolean` | rw | is this column visible |

#### `alias list`

A list of aliases. Use ‘as alias list’ when a list of aliases is needed (instead of a list of file system item references).

### Enumerations

#### `earr`

- `not arranged`
- `snap to grid`
- `arranged by name`
- `arranged by modification date`
- `arranged by creation date`
- `arranged by size`
- `arranged by kind`
- `arranged by label`

#### `epos`

- `right`
- `bottom`

#### `sodr`

- `normal`
- `reversed`

#### `elsv`

- `name column`
- `modification date column`
- `creation date column`
- `size column`
- `kind column`
- `label column`
- `version column`
- `comment column`

#### `lvic`

- `small icon`
- `large icon`

## Enumerations

> Enumerations for the Finder

### Enumerations

#### `isiz`

- `mini`
- `small`
- `large`

#### `sort`

- `name`
- `modification date`
- `creation date`
- `size`
- `kind`
- `label index`
- `comment`
- `version`
