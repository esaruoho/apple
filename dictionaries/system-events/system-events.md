# System Events — AppleScript Reference

> Extracted from scripting dictionary via `sdef`
> 31 commands, 89 classes, 18 suites

```applescript
tell application "System Events"
    -- commands go here
end tell
```

## System Events Suite

> Terms and Events for controlling the System Events application

### Commands

#### `abort transaction`

Discard the results of a bounded update session with one or more files.


#### `begin transaction`

Begin a bounded update session with one or more files.

- **Returns**: `integer` — 

#### `end transaction`

Apply the results of a bounded update session with one or more files.


### Enumerations

#### `saveable file format`

- `text` — Text File Format

## Accounts Suite

> Terms and Events for controlling the users account settings

### Classes

#### `user`

user account

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `full name` | `text` | r | user's full name |
| `home directory` | `` | r | path to user's home directory |
| `name` | `text` | r | user's short name |
| `picture path` | `` | rw | path to user's picture. Can be set for current user only! |

## Appearance Suite

> Terms for controlling Appearance preferences

### Classes

#### `appearance preferences object`

A collection of appearance preferences

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `appearance` | `Appearances` | rw | the overall look of buttons, menus and windows |
| `font smoothing` | `boolean` | rw | Is font smoothing on? |
| `font smoothing style` | `FontSmoothingStyles` | rw | the method used for smoothing fonts |
| `highlight color` | `` | rw | color used for hightlighting selected text and lists |
| `recent applications limit` | `integer` | rw | the number of recent applications to track |
| `recent documents limit` | `integer` | rw | the number of recent documents to track |
| `recent servers limit` | `integer` | rw | the number of recent servers to track |
| `scroll bar action` | `ScrollPageBehaviors` | rw | the action performed by clicking the scroll bar |
| `smooth scrolling` | `boolean` | rw | Is smooth scrolling used? |
| `dark mode` | `boolean` | rw | use dark menu bar and dock |

### Enumerations

#### `ScrollPageBehaviors`

- `jump to here` — jump to here
- `jump to next page` — jump to next page

#### `FontSmoothingStyles`

- `automatic` — automatic
- `light` — light
- `medium` — medium
- `standard` — standard
- `strong` — strong

#### `Appearances`

- `blue` — blue
- `graphite` — graphite

#### `HighlightColors`

- `blue` — blue
- `gold` — gold
- `graphite` — graphite
- `green` — green
- `orange` — orange
- `purple` — purple
- `red` — red
- `silver` — silver

## CD and DVD Preferences Suite

> Terms and Events for controlling the actions when inserting CDs and DVDs

### Classes

#### `CD and DVD preferences object`

user's CD and DVD insertion preferences

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `blank CD` | `insertion preference` | r | the blank CD insertion preference |
| `blank DVD` | `insertion preference` | r | the blank DVD insertion preference |
| `blank BD` | `insertion preference` | r | the blank BD insertion preference |
| `music CD` | `insertion preference` | r | the music CD insertion preference |
| `picture CD` | `insertion preference` | r | the picture CD insertion preference |
| `video DVD` | `insertion preference` | r | the video DVD insertion preference |
| `video BD` | `insertion preference` | r | the video BD insertion preference |

#### `insertion preference`

a specific insertion preference

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `custom application` | `` | rw | application to launch or activate on the insertion of media |
| `custom script` | `` | rw | AppleScript to launch or activate on the insertion of media |
| `insertion action` | `dhac` | rw | action to perform on media insertion |

### Enumerations

#### `dhac`

- `ask what to do` — ask what to do
- `ignore` — ignore
- `open application` — open application
- `run a script` — run a script

## Desktop Suite

> Terms and Events for controlling the desktop picture settings.

### Classes

#### `desktop`

desktop picture settings

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `name` | `text` | r | name of the desktop |
| `id` | `integer` | r | unique identifier of the desktop |
| `change interval` | `real` | rw | number of seconds to wait between changing the desktop picture |
| `display name` | `text` | r | name of display on which this desktop appears |
| `picture` | `` | rw | path to file used as desktop picture |
| `picture rotation` | `integer` | rw | never, using interval, using login, after sleep |
| `pictures folder` | `` | rw | path to folder containing pictures for changing desktop background |
| `random order` | `boolean` | rw | turn on for random ordering of changing desktop pictures |
| `translucent menu bar` | `boolean` | rw | indicates whether the menu bar is translucent |
| `dynamic style` | `dynamic style` | rw | desktop picture dynamic style |

### Enumerations

#### `dynamic style`

- `auto` — automatic (if supported, follows light/dark appearance)
- `dynamic` — dynamic (if supported, updates desktop picture based on time and/or location)
- `light` — light
- `dark` — dark
- `unknown` — unknown value

## Dock Preferences Suite

> Terms and Events for controlling the dock preferences

### Classes

#### `dock preferences object`

user's dock preferences

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `animate` | `boolean` | rw | is the animation of opening applications on or off? |
| `autohide` | `boolean` | rw | is autohiding the dock on or off? |
| `dock size` | `real` | rw | size/height of the items (between 0.0 (minimum) and 1.0 (maximum)) |
| `autohide menu bar` | `boolean` | rw | is autohiding the menu bar on or off? |
| `double click behavior` | `dpbh` | rw | behaviour when double clicking window a title bar |
| `magnification` | `boolean` | rw | is magnification on or off? |
| `magnification size` | `real` | rw | maximum magnification size when magnification is on (between 0.0 (minimum) and 1.0 (maximum)) |
| `minimize effect` | `dpef` | rw | minimization effect |
| `minimize into application` | `boolean` | rw | minimize window into its application? |
| `screen edge` | `dpls` | rw | location on screen |
| `show indicators` | `boolean` | rw | show indicators for open applications? |
| `show recents` | `boolean` | rw | show recent applications? |

### Enumerations

#### `dpls`

- `bottom` — bottom
- `left` — left
- `right` — right

#### `dpef`

- `genie` — genie
- `scale` — scale

#### `dpbh`

- `minimize` — minimize
- `off` — off
- `zoom` — zoom

## Login Items Suite

> Terms and Events for controlling the Login Items application

### Classes

#### `login item`

an item to be launched or opened at login

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `hidden` | `boolean` | rw | Is the Login Item hidden when launched? |
| `kind` | `text` | r | the file type of the Login Item |
| `name` | `text` | r | the name of the Login Item |
| `path` | `text` | r | the file system path to the Login Item |

## Network Preferences Suite

> Terms and Commands for manipulating and viewing network settings

### Commands

#### `connect`

connect a configuration or service

- **Direct parameter**: `specifier` — a configuration or service
- **Returns**: `configuration` — 

#### `disconnect`

disconnect a configuration or service

- **Direct parameter**: `specifier` — a configuration or service
- **Returns**: `configuration` — 

### Classes

#### `configuration`

A collection of settings for configuring a connection

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `account name` | `text` | rw | the name used to authenticate |
| `connected` | `boolean` | r | Is the configuration connected? |
| `id` | `text` | r | the unique identifier for the configuration |
| `name` | `text` | r | the name of the configuration |

#### `interface`

A collection of settings for a network interface

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `automatic` | `boolean` | rw | configure the interface speed, duplex, and mtu automatically? |
| `duplex` | `text` | rw | the duplex setting  half | full | full with flow control |
| `id` | `text` | r | the unique identifier for the interface |
| `kind` | `text` | r | the type of interface |
| `MAC address` | `text` | r | the MAC address for the interface |
| `mtu` | `integer` | rw | the packet size |
| `name` | `text` | r | the name of the interface |
| `speed` | `integer` | rw | ethernet speed 10 | 100 | 1000 |

#### `location`

A set of services

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `id` | `text` | r | the unique identifier for the location |
| `name` | `text` | rw | the name of the location |

**Contains**: `service`

#### `network preferences object`

the preferences for the current user's network

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `current location` | `location` | rw | the current location |

**Contains**: `interface`, `location`, `service`

#### `service`

A collection of settings for a network service

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `active` | `boolean` | r | Is the service active? |
| `current configuration` | `configuration` | rw | the currently selected configuration |
| `id` | `text` | r | the unique identifier for the service |
| `interface` | `interface` | r | the interface the service is built on |
| `kind` | `integer` | r | the type of service |
| `name` | `text` | rw | the name of the service |

**Contains**: `configuration`

## Screen Saver Suite

> Terms and Events for controlling screen saver settings.

### Commands

#### `start`

start the screen saver

- **Direct parameter**: `specifier` — the object for the command

#### `stop`

stop the screen saver

- **Direct parameter**: `specifier` — the object for the command

### Classes

#### `screen saver`

an installed screen saver

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `displayed name` | `text` | r | name of the screen saver module as displayed to the user |
| `name` | `text` | r | name of the screen saver module to be displayed |
| `path` | `alias` | r | path to the screen saver module |
| `picture display style` | `text` | rw | effect to use when displaying picture-based screen savers (slideshow, collage, or mosaic) |

#### `screen saver preferences object`

screen saver settings

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `delay interval` | `integer` | rw | number of seconds of idle time before the screen saver starts; zero for never |
| `main screen only` | `boolean` | rw | should the screen saver be shown only on the main screen? |
| `running` | `boolean` | r | is the screen saver running? |
| `show clock` | `boolean` | rw | should a clock appear over the screen saver? |

## Security Suite

> Terms for controlling Security preferences

### Classes

#### `security preferences object`

a collection of security preferences

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `automatic login` | `boolean` | rw | Is automatic login allowed? |
| `log out when inactive` | `boolean` | rw | Will the computer log out when inactive? |
| `log out when inactive interval` | `integer` | rw | The interval of inactivity after which the computer will log out |
| `require password to unlock` | `boolean` | rw | Is a password required to unlock secure preferences? |
| `require password to wake` | `boolean` | rw | Is a password required to wake the computer from sleep or screen saver? |
| `secure virtual memory` | `boolean` | rw | Is secure virtual memory being used? |

## Disk-Folder-File Suite

> Terms and Events for controlling Disks, Folders, and Files

### Commands

#### `delete`

Delete disk item(s).

- **Direct parameter**: `disk item` — The disk item(s) to be deleted.

#### `move`

Move disk item(s) to a new location.

- **Direct parameter**: `specifier` — The disk item(s) to be moved.
- **to**: `specifier` — The new location for the disk item(s).
- **Returns**: `specifier` — 

#### `open`

Open disk item(s) with the appropriate application.

- **Direct parameter**: `specifier` — The disk item(s) to be opened.
- **Returns**: `file` — 

### Classes

#### `alias`

An alias in the file system

*Inherits from: `disk item`*

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `creator type` | `` | rw | the OSType identifying the application that created the alias |
| `default application` | `` | rw | the application that will launch if the alias is opened |
| `file type` | `` | rw | the OSType identifying the type of data contained in the alias |
| `kind` | `text` | r | The kind of alias, as shown in Finder |
| `product version` | `text` | r | the version of the product (visible at the top of the "Get Info" window) |
| `short version` | `text` | r | the short version of the application bundle referenced by the alias |
| `stationery` | `boolean` | rw | Is the alias a stationery pad? |
| `type identifier` | `text` | r | The type identifier of the alias |
| `version` | `text` | r | the version of the application bundle referenced by the alias (visible at the bottom of the "Get Info" window) |

**Contains**: `alias`, `disk item`, `file`, `file package`, `folder`, `item`

#### `Classic domain object`

The Classic domain in the file system

*Inherits from: `domain`*

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `apple menu folder` | `folder` | r | The Apple Menu Items folder |
| `control panels folder` | `folder` | r | The Control Panels folder |
| `control strip modules folder` | `folder` | r | The Control Strip Modules folder |
| `desktop folder` | `folder` | r | The Classic Desktop folder |
| `extensions folder` | `folder` | r | The Extensions folder |
| `fonts folder` | `folder` | r | The Fonts folder |
| `launcher items folder` | `folder` | r | The Launcher Items folder |
| `preferences folder` | `folder` | r | The Classic Preferences folder |
| `shutdown folder` | `folder` | r | The Shutdown Items folder |
| `startup items folder` | `folder` | r | The StartupItems folder |
| `system folder` | `folder` | r | The System folder |

**Contains**: `folder`

#### `disk`

A disk in the file system

*Inherits from: `disk item`*

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `capacity` | `number` | r | the total number of bytes (free or used) on the disk |
| `ejectable` | `boolean` | r | Can the media be ejected (floppies, CD's, and so on)? |
| `format` | `edfm` | r | the file system format of this disk |
| `free space` | `number` | r | the number of free bytes left on the disk |
| `ignore privileges` | `boolean` | rw | Ignore permissions on this disk? |
| `local volume` | `boolean` | r | Is the media a local volume (as opposed to a file server)? |
| `server` | `` | r | the server on which the disk resides, AFP volumes only |
| `startup` | `boolean` | r | Is this disk the boot disk? |
| `zone` | `` | r | the zone in which the disk's server resides, AFP volumes only |

**Contains**: `alias`, `disk item`, `file`, `file package`, `folder`, `item`

#### `disk item`

An item stored in the file system

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `busy status` | `boolean` | r | Is the disk item busy? |
| `container` | `disk item` | r | the folder or disk which has this disk item as an element |
| `creation date` | `date` | r | the date on which the disk item was created |
| `displayed name` | `text` | r | the name of the disk item as displayed in the User Interface |
| `id` | `text` | r | the unique ID of the disk item |
| `modification date` | `date` | rw | the date on which the disk item was last modified |
| `name` | `text` | rw | the name of the disk item |
| `name extension` | `text` | r | the extension portion of the name |
| `package folder` | `boolean` | r | Is the disk item a package? |
| `path` | `text` | r | the file system path of the disk item |
| `physical size` | `integer` | r | the actual space used by the disk item on disk |
| `POSIX path` | `text` | r | the POSIX file system path of the disk item |
| `size` | `integer` | r | the logical size of the disk item |
| `URL` | `text` | r | the URL of the disk item |
| `visible` | `boolean` | rw | Is the disk item visible? |
| `volume` | `text` | r | the volume on which the disk item resides |

#### `domain`

A domain in the file system

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `application support folder` | `folder` | r | The Application Support folder |
| `applications folder` | `folder` | r | The Applications folder |
| `desktop pictures folder` | `folder` | r | The Desktop Pictures folder |
| `Folder Action scripts folder` | `folder` | r | The Folder Action Scripts folder |
| `fonts folder` | `folder` | r | The Fonts folder |
| `id` | `text` | r | the unique identifier of the domain |
| `library folder` | `folder` | r | The Library folder |
| `name` | `text` | r | the name of the domain |
| `preferences folder` | `folder` | r | The Preferences folder |
| `scripting additions folder` | `folder` | r | The Scripting Additions folder |
| `scripts folder` | `folder` | r | The Scripts folder |
| `shared documents folder` | `folder` | r | The Shared Documents folder |
| `speakable items folder` | `folder` | r | The Speakable Items folder |
| `utilities folder` | `folder` | r | The Utilities folder |
| `workflows folder` | `folder` | r | The Automator Workflows folder |

**Contains**: `folder`

#### `file`

A file in the file system

*Inherits from: `disk item`*

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `creator type` | `` | rw | the OSType identifying the application that created the file |
| `default application` | `` | rw | the application that will launch if the file is opened |
| `file type` | `` | rw | the OSType identifying the type of data contained in the file |
| `kind` | `text` | r | The kind of file, as shown in Finder |
| `product version` | `text` | r | the version of the product (visible at the top of the "Get Info" window) |
| `short version` | `text` | r | the short version of the file |
| `stationery` | `boolean` | rw | Is the file a stationery pad? |
| `type identifier` | `text` | r | The type identifier of the file |
| `version` | `text` | r | the version of the file (visible at the bottom of the "Get Info" window) |

#### `file package`

A file package in the file system

*Inherits from: `file`*

**Contains**: `alias`, `disk item`, `file`, `file package`, `folder`, `item`

#### `folder`

A folder in the file system

*Inherits from: `disk item`*

**Contains**: `alias`, `disk item`, `file`, `file package`, `folder`, `item`

#### `local domain object`

The local domain in the file system

*Inherits from: `domain`*

**Contains**: `folder`

#### `network domain object`

The network domain in the file system

*Inherits from: `domain`*

**Contains**: `folder`

#### `system domain object`

The system domain in the file system

*Inherits from: `domain`*

**Contains**: `folder`

#### `user domain object`

The user domain in the file system

*Inherits from: `domain`*

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `desktop folder` | `folder` | r | The user's Desktop folder |
| `documents folder` | `folder` | r | The user's Documents folder |
| `downloads folder` | `folder` | r | The user's Downloads folder |
| `favorites folder` | `folder` | r | The user's Favorites folder |
| `home folder` | `folder` | r | The user's Home folder |
| `movies folder` | `folder` | r | The user's Movies folder |
| `music folder` | `folder` | r | The user's Music folder |
| `pictures folder` | `folder` | r | The user's Pictures folder |
| `public folder` | `folder` | r | The user's Public folder |
| `sites folder` | `folder` | r | The user's Sites folder |
| `temporary items folder` | `folder` | r | The Temporary Items folder |

**Contains**: `folder`

### Enumerations

#### `edfm`

- `Apple Photo format` — Apple Photo format
- `AppleShare format` — AppleShare format
- `audio format` — audio format
- `High Sierra format` — High Sierra format
- `ISO 9660 format` — ISO 9660 format
- `Mac OS Extended format` — Mac OS Extended format
- `Mac OS format` — Mac OS format
- `MSDOS format` — MSDOS format
- `NFS format` — NFS format
- `ProDOS format` — ProDOS format
- `QuickTake format` — QuickTake format
- `UDF format` — UDF format
- `UFS format` — UFS format
- `unknown format` — unknown format
- `WebDAV format` — WebDAV format

## Power Suite

> Terms and Events for controlling System power

### Commands

#### `log out`

Log out the current user


#### `restart`

Restart the computer

- **state saving preference**: `boolean` *(optional)* — Is the user defined state saving preference followed?

#### `shut down`

Shut Down the computer

- **state saving preference**: `boolean` *(optional)* — Is the user defined state saving preference followed?

#### `sleep`

Put the computer to sleep


## Processes Suite

> Terms and Events for controlling Processes

### Commands

#### `click`

cause the target process to behave as if the UI element were clicked

- **Direct parameter**: `UI element` *(optional)* — The UI element to be clicked.
- **at**: `specifier` *(optional)* — when sent to a "process" object, the { x, y } location at which to click, in global coordinates
- **Returns**: `specifier` — 

#### `key code`

cause the target process to behave as if key codes were entered

- **Direct parameter**: `specifier` — The key code(s) to be sent. May be a list.
- **using**: `specifier` *(optional)* — modifiers with which the key codes are to be entered

#### `keystroke`

cause the target process to behave as if keystrokes were entered

- **Direct parameter**: `text` — The keystrokes to be sent.
- **using**: `specifier` *(optional)* — modifiers with which the keystrokes are to be entered

#### `perform`

cause the target process to behave as if the action were applied to its UI element

- **Direct parameter**: `action` — The action to be performed.
- **Returns**: `action` — 

#### `select`

set the selected property of the UI element

- **Direct parameter**: `UI element` — The UI element to be selected.
- **Returns**: `UI element` — 

### Classes

#### `action`

An action that can be performed on the UI element

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `description` | `text` | r | what the action does |
| `name` | `text` | r | the name of the action |

#### `application process`

A process launched from an application file

*Inherits from: `process`*

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `application file` | `` | r | a reference to the application file from which this process was launched |

#### `attribute`

An named data value associated with the UI element

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `name` | `text` | r | the name of the attribute |
| `settable` | `boolean` | r | Can the attribute be set? |
| `value` | `` | rw | the current value of the attribute |

#### `browser`

A browser belonging to a window

*Inherits from: `UI element`*

#### `busy indicator`

A busy indicator belonging to a window

*Inherits from: `UI element`*

#### `button`

A button belonging to a window or scroll bar

*Inherits from: `UI element`*

#### `checkbox`

A checkbox belonging to a window

*Inherits from: `UI element`*

#### `color well`

A color well belonging to a window

*Inherits from: `UI element`*

#### `column`

A column belonging to a table

*Inherits from: `UI element`*

#### `combo box`

A combo box belonging to a window

*Inherits from: `UI element`*

#### `desk accessory process`

A process launched from an desk accessory file

*Inherits from: `process`*

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `desk accessory file` | `alias` | r | a reference to the desk accessory file from which this process was launched |

#### `drawer`

A drawer that may be extended from a window

*Inherits from: `UI element`*

#### `group`

A group belonging to a window

*Inherits from: `UI element`*

**Contains**: `checkbox`, `static text`

#### `grow area`

A grow area belonging to a window

*Inherits from: `UI element`*

#### `image`

An image belonging to a static text field

*Inherits from: `UI element`*

#### `incrementor`

A incrementor belonging to a window

*Inherits from: `UI element`*

#### `list`

A list belonging to a window

*Inherits from: `UI element`*

#### `menu`

A menu belonging to a menu bar item

*Inherits from: `UI element`*

**Contains**: `menu item`

#### `menu bar`

A menu bar belonging to a process

*Inherits from: `UI element`*

**Contains**: `menu`, `menu bar item`

#### `menu bar item`

A menu bar item belonging to a menu bar

*Inherits from: `UI element`*

**Contains**: `menu`

#### `menu button`

A menu button belonging to a window

*Inherits from: `UI element`*

#### `menu item`

A menu item belonging to a menu

*Inherits from: `UI element`*

**Contains**: `menu`

#### `outline`

A outline belonging to a window

*Inherits from: `UI element`*

#### `pop over`

A pop over belonging to a window

*Inherits from: `UI element`*

#### `pop up button`

A pop up button belonging to a window

*Inherits from: `UI element`*

#### `process`

A process running on this computer

*Inherits from: `UI element`*

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `accepts high level events` | `boolean` | r | Is the process high-level event aware (accepts open application, open document, print document, and quit)? |
| `accepts remote events` | `boolean` | r | Does the process accept remote events? |
| `architecture` | `text` | r | the architecture in which the process is running |
| `background only` | `boolean` | r | Does the process run exclusively in the background? |
| `bundle identifier` | `text` | r | the bundle identifier of the process' application file |
| `Classic` | `boolean` | r | Is the process running in the Classic environment? |
| `creator type` | `text` | r | the OSType of the creator of the process (the signature) |
| `displayed name` | `text` | r | the name of the file from which the process was launched, as displayed in the User Interface |
| `file` | `` | r | the file from which the process was launched |
| `file type` | `text` | r | the OSType of the file type of the process |
| `frontmost` | `boolean` | rw | Is the process the frontmost process |
| `has scripting terminology` | `boolean` | r | Does the process have a scripting terminology, i.e., can it be scripted? |
| `id` | `integer` | r | The unique identifier of the process |
| `name` | `text` | r | the name of the process |
| `partition space used` | `integer` | r | the number of bytes currently used in the process' partition |
| `short name` | `` | r | the short name of the file from which the process was launched |
| `total partition size` | `integer` | r | the size of the partition with which the process was launched |
| `unix id` | `integer` | r | The Unix process identifier of a process running in the native environment, or -1 for a process running in the Classic environment |
| `visible` | `` | rw | Is the process' layer visible? |

**Contains**: `menu bar`, `window`

#### `progress indicator`

A progress indicator belonging to a window

*Inherits from: `UI element`*

#### `radio button`

A radio button belonging to a window

*Inherits from: `UI element`*

#### `radio group`

A radio button group belonging to a window

*Inherits from: `UI element`*

**Contains**: `radio button`

#### `relevance indicator`

A relevance indicator belonging to a window

*Inherits from: `UI element`*

#### `row`

A row belonging to a table

*Inherits from: `UI element`*

#### `scroll area`

A scroll area belonging to a window

*Inherits from: `UI element`*

#### `scroll bar`

A scroll bar belonging to a window

*Inherits from: `UI element`*

**Contains**: `button`, `value indicator`

#### `sheet`

A sheet displayed over a window

*Inherits from: `UI element`*

#### `slider`

A slider belonging to a window

*Inherits from: `UI element`*

#### `splitter`

A splitter belonging to a window

*Inherits from: `UI element`*

#### `splitter group`

A splitter group belonging to a window

*Inherits from: `UI element`*

#### `static text`

A static text field belonging to a window

*Inherits from: `UI element`*

**Contains**: `image`

#### `tab group`

A tab group belonging to a window

*Inherits from: `UI element`*

#### `table`

A table belonging to a window

*Inherits from: `UI element`*

#### `text area`

A text area belonging to a window

*Inherits from: `UI element`*

#### `text field`

A text field belonging to a window

*Inherits from: `UI element`*

#### `toolbar`

A toolbar belonging to a window

*Inherits from: `UI element`*

#### `UI element`

A piece of the user interface of a process

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `accessibility description` | `` | r | a more complete description of the UI element and its capabilities |
| `class` | `type` | r | the class of the UI Element, which identifies it function |
| `description` | `` | r | the accessibility description, if available; otherwise, the role description |
| `enabled` | `` | r | Is the UI element enabled? ( Does it accept clicks? ) |
| `entire contents` | `` | r | a list of every UI element contained in this UI element and its child UI elements, to the limits of the tree |
| `focused` | `` | rw | Is the focus on this UI element? |
| `help` | `` | r | an elaborate description of the UI element and its capabilities |
| `maximum value` | `` | r | the maximum value that the UI element can take on |
| `minimum value` | `` | r | the minimum value that the UI element can take on |
| `name` | `text` | r | the name of the UI Element, which identifies it within its container |
| `orientation` | `` | r | the orientation of the UI element |
| `position` | `` | rw | the position of the UI element |
| `role` | `text` | r | an encoded description of the UI element and its capabilities |
| `role description` | `text` | r | a more complete description of the UI element's role |
| `selected` | `` | rw | Is the UI element selected? |
| `size` | `` | rw | the size of the UI element |
| `subrole` | `` | r | an encoded description of the UI element and its capabilities |
| `title` | `text` | r | the title of the UI element as it appears on the screen |
| `value` | `` | rw | the current value of the UI element |

**Contains**: `action`, `attribute`, `browser`, `busy indicator`, `button`, `checkbox`, `color well`, `column`, `combo box`, `drawer`, `group`, `grow area`, `image`, `incrementor`, `list`, `menu`, `menu bar`, `menu bar item`, `menu button`, `menu item`, `outline`, `pop over`, `pop up button`, `progress indicator`, `radio button`, `radio group`, `relevance indicator`, `row`, `scroll area`, `scroll bar`, `sheet`, `slider`, `splitter`, `splitter group`, `static text`, `tab group`, `table`, `text area`, `text field`, `toolbar`, `UI element`, `value indicator`, `window`

#### `value indicator`

A value indicator ( thumb or slider ) belonging to a scroll bar

*Inherits from: `UI element`*

### Enumerations

#### `eMds`

- `command down` — command down
- `control down` — control down
- `option down` — option down
- `shift down` — shift down

#### `eMky`

- `command` — command
- `control` — control
- `option` — option
- `shift` — shift

## Property List Suite

> Terms and Events for accessing the content of Property List files

### Classes

#### `property list file`

A file containing data in Property List format

*Inherits from: `file`*

#### `property list item`

A unit of data in Property List format

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `kind` | `type` | r | the kind of data stored in the property list item: boolean/data/date/list/number/record/string |
| `name` | `text` | r | the name of the property list item ( if any ) |
| `text` | `text` | rw | the text representation of the property list data |
| `value` | `` | rw | the value of the property list item |

**Contains**: `property list item`

## XML Suite

> Terms and Events for accessing the content of XML files

### Classes

#### `XML attribute`

A named value associated with a unit of data in XML format

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `name` | `text` | r | the name of the XML attribute |
| `value` | `` | rw | the value of the XML attribute |

#### `XML data`

Data in XML format

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `id` | `text` | r | the unique identifier of the XML data |
| `name` | `text` | rw | the name of the XML data |
| `text` | `text` | rw | the text representation of the XML data |

**Contains**: `XML element`

#### `XML element`

A unit of data in XML format

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `id` | `text` | r | the unique identifier of the XML element |
| `name` | `text` | r | the name of the XML element |
| `value` | `` | rw | the value of the XML element |

**Contains**: `XML attribute`, `XML element`

#### `XML file`

A file containing data in XML format

*Inherits from: `file`*

## Type Definitions

> Records used in scripting System Events

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

## Hidden Suite

> Hidden Terms and Events for controlling the System Events application

### Commands

#### `attach action to`

Attach an action to a folder

- **Direct parameter**: `specifier` — the object for the command
- **using**: `text` — a file containing the script to attach
- **Returns**: `folder action` — 

#### `attached scripts`

List the actions attached to a folder

- **Direct parameter**: `specifier` — the object for the command
- **Returns**: `specifier` — 

#### `cancel`

cause the target process to behave as if the UI element were cancelled

- **Direct parameter**: `specifier` — the object for the command
- **Returns**: `UI element` — 

#### `confirm`

cause the target process to behave as if the UI element were confirmed

- **Direct parameter**: `specifier` — the object for the command
- **Returns**: `UI element` — 

#### `decrement`

cause the target process to behave as if the UI element were decremented

- **Direct parameter**: `specifier` — the object for the command
- **Returns**: `UI element` — 

#### `do folder action`

Send a folder action code to a folder action script

- **Direct parameter**: `specifier` — the object for the command
- **folder action code**: `actn` — the folder action message to process
- **with item list**: `any` *(optional)* — a list of items for the folder action message to process
- **with window size**: `rectangle` *(optional)* — the new window size for the folder action message to process

#### `edit action of`

Edit an action of a folder

- **Direct parameter**: `specifier` — the object for the command
- **using action name**: `text` *(optional)* — ...or the name of the action to edit
- **using action number**: `integer` *(optional)* — the index number of the action to edit...
- **Returns**: `file` — 

#### `increment`

cause the target process to behave as if the UI element were incremented

- **Direct parameter**: `specifier` — the object for the command
- **Returns**: `UI element` — 

#### `key down`

cause the target process to behave as if keys were held down

- **Direct parameter**: `specifier` — a keystroke, key code, or (list of) modifier key names.

#### `key up`

cause the target process to behave as if keys were released

- **Direct parameter**: `specifier` — a keystroke, key code, or (list of) modifier key names.

#### `pick`

cause the target process to behave as if the UI element were picked

- **Direct parameter**: `specifier` — the object for the command
- **Returns**: `UI element` — 

#### `remove action from`

Remove a folder action from a folder

- **Direct parameter**: `specifier` — the object for the command
- **using action name**: `text` *(optional)* — ...or the name of the action to remove
- **using action number**: `integer` *(optional)* — the index number of the action to remove...
- **Returns**: `folder action` — 

### Enumerations

#### `actn`

- `items added` — items added
- `items removed` — items removed
- `window closed` — window closed
- `window moved` — window moved
- `window opened` — window opened

## Scripting Definition Suite

>  Terms and Events for examining the System Events scripting definition

### Classes

#### `scripting class`

A class within a suite within a scripting definition

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `name` | `text` | r | The name of the class |
| `id` | `text` | r | The unique identifier of the class |
| `description` | `text` | r | The description of the class |
| `hidden` | `boolean` | r | Is the class hidden? |
| `plural name` | `text` | r | The plural name of the class |
| `suite name` | `text` | r | The name of the suite to which this class belongs |
| `superclass` | `scripting class` | r | The class from which this class inherits |

**Contains**: `scripting element`, `scripting property`

#### `scripting command`

A command within a suite within a scripting definition

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `name` | `text` | r | The name of the command |
| `id` | `text` | r | The unique identifier of the command |
| `description` | `text` | r | The description of the command |
| `direct parameter` | `scripting parameter` | r | The direct parameter of the command |
| `hidden` | `boolean` | r | Is the command hidden? |
| `scripting result` | `scripting result object` | r | The object or data returned by this command |
| `suite name` | `text` | r | The name of the suite to which this command belongs |

**Contains**: `scripting parameter`

#### `scripting definition object`

The scripting definition of the System Events applicaation

**Contains**: `scripting suite`

#### `scripting element`

An element within a class within a suite within a scripting definition

*Inherits from: `scripting class`*

#### `scripting enumeration`

An enumeration within a suite within a scripting definition

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `name` | `text` | r | The name of the enumeration |
| `id` | `text` | r | The unique identifier of the enumeration |
| `hidden` | `boolean` | r | Is the enumeration hidden? |

**Contains**: `scripting enumerator`

#### `scripting enumerator`

An enumerator within an enumeration within a suite within a scripting definition

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `name` | `text` | r | The name of the enumerator |
| `id` | `text` | r | The unique identifier of the enumerator |
| `description` | `text` | r | The description of the enumerator |
| `hidden` | `boolean` | r | Is the enumerator hidden? |

#### `scripting parameter`

A parameter within a command within a suite within a scripting definition

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `name` | `text` | r | The name of the parameter |
| `id` | `text` | r | The unique identifier of the parameter |
| `description` | `text` | r | The description of the parameter |
| `hidden` | `boolean` | r | Is the parameter hidden? |
| `kind` | `text` | r | The kind of object or data specified by this parameter |
| `optional` | `boolean` | r | Is the parameter optional? |

#### `scripting property`

A property within a class within a suite within a scripting definition

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `name` | `text` | r | The name of the property |
| `id` | `text` | r | The unique identifier of the property |
| `access` | `accs` | r | The type of access to this property |
| `description` | `text` | r | The description of the property |
| `enumerated` | `boolean` | r | Is the property's value an enumerator? |
| `hidden` | `boolean` | r | Is the property hidden? |
| `kind` | `text` | r | The kind of object or data returned by this property |
| `listed` | `boolean` | r | Is the property's value a list? |

#### `scripting result object`

The result of a command within a suite within a scripting definition

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `description` | `text` | r | The description of the property |
| `enumerated` | `boolean` | r | Is the scripting result's value an enumerator? |
| `kind` | `text` | r | The kind of object or data returned by this property |
| `listed` | `boolean` | r | Is the scripting result's value a list? |

#### `scripting suite`

A suite within a scripting definition

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `name` | `text` | r | The name of the suite |
| `id` | `text` | r | The unique identifier of the suite |
| `description` | `text` | r | The description of the suite |
| `hidden` | `boolean` | r | Is the suite hidden? |

**Contains**: `scripting command`, `scripting class`, `scripting enumeration`

### Enumerations

#### `accs`

- `none` — none
- `read only` — read only
- `read write` — read write
- `write only` — write only
