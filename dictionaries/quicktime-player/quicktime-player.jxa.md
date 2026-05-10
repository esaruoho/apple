# Quicktime Player — JavaScript for Automation (JXA) Reference

> Rendered from `quicktime-player.yaml` by `bin/sdef-to-jxa.py`. JXA dialect of the AppleScript dictionary in `quicktime-player.md`.
> Translation rules: WWDC 2014 #306 — *JavaScript for Automation* (Sal Soghoian + David Steinberg).

## Get the application

```javascript
var QuicktimePlayer = Application('Quicktime Player')
QuicktimePlayer.includeStandardAdditions = true   // if calling beep/say/displayDialog
```

**Commands:** 15  ·  **Classes:** 5  ·  **Suites:** 2

## Suite — Internet Suite

_Common URL related functionality_

### Commands

```javascript
// Open a URL.
QuicktimePlayer.openUrl('...')

```

## Suite — QuickTime Player Suite

_Classes and Commands for working with QuickTime Player_

### Commands

```javascript
// Play the movie.
QuicktimePlayer.play(/* document */)

// Start the movie recording.
QuicktimePlayer.start(/* document */)

// Pause the recording.
QuicktimePlayer.pause(/* document */)

// Resume the recording.
QuicktimePlayer.resume(/* document */)

// Stop the movie or recording.
QuicktimePlayer.stop(/* document */)

// Step the movie backward the specified number of steps (default is 1).
QuicktimePlayer.stepBackward(/* document */, {by: /* integer */})

// Step the movie forward the specified number of steps (default is 1).
QuicktimePlayer.stepForward(/* document */, {by: /* integer */})

// Trim the movie.
QuicktimePlayer.trim(/* document */, {from: /* real */, to: /* real */})

// Present the document full screen.
QuicktimePlayer.present(/* document */)

// Create a new movie recording document.
QuicktimePlayer.newMovieRecording()

// Create a new audio recording document.
QuicktimePlayer.newAudioRecording()

// Create a new screen recording document.
QuicktimePlayer.newScreenRecording()

// Export a movie to another file
QuicktimePlayer.export(/* document */, {in: Path('/path'), usingSettingsPreset: '...'})

// Show the document's Remote HUD
QuicktimePlayer.showRemoteHud(/* document */)

```

### Classes

```javascript
// class: video recording device
// A video recording device
videorecordingdevice.name        // read-only getter (text)

// class: audio recording device
// An audio recording device
audiorecordingdevice.name        // read-only getter (text)

// class: audio compression preset
// An audio recording compression preset
audiocompressionpreset.name        // read-only getter (text)

// class: movie compression preset
// A movie recording compression preset
moviecompressionpreset.name        // read-only getter (text)

// class: screen compression preset
// A screen recording compression preset
screencompressionpreset.name        // read-only getter (text)

```

## JXA gotchas (apply to every app)

- **Property getters take parens:** `doc.name()` not `doc.name`. `=` setter works without parens.
- **Standard Additions are opt-in:** `app.includeStandardAdditions = true` before `beep` / `say` / `displayDialog`.
- **Paths via `Path()`:** `Path('/Users/.../file.rtf')` — no `POSIX file` / `as alias` coercion needed.
- **`whose(...)` takes a record:** `messages.whose({subject: 'JS'})`; comparators are `_`-prefixed: `{age: {_greaterThan: 30}}`, `{name: {_contains: 'Smith'}}`.
- **Named parameters become record keys:** `msg.reply({replyAll: true, openingWindow: false})`.
- **ID lookup:** `app.windows['#412']` (hash-prefix = ID).
