# Calendar — JavaScript for Automation (JXA) Reference

> Rendered from `calendar.yaml` by `bin/sdef-to-jxa.py`. JXA dialect of the AppleScript dictionary in `calendar.md`.
> Translation rules: WWDC 2014 #306 — *JavaScript for Automation* (Sal Soghoian + David Steinberg).

## Get the application

```javascript
var Calendar = Application('Calendar')
Calendar.includeStandardAdditions = true   // if calling beep/say/displayDialog
```

**Commands:** 8  ·  **Classes:** 7  ·  **Suites:** 2

## Suite — Standard Suite

_Common classes and commands for all applications._

## Suite — iCal

_iCal classes and commands_

### Commands

```javascript
// Creates a new calendar (obsolete, will be removed in next release)
Calendar.createCalendar({withName: '...'})

// Tell the application to reload all calendar files contents
Calendar.reloadCalendars()

// Show calendar on the given view
Calendar.switchView({to: /* view type */})

// Show calendar on the given date
Calendar.viewCalendar({at: /* date */})

// Subscribe to a remote calendar through a webcal or http URL
Calendar.geturl('...')

// Show the event or to-do in the calendar window
Calendar.show(target)

Calendar.make({new: /* type */, at: Path('/path'), withData: /* any */, withProperties: {}})

Calendar.save()

```

### Classes

```javascript
// class: calendar
// This class represents a calendar.
calendar.name        // getter (text)
calendar.name = '...'  // setter
calendar.calendaridentifier        // read-only getter (text)
calendar.events[0]                   // first event
calendar.events.whose({name: 'x'})  // filter

// class: display alarm
// This class represents a message alarm.
displayalarm.triggerInterval        // getter (integer)
displayalarm.triggerInterval = /* value */  // setter

// class: mail alarm
// This class represents a mail alarm.
mailalarm.triggerInterval        // getter (integer)
mailalarm.triggerInterval = /* value */  // setter

// class: sound alarm
// This class represents a sound alarm.
soundalarm.triggerInterval        // getter (integer)
soundalarm.triggerInterval = /* value */  // setter

// class: open file alarm
// This class represents an 'open file' alarm. Starting with OS X 10.14, it is not possible to create new open file alarms or view URLs for existing open file alarms. Trying to save or modify an open file alarm will result in a save error. Editing other aspects of events or reminders that have existing open file alarms is allowed as long as the alarm isn't modified.
openfilealarm.triggerInterval        // getter (integer)
openfilealarm.triggerInterval = /* value */  // setter

// class: attendee
// This class represents a attendee.
attendee.displayName        // read-only getter (text)

// class: event
// This class represents an event.
event.description        // getter (text)
event.description = '...'  // setter
event.sequence        // read-only getter (integer)
event.attendees[0]                   // first attendee
event.attendees.whose({name: 'x'})  // filter

```

## JXA gotchas (apply to every app)

- **Property getters take parens:** `doc.name()` not `doc.name`. `=` setter works without parens.
- **Standard Additions are opt-in:** `app.includeStandardAdditions = true` before `beep` / `say` / `displayDialog`.
- **Paths via `Path()`:** `Path('/Users/.../file.rtf')` — no `POSIX file` / `as alias` coercion needed.
- **`whose(...)` takes a record:** `messages.whose({subject: 'JS'})`; comparators are `_`-prefixed: `{age: {_greaterThan: 30}}`, `{name: {_contains: 'Smith'}}`.
- **Named parameters become record keys:** `msg.reply({replyAll: true, openingWindow: false})`.
- **ID lookup:** `app.windows['#412']` (hash-prefix = ID).
