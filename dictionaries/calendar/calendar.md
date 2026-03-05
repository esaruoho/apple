# Calendar — AppleScript Reference

> Extracted from scripting dictionary via `sdef`
> 8 commands, 7 classes, 2 suites

```applescript
tell application "Calendar"
    -- commands go here
end tell
```

## Standard Suite

> Common classes and commands for all applications.

## iCal

> iCal classes and commands

### Commands

#### `create calendar`

Creates a new calendar (obsolete, will be removed in next release)

- **with name**: `text` *(optional)* — the calendar new name

#### `reload calendars`

Tell the application to reload all calendar files contents


#### `switch view`

Show calendar on the given view

- **to**: `view type` — the calendar view to be displayed

#### `view calendar`

Show calendar on the given date

- **at**: `date` — the date to be displayed

#### `GetURL`

Subscribe to a remote calendar through a webcal or http URL

- **Direct parameter**: `text` — the iCal URL

#### `show`

Show the event or to-do in the calendar window

- **Direct parameter**: `specifier` — the item

#### `make`
- **new**: `type` — The class of the new object.
- **at**: `location specifier` *(optional)* — The location at which to insert the object.
- **with data**: `any` *(optional)* — The initial contents of the object.
- **with properties**: `record` *(optional)* — The initial values for properties of the object.
- **Returns**: `specifier` — The new object.

#### `save`

### Classes

#### `calendar`

This class represents a calendar.

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `name` | `text` | rw | This is the calendar title. |
| `color` | `RGB color` | rw | The calendar color. |
| `calendarIdentifier` | `text` | r | An unique calendar key |
| `writable` | `boolean` | r | This is the calendar title. |
| `description` | `text` | rw | This is the calendar description. |

**Contains**: `event`

#### `display alarm`

This class represents a message alarm.

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `trigger interval` | `integer` | rw | The interval in minutes between the event and the alarm: (positive for alarm that trigger after the event date or negative for alarms that trigger before). |
| `trigger date` | `date` | rw | An absolute alarm date. |

#### `mail alarm`

This class represents a mail alarm.

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `trigger interval` | `integer` | rw | The interval in minutes between the event and the alarm: (positive for alarm that trigger after the event date or negative for alarms that trigger before). |
| `trigger date` | `date` | rw | An absolute alarm date. |

#### `sound alarm`

This class represents a sound alarm.

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `trigger interval` | `integer` | rw | The interval in minutes between the event and the alarm: (positive for alarm that trigger after the event date or negative for alarms that trigger before). |
| `trigger date` | `date` | rw | An absolute alarm date. |
| `sound name` | `text` | rw | The system sound name to be used for the alarm |
| `sound file` | `text` | rw | The (POSIX) path to the sound file to be used for the alarm |

#### `open file alarm`

This class represents an 'open file' alarm. Starting with OS X 10.14, it is not possible to create new open file alarms or view URLs for existing open file alarms. Trying to save or modify an open file alarm will result in a save error. Editing other aspects of events or reminders that have existing open file alarms is allowed as long as the alarm isn't modified.

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `trigger interval` | `integer` | rw | The interval in minutes between the event and the alarm: (positive for alarm that trigger after the event date or negative for alarms that trigger before). |
| `trigger date` | `date` | rw | An absolute alarm date. |
| `filepath` | `text` | rw | The (POSIX) path to be opened by the alarm |

#### `attendee`

This class represents a attendee.

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `display name` | `text` | r | The first and last name of the attendee. |
| `email` | `text` | r | e-mail of the attendee. |
| `participation status` | `participation status` | r | The invitation status for the attendee. |

#### `event`

This class represents an event.

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `description` | `text` | rw | The events notes. |
| `start date` | `date` | rw | The event start date. |
| `end date` | `date` | rw | The event end date. |
| `allday event` | `boolean` | rw | True if the event is an all-day event |
| `recurrence` | `text` | rw | The iCalendar (RFC 2445) string describing the event recurrence, if defined |
| `sequence` | `integer` | r | The event version. |
| `stamp date` | `date` | rw | The event modification date. |
| `excluded dates` | `` | rw | The exception dates. |
| `status` | `event status` | rw | The event status. |
| `summary` | `text` | rw | This is the event summary. |
| `location` | `text` | rw | This is the event location. |
| `uid` | `text` | r | An unique event key. |
| `url` | `text` | rw | The URL associated to the event. |

**Contains**: `attendee`, `display alarm`, `mail alarm`, `open file alarm`, `sound alarm`

### Enumerations

#### `participation status`

- `unknown` — No anwser yet
- `accepted` — Invitation has been accepted
- `declined` — Invitation has been declined
- `tentative` — Invitation has been tentatively accepted

#### `event status`

- `cancelled` — A cancelled event
- `confirmed` — A confirmed event
- `none` — An event without status
- `tentative` — A tentative event

#### `calendar priority`

- `no priority` — No priority
- `low priority` — Low priority
- `medium priority` — Medium priority
- `high priority` — High priority

#### `view type`

- `day view` — The iCal day view
- `week view` — The iCal week view
- `month view` — The iCal month view
