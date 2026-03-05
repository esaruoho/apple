# Reminders — AppleScript Reference

> Extracted from scripting dictionary via `sdef`
> 1 commands, 3 classes, 1 suites

```applescript
tell application "Reminders"
    -- commands go here
end tell
```

## Reminders Suite

> Terms and Events for controlling the Reminders application

### Commands

#### `show`

Show an object in the Reminders UI

- **Direct parameter**: `specifier` — The object to be shown
- **Returns**: `specifier` — The object shown

### Classes

#### `account`

An account in the Reminders application

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `id` | `text` | r | The unique identifier of the account |
| `name` | `text` | r | The name of the account |

**Contains**: `list`, `reminder`

#### `list`

A list in the Reminders application

*Inherits from: `item`*

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `id` | `text` | r | The unique identifier of the list |
| `name` | `text` | rw | The name of the list |
| `container` | `` | r | The container of the list |
| `color` | `text` | rw | The color of the list |
| `emblem` | `text` | rw | The emblem icon name of the list |

**Contains**: `reminder`

#### `reminder`

A reminder in the Reminders application

*Inherits from: `item`*

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `name` | `text` | rw | The name of the reminder |
| `id` | `text` | r | The unique identifier of the reminder |
| `container` | `` | r | The container of the reminder |
| `creation date` | `date` | r | The creation date of the reminder |
| `modification date` | `date` | r | The modification date of the reminder |
| `body` | `text` | rw | The notes attached to the reminder |
| `completed` | `boolean` | rw | Whether the reminder is completed |
| `completion date` | `date` | rw | The completion date of the reminder |
| `due date` | `date` | rw | The due date of the reminder; will set both date and time |
| `allday due date` | `date` | rw | The all-day due date of the reminder; will only set a date |
| `remind me date` | `date` | rw | The remind date of the reminder |
| `priority` | `integer` | rw | The priority of the reminder; 0: no priority, 1–4: high, 5: medium, 6–9: low |
| `flagged` | `boolean` | rw | Whether the reminder is flagged |

### Enumerations

#### `saveable file format`

- `text` — Text File Format
