# Messages — AppleScript Reference

> Extracted from scripting dictionary via `sdef`
> 3 commands, 4 classes, 1 suites

```applescript
tell application "Messages"
    -- commands go here
end tell
```

## Messages Suite

> commands and classes for Messages scripting.

### Commands

#### `send`

Sends a message to a participant or to a chat.

- **Direct parameter**: `specifier` — 
- **to**: `specifier` — 

#### `login`

Login to all accounts.


#### `logout`

Logout of all accounts.


### Classes

#### `participant`

A participant for an account.

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `id` | `text` | r | The participant's unique identifier. For example: 01234567-89AB-CDEF-0123-456789ABCDEF:+11234567890 |
| `account` | `account` | r | The account for this participant. |
| `name` | `text` | r | The participant's name as it appears in the participant list. |
| `handle` | `text` | r | The participant's handle. |
| `first name` | `text` | r | The first name from this participan's Contacts card, if available |
| `last name` | `text` | r | The last name from this participant's Contacts card, if available |
| `full name` | `text` | r | The full name from this participant's Contacts card, if available |

#### `account`

An account that can be logged in to from this system

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `id` | `text` | r | A unique identifier for this account. |
| `description` | `text` | r | The name of this account as defined in Account preferences description field |
| `enabled` | `boolean` | rw | Is the account enabled? |
| `connection status` | `connection status` | r | The connection status for this account. |
| `service type` | `service type` | r | The type of service for this account |

**Contains**: `chat`, `participant`

#### `chat`

An SMS or iMessage chat.

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `id` | `text` | r | A guid identifier for this chat. |
| `name` | `text` | r | The chat's name as it appears in the chat list. |
| `account` | `account` | r | The account which is participating in this chat. |

**Contains**: `participant`

#### `file transfer`

A file being sent or received

*Inherits from: `item`*

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `id` | `text` | r | The guid for this file transfer |
| `name` | `text` | r | The name of this file |
| `file path` | `file` | r | The local path to this file transfer |
| `direction` | `direction` | r | The direction in which this file is being sent |
| `account` | `account` | r | The account on which this file transfer is taking place |
| `participant` | `participant` | r | The other participatant in this file transfer |
| `file size` | `integer` | r | The total size in bytes of the completed file transfer |
| `file progress` | `integer` | r | The number of bytes that have been transferred |
| `transfer status` | `transfer status` | r | The current status of this file transfer |
| `started` | `date` | r | The date that this file transfer started |

### Enumerations

#### `service type`

- `SMS`
- `iMessage`
- `RCS`

#### `direction`

- `incoming`
- `outgoing`

#### `transfer status`

- `preparing`
- `waiting`
- `transferring`
- `finalizing`
- `finished`
- `failed`

#### `connection status`

- `disconnecting`
- `connected`
- `connecting`
- `disconnected`
