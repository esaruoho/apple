# Contacts — JavaScript for Automation (JXA) Reference

> Rendered from `contacts.yaml` by `bin/sdef-to-jxa.py`. JXA dialect of the AppleScript dictionary in `contacts.md`.
> Translation rules: WWDC 2014 #306 — *JavaScript for Automation* (Sal Soghoian + David Steinberg).

## Get the application

```javascript
var Contacts = Application('Contacts')
Contacts.includeStandardAdditions = true   // if calling beep/say/displayDialog
```

**Commands:** 8  ·  **Classes:** 17  ·  **Suites:** 3

## Suite — Standard Suite

_Common classes and commands for all applications._

### Commands

```javascript
// Create a new object.
Contacts.make({new: /* type */, at: Path('/path'), withData: /* any */, withProperties: {}})

```

## Suite — Contacts Script Suite

_commands and classes for Contacts scripting._

### Commands

```javascript
// Add a child object.
Contacts.add(/* entry */, {to: /* specifier */})

// Remove a child object.
Contacts.remove(/* entry */, {from: /* specifier */})

// Save all Contacts changes. Also see the unsaved property for the application class.
Contacts.save()

```

### Classes

```javascript
// class: address
// Address for the given record.
address.city        // getter ()
address.city = /* value */  // setter
address.formattedAddress        // read-only getter ()

// class: AIM Handle
// User name for America Online (AOL) instant messaging.

// class: contact info
// Container object in the database, holds a key and a value
contactinfo.label        // getter ()
contactinfo.label = /* value */  // setter
contactinfo.id        // read-only getter ()

// class: custom date
// Arbitrary date associated with this person.

// class: email
// Email address for a person.

// class: entry
// An entry in the address book database
entry.selected        // getter (boolean)
entry.selected = /* value */  // setter
entry.modificationDate        // read-only getter (date)

// class: group
// A Group Record in the address book database
group.name        // getter ()
group.name = /* value */  // setter
group.groups[0]                   // first group
group.groups.whose({name: 'x'})  // filter

// class: ICQ handle
// User name for ICQ instant messaging.

// class: instant message
// Address for instant messaging.
instantmessage.serviceType        // getter ()
instantmessage.serviceType = /* value */  // setter
instantmessage.serviceName        // read-only getter ()

// class: Jabber handle
// User name for Jabber instant messaging.

// class: MSN handle
// User name for Microsoft Network (MSN) instant messaging.

// class: person
// A person in the address book database.
person.nickname        // getter ()
person.nickname = /* value */  // setter
person.vcard        // read-only getter ()
person.msnHandles[0]                   // first MSN handle
person.msnHandles.whose({name: 'x'})  // filter

// class: phone
// Phone number for a person.

// class: related name
// Other names related to this person.

// class: social profile
// Profile for social networks.
socialprofile.serviceName        // getter ()
socialprofile.serviceName = /* value */  // setter
socialprofile.id        // read-only getter ()

// class: url
// URLs for this person.

// class: Yahoo handle
// User name for Yahoo instant messaging.

```

## Suite — Address Book Rollover Suite

_These event definitions are used for constructing Address Book Rollover plug-ins. They would not normally appear in a typical end user script._

### Commands

```javascript
// RollOver - Which property this roll over is associated with (Properties can be one of maiden name, phone, email, url, birth date, custom date, related name, aim, icq, jabber, msn, yahoo, address.)
Contacts.actionProperty()

// RollOver - Returns the title that will be placed in the menu for this roll over
Contacts.actionTitle({with: /* any */, for: /* person */})

// RollOver - Performs the action on the given person and value
Contacts.performAction({with: /* any */, for: /* person */})

// RollOver - Determines if the rollover action should be enabled for the given person and value
Contacts.shouldEnableAction({with: /* any */, for: /* person */})

```

## JXA gotchas (apply to every app)

- **Property getters take parens:** `doc.name()` not `doc.name`. `=` setter works without parens.
- **Standard Additions are opt-in:** `app.includeStandardAdditions = true` before `beep` / `say` / `displayDialog`.
- **Paths via `Path()`:** `Path('/Users/.../file.rtf')` — no `POSIX file` / `as alias` coercion needed.
- **`whose(...)` takes a record:** `messages.whose({subject: 'JS'})`; comparators are `_`-prefixed: `{age: {_greaterThan: 30}}`, `{name: {_contains: 'Smith'}}`.
- **Named parameters become record keys:** `msg.reply({replyAll: true, openingWindow: false})`.
- **ID lookup:** `app.windows['#412']` (hash-prefix = ID).
