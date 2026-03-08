# Data Type Chaining on macOS

How AppleScript data flows between apps — and where the chain breaks.

---

## 1. What Is Data Type Chaining?

Sal Soghoian's Automator patent (US 7,428,535 B1, granted 2008) introduced the concept of **typed data flow between actions**. The core idea:

1. Each action **produces** typed output (e.g., file references, text, URLs)
2. Each action **accepts** typed input
3. The system **filters** available next-actions based on type compatibility
4. When types don't match, an invisible **Data Conversion Engine** bridges them automatically using breadth-first search for the shortest conversion path

This is what makes Automator "smart." When you place a "Get Selected Finder Items" action, Automator knows it produces `file references` and only offers actions that accept file references as the next step. Actions are ranked by conversion cost: exact match (highest relevance), convertible (medium), incompatible (hidden).

The patent also introduced **Universal Type Identifiers (UTIs)** — Apple's reverse-DNS naming convention (`com.apple.iphoto.photo`, `public.alias`) — as the type system. UTIs are still used across macOS and iOS today.

**Related patents filed the same day (June 25, 2004):**

| Patent | Title | Role |
|--------|-------|------|
| US 7,428,535 | Automatic Relevance Filtering | Data type chaining + action filtering |
| 10/877,292 | Visual Programming Tool | The Automator UI |
| 10/876,940 | Automatic Execution Flow Ordering | Runtime flow logic |
| 10/876,931 | Automatic Conversion for Disparate Data Types | Data type bridging |

Together, these four patents form the complete intellectual foundation of Automator.

---

## 2. Data Type Map — 13 Apps

Every app with an AppleScript dictionary declares what data types it accepts as input and what it produces as output. These were extracted from the YAML scripting dictionaries via `sdef-extract.py`.

### Finder

| Direction | Data Types |
|-----------|-----------|
| **Accepts** | `boolean`, `list`, `location specifier`, `property`, `record`, `specifier`, `text`, `type` |
| **Produces** | `boolean`, `integer`, `specifier` |

Key objects: `file`, `folder`, `disk`, `alias file`, `application file`, `document file`, `package`, `window`
Notable properties: `name` (text), `URL` (text), `size` (double integer), `creation date` (date), `modification date` (date), `kind` (text), `comment` (text)

### Music

| Direction | Data Types |
|-----------|-----------|
| **Accepts** | `boolean`, `eExF`, `eKnd`, `eSrA`, `file`, `file track`, `item`, `location specifier`, `playlist`, `print settings`, `record`, `specifier`, `text`, `type` |
| **Produces** | `boolean`, `integer`, `specifier`, `text`, `track` |

Key objects: `track`, `playlist`, `source`, `artwork`, `AirPlay device`
Notable properties: `name` (text), `artist` (text), `album` (text), `genre` (text), `duration` (real), `current track` (track), `current stream URL` (text), `lyrics` (text)

### Mail

| Direction | Data Types |
|-----------|-----------|
| **Accepts** | `account`, `boolean`, `file`, `location specifier`, `mailbox`, `message`, `outgoing message`, `record`, `rule`, `specifier`, `text` |
| **Produces** | `boolean`, `outgoing message`, `text` |

Key objects: `message`, `outgoing message`, `mailbox`, `account`, `mail attachment`, `recipient`
Notable properties: `subject` (text), `sender` (text), `content` (rich text), `date received` (date), `file name` (file, on attachment)

### Safari

| Direction | Data Types |
|-----------|-----------|
| **Accepts** | `any`, `specifier`, `text` |
| **Produces** | `any` |

Key objects: `tab`
Notable properties: `URL` (text), `name` (text), `source` (text), `text` (text)

### Photos

| Direction | Data Types |
|-----------|-----------|
| **Accepts** | `album`, `any`, `boolean`, `file`, `folder`, `specifier`, `text`, `type` |
| **Produces** | `boolean`, `integer`, `media item`, `specifier` |

Key objects: `media item`, `album`, `folder`, `container`
Notable properties: `filename` (text), `name` (text), `description` (text), `date` (date), `height` (integer), `width` (integer), `favorite` (boolean)

### Notes

| Direction | Data Types |
|-----------|-----------|
| **Accepts** | `boolean`, `specifier` |
| **Produces** | `specifier` |

Key objects: `note`, `folder`, `account`, `attachment`
Notable properties: `name` (text), `body` (text), `plaintext` (text), `creation date` (date), `modification date` (date), `URL` (text, on attachment)

### Calendar

| Direction | Data Types |
|-----------|-----------|
| **Accepts** | `any`, `date`, `location specifier`, `record`, `specifier`, `text`, `type`, `view type` |
| **Produces** | `specifier` |

Key objects: `calendar`, `event`, `attendee`, `display alarm`, `mail alarm`, `sound alarm`
Notable properties: `summary` (text), `start date` (date), `end date` (date), `location` (text), `url` (text), `description` (text)

### Contacts

| Direction | Data Types |
|-----------|-----------|
| **Accepts** | `any`, `entry`, `location specifier`, `person`, `record`, `specifier`, `type` |
| **Produces** | `any`, `boolean`, `person`, `specifier`, `text` |

Key objects: `person`, `group`, `entry`, `email`, `phone`, `address`, `url`
Notable properties: `name` (text), `first name` (text), `last name` (text), `email` (text), `phone` (text), `vcard` (text), `home page` (text)

### Reminders

| Direction | Data Types |
|-----------|-----------|
| **Accepts** | `specifier` |
| **Produces** | `specifier` |

Key objects: `reminder`, `list`, `account`
Notable properties: `name` (text), `body` (text), `due date` (date), `completed` (boolean), `priority` (integer), `remind me date` (date)

### Messages

| Direction | Data Types |
|-----------|-----------|
| **Accepts** | `specifier` |
| **Produces** | *(none declared)* |

Key objects: `chat`, `participant`, `account`, `file transfer`
Notable properties: `name` (text), `handle` (text), `file path` (file, on file transfer)

### TextEdit

| Direction | Data Types |
|-----------|-----------|
| **Accepts** | `alias`, `any`, `boolean`, `location specifier`, `print settings`, `record`, `savo`, `specifier`, `text`, `type` |
| **Produces** | `any`, `boolean`, `document`, `integer`, `specifier` |

Key objects: `document`, `text`, `paragraph`, `word`, `character`, `attachment`
Notable properties: `name` (text), `path` (text), `font` (text), `size` (integer), `color` (color)

### Terminal

| Direction | Data Types |
|-----------|-----------|
| **Accepts** | `any`, `boolean`, `file`, `location specifier`, `print settings`, `record`, `save options`, `specifier`, `text`, `type` |
| **Produces** | `boolean`, `integer`, `specifier`, `tab` |

Key objects: `tab`, `settings set`, `window`
Notable properties: `contents` (text), `history` (text), `tty` (text), `custom title` (text), `busy` (boolean)

### System Events

| Direction | Data Types |
|-----------|-----------|
| **Accepts** | `UI element`, `action`, `actn`, `any`, `boolean`, `disk item`, `integer`, `rectangle`, `specifier`, `text` |
| **Produces** | `UI element`, `action`, `configuration`, `file`, `folder action`, `integer`, `specifier` |

Key objects: `process`, `UI element`, `window`, `disk item`, `file`, `folder`, `property list item`, `XML element`
Notable properties: `name` (text), `value` (any), `position` (list), `size` (list), `role` (text), `POSIX path` (text)

---

## 3. Chaining Compatibility Matrix

The universal bridge type is **`specifier`** — nearly every app both accepts and produces it. The practical bridge type is **`text`** — most real-world chains pass text (file paths, URLs, names) between apps.

### What Each App Produces (That Others Can Consume)

```
                  specifier  text  boolean  integer  file  person  track  media item  UI element  outgoing message  document  tab
Finder            X          .     X        X        .     .       .      .           .           .                  .         .
Music             X          X     X        X        .     .       X      .           .           .                  .         .
Mail              .          X     X        .        .     .       .      .           .           X                  .         .
Safari            *          .     .        .        .     .       .      .           .           .                  .         .
Photos            X          .     X        X        .     .       .      X           .           .                  .         .
Notes             X          .     .        .        .     .       .      .           .           .                  .         .
Calendar          X          .     .        .        .     .       .      .           .           .                  .         .
Contacts          X          X     X        .        .     X       .      .           .           .                  .         .
Reminders         X          .     .        .        .     .       .      .           .           .                  .         .
Messages          .          .     .        .        .     .       .      .           .           .                  .         .
TextEdit          X          .     X        X        .     .       .      .           .           .                  X         .
Terminal          X          .     X        X        .     .       .      .           .           .                  .         X
System Events     X          .     .        X        X     .       .      .           X           .                  .         .
```

`X` = produces this type. `*` = Safari produces `any`. `.` = does not produce.

### Direct Chain Compatibility

An app can chain **to** another app when the first app's output type matches something in the second app's accepts list. Since `specifier` is nearly universal, most apps can technically chain to most other apps. The interesting question is what **meaningful** data flows between them.

**High-compatibility chains** (shared specific types beyond `specifier`):

| From | To | Shared Type | What Flows |
|------|----|-------------|-----------|
| Finder | Music | `file` | Audio files to import |
| Finder | Mail | `file` | Files to attach |
| Finder | Photos | `file` | Images to import |
| Finder | Terminal | `file`, `text` | Paths to `cd` into |
| Finder | TextEdit | `text` | File paths, names |
| Music | Music | `track`, `playlist` | Internal chaining |
| Mail | Mail | `outgoing message`, `message` | Reply/forward chains |
| Contacts | Mail | `text` | Email addresses |
| Contacts | Messages | `text` (via properties) | Phone numbers, handles |
| System Events | Finder | `file` | Disk items to Finder items |
| Calendar | Reminders | `text`, `date` (via properties) | Event details to reminder fields |

**Low-compatibility chains** (require text extraction as bridge):

| From | To | Bridge Required |
|------|----|----------------|
| Safari | Notes | Extract `URL` property as text, set note `body` |
| Music | Messages | Extract `name`/`artist` as text, pass to `send` |
| Photos | Finder | Export to file path, then reference in Finder |
| Calendar | Mail | Extract event `summary`/`description`, compose message |
| Reminders | Calendar | Extract reminder `name`/`due date`, create event |

---

## 4. Chain Examples — Real Multi-App Workflows

### Finder to Mail: Attach Selected Files to New Message

```applescript
-- Get selected files from Finder (produces: specifier/file references)
tell application "Finder"
    set selectedFiles to selection as alias list
end tell

-- Chain to Mail (accepts: file via attachment)
tell application "Mail"
    set newMessage to make new outgoing message with properties {subject:"Files attached", visible:true}
    repeat with theFile in selectedFiles
        tell content of newMessage
            make new attachment with properties {file name:theFile} at after last paragraph
        end tell
    end repeat
    activate
end tell
```

**Data flow:** Finder `selection` (specifier) -> coerced to `alias list` -> Mail `attachment` (file)

### Safari to Notes: Save Current URL as Note

```applescript
-- Get URL from Safari (produces: text via property access)
tell application "Safari"
    set pageURL to URL of current tab of front window
    set pageTitle to name of current tab of front window
end tell

-- Chain to Notes (accepts: text via property setting)
tell application "Notes"
    tell account "iCloud"
        make new note at folder "Notes" with properties {name:pageTitle, body:"<a href=\"" & pageURL & "\">" & pageTitle & "</a>"}
    end tell
end tell
```

**Data flow:** Safari tab `URL` (text) + `name` (text) -> Notes `body` (text/HTML) + `name` (text)

### Music to Messages: Send Now Playing to a Friend

```applescript
-- Get current track info from Music (produces: text via properties)
tell application "Music"
    set trackName to name of current track
    set trackArtist to artist of current track
    set trackAlbum to album of current track
end tell

set nowPlaying to "Now playing: " & trackName & " by " & trackArtist & " (" & trackAlbum & ")"

-- Chain to Messages (accepts: specifier/text)
tell application "Messages"
    set targetChat to a reference to chat id "iMessage;-;+1234567890"
    send nowPlaying to targetChat
end tell
```

**Data flow:** Music `current track` properties (text) -> concatenated string -> Messages `send` (text to specifier)

### Calendar to Reminders: Create Reminders from Today's Events

```applescript
-- Get today's events from Calendar (produces: specifier/event objects)
tell application "Calendar"
    set todayStart to current date
    set time of todayStart to 0
    set todayEnd to todayStart + (1 * days)
    set todayEvents to {}
    repeat with cal in calendars
        set todayEvents to todayEvents & (every event of cal whose start date >= todayStart and start date < todayEnd)
    end repeat
end tell

-- Chain to Reminders (accepts: text via property setting on make)
tell application "Reminders"
    set targetList to list "Follow Up"
    repeat with evt in todayEvents
        tell application "Calendar"
            set evtName to summary of evt
            set evtDate to end date of evt
        end tell
        tell application "Reminders"
            make new reminder at end of reminders of targetList with properties {name:"Follow up: " & evtName, due date:evtDate}
        end tell
    end repeat
end tell
```

**Data flow:** Calendar `event` properties (`summary` as text, `end date` as date) -> Reminders `reminder` properties (`name` as text, `due date` as date)

### Photos to Finder: Export Selected Photos to a Folder

```applescript
-- Export from Photos (produces: files at destination)
tell application "Photos"
    set selectedItems to selection
    if selectedItems is {} then
        display dialog "No photos selected in Photos."
        return
    end if
    set exportPath to POSIX file "/Users/esaruoho/Desktop/Exported Photos"
    export selectedItems to exportPath using originals true
end tell

-- Chain to Finder (accepts: specifier/file references)
tell application "Finder"
    open folder "Exported Photos" of desktop
end tell
```

**Data flow:** Photos `selection` (media item specifier) -> `export` writes files to disk -> Finder opens the folder (file system is the bridge)

### Finder to Terminal: Open Terminal at Selected Folder

```applescript
-- Get folder path from Finder (produces: text via POSIX path coercion)
tell application "Finder"
    if (count of Finder windows) > 0 then
        set currentFolder to target of front Finder window as alias
    else
        set currentFolder to desktop as alias
    end if
    set folderPath to POSIX path of currentFolder
end tell

-- Chain to Terminal (accepts: text via do script)
tell application "Terminal"
    activate
    do script "cd " & quoted form of folderPath
end tell
```

**Data flow:** Finder `target` (specifier) -> coerced to `alias` -> `POSIX path` (text) -> Terminal `do script` (text)

---

## 5. The Broken Chains

Some apps break the data type chain entirely. These are the dead ends where Automator's patent vision fails on modern macOS.

### System Settings — No Typed Output

System Settings (formerly System Preferences) has **no AppleScript dictionary at all** on modern macOS. You cannot:
- Read the current setting value
- Get a reference to a preference pane
- Chain any output from it to another app

**Workaround:** Use `System Events` to interact with System Settings via UI scripting (`click button`, `set value of slider`), or use `defaults read`/`defaults write` via `do shell script`. Neither produces typed output that chains naturally.

### Home / HomeKit — No AppleScript Surface

The Home app has zero scripting surface. There is no sdef, no URL scheme that returns data, no way to query device state via AppleScript.

**Workaround:** Use Shortcuts as a bridge. A Shortcut can read HomeKit device state and return it. AppleScript can run shortcuts via `shortcuts run "Shortcut Name"`. This is exactly what the `homepod/homepod-climate.sh` script does — it reads HomePod temperature/humidity through a Shortcut.

### Preview — Nothing Scriptable

Preview responds to basic `open` and `quit` but has no meaningful scripting dictionary. You cannot:
- Get the current document's file path
- Read annotations or markup
- Export to a different format
- Chain any document information to another app

**Workaround:** Use `qlmanage` (Quick Look CLI) for previewing, or use Automator/Shortcuts "Quick Actions" for PDF manipulation.

### Messages — Produces Nothing

Messages can `send` but its dictionary declares **no output types at all**. You can push data into Messages but cannot pull anything back out. You cannot:
- Get the last received message text
- Read conversation history
- Chain message content to another app

**Workaround:** Access the Messages SQLite database directly at `~/Library/Messages/chat.db` via `do shell script`, though this requires Full Disk Access.

### Maps, FaceTime, App Store, News, Stocks, Weather — No Dictionary

These apps have no AppleScript dictionaries. They exist as islands in the macOS ecosystem, unreachable by the data type chain.

### Shortcuts — Partial Bridge Only

Shortcuts has a minimal AppleScript dictionary (essentially just `run`). It can execute a shortcut but cannot:
- Pass typed data in (only text input)
- Receive structured typed data back (only stdout text)
- Enumerate available shortcuts programmatically

Shortcuts is ironically both the successor to Automator's vision and a step backward in typed data interoperability.

---

## 6. How This Repo Bridges the Gap

The Automator patent envisions invisible, automatic type conversion. In practice, AppleScript workflows must manually bridge type gaps. This is exactly what `workflow-gen.py` does — it generates 209 scripts across 31 apps that handle the bridging explicitly.

### Bridge Patterns Used

**Text as universal bridge:**
Most cross-app chains extract properties as text, manipulate the string, then pass it to the target app's text-accepting commands. This is the most common pattern in the 209 generated workflows.

```applescript
-- Pattern: extract as text, pass as text
tell application "Safari" to set pageURL to URL of current tab of front window
tell application "Notes" to make new note with properties {name:"Bookmark", body:pageURL}
```

**File system as bridge:**
When apps cannot talk directly, the file system serves as an intermediary. One app writes/exports, the other reads/imports.

```applescript
-- Pattern: export to disk, import from disk
tell application "Photos" to export selection to exportFolder
tell application "Mail" to make new attachment with properties {file name:exportedFile}
```

**`do shell script` as bridge:**
Shell commands fill gaps where AppleScript cannot reach. This is used for system state, file manipulation, clipboard operations, and talking to apps with no AppleScript dictionary.

```applescript
-- Pattern: shell command produces text that feeds back into AppleScript
set cpuUsage to do shell script "top -l 1 | grep 'CPU usage' | awk '{print $3}'"
tell application "Terminal" to do script "echo Current CPU: " & cpuUsage
```

**Variables as bridge:**
AppleScript variables hold extracted data between `tell` blocks, manually doing what Automator's Data Conversion Engine does automatically.

```applescript
-- Pattern: extract into variables, use in next tell block
tell application "Calendar"
    set evtName to summary of event 1 of calendar 1
    set evtDate to start date of event 1 of calendar 1
end tell
-- evtName and evtDate bridge the gap
tell application "Reminders"
    make new reminder with properties {name:evtName, due date:evtDate}
end tell
```

### What Sal's Patent Got Right

The patent's key insight was that **the system should be smart so the user doesn't have to be**. The Data Conversion Engine, relevance filtering, and automatic bridging were designed to hide complexity.

In the AppleScript world, we do this manually. Every script in this repo that chains two apps together is implementing — by hand — what Automator's patent described as automatic. The `workflow-gen.py` recipes encode the tribal knowledge of which types bridge to which, what properties to extract, and how to coerce data between apps.

The chain is only as strong as its weakest link. And on modern macOS, those weak links — System Settings, Home, Preview, Messages output — are where the chain breaks and `do shell script` has to pick up the slack.

---

## Appendix: The Specifier Problem

Nearly every app accepts and produces `specifier` — but a Finder specifier and a Music specifier are not interchangeable. A `specifier` is a reference to an object *within a specific app's object model*. You cannot pass a Finder file specifier directly to Music and have it understand the reference.

This is why **coercion** matters:
- `as alias` — converts a Finder specifier to a file system alias (portable)
- `as text` — extracts the string representation
- `as POSIX path` — extracts the Unix file path
- `as alias list` — converts a selection to a list of portable file references

The Automator patent handled this with its Data Conversion Engine. In raw AppleScript, you handle it yourself.
