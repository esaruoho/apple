# System Settings — AppleScript Reference

> Extracted from scripting dictionary via `sdef`
> 3 commands, 2 classes, 2 suites

```applescript
tell application "System Settings"
    -- commands go here
end tell
```

## Standard Suite
## System Settings

> Classes and Commands specific to System Settings

### Commands

#### `reveal`

Reveals a settings pane or an anchor within a pane.

- **Direct parameter**: `specifier` — 
- **Returns**: `specifier` — 

#### `authorize`

Prompt for authorization for a settings pane. Deprecated: no longer does anything.

- **Direct parameter**: `pane` — 
- **Returns**: `specifier` — 

#### `timedLoad`

Times and loads given settings pane and returns load time. Deprecated: no longer does anything.

- **Direct parameter**: `pane` — 
- **Returns**: `real` — 

### Classes

#### `pane`

A settings pane.

*Inherits from: `item`*

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `id` | `text` | r | The id of the settings pane. |
| `name` | `text` | r | The name of the settings pane. |

**Contains**: `anchor`

#### `anchor`

An anchor within a settings pane.

*Inherits from: `item`*

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `name` | `text` | r | The name of the anchor. |
