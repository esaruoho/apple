# WWDC 2003 #623 — AppleScript for SysAdmins

**Speaker:** Sal Soghoian (solo, 1:14:11) · Track: Enterprise IT · **Unlisted on apple.com — Whisper transcript is the only surviving record**
**nonstrict:** https://nonstrict.eu/wwdcindex/wwdc2003/623/

**The densest single dose of pure Sal in the entire archive.** No co-presenter. This is Sal teaching what experienced AppleScripters know but never write down.

## The hooks

> *"AppleScript is the cocaine of programming. One line, and you'll be ours forever. So you have been warned, resist as much as you can."*

> *"AppleScript is a peer to Aqua. Aqua is the graphic user interface to the OS, and AppleScript is the language user interface to the OS. There's also another language interface that's really low level, which is the Unix interface."*

WWSD #31 (peer to Aqua) comes from this exact sentence.

## The vision sentence (operational, different from 401's biographical version)

> *"Duplicate every file of the startup disk whose name contains Smith Project to the folder named Backup. That's actually a script. It's not just a concept. You take the mind, you rethink the thought, and you write it, and it should work. Most of the time."*

## What Sal teaches — the syllabus

### 1. Five reference types and the coercion matrix

| Type | Form | Generatable by script? |
|------|------|------------------------|
| Nested reference | `folder documents of folder sal of folder users of startup disk` | No (returned by apps) |
| Path reference | `file "Macintosh HD:Users:sal:Documents:cars.pdf"` | Yes (string concat) |
| Alias reference | `alias "Macintosh HD:Users:sal:Documents:"` | Live, tracks moves |
| POSIX | `/Users/sal/Documents/cars.pdf` | Most apps don't accept |
| File URL | `file://localhost/Users/sal/Documents/` | Rare but useful |

Coercion paths:
- Nested → alias: `... as alias`
- Path → alias: `(file "Macintosh HD:Applications") as alias`
- POSIX → alias: `(POSIX file "/Users/sal/Documents") as alias`
- Alias → POSIX: `POSIX path of <alias>`
- Alias → quoted POSIX: `quoted form of POSIX path of <alias>` (shell-safe, auto-escapes apostrophes)

Sal: *"If you didn't know that, life is horrible. If you do know that, you're in the air conditioning."*

### 2. Finding items — index, descriptive, relative, property

**By index:**
- `item 1 of home`, `item 12 of home`
- **Negative index:** `item -1 of home` (last), `item -2` (second-to-last)
- Range: `items 2 thru 5 of startup disk`, `items 1 thru -1` (== `every item`)

**Descriptive (conversational):**
- `first item`, `second item`, `22nd item`, `last item`, `middle item`

**Relative position:**
- `front` / `first` / `back` / `last` / `middle`
- `item before the last item`
- `some item of startup disk` — picks at random

**By property:**
```applescript
the first document file of home whose name contains "Smith Project"
the first folder whose size is greater than 500000
every document file whose file type is "JPEG"
every document file whose name extension is "pdf"
```

Comparison operators: `contains`, `does not contain`, `is in`, `begins with`, `ends with`, `is greater than`, `is less than`, `≥`, `≤`, `isn't`, `is not`.

### 3. Recursion via `entire contents` — civilized recursion

> *"How do you get down through a directory? Well, you go to JavaScript and you write 'for if and and', and then you start doing a recursive loop. No, we don't do that in AppleScript. We're civilized. We're bohemian but civilized."*

```applescript
every document file of the entire contents of folder documents of home ¬
    whose name contains "Smith Project"
```

Finder/System Events walks the tree for you. You write the query, AppleScript writes the loop.

**WWSD #37 codified.**

### 4. The "cleaning and waxing" principle

After running `tell app Finder to get every item of home whose name contains "si"` and then `reveal` on the result:

> *"What we have here is cleaning and waxing in one motion. In one motion I find the stuff, the other one I actually do something with it. In one line of AppleScript, we are able to clean and wax together."*

**Find + act in one line. WWSD #36.**

### 5. Script Editor tour

- Top pane = script
- Bottom pane = description / result / event log (three tabs)
- Description pane is shippable — checkbox at save time → users see this popup when running the script
- Event log shows every command sent + every result returned — debugger by default
- Result pane shows last action's return value

### 6. Open Dictionary

> *"Applications that are scriptable have scriptable objects. You can examine the entire structure by asking for its dictionary."*

`File → Open Dictionary → <app>`. Standard Suite = common verbs. App-specific suite = the app's unique classes + verbs.

Sal walks through QuickTime Player's dictionary live: app properties, Movie class properties, Track class.

### 7. Where AppleScript lives

`/Applications/AppleScript/` — Script Editor, Script Menu installer, Folder Actions Setup. *"This is AppleScript's home turf."*

## The "free, free, free" passage

> *"All of this is free, by the way. Did I say free? I meant to say free. Did I say free? Free, free, free. You don't have to pay for AppleScript. You don't have to pay for this incredible ability. It's part of every computer that Apple Computer sells."*

Three "frees" in a row. The economic-floor point — **the price of automation on Mac is zero** — is WWSD-grade.

## Why it matters

This is the **teaching session** of the WWDC archive. Every AppleScript reference card you've seen in the last 20 years has been a rewrite of slides Sal taught here. The five-reference-types matrix, the index/property/whose grammar, the `entire contents` recursion idiom — all canonical from this session.
