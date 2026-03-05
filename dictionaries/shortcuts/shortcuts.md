# Shortcuts — AppleScript Reference

> Extracted from scripting dictionary via `sdef`
> 1 commands, 2 classes, 1 suites

```applescript
tell application "Shortcuts"
    -- commands go here
end tell
```

## Shortcuts Suite

> Classes and Commands for working with Shortcuts

### Commands

#### `run`

Run a shortcut. To run a shortcut in the background, without opening the Shortcuts app, tell 'Shortcuts Events' instead of 'Shortcuts'.

- **Direct parameter**: `shortcut` — the shortcut to run
- **with input**: `any` *(optional)* — the input to provide to the shortcut
- **Returns**: `any` — the result of the shortcut

### Classes

#### `shortcut`

a shortcut in the Shortcuts application

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `name` | `text` | r | the name of the shortcut |
| `subtitle` | `text` | r | the shortcut's subtitle |
| `id` | `text` | r | the unique identifier of the shortcut |
| `folder` | `folder` | rw | the folder containing this shortcut |
| `color` | `RGB color` | r | the shortcut's color |
| `icon` | `TIFF image` | r | the shortcut's icon |
| `accepts input` | `boolean` | r | indicates whether or not the shortcut accepts input data |
| `action count` | `integer` | r | the number of actions in the shortcut |

#### `folder`

a folder containing shortcuts

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `name` | `text` | rw | the name of the folder |
| `id` | `text` | r | the unique identifier of the folder |

**Contains**: `shortcut`
