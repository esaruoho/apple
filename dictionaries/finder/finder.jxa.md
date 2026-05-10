# Finder — JavaScript for Automation (JXA) Reference

> Rendered from `finder.yaml` by `bin/sdef-to-jxa.py`. JXA dialect of the AppleScript dictionary in `finder.md`.
> Translation rules: WWDC 2014 #306 — *JavaScript for Automation* (Sal Soghoian + David Steinberg).

## Get the application

```javascript
var Finder = Application('Finder')
Finder.includeStandardAdditions = true   // if calling beep/say/displayDialog
```

**Commands:** 25  ·  **Classes:** 32  ·  **Suites:** 9

## Suite — Standard Suite

_Common terms that most applications should support_

### Commands

```javascript
// Open the specified object(s)
Finder.open(target, {using: /* specifier */, withProperties: {}})

// Print the specified object(s)
Finder.print(target, {withProperties: {}})

// Quit the Finder
Finder.quit()

// Activate the specified window (or the Finder)
Finder.activate(target)

// Close an object
Finder.close(target)

// Return the number of elements of a particular class within an object
Finder.count(target, {each: /* type */})

// Return the size in bytes of an object
Finder.dataSize(target, {as: /* type */})

// Move an item from its container to the trash
Finder.delete(target)

// Duplicate one or more object(s)
Finder.duplicate(target, {to: Path('/path'), replacing: true, routingSuppressed: true, exactCopy: true})

// Verify if an object exists
Finder.exists(target)

// Make a new element
Finder.make({new: /* type */, at: Path('/path'), to: /* specifier */, withProperties: {}})

// Move object(s) to a new location
Finder.move(target, {to: Path('/path'), replacing: true, positionedAt: /* list */, routingSuppressed: true})

// Select the specified object(s)
Finder.select(target)

```

## Suite — Finder Basics

_Commonly-used Finder commands and object classes_

### Commands

```javascript
// Private event to open a virtual location
Finder.openvirtuallocation('...')

// (NOT AVAILABLE YET) Copy the selected items to the clipboard (the Finder must be the front application)
Finder.copy()

// Return the specified object(s) in a sorted list
Finder.sort(target, {by: /* property */})

```

### Classes

```javascript
// class: application
// The Finder
application.visible        // getter (boolean)
application.visible = /* value */  // setter
application.clipboard        // read-only getter (specifier)
application.items[0]                   // first item
application.items.whose({name: 'x'})  // filter

```

## Suite — Finder items

_Commands used with file system items, and basic item definition_

### Commands

```javascript
// Arrange items in window nicely (only applies to open windows in icon view that are not kept arranged)
Finder.cleanUp(target, {by: /* property */})

// Eject the specified disk(s)
Finder.eject(target)

// Empty the trash
Finder.empty(target, {security: true})

// (NOT AVAILABLE) Erase the specified disk(s)
Finder.erase(target)

// Bring the specified object(s) into view
Finder.reveal(target)

// Update the display of the specified object(s) to match their on-disk representation
Finder.update(target, {necessity: true, registeringApplications: true})

```

### Classes

```javascript
// class: item
// An item
item.name        // getter (text)
item.name = '...'  // setter
item.displayedName        // read-only getter (text)

```

## Suite — Containers and folders

_Classes that can contain other file system items_

### Classes

```javascript
// class: container
// An item that contains other items
container.expanded        // getter (boolean)
container.expanded = /* value */  // setter
container.entireContents        // read-only getter (specifier)
container.items[0]                   // first item
container.items.whose({name: 'x'})  // filter

// class: computer-object
// the Computer location (as in Go > Computer)

// class: disk
// A disk
disk.ignorePrivileges        // getter (boolean)
disk.ignorePrivileges = /* value */  // setter
disk.id        // read-only getter (integer)
disk.items[0]                   // first item
disk.items.whose({name: 'x'})  // filter

// class: folder
// A folder
folder.items[0]                   // first item
folder.items.whose({name: 'x'})  // filter

// class: desktop-object
// Desktop-object is the class of the “desktop” object
desktop-object.items[0]                   // first item
desktop-object.items.whose({name: 'x'})  // filter

// class: trash-object
// Trash-object is the class of the “trash” object
trash-object.warnsBeforeEmptying        // getter (boolean)
trash-object.warnsBeforeEmptying = /* value */  // setter
trash-object.items[0]                   // first item
trash-object.items.whose({name: 'x'})  // filter

```

## Suite — Files

_Classes representing files_

### Classes

```javascript
// class: file
// A file
file.fileType        // getter (type)
file.fileType = /* value */  // setter
file.productVersion        // read-only getter (text)

// class: alias file
// An alias file (created with “Make Alias”)
aliasfile.originalItem        // getter (specifier)
aliasfile.originalItem = /* value */  // setter

// class: application file
// An application's file on disk
applicationfile.minimumSize        // getter (integer)
applicationfile.minimumSize = /* value */  // setter
applicationfile.id        // read-only getter (text)

// class: document file
// A document file

// class: internet location file
// A file containing an internet location
internetlocationfile.location        // read-only getter (text)

// class: clipping
// A clipping
clipping.clippingWindow        // read-only getter (specifier)

// class: package
// A package

```

## Suite — Window classes

_Classes representing windows_

### Classes

```javascript
// class: window
// A window
window.position        // getter (point)
window.position = /* value */  // setter
window.id        // read-only getter (integer)

// class: Finder window
// A file viewer window
finderwindow.target        // getter (specifier)
finderwindow.target = /* value */  // setter
finderwindow.iconViewOptions        // read-only getter (icon view options)

// class: desktop window
// the desktop window

// class: information window
// An inspector window (opened by “Show Info”)
informationwindow.currentPanel        // getter (ipnl)
informationwindow.currentPanel = /* value */  // setter
informationwindow.item        // read-only getter (specifier)

// class: preferences window
// The Finder Preferences window
preferenceswindow.currentPanel        // getter (pple)
preferenceswindow.currentPanel = /* value */  // setter

// class: clipping window
// The window containing a clipping

```

## Suite — Legacy suite

_Operations formerly handled by the Finder, but now automatically delegated to other applications_

### Commands

```javascript
// Restart the computer
Finder.restart()

// Shut Down the computer
Finder.shutDown()

// Put the computer to sleep
Finder.sleep()

```

### Classes

```javascript
// class: process
// A process running on this computer
process.visible        // getter (boolean)
process.visible = /* value */  // setter
process.name        // read-only getter (text)

// class: application process
// A process launched from an application file
applicationprocess.applicationFile        // read-only getter (application file)

// class: desk accessory process
// A process launched from a desk accessory file
deskaccessoryprocess.deskAccessoryFile        // read-only getter (specifier)

```

## Suite — Type Definitions

_Definitions of records used in scripting the Finder_

### Classes

```javascript
// class: preferences
// The Finder Preferences
preferences.foldersSpringOpen        // getter (boolean)
preferences.foldersSpringOpen = /* value */  // setter
preferences.window        // read-only getter (preferences window)

// class: label
// (NOT AVAILABLE YET) A Finder label (name and color)
label.name        // getter (text)
label.name = '...'  // setter

// class: icon family
// (NOT AVAILABLE YET) A family of icons
iconfamily.largeMonochromeIconAndMask        // read-only getter (ICN#)

// class: icon view options
// the icon view options
iconviewoptions.arrangement        // getter (earr)
iconviewoptions.arrangement = /* value */  // setter

// class: column view options
// the column view options
columnviewoptions.textSize        // getter (integer)
columnviewoptions.textSize = /* value */  // setter

// class: list view options
// the list view options
listviewoptions.calculatesFolderSizes        // getter (boolean)
listviewoptions.calculatesFolderSizes = /* value */  // setter
listviewoptions.columns[0]                   // first column
listviewoptions.columns.whose({name: 'x'})  // filter

// class: column
// a column of a list view
column.index        // getter (integer)
column.index = /* value */  // setter
column.name        // read-only getter (elsv)

// class: alias list
// A list of aliases. Use ‘as alias list’ when a list of aliases is needed (instead of a list of file system item references).

```

## Suite — Enumerations

_Enumerations for the Finder_

## JXA gotchas (apply to every app)

- **Property getters take parens:** `doc.name()` not `doc.name`. `=` setter works without parens.
- **Standard Additions are opt-in:** `app.includeStandardAdditions = true` before `beep` / `say` / `displayDialog`.
- **Paths via `Path()`:** `Path('/Users/.../file.rtf')` — no `POSIX file` / `as alias` coercion needed.
- **`whose(...)` takes a record:** `messages.whose({subject: 'JS'})`; comparators are `_`-prefixed: `{age: {_greaterThan: 30}}`, `{name: {_contains: 'Smith'}}`.
- **Named parameters become record keys:** `msg.reply({replyAll: true, openingWindow: false})`.
- **ID lookup:** `app.windows['#412']` (hash-prefix = ID).
