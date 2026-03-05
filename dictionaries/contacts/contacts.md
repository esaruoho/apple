# Contacts — AppleScript Reference

> Extracted from scripting dictionary via `sdef`
> 8 commands, 12 classes, 3 suites

```applescript
tell application "Contacts"
    -- commands go here
end tell
```

## Standard Suite

> Common classes and commands for all applications.

### Commands

#### `make`

Create a new object.

- **new**: `type` — The class of the new object.
- **at**: `location specifier` *(optional)* — The location at which to insert the object.
- **with data**: `any` *(optional)* — The initial contents of the object.
- **with properties**: `record` *(optional)* — The initial values for properties of the object.
- **Returns**: `specifier` — The new object.

## Contacts Script Suite

> commands and classes for Contacts scripting.

### Commands

#### `add`

Add a child object.

- **Direct parameter**: `entry` — object to add.
- **to**: `specifier` — where to add this child to.
- **Returns**: `person` — 

#### `remove`

Remove a child object.

- **Direct parameter**: `entry` — object to remove.
- **from**: `specifier` — where to remove this child from.
- **Returns**: `person` — 

#### `save`

Save all Contacts changes. Also see the unsaved property for the application class.

- **Returns**: `any` — 

### Classes

#### `address`

Address for the given record.

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `city` | `` | rw | City part of the address. |
| `formatted address` | `` | r | properly formatted string for this address. |
| `street` | `` | rw | Street part of the address, multiple lines separated by carriage returns. |
| `id` | `` | rw | unique identifier for this address. |
| `zip` | `` | rw | Zip or postal code of the address. |
| `country` | `` | rw | Country part of the address. |
| `label` | `` | rw | Label. |
| `country code` | `` | rw | Country code part of the address (should be a two character iso country code). |
| `state` | `` | rw | State, Province, or Region part of the address. |

#### `contact info`

Container object in the database, holds a key and a value

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `label` | `` | rw | Label is the label associated with value like "work", "home", etc. |
| `value` | `` | rw | Value. |
| `id` | `` | r | unique identifier for this entry, this is persistent, and stays with the record. |

#### `custom date`

Arbitrary date associated with this person.

*Inherits from: `contact info`*

#### `email`

Email address for a person.

*Inherits from: `contact info`*

#### `entry`

An entry in the address book database

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `modification date` | `date` | r | when the contact was last modified. |
| `creation date` | `date` | r | when the contact was created. |
| `id` | `` | r | unique and persistent identifier for this record. |
| `selected` | `boolean` | rw | Is the entry selected? |

#### `group`

A Group Record in the address book database

*Inherits from: `entry`*

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `name` | `` | rw | The name of this group. |

**Contains**: `group`, `person`

#### `instant message`

Address for instant messaging.

*Inherits from: `contact info`*

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `service name` | `` | r | The service name of this instant message address. |
| `service type` | `` | rw | The service type of this instant message address. |
| `user name` | `` | rw | The user name of this instant message address. |

#### `person`

A person in the address book database.

*Inherits from: `entry`*

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `nickname` | `` | rw | The Nickname of this person. |
| `organization` | `` | rw | Organization that employs this person. |
| `maiden name` | `` | rw | The Maiden name of this person. |
| `suffix` | `` | rw | The Suffix of this person. |
| `vcard` | `` | r | Person information in vCard format, this always returns a card in version 3.0 format. |
| `home page` | `` | rw | The home page of this person. |
| `birth date` | `` | rw | The birth date of this person. |
| `phonetic last name` | `` | rw | The phonetic version of the Last name of this person. |
| `title` | `` | rw | The title of this person. |
| `phonetic middle name` | `` | rw | The Phonetic version of the Middle name of this person. |
| `department` | `` | rw | Department that this person works for. |
| `image` | `` | rw | Image for person. |
| `name` | `` | r | First/Last name of the person, uses the name display order preference setting in Contacts. |
| `note` | `` | rw | Notes for this person. |
| `company` | `boolean` | rw | Is the current record a company or a person. |
| `middle name` | `` | rw | The Middle name of this person. |
| `phonetic first name` | `` | rw | The phonetic version of the First name of this person. |
| `job title` | `` | rw | The job title of this person. |
| `last name` | `` | rw | The Last name of this person. |
| `first name` | `` | rw | The First name of this person. |

**Contains**: `MSN handle`, `url`, `address`, `phone`, `Jabber handle`, `group`, `custom date`, `AIM Handle`, `Yahoo handle`, `ICQ handle`, `instant message`, `social profile`, `related name`, `email`

#### `phone`

Phone number for a person.

*Inherits from: `contact info`*

#### `related name`

Other names related to this person.

*Inherits from: `contact info`*

#### `social profile`

Profile for social networks.

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `id` | `` | r | The persistent unique identifier for this profile. |
| `service name` | `` | rw | The service name of this social profile. |
| `user name` | `` | rw | The username used with this social profile. |
| `user identifier` | `` | rw | A service-specific identifier used with this social profile. |
| `url` | `` | rw | The URL of this social profile. |

#### `url`

URLs for this person.

*Inherits from: `contact info`*

### Enumerations

#### `saveable file format`

- `archive` — The native Contacts file format

#### `instant message service type`

- `AIM`
- `Facebook`
- `Gadu Gadu`
- `Google Talk`
- `ICQ`
- `Jabber`
- `MSN`
- `QQ`
- `Skype`
- `Yahoo`

## Address Book Rollover Suite

> These event definitions are used for constructing Address Book Rollover plug-ins. They would not normally appear in a typical end user script.

### Commands

#### `action property`

RollOver - Which property this roll over is associated with (Properties can be one of maiden name, phone, email, url, birth date, custom date, related name, aim, icq, jabber, msn, yahoo, address.)

- **Returns**: `text` — 

#### `action title`

RollOver - Returns the title that will be placed in the menu for this roll over

- **with**: `any` — property that that was returned from the "action property" handler.
- **for**: `person` — Currently selected person.
- **Returns**: `text` — 

#### `perform action`

RollOver - Performs the action on the given person and value

- **with**: `any` — property that that was returned from the "action property" handler.
- **for**: `person` — Currently selected person.
- **Returns**: `boolean` — 

#### `should enable action`

RollOver - Determines if the rollover action should be enabled for the given person and value

- **with**: `any` — property that that was returned from the "action property" handler.
- **for**: `person` — Currently selected person.
- **Returns**: `boolean` — 
