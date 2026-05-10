# Music — JavaScript for Automation (JXA) Reference

> Rendered from `music.yaml` by `bin/sdef-to-jxa.py`. JXA dialect of the AppleScript dictionary in `music.md`.
> Translation rules: WWDC 2014 #306 — *JavaScript for Automation* (Sal Soghoian + David Steinberg).

## Get the application

```javascript
var Music = Application('Music')
Music.includeStandardAdditions = true   // if calling beep/say/displayDialog
```

**Commands:** 31  ·  **Classes:** 26  ·  **Suites:** 3

## Suite — Standard Suite

_Common terms for most applications_

### Commands

```javascript
// Print the specified object(s)
Music.print(target, {printDialog: true, withProperties: /* print settings */, kind: /* eKnd */, theme: '...'})

// Close an object
Music.close(target)

// Return the number of elements of a particular class within an object
Music.count(target, {each: /* type */})

// Delete an element from an object
Music.delete(target)

// Duplicate one or more object(s)
Music.duplicate(target, {to: Path('/path')})

// Verify if an object exists
Music.exists(target)

// Make a new element
Music.make({new: /* type */, at: Path('/path'), withProperties: {}})

// Move playlist(s) to a new location
Music.move(/* playlist */, {to: Path('/path')})

// Open the specified object(s)
Music.open(target)

// Run the application
Music.run()

// Quit the application
Music.quit()

// Save the specified object(s)
Music.save(target)

```

## Suite — Music Suite

_The event suite specific to Music_

### Commands

```javascript
// add one or more files to a playlist
Music.add(target, {to: Path('/path')})

// reposition to beginning of current track or go to previous track if already at start of current track
Music.backTrack()

// convert one or more files or tracks
Music.convert(target)

// download a cloud track or playlist
Music.download(/* item */)

// export a source or playlist
Music.export(/* item */, {as: /* eExF */, to: Path('/path')})

// skip forward in a playing track
Music.fastForward()

// advance to the next track in the current playlist
Music.nextTrack()

// pause playback
Music.pause()

// play the current track or the specified track or file.
Music.play(target, {once: true})

// toggle the playing/paused state of the current track
Music.playpause()

// return to the previous track in the current playlist
Music.previousTrack()

// update file track information from the current information in the track’s file
Music.refresh(/* file track */)

// disable fast forward/rewind and resume playback, if playing.
Music.resume()

// reveal and select a track or playlist
Music.reveal(/* item */)

// skip backwards in a playing track
Music.rewind()

// search a playlist for tracks matching the search string. Identical to entering search text in the Search field.
Music.search(/* playlist */, {for: '...', only: /* eSrA */})

// select the specified object(s)
Music.select(target)

// stop playback
Music.stop()

```

### Classes

```javascript
// class: AirPlay device
// an AirPlay device
airPlaydevice.selected        // getter (boolean)
airPlaydevice.selected = /* value */  // setter
airPlaydevice.active        // read-only getter (boolean)

// class: application
// The application program
application.currentAirplayDevices        // getter ()
application.currentAirplayDevices = /* value */  // setter
application.airplayEnabled        // read-only getter (boolean)
application.airplayDevices[0]                   // first AirPlay device
application.airplayDevices.whose({name: 'x'})  // filter

// class: artwork
// a piece of art within a track or playlist
artwork.data        // getter (picture)
artwork.data = /* value */  // setter
artwork.downloaded        // read-only getter (boolean)

// class: audio CD playlist
// a playlist representing an audio CD
audioCDplaylist.artist        // getter (text)
audioCDplaylist.artist = '...'  // setter
audioCDplaylist.audioCdTracks[0]                   // first audio CD track
audioCDplaylist.audioCdTracks.whose({name: 'x'})  // filter

// class: audio CD track
// a track on an audio CD
audioCDtrack.location        // read-only getter (file)

// class: browser window
// the main window
browserwindow.view        // getter (playlist)
browserwindow.view = /* value */  // setter
browserwindow.selection        // read-only getter (specifier)

// class: encoder
// converts a track to a specific file format
encoder.format        // read-only getter (text)

// class: EQ preset
// equalizer preset configuration
eQpreset.band1        // getter (real)
eQpreset.band1 = /* value */  // setter
eQpreset.modifiable        // read-only getter (boolean)

// class: EQ window
// the equalizer window

// class: file track
// a track representing an audio file (MP3, AIFF, etc.)
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

// class: miniplayer window
// the miniplayer window

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

// class: radio tuner playlist
// the radio tuner playlist
radiotunerplaylist.urlTracks[0]                   // first URL track
radiotunerplaylist.urlTracks.whose({name: 'x'})  // filter

// class: shared track
// a track residing in a shared library

// class: source
// a media source (library, CD, device, etc.)
source.capacity        // read-only getter (double integer)
source.audioCdPlaylists[0]                   // first audio CD playlist
source.audioCdPlaylists.whose({name: 'x'})  // filter

// class: subscription playlist
// a subscription playlist from Apple Music
subscriptionplaylist.fileTracks[0]                   // first file track
subscriptionplaylist.fileTracks.whose({name: 'x'})  // filter

// class: track
// playable audio source
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

// class: visual
// a visual plug-in

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
// Opens an iTunes Store or audio stream URL
Music.openLocation('...')

```

## JXA gotchas (apply to every app)

- **Property getters take parens:** `doc.name()` not `doc.name`. `=` setter works without parens.
- **Standard Additions are opt-in:** `app.includeStandardAdditions = true` before `beep` / `say` / `displayDialog`.
- **Paths via `Path()`:** `Path('/Users/.../file.rtf')` — no `POSIX file` / `as alias` coercion needed.
- **`whose(...)` takes a record:** `messages.whose({subject: 'JS'})`; comparators are `_`-prefixed: `{age: {_greaterThan: 30}}`, `{name: {_contains: 'Smith'}}`.
- **Named parameters become record keys:** `msg.reply({replyAll: true, openingWindow: false})`.
- **ID lookup:** `app.windows['#412']` (hash-prefix = ID).
