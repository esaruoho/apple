# Tv — JavaScript for Automation (JXA) Reference

> Rendered from `tv.yaml` by `bin/sdef-to-jxa.py`. JXA dialect of the AppleScript dictionary in `tv.md`.
> Translation rules: WWDC 2014 #306 — *JavaScript for Automation* (Sal Soghoian + David Steinberg).

## Get the application

```javascript
var Tv = Application('Tv')
Tv.includeStandardAdditions = true   // if calling beep/say/displayDialog
```

**Commands:** 29  ·  **Classes:** 16  ·  **Suites:** 3

## Suite — Standard Suite

_Common terms for most applications_

### Commands

```javascript
// Close an object
Tv.close(target)

// Return the number of elements of a particular class within an object
Tv.count(target, {each: /* type */})

// Delete an element from an object
Tv.delete(target)

// Duplicate one or more object(s)
Tv.duplicate(target, {to: Path('/path')})

// Verify if an object exists
Tv.exists(target)

// Make a new element
Tv.make({new: /* type */, at: Path('/path'), withProperties: {}})

// Move playlist(s) to a new location
Tv.move(/* playlist */, {to: Path('/path')})

// Open the specified object(s)
Tv.open(target)

// Run the application
Tv.run()

// Quit the application
Tv.quit()

// Save the specified object(s)
Tv.save(target)

```

## Suite — TV Suite

_The event suite specific to TV_

### Commands

```javascript
// add one or more files to a playlist
Tv.add(target, {to: Path('/path')})

// reposition to beginning of current track or go to previous track if already at start of current track
Tv.backTrack()

// convert one or more files or tracks
Tv.convert(target)

// download a cloud track or playlist
Tv.download(/* item */)

// skip forward in a playing track
Tv.fastForward()

// advance to the next track in the current playlist
Tv.nextTrack()

// pause playback
Tv.pause()

// play the current track or the specified track or file.
Tv.play(target, {once: true})

// toggle the playing/paused state of the current track
Tv.playpause()

// return to the previous track in the current playlist
Tv.previousTrack()

// update file track information from the current information in the track’s file
Tv.refresh(/* file track */)

// disable fast forward/rewind and resume playback, if playing.
Tv.resume()

// reveal and select a track or playlist
Tv.reveal(/* item */)

// skip backwards in a playing track
Tv.rewind()

// search a playlist for tracks matching the search string. Identical to entering search text in the Search field.
Tv.search(/* playlist */, {for: '...', only: /* eSrA */})

// select the specified object(s)
Tv.select(target)

// stop playback
Tv.stop()

```

### Classes

```javascript
// class: application
// The application program
application.fixedIndexing        // getter (boolean)
application.fixedIndexing = /* value */  // setter
application.currentPlaylist        // read-only getter (playlist)
application.browserWindows[0]                   // first browser window
application.browserWindows.whose({name: 'x'})  // filter

// class: artwork
// a piece of art within a track or playlist
artwork.data        // getter (picture)
artwork.data = /* value */  // setter
artwork.downloaded        // read-only getter (boolean)

// class: browser window
// the main window
browserwindow.view        // getter (playlist)
browserwindow.view = /* value */  // setter
browserwindow.selection        // read-only getter (specifier)

// class: file track
// a track representing a video file
filetrack.location        // getter (file)
filetrack.location = /* value */  // setter

// class: folder playlist
// a folder that contains other playlists

// class: item
// an item
item.name        // getter (text)
item.name = '...'  // setter
item.class        // read-only getter (type)

// class: library playlist
// the main library playlist
libraryplaylist.fileTracks[0]                   // first file track
libraryplaylist.fileTracks.whose({name: 'x'})  // filter

// class: playlist
// a list of tracks/streams
playlist.description        // getter (text)
playlist.description = '...'  // setter
playlist.duration        // read-only getter (integer)
playlist.tracks[0]                   // first track
playlist.tracks.whose({name: 'x'})  // filter

// class: playlist window
// a sub-window showing a single playlist
playlistwindow.selection        // read-only getter (specifier)

// class: shared track
// a track residing in a shared library

// class: source
// a media source (library, CD, device, etc.)
source.capacity        // read-only getter (double integer)
source.libraryPlaylists[0]                   // first library playlist
source.libraryPlaylists.whose({name: 'x'})  // filter

// class: track
// playable video source
track.album        // getter (text)
track.album = '...'  // setter
track.albumRatingKind        // read-only getter (eRtK)
track.artworks[0]                   // first artwork
track.artworks.whose({name: 'x'})  // filter

// class: URL track
// a track representing a network stream
uRLtrack.address        // getter (text)
uRLtrack.address = '...'  // setter

// class: user playlist
// custom playlists created by the user
userplaylist.shared        // getter (boolean)
userplaylist.shared = /* value */  // setter
userplaylist.smart        // read-only getter (boolean)
userplaylist.fileTracks[0]                   // first file track
userplaylist.fileTracks.whose({name: 'x'})  // filter

// class: video window
// the video window

// class: window
// any window
window.bounds        // getter (rectangle)
window.bounds = /* value */  // setter
window.closeable        // read-only getter (boolean)

```

## Suite — Internet suite

_Standard terms for Internet scripting_

### Commands

```javascript
// Opens an iTunes Store or stream URL
Tv.openLocation('...')

```

## JXA gotchas (apply to every app)

- **Property getters take parens:** `doc.name()` not `doc.name`. `=` setter works without parens.
- **Standard Additions are opt-in:** `app.includeStandardAdditions = true` before `beep` / `say` / `displayDialog`.
- **Paths via `Path()`:** `Path('/Users/.../file.rtf')` — no `POSIX file` / `as alias` coercion needed.
- **`whose(...)` takes a record:** `messages.whose({subject: 'JS'})`; comparators are `_`-prefixed: `{age: {_greaterThan: 30}}`, `{name: {_contains: 'Smith'}}`.
- **Named parameters become record keys:** `msg.reply({replyAll: true, openingWindow: false})`.
- **ID lookup:** `app.windows['#412']` (hash-prefix = ID).
