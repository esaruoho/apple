# Image Events — JavaScript for Automation (JXA) Reference

> Rendered from `image-events.yaml` by `bin/sdef-to-jxa.py`. JXA dialect of the AppleScript dictionary in `image-events.md`.
> Translation rules: WWDC 2014 #306 — *JavaScript for Automation* (Sal Soghoian + David Steinberg).

## Get the application

```javascript
var ImageEvents = Application('Image Events')
ImageEvents.includeStandardAdditions = true   // if calling beep/say/displayDialog
```

**Commands:** 13  ·  **Classes:** 16  ·  **Suites:** 3

## Suite — Disk-Folder-File Suite

_Terms and Events for controlling Disks, Folders, and Files_

### Commands

```javascript
// Delete disk item(s).
ImageEvents.delete(/* disk item */)

// Move disk item(s) to a new location.
ImageEvents.move(target, {to: /*  */})

// Open disk item(s) with the appropriate application.
ImageEvents.open(target)

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

## Suite — Image Suite

_Terms and Events for controlling Images_

### Commands

```javascript
// Close an image
ImageEvents.close(target, {saving: /* savo */, savingIn: '...'})

// Crop an image
ImageEvents.crop(target, {toDimensions: /*  */})

// Embed an image with an ICC profile
ImageEvents.embed(target, {withSource: /* profile */})

// Flip an image
ImageEvents.flip(target, {horizontal: true, vertical: true})

// Match an image
ImageEvents.match(target, {toDestination: /* profile */})

// Pad an image
ImageEvents.pad(target, {toDimensions: /*  */, withPadColor: /*  */})

// Rotate an image
ImageEvents.rotate(target, {toAngle: /* real */})

// Save an image to a file in one of various formats
ImageEvents.save(target, {as: /* typv */, icon: true, in: '...', packbits: true, withCompressionLevel: /* cmlv */})

// Scale an image
ImageEvents.scale(target, {byFactor: /* real */, toSize: /* integer */})

// Remove any embedded ICC profiles from an image
ImageEvents.unembed(target)

```

### Classes

```javascript
// class: display
// A monitor connected to the computer
display.displayNumber        // read-only getter (integer)

// class: image
// An image contained in a file
image.bitDepth        // read-only getter (bitz)
image.metadataTags[0]                   // first metadata tag
image.metadataTags.whose({name: 'x'})  // filter

// class: metadata tag
// A metadata tag: EXIF, IPTC, etc.
metadatatag.description        // read-only getter (text)

// class: profile
// A ColorSync ICC profile.
profile.colorSpace        // read-only getter (pSpc)

```

## Suite — Image Events Suite

_Terms and Events for controlling the Image Events application_

## JXA gotchas (apply to every app)

- **Property getters take parens:** `doc.name()` not `doc.name`. `=` setter works without parens.
- **Standard Additions are opt-in:** `app.includeStandardAdditions = true` before `beep` / `say` / `displayDialog`.
- **Paths via `Path()`:** `Path('/Users/.../file.rtf')` — no `POSIX file` / `as alias` coercion needed.
- **`whose(...)` takes a record:** `messages.whose({subject: 'JS'})`; comparators are `_`-prefixed: `{age: {_greaterThan: 30}}`, `{name: {_contains: 'Smith'}}`.
- **Named parameters become record keys:** `msg.reply({replyAll: true, openingWindow: false})`.
- **ID lookup:** `app.windows['#412']` (hash-prefix = ID).
