# QuickTime Player — AppleScript Reference

> Extracted from scripting dictionary via `sdef`
> 15 commands, 5 classes, 2 suites

```applescript
tell application "QuickTime Player"
    -- commands go here
end tell
```

## Internet Suite

> Common URL related functionality

### Commands

#### `open URL`

Open a URL.

- **Direct parameter**: `text` — the URL

## QuickTime Player Suite

> Classes and Commands for working with QuickTime Player

### Commands

#### `play`

Play the movie.

- **Direct parameter**: `document` — the movie to play

#### `start`

Start the movie recording.

- **Direct parameter**: `document` — the recording to start

#### `pause`

Pause the recording.

- **Direct parameter**: `document` — the recording to pause

#### `resume`

Resume the recording.

- **Direct parameter**: `document` — the recording to resume

#### `stop`

Stop the movie or recording.

- **Direct parameter**: `document` — the movie or recording to stop

#### `step backward`

Step the movie backward the specified number of steps (default is 1).

- **Direct parameter**: `document` — the movie to step
- **by**: `integer` *(optional)* — number of steps

#### `step forward`

Step the movie forward the specified number of steps (default is 1).

- **Direct parameter**: `document` — the movie to step
- **by**: `integer` *(optional)* — number of steps

#### `trim`

Trim the movie.

- **Direct parameter**: `document` — the movie to trim
- **from**: `real` — start time in seconds
- **to**: `real` — end time in seconds

#### `present`

Present the document full screen.

- **Direct parameter**: `document` — the document to present

#### `new movie recording`

Create a new movie recording document.

- **Returns**: `specifier` — The new movie recording document.

#### `new audio recording`

Create a new audio recording document.

- **Returns**: `specifier` — The new audio recording document.

#### `new screen recording`

Create a new screen recording document.


#### `export`

Export a movie to another file

- **Direct parameter**: `document` — the movie to export
- **in**: `file` — the destination file
- **using settings preset**: `text` — the name of the export settings preset to use

#### `show remote hud`

Show the document's Remote HUD

- **Direct parameter**: `document` — 

### Classes

#### `video recording device`

A video recording device

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `name` | `text` | r | The name of the device. |
| `id` | `text` | r | The unique identifier of the device. |

#### `audio recording device`

An audio recording device

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `name` | `text` | r | The name of the device. |
| `id` | `text` | r | The unique identifier of the device. |

#### `audio compression preset`

An audio recording compression preset

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `name` | `text` | r | The name of the preset. |
| `id` | `text` | r | The unique identifier of the preset. |

#### `movie compression preset`

A movie recording compression preset

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `name` | `text` | r | The name of the preset. |
| `id` | `text` | r | The unique identifier of the preset. |

#### `screen compression preset`

A screen recording compression preset

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `name` | `text` | r | The name of the preset. |
| `id` | `text` | r | The unique identifier of the preset. |
