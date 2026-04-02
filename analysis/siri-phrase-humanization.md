# Siri Phrase Humanization — Sal's 251 vs Our 1,254

## The Core Problem

Sal hand-crafted 251 dictation commands that sound like things humans actually say.
We auto-generated 1,254 Siri phrases from script filenames. They sound like menu items.

| What Sal wrote | What we generate |
|---|---|
| "show the calendar for today" | "Show Today" |
| "open the applications folder" | "New Window Desktop" |
| "make a new presentation" | "New Presentation" |
| "hide the other applications" | "Hideallothers" |
| "empty the trash" | "Empty Trash" |
| "mute the computer audio" | "Mute Toggle" |
| "what is on this slide" | "Current Slide" |
| "tell me about this image" | "File Info" |
| "play this from the beginning" | "Play Frontmost" |
| "AirDrop these files" | "Airdrop Reveal" |
| "make a new audio recording" | "New Audio Recording" |
| "rate 5 stars" | "Rating 5 Stars" |
| "assist me with presenter notes" | "Presenter Notes" |
| "export these presenter notes to Mail" | "Export Pdf" |
| "close all windows but this one" | "Close All Windows" |

## 8 Patterns Sal Uses That We Don't

### 1. Articles and Possessives
Sal: `open [the] documents folder`, `mute [the] computer audio`, `show [my] applications`
Ours: "Empty Trash", "Copy Path", "New Folder"

**Rule**: Insert "the" before nouns, "a/an" before creation. "my" for user folders.

### 2. Optional Words (Flexibility)
Sal: `make [a] [new] [mail] message` — works whether you say "make message", "make a message", "make a new mail message"

**Rule**: The phrase should be the LONGEST natural form. Siri's fuzzy matching handles abbreviation.

### 3. Conversational Verbs
Sal uses everyday verbs; we use programmer verbs:

| Sal says | We say | Why Sal's is better |
|---|---|---|
| "make" | "create" | People say "make a folder", not "create a folder" |
| "show" / "show me" | "list" / "get" | "Show me my playlists" vs "List Playlists" |
| "tell me about" | "info" / "detail" | Natural question form |
| "get rid of" | "delete" / "clear" | How people actually phrase deletion |
| "turn on/off" | "toggle" | Nobody says "toggle dark mode" out loud |
| "put" | "move" / "set" | "Put that in a new mail message" |
| "what is" | "get" | "What is the volume?" vs "Volume Set" |
| "how many" | "count" | "How many photos?" vs "Count Photos" |
| "begin" / "start" | "new" / "start" | "Begin a screen recording" vs "New Screen Recording" |

### 4. Deictic Context — "this", "these", "that"
Sal: `AirDrop (this|these) (file|folder|item|files|folders|items)`
Sal: `reply to this message`, `read this slide`, `export these to disk`
Ours: Never references what the user is looking at.

**Rule**: When a command acts on current selection, say "this/these". When it acts on clipboard, say "that".

### 5. Question Forms
Sal: `what is on this slide`, `what slide is this`, `how many items are selected`, `what is the computer volume`
Ours: Never asks questions. Everything is imperative.

**Rule**: Query commands should be phrased as questions — "what is..." / "how many..."

### 6. Prepositions and Flow Words
Sal: `save this presentation to my thumb drive and eject it`
Sal: `export this table to Keynote as a chart`
Sal: `move these into the documents folder`
Ours: "Export Pdf", "Move To Trash", "Save As Txt"

**Rule**: Include "to", "from", "into", "as", "for", "in" — they're the joints of natural speech.

### 7. No App Name in the Phrase
Sal's commands are spoken WHILE using an app — context is implicit.
`make a new presentation` not `Keynote New Presentation`
`reply to this message` not `Mail Reply To Selected`

Our current code strips the app prefix, which is correct. But residue remains:
- "Events Convert Format" (Image Events prefix leaked)
- "Machine Latest Backup" (Time Machine prefix leaked)
- "Editor Compile" (Script Editor prefix leaked)
- "Settings Battery" (System Settings prefix leaked)
- "Utility Disk Info" (Disk Utility prefix leaked)
- "Information Hardware" (System Information prefix leaked)

**Rule**: The phrase should make sense without ANY app name.

### 8. Compound Actions / Chaining
Sal: `save this presentation to my thumb drive and eject it`
Sal: `export these presenter notes to Pages`
Sal: `put clipboard into a new Pages document`
Ours: One verb, one noun. No chaining.

**Rule**: Where a script does multiple things, the phrase should describe the outcome, not just the first step.

## Concrete Rewrites

### Worst offenders (must fix)

| Current | Humanized | Pattern applied |
|---|---|---|
| "Hideallothers" | "hide the other apps" | articles, spaces, conversational |
| "Mosaicwindows" | "tile all windows" | conversational verb |
| "Whiteboardbrowse" | "browse whiteboards" | verb + noun |
| "Playpause" | "play pause" or "pause the music" | split compound, article |
| "Mute Toggle" | "mute the sound" or "unmute" | conversational, no "toggle" |
| "Rating 0 Stars" | "remove the rating" | conversational |
| "Rating 5 Stars" | "rate five stars" | verb not noun |
| "Events Convert Format" | "convert image format" | drop app prefix residue |
| "Machine Latest Backup" | "when was the last backup" | question form |
| "Machine Start Backup" | "start a backup" | article |
| "Editor Compile" | "compile this script" | deictic + drop prefix |
| "Settings Battery" | "open battery settings" | verb + noun |
| "Utility Disk Info" | "show disk info" | verb + drop prefix |
| "Information Hardware" | "show hardware info" | verb + drop prefix |
| "Char Count" | "how many characters" | question form |
| "Word Count" | "how many words" | question form |
| "Tab Count" | "how many tabs are open" | question form |
| "Unread Count" | "how many unread emails" | question form |
| "Ip Address" | "what is my IP address" | question + possessive |
| "Uptime" | "how long has the computer been on" | question form |
| "Trash Size" | "how big is the trash" | question form |
| "Now Playing" | "what's playing" | question form |
| "Current Url" | "what's the URL" | question form |
| "Battery Status" | "what's the battery at" | question form |
| "Disk Usage" | "how much disk space is left" | question form |
| "Memory Pressure" | "how's the memory" | question form |
| "Cpu Info" | "how's the CPU doing" | question form |
| "List Running Apps" | "what apps are running" | question form |
| "Get Frontmost App" | "what app is this" | question form |
| "Spotlight Status" | "is Spotlight working" | question form |
| "Bluetooth Devices" | "what Bluetooth devices are connected" | question form |
| "Audio Devices" | "what audio devices are available" | question form |
| "Usb Devices" | "what USB devices are connected" | question form |
| "Do Javascript" | "run JavaScript on this page" | deictic, specific |
| "Ssh Connect" | "connect to a server" | conversational |
| "New From Clipboard" | "make a new document from the clipboard" | Sal-style full sentence |
| "Send Quick" | "send a quick email" | article + noun |
| "Compose To" | "compose an email to someone" | full phrase |
| "Flag Selected" | "flag this email" | deictic |
| "Archive Selected" | "archive this email" | deictic |

### Already good (keep as-is or minor tweaks)

| Current | Verdict |
|---|---|
| "Empty Trash" | Good. Could add "the" → "empty the trash" |
| "New Folder" | Good. Could add "make a" → "make a new folder" |
| "Copy Path" | Good for power users |
| "Toggle Dark Mode" | Works, though "turn on/off dark mode" is more Sal |
| "Check Mail" | Good. Natural. |
| "Next Track" | Good. Universal. |
| "Search Notes" | Good. Direct. |

## Implementation Plan

### Phase 1: Rewrite Table
Build a `PHRASE_OVERRIDES` dict in `shortcut-gen.py` — maps script stems to human phrases. This is the Sal approach: hand-craft the phrases that matter, because naming IS the interface.

### Phase 2: Pattern Rules
For scripts without overrides, apply automatic transformations:
1. Split camelCase/compounds: "Playpause" → "Play Pause"
2. Add articles: "New X" → "make a new X", "Start X" → "start a X"
3. Convert counts to questions: "X Count" / "Count X" → "how many X"
4. Convert status to questions: "X Status" / "X Info" → "what's the X"
5. Add "the" before common nouns: trash, music, sound, volume
6. Strip leaked prefixes: Events, Machine, Editor, Settings, Utility, Information
7. "Toggle X" → "turn X on" (or just both as alternatives)

### Phase 3: Alternatives
Sal's `(this|these)` and `[optional]` patterns can't map 1:1 to Siri phrases (Siri expects one phrase per shortcut). But we can:
- Pick the most natural full form as the primary phrase
- Document alternatives in scripts.md for discoverability
- Consider generating multiple shortcuts for the same script with different trigger phrases

## The Deeper Insight

Sal's 251 commands prove that **naming is user interface design**. The command name isn't a label — it's the entire interaction. There's no button, no menu, no icon. The phrase IS the affordance.

Our auto-generation treats naming as a bookkeeping problem (derive from filename). Sal treated it as a design problem (what would a human say to accomplish this?).

The fix isn't just better string manipulation. It's asking, for each of our 288 workflows: **"What would someone say out loud to make this happen?"** — and writing that down.
