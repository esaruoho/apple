# Standard — JavaScript for Automation (JXA) Reference

> Rendered from `photos.yaml` by `bin/sdef-to-jxa.py`. JXA dialect of the AppleScript dictionary in `photos.md`.
> Translation rules: WWDC 2014 #306 — *JavaScript for Automation* (Sal Soghoian + David Steinberg).

## Get the application

```javascript
var Standard = Application('Standard')
Standard.includeStandardAdditions = true   // if calling beep/say/displayDialog
```

**Commands:** 18  ·  **Classes:** 6  ·  **Suites:** 2

## Suite — Standard Suite

_Common classes and commands for all applications._

### Commands

```javascript
// Return the number of elements of a particular class within an object.
Standard.count(target, {each: /* type */})

// Verify that an object exists.
Standard.exists(/* any */)

// Open a photo library
Standard.open(target)

// Quit the application.
Standard.quit()

```

### Classes

```javascript
// class: application
// The application's top-level scripting object.
application.name        // read-only getter (text)

```

## Suite — Photos Suite

_Classes and commands for Photos_

### Commands

```javascript
// Import files into the library
Standard.import(target, {into: /* album */, skipCheckDuplicates: true})

// Export media items to the specified location as files
Standard.export(target, {to: Path('/path'), usingOriginals: true})

// Duplicate an object.  Only media items can be duplicated
Standard.duplicate(target)

// Create a new object.  Only new albums and folders can be created.
Standard.make({new: /* type */, named: '...', at: /* folder */})

// Delete an object.  Only albums and folders can be deleted.
Standard.delete(target)

// Add media items to an album.
Standard.add(target, {to: /* album */})

// Display an ad-hoc slide show from a list of media items, an album, or a folder.
Standard.startSlideshow({using: /*  */})

// End the currently-playing slideshow.
Standard.stopSlideshow()

// Skip to next slide in currently-playing slideshow.
Standard.nextSlide()

// Skip to previous slide in currently-playing slideshow.
Standard.previousSlide()

// Pause the currently-playing slideshow.
Standard.pauseSlideshow()

// Resume the currently-playing slideshow.
Standard.resumeSlideshow()

// Show the image at path in the application, used to show spotlight search results
Standard.spotlight(target)

// search for items matching the search string. Identical to entering search text in the Search field in Photos
Standard.search({for: '...'})

```

### Classes

```javascript
// class: media item
// A media item, such as a photo or video.
mediaitem.keywords        // getter ()
mediaitem.keywords = /* value */  // setter
mediaitem.id        // read-only getter (text)

// class: container
// Base class for collections that contains other items, such as albums and folders
container.name        // getter (text)
container.name = '...'  // setter
container.id        // read-only getter (text)

// class: album
// An album. A container that holds media items
album.mediaItems[0]                   // first media item
album.mediaItems.whose({name: 'x'})  // filter

// class: folder
// A folder. A container that holds albums and other folders, but not media items
folder.containers[0]                   // first container
folder.containers.whose({name: 'x'})  // filter

// class: moment
// A set of media items that represents a Moment.
moment.id        // read-only getter (text)
moment.mediaItems[0]                   // first media item
moment.mediaItems.whose({name: 'x'})  // filter

```

## JXA gotchas (apply to every app)

- **Property getters take parens:** `doc.name()` not `doc.name`. `=` setter works without parens.
- **Standard Additions are opt-in:** `app.includeStandardAdditions = true` before `beep` / `say` / `displayDialog`.
- **Paths via `Path()`:** `Path('/Users/.../file.rtf')` — no `POSIX file` / `as alias` coercion needed.
- **`whose(...)` takes a record:** `messages.whose({subject: 'JS'})`; comparators are `_`-prefixed: `{age: {_greaterThan: 30}}`, `{name: {_contains: 'Smith'}}`.
- **Named parameters become record keys:** `msg.reply({replyAll: true, openingWindow: false})`.
- **ID lookup:** `app.windows['#412']` (hash-prefix = ID).
