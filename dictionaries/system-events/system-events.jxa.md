# System Events — JavaScript for Automation (JXA) Reference

> Rendered from `system-events.yaml` by `bin/sdef-to-jxa.py`. JXA dialect of the AppleScript dictionary in `system-events.md`.
> Translation rules: WWDC 2014 #306 — *JavaScript for Automation* (Sal Soghoian + David Steinberg).

## Get the application

```javascript
var SystemEvents = Application('System Events')
SystemEvents.includeStandardAdditions = true   // if calling beep/say/displayDialog
```

**Commands:** 31  ·  **Classes:** 90  ·  **Suites:** 18

## Suite — System Events Suite

_Terms and Events for controlling the System Events application_

### Commands

```javascript
// Discard the results of a bounded update session with one or more files.
SystemEvents.abortTransaction()

// Begin a bounded update session with one or more files.
SystemEvents.beginTransaction()

// Apply the results of a bounded update session with one or more files.
SystemEvents.endTransaction()

```

## Suite — Accounts Suite

_Terms and Events for controlling the users account settings_

### Classes

```javascript
// class: user
// user account
user.picturePath        // getter ()
user.picturePath = /* value */  // setter
user.fullName        // read-only getter (text)

```

## Suite — Appearance Suite

_Terms for controlling Appearance preferences_

### Classes

```javascript
// class: appearance preferences object
// A collection of appearance preferences
appearancepreferencesobject.appearance        // getter (Appearances)
appearancepreferencesobject.appearance = /* value */  // setter
appearancepreferencesobject.fontSmoothingLimit        // read-only getter (integer)

```

## Suite — CD and DVD Preferences Suite

_Terms and Events for controlling the actions when inserting CDs and DVDs_

### Classes

```javascript
// class: CD and DVD preferences object
// user's CD and DVD insertion preferences
cDandDVDpreferencesobject.blankCd        // read-only getter (insertion preference)

// class: insertion preference
// a specific insertion preference
insertionpreference.customApplication        // getter ()
insertionpreference.customApplication = /* value */  // setter

```

## Suite — Desktop Suite

_Terms and Events for controlling the desktop picture settings._

### Classes

```javascript
// class: desktop
// desktop picture settings
desktop.changeInterval        // getter (real)
desktop.changeInterval = /* value */  // setter
desktop.name        // read-only getter (text)

```

## Suite — Dock Preferences Suite

_Terms and Events for controlling the dock preferences_

### Classes

```javascript
// class: dock preferences object
// user's dock preferences
dockpreferencesobject.animate        // getter (boolean)
dockpreferencesobject.animate = /* value */  // setter

```

## Suite — Login Items Suite

_Terms and Events for controlling the Login Items application_

### Classes

```javascript
// class: login item
// an item to be launched or opened at login
loginitem.hidden        // getter (boolean)
loginitem.hidden = /* value */  // setter
loginitem.kind        // read-only getter (text)

```

## Suite — Network Preferences Suite

_Terms and Commands for manipulating and viewing network settings_

### Commands

```javascript
// connect a configuration or service
SystemEvents.connect(target)

// disconnect a configuration or service
SystemEvents.disconnect(target)

```

### Classes

```javascript
// class: configuration
// A collection of settings for configuring a connection
configuration.accountName        // getter (text)
configuration.accountName = '...'  // setter
configuration.connected        // read-only getter (boolean)

// class: interface
// A collection of settings for a network interface
interface.automatic        // getter (boolean)
interface.automatic = /* value */  // setter
interface.id        // read-only getter (text)

// class: location
// A set of services
location.name        // getter (text)
location.name = '...'  // setter
location.id        // read-only getter (text)
location.services[0]                   // first service
location.services.whose({name: 'x'})  // filter

// class: network preferences object
// the preferences for the current user's network
networkpreferencesobject.currentLocation        // getter (location)
networkpreferencesobject.currentLocation = /* value */  // setter
networkpreferencesobject.interfaces[0]                   // first interface
networkpreferencesobject.interfaces.whose({name: 'x'})  // filter

// class: service
// A collection of settings for a network service
service.currentConfiguration        // getter (configuration)
service.currentConfiguration = /* value */  // setter
service.active        // read-only getter (boolean)
service.configurations[0]                   // first configuration
service.configurations.whose({name: 'x'})  // filter

```

## Suite — Screen Saver Suite

_Terms and Events for controlling screen saver settings._

### Commands

```javascript
// start the screen saver
SystemEvents.start(target)

// stop the screen saver
SystemEvents.stop(target)

```

### Classes

```javascript
// class: screen saver
// an installed screen saver
screensaver.pictureDisplayStyle        // getter (text)
screensaver.pictureDisplayStyle = '...'  // setter
screensaver.displayedName        // read-only getter (text)

// class: screen saver preferences object
// screen saver settings
screensaverpreferencesobject.delayInterval        // getter (integer)
screensaverpreferencesobject.delayInterval = /* value */  // setter
screensaverpreferencesobject.running        // read-only getter (boolean)

```

## Suite — Security Suite

_Terms for controlling Security preferences_

### Classes

```javascript
// class: security preferences object
// a collection of security preferences
securitypreferencesobject.automaticLogin        // getter (boolean)
securitypreferencesobject.automaticLogin = /* value */  // setter

```

## Suite — Disk-Folder-File Suite

_Terms and Events for controlling Disks, Folders, and Files_

### Commands

```javascript
// Delete disk item(s).
SystemEvents.delete(/* disk item */)

// Move disk item(s) to a new location.
SystemEvents.move(target, {to: /*  */})

// Open disk item(s) with the appropriate application.
SystemEvents.open(target)

```

### Classes

```javascript
// class: alias
// An alias in the file system
alias.creatorType        // getter ()
alias.creatorType = /* value */  // setter
alias.kind        // read-only getter (text)
alias.alias[0]                   // first alias
alias.alias.whose({name: 'x'})  // filter

// class: Classic domain object
// The Classic domain in the file system
classicdomainobject.appleMenuFolder        // read-only getter (folder)
classicdomainobject.folders[0]                   // first folder
classicdomainobject.folders.whose({name: 'x'})  // filter

// class: disk
// A disk in the file system
disk.ignorePrivileges        // getter (boolean)
disk.ignorePrivileges = /* value */  // setter
disk.capacity        // read-only getter (number)
disk.alias[0]                   // first alias
disk.alias.whose({name: 'x'})  // filter

// class: disk item
// An item stored in the file system
diskitem.modificationDate        // getter (date)
diskitem.modificationDate = /* value */  // setter
diskitem.busyStatus        // read-only getter (boolean)

// class: domain
// A domain in the file system
domain.applicationSupportFolder        // read-only getter (folder)
domain.folders[0]                   // first folder
domain.folders.whose({name: 'x'})  // filter

// class: file
// A file in the file system
file.creatorType        // getter ()
file.creatorType = /* value */  // setter
file.kind        // read-only getter (text)

// class: file package
// A file package in the file system
filepackage.alias[0]                   // first alias
filepackage.alias.whose({name: 'x'})  // filter

// class: folder
// A folder in the file system
folder.alias[0]                   // first alias
folder.alias.whose({name: 'x'})  // filter

// class: local domain object
// The local domain in the file system
localdomainobject.folders[0]                   // first folder
localdomainobject.folders.whose({name: 'x'})  // filter

// class: network domain object
// The network domain in the file system
networkdomainobject.folders[0]                   // first folder
networkdomainobject.folders.whose({name: 'x'})  // filter

// class: system domain object
// The system domain in the file system
systemdomainobject.folders[0]                   // first folder
systemdomainobject.folders.whose({name: 'x'})  // filter

// class: user domain object
// The user domain in the file system
userdomainobject.desktopFolder        // read-only getter (folder)
userdomainobject.folders[0]                   // first folder
userdomainobject.folders.whose({name: 'x'})  // filter

```

## Suite — Power Suite

_Terms and Events for controlling System power_

### Commands

```javascript
// Log out the current user
SystemEvents.logOut()

// Restart the computer
SystemEvents.restart({stateSavingPreference: true})

// Shut Down the computer
SystemEvents.shutDown({stateSavingPreference: true})

// Put the computer to sleep
SystemEvents.sleep()

```

## Suite — Processes Suite

_Terms and Events for controlling Processes_

### Commands

```javascript
// cause the target process to behave as if the UI element were clicked
SystemEvents.click(/* UI element */, {at: /*  */})

// cause the target process to behave as if key codes were entered
SystemEvents.keyCode(target, {using: /*  */})

// cause the target process to behave as if keystrokes were entered
SystemEvents.keystroke('...', {using: /*  */})

// cause the target process to behave as if the action were applied to its UI element
SystemEvents.perform(/* action */)

// set the selected property of the UI element
SystemEvents.select(/* UI element */)

```

### Classes

```javascript
// class: action
// An action that can be performed on the UI element
action.description        // read-only getter (text)

// class: application process
// A process launched from an application file
applicationprocess.applicationFile        // read-only getter ()

// class: attribute
// An named data value associated with the UI element
attribute.value        // getter ()
attribute.value = /* value */  // setter
attribute.name        // read-only getter (text)

// class: browser
// A browser belonging to a window

// class: busy indicator
// A busy indicator belonging to a window

// class: button
// A button belonging to a window or scroll bar

// class: checkbox
// A checkbox belonging to a window

// class: color well
// A color well belonging to a window

// class: column
// A column belonging to a table

// class: combo box
// A combo box belonging to a window

// class: desk accessory process
// A process launched from an desk accessory file
deskaccessoryprocess.deskAccessoryFile        // read-only getter (alias)

// class: drawer
// A drawer that may be extended from a window

// class: group
// A group belonging to a window
group.checkboxs[0]                   // first checkbox
group.checkboxs.whose({name: 'x'})  // filter

// class: grow area
// A grow area belonging to a window

// class: image
// An image belonging to a static text field

// class: incrementor
// A incrementor belonging to a window

// class: list
// A list belonging to a window

// class: menu
// A menu belonging to a menu bar item
menu.menuItems[0]                   // first menu item
menu.menuItems.whose({name: 'x'})  // filter

// class: menu bar
// A menu bar belonging to a process
menubar.menus[0]                   // first menu
menubar.menus.whose({name: 'x'})  // filter

// class: menu bar item
// A menu bar item belonging to a menu bar
menubaritem.menus[0]                   // first menu
menubaritem.menus.whose({name: 'x'})  // filter

// class: menu button
// A menu button belonging to a window

// class: menu item
// A menu item belonging to a menu
menuitem.menus[0]                   // first menu
menuitem.menus.whose({name: 'x'})  // filter

// class: outline
// A outline belonging to a window

// class: pop over
// A pop over belonging to a window

// class: pop up button
// A pop up button belonging to a window

// class: process
// A process running on this computer
process.frontmost        // getter (boolean)
process.frontmost = /* value */  // setter
process.acceptsHighLevelEvents        // read-only getter (boolean)
process.menuBars[0]                   // first menu bar
process.menuBars.whose({name: 'x'})  // filter

// class: progress indicator
// A progress indicator belonging to a window

// class: radio button
// A radio button belonging to a window

// class: radio group
// A radio button group belonging to a window
radiogroup.radioButtons[0]                   // first radio button
radiogroup.radioButtons.whose({name: 'x'})  // filter

// class: relevance indicator
// A relevance indicator belonging to a window

// class: row
// A row belonging to a table

// class: scroll area
// A scroll area belonging to a window

// class: scroll bar
// A scroll bar belonging to a window
scrollbar.buttons[0]                   // first button
scrollbar.buttons.whose({name: 'x'})  // filter

// class: sheet
// A sheet displayed over a window

// class: slider
// A slider belonging to a window

// class: splitter
// A splitter belonging to a window

// class: splitter group
// A splitter group belonging to a window

// class: static text
// A static text field belonging to a window
statictext.images[0]                   // first image
statictext.images.whose({name: 'x'})  // filter

// class: tab group
// A tab group belonging to a window

// class: table
// A table belonging to a window

// class: text area
// A text area belonging to a window

// class: text field
// A text field belonging to a window

// class: toolbar
// A toolbar belonging to a window

// class: UI element
// A piece of the user interface of a process
uIelement.focused        // getter ()
uIelement.focused = /* value */  // setter
uIelement.accessibilityDescription        // read-only getter ()
uIelement.actions[0]                   // first action
uIelement.actions.whose({name: 'x'})  // filter

// class: value indicator
// A value indicator ( thumb or slider ) belonging to a scroll bar

```

## Suite — Property List Suite

_Terms and Events for accessing the content of Property List files_

### Classes

```javascript
// class: property list file
// A file containing data in Property List format

// class: data
// A data blob

// class: property list item
// A unit of data in Property List format
propertylistitem.text        // getter (text)
propertylistitem.text = '...'  // setter
propertylistitem.kind        // read-only getter (type)
propertylistitem.propertyListItems[0]                   // first property list item
propertylistitem.propertyListItems.whose({name: 'x'})  // filter

```

## Suite — XML Suite

_Terms and Events for accessing the content of XML files_

### Classes

```javascript
// class: XML attribute
// A named value associated with a unit of data in XML format
xMLattribute.value        // getter ()
xMLattribute.value = /* value */  // setter
xMLattribute.name        // read-only getter (text)

// class: XML data
// Data in XML format
xMLdata.name        // getter (text)
xMLdata.name = '...'  // setter
xMLdata.id        // read-only getter (text)
xMLdata.xmlElements[0]                   // first XML element
xMLdata.xmlElements.whose({name: 'x'})  // filter

// class: XML element
// A unit of data in XML format
xMLelement.value        // getter ()
xMLelement.value = /* value */  // setter
xMLelement.id        // read-only getter (text)
xMLelement.xmlAttributes[0]                   // first XML attribute
xMLelement.xmlAttributes.whose({name: 'x'})  // filter

// class: XML file
// A file containing data in XML format

```

## Suite — Type Definitions

_Records used in scripting System Events_

### Classes

```javascript
// class: print settings
printsettings.copies        // getter (integer)
printsettings.copies = /* value */  // setter

```

## Suite — Hidden Suite

_Hidden Terms and Events for controlling the System Events application_

### Commands

```javascript
// Attach an action to a folder
SystemEvents.attachActionTo(target, {using: '...'})

// List the actions attached to a folder
SystemEvents.attachedScripts(target)

// cause the target process to behave as if the UI element were cancelled
SystemEvents.cancel(target)

// cause the target process to behave as if the UI element were confirmed
SystemEvents.confirm(target)

// cause the target process to behave as if the UI element were decremented
SystemEvents.decrement(target)

// Send a folder action code to a folder action script
SystemEvents.doFolderAction(target, {folderActionCode: /* actn */, withItemList: /* any */, withWindowSize: /* rectangle */})

// Edit an action of a folder
SystemEvents.editActionOf(target, {usingActionName: '...', usingActionNumber: /* integer */})

// cause the target process to behave as if the UI element were incremented
SystemEvents.increment(target)

// cause the target process to behave as if keys were held down
SystemEvents.keyDown(target)

// cause the target process to behave as if keys were released
SystemEvents.keyUp(target)

// cause the target process to behave as if the UI element were picked
SystemEvents.pick(target)

// Remove a folder action from a folder
SystemEvents.removeActionFrom(target, {usingActionName: '...', usingActionNumber: /* integer */})

```

## Suite — Scripting Definition Suite

_ Terms and Events for examining the System Events scripting definition_

### Classes

```javascript
// class: scripting class
// A class within a suite within a scripting definition
scriptingclass.name        // read-only getter (text)
scriptingclass.scriptingElements[0]                   // first scripting element
scriptingclass.scriptingElements.whose({name: 'x'})  // filter

// class: scripting command
// A command within a suite within a scripting definition
scriptingcommand.name        // read-only getter (text)
scriptingcommand.scriptingParameters[0]                   // first scripting parameter
scriptingcommand.scriptingParameters.whose({name: 'x'})  // filter

// class: scripting definition object
// The scripting definition of the System Events applicaation
scriptingdefinitionobject.scriptingSuites[0]                   // first scripting suite
scriptingdefinitionobject.scriptingSuites.whose({name: 'x'})  // filter

// class: scripting element
// An element within a class within a suite within a scripting definition

// class: scripting enumeration
// An enumeration within a suite within a scripting definition
scriptingenumeration.name        // read-only getter (text)
scriptingenumeration.scriptingEnumerators[0]                   // first scripting enumerator
scriptingenumeration.scriptingEnumerators.whose({name: 'x'})  // filter

// class: scripting enumerator
// An enumerator within an enumeration within a suite within a scripting definition
scriptingenumerator.name        // read-only getter (text)

// class: scripting parameter
// A parameter within a command within a suite within a scripting definition
scriptingparameter.name        // read-only getter (text)

// class: scripting property
// A property within a class within a suite within a scripting definition
scriptingproperty.name        // read-only getter (text)

// class: scripting result object
// The result of a command within a suite within a scripting definition
scriptingresultobject.description        // read-only getter (text)

// class: scripting suite
// A suite within a scripting definition
scriptingsuite.name        // read-only getter (text)
scriptingsuite.scriptingCommands[0]                   // first scripting command
scriptingsuite.scriptingCommands.whose({name: 'x'})  // filter

```

## JXA gotchas (apply to every app)

- **Property getters take parens:** `doc.name()` not `doc.name`. `=` setter works without parens.
- **Standard Additions are opt-in:** `app.includeStandardAdditions = true` before `beep` / `say` / `displayDialog`.
- **Paths via `Path()`:** `Path('/Users/.../file.rtf')` — no `POSIX file` / `as alias` coercion needed.
- **`whose(...)` takes a record:** `messages.whose({subject: 'JS'})`; comparators are `_`-prefixed: `{age: {_greaterThan: 30}}`, `{name: {_contains: 'Smith'}}`.
- **Named parameters become record keys:** `msg.reply({replyAll: true, openingWindow: false})`.
- **ID lookup:** `app.windows['#412']` (hash-prefix = ID).
