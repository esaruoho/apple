# Final Cut Pro — AppleScript Reference

> Extracted from scripting dictionary via `sdef`
> 1 commands, 5 classes, 2 suites

```applescript
tell application "Final Cut Pro"
    -- commands go here
end tell
```

## Final Cut Pro Library

> Scripting terminology for Final Cut Pro Library Model.

### Classes

#### `sequence`

A clip sequence.

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `name` | `text` | r | The name of the sequence. |
| `id` | `text` | r | The unique identifier of the sequence. |
| `container` | `item` | r |  |
| `start time` | `media time` | r | The start time of the sequence. |
| `duration` | `media time` | r | The duration of the sequence. |
| `frame duration` | `media time` | r | The duration of a video frame, an inverse is the frame rate. |
| `timecode format` | `timecode formats` | r | Timecode format, Drop Frame (DF) or Non Drop Frame (NDF). |
| `essential properties` | `record` | r | essential property of the item |

#### `item`

an item

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `class` | `type` | r | the class of the item |
| `container` | `item` | r | the container of the item |
| `id` | `text` | r | the id of the item |
| `index` | `integer` | r | The index of the item in internal application order. |
| `name` | `text` | rw | the name of the item |
| `persistent ID` | `text` | r | the id of the item as a hexadecimal string. This id does not change over time. |
| `properties` | `record` | rw | every property of the item |
| `essential properties` | `record` | r | essential property of the item |

#### `project`

A project.

*Inherits from: `item`*

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `name` | `text` | r | The name of the project. |
| `id` | `text` | r | The unique identifier of the project. |
| `container` | `item` | r |  |
| `essential properties` | `record` | r | essential property of the item |
| `sequence` | `sequence` | r |  |

#### `event`

An event.

*Inherits from: `item`*

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `name` | `text` | r | The name of the event. |
| `id` | `text` | r | The unique identifier of the event. |
| `container` | `item` | r |  |
| `essential properties` | `record` | r | essential property of the item |

**Contains**: `sequence`, `project`

#### `library`

A library.

*Inherits from: `item`*

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `name` | `text` | r | The name of the library. |
| `id` | `text` | r | The unique identifier of the library. |
| `container` | `application` | r |  |
| `essential properties` | `record` | r | essential property of the item |
| `file` | `file` | r |  |

**Contains**: `event`

### Enumerations

#### `timecode formats`

- `unspecified` — Timecode format unspecified.
- `drop frame` — Drop frame timecode.
- `non drop frame` — Non drop frame timecode.

## Final Cut Pro Application

> Scripting terminology for Final Cut Pro application.

### Commands

#### `get`

Get data.

- **Direct parameter**: `specifier` — Object specifier.
- **Returns**: `any` — The data for the object specifier.
