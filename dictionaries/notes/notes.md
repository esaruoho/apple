# Notes — AppleScript Reference

> Extracted from scripting dictionary via `sdef`
> 2 commands, 4 classes, 1 suites

```applescript
tell application "Notes"
    -- commands go here
end tell
```

## Notes Suite

> Terms and Events for controlling the Notes application

### Commands

#### `open note location`

Open a note URL.

- **Direct parameter**: `specifier` — The URL to be opened.

#### `show`

Show an object in the UI

- **Direct parameter**: `specifier` — The object to be shown
- **separately**: `boolean` *(optional)* — 
- **Returns**: `specifier` — The object shown.

### Classes

#### `account`

a Notes account

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `default folder` | `folder` | rw | the default folder for creating notes |
| `name` | `text` | rw | the name of the account |
| `upgraded` | `boolean` | r | Is the account upgraded? |
| `id` | `text` | r | the unique identifier of the account |

**Contains**: `folder`, `note`

#### `folder`

a folder containing notes

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `name` | `text` | rw | the name of the folder |
| `id` | `text` | r | the unique identifier of the folder |
| `shared` | `boolean` | r | Is the folder shared? |
| `container` | `` | r | the container of the folder |

**Contains**: `folder`, `note`

#### `note`

a note in the Notes application

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `name` | `text` | rw | the name of the note (normally the first line of the body) |
| `id` | `text` | r | the unique identifier of the note |
| `container` | `folder` | r | the folder of the note |
| `body` | `text` | rw | the HTML content of the note |
| `plaintext` | `text` | r | the plaintext content of the note |
| `creation date` | `date` | r | the creation date of the note |
| `modification date` | `date` | r | the modification date of the note |
| `password protected` | `boolean` | r | Is the note password protected? |
| `shared` | `boolean` | r | Is the note shared? |

**Contains**: `attachment`

#### `attachment`

an attachment in a note

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `name` | `text` | r | the name of the attachment |
| `id` | `text` | r | the unique identifier of the attachment |
| `container` | `note` | r | the note containing the attachment |
| `content identifier` | `text` | r | the content-id URL in the note's HTML |
| `creation date` | `date` | r | the creation date of the attachment |
| `modification date` | `date` | r | the modification date of the attachment |
| `URL` | `text` | r | for URL attachments, the URL the attachment represents |
| `shared` | `boolean` | r | Is the attachment shared? |

### Enumerations

#### `saveable file format`

- `native format` — Native format
