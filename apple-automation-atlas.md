# Apple Automation Atlas

> "The power of the computer should reside in the hands of the one using it." — Sal Soghoian

This is the complete map of every Apple app's automation capabilities — AppleScript dictionaries, CLI tools, Automator actions, and Terminal integration. Pearls on a chain.

---

## The Automation Stack

Sal built these layers to work together. They're not separate tools — they're one system:

| Layer | Tool | Purpose |
|-------|------|---------|
| **GUI** | Automator | Visual workflow builder — drag actions, no code |
| **Scripting** | AppleScript | English-like language for controlling apps |
| **Scripting** | JavaScript for Automation (JXA) | JS alternative to AppleScript |
| **Bridge** | System Events | UI automation, keystrokes, menu clicks, process control |
| **Bridge** | Image Events | Image processing without opening an app |
| **CLI** | `osascript` | Run AppleScript/JXA from Terminal |
| **CLI** | `automator` | Run Automator workflows from Terminal |
| **CLI** | `shortcuts` | Run Shortcuts from Terminal |
| **CLI** | `sdef` | Extract scripting dictionary from any app |
| **CLI** | `osacompile` | Compile AppleScript to .scpt binary |
| **CLI** | `osadecompile` | Decompile .scpt back to text |
| **Editor** | Script Editor | Apple's built-in AppleScript IDE |
| **Modern** | Shortcuts | Successor to Automator, cross-platform (macOS/iOS) |

---

## Apple Apps — Full Scriptability Map

### Tier 1: Fully Scriptable (Rich AppleScript Dictionary)

These apps have deep scripting dictionaries. You can control almost everything.

| App | Location | Scripting | Key Automation Powers |
|-----|----------|-----------|----------------------|
| **Finder** | CoreServices | AppleScript | File/folder operations, window management, metadata, tags, Spotlight |
| **Mail** | System Apps | AppleScript | Create/send messages, manage mailboxes, rules, attachments |
| **Safari** | /Applications | AppleScript | Tabs, windows, URLs, page content, JavaScript execution |
| **Music** | System Apps | AppleScript | Playlists, tracks, playback, library management |
| **Photos** | System Apps | AppleScript | Albums, media items, export, metadata |
| **Notes** | System Apps | AppleScript | Create/read/modify notes, folders, attachments |
| **Reminders** | System Apps | AppleScript | Lists, reminders, due dates, completion |
| **Calendar** | System Apps | AppleScript | Events, calendars, attendees, recurrence |
| **Contacts** | System Apps | AppleScript | People, groups, addresses, phone numbers |
| **Messages** | System Apps | AppleScript | Send messages, read conversations, manage chats |
| **TV** | System Apps | AppleScript | Library, playlists, playback |
| **TextEdit** | System Apps | AppleScript | Documents, text manipulation, formatting |
| **Preview** | System Apps | AppleScript | Documents, windows (limited but useful) |
| **QuickTime Player** | System Apps | AppleScript | Recording, playback, export |
| **Keynote** | /Applications | AppleScript | Slides, builds, animations, themes, export |
| **Numbers** | /Applications | AppleScript | Sheets, tables, cells, formulas, charts |
| **Pages** | /Applications | AppleScript | Documents, text, images, sections, export |
| **Final Cut Pro** | /Applications | AppleScript | Projects, timelines, export |
| **Logic Pro** | /Applications | AppleScript | Projects, tracks, regions, MIDI |
| **iMovie** | /Applications | AppleScript | Projects, clips, export |
| **Automator** | System Apps | AppleScript | Workflows, actions |
| **Shortcuts** | System Apps | AppleScript | Run shortcuts, list shortcuts |

### Tier 2: Scriptable Utilities

| App | Location | Key Automation Powers |
|-----|----------|----------------------|
| **Terminal** | Utilities | Execute commands, manage tabs/windows, run scripts |
| **Script Editor** | Utilities | Compile, run, edit scripts programmatically |
| **Console** | Utilities | Log access, filtering |
| **System Information** | Utilities | Hardware/software info queries |
| **Screen Sharing** | Utilities | Remote connections |
| **Bluetooth File Exchange** | Utilities | File transfer |

### Tier 3: Hidden Powerhouses (CoreServices)

These aren't in /Applications but are the backbone of Apple automation:

| App | Purpose | Key Powers |
|-----|---------|------------|
| **System Events** | The master controller | UI element access, keystrokes, menu clicks, process management, property list files, XML, disk info, login items, screen savers, network prefs |
| **Image Events** | Headless image processing | Resize, rotate, crop, flip, pad, scale — all without opening any app |
| **Finder** | File system | Everything file/folder related, plus desktop, trash, windows |

### Tier 4: Activate-Only (No Scripting Dictionary)

These can be launched/activated but not deeply controlled via AppleScript. **System Events UI scripting** can still automate their interfaces.

| App | Can Launch | Can UI-Script via System Events |
|-----|-----------|--------------------------------|
| Maps | Yes | Yes — click buttons, menus, enter text |
| Books | Yes | Yes |
| News | Yes | Yes |
| Stocks | Yes | Yes |
| Weather | Yes | Yes |
| Podcasts | Yes | Yes |
| FaceTime | Yes | Yes |
| Home | Yes | Yes |
| Freeform | Yes | Yes |
| App Store | Yes | Yes |
| Font Book | Yes | Yes |
| Calculator | Yes | Yes |
| Chess | Yes | Yes |
| Clock | Yes | Yes |
| Stickies | Yes | Yes |
| Dictionary | Yes | Yes |
| Image Capture | Yes | Yes |
| Photo Booth | Yes | Yes |
| Voice Memos | Yes | Yes |
| Activity Monitor | Yes | Yes |
| Audio MIDI Setup | Yes | Yes |
| Disk Utility | Yes | Yes |
| System Settings | Partial | Yes |

---

## CLI Tools — The Terminal Side

### Core Automation Commands

```bash
# Run AppleScript from Terminal
osascript script.applescript
osascript -e 'tell application "Finder" to activate'

# Run JXA from Terminal
osascript -l JavaScript script.js
osascript -l JavaScript -e 'Application("Finder").activate()'

# Run Automator workflow from Terminal
automator workflow.workflow

# Run Shortcut from Terminal
shortcuts run "Shortcut Name"
shortcuts list  # see all available shortcuts

# Extract scripting dictionary (see what an app can do)
sdef /Applications/Safari.app
sdef /System/Library/CoreServices/Finder.app

# Compile AppleScript to binary
osacompile -o script.scpt script.applescript

# Decompile binary back to text
osadecompile script.scpt
```

### macOS System Commands (Apple-native)

| Command | Purpose | Automation Value |
|---------|---------|-----------------|
| `open` | Open files/folders/URLs/apps | `open .` opens Finder here, `open -a AppName` launches app |
| `pbcopy` / `pbpaste` | Clipboard | Pipe data to/from clipboard |
| `say` | Text-to-speech | `say "Hello"` — voice output from scripts |
| `screencapture` | Screenshots | `-c` clipboard, `-T` delay, `-R` region |
| `defaults` | Read/write preferences | `defaults read com.apple.dock` — deep system config |
| `mdls` | Spotlight metadata | File metadata queries |
| `mdfind` | Spotlight search | `mdfind "kMDItemFSName == '*.pdf'"` |
| `afplay` | Play audio | `afplay sound.aiff` — play audio from CLI |
| `afconvert` | Convert audio | Audio format conversion |
| `sips` | Image processing | Resize, rotate, convert images from CLI |
| `qlmanage` | Quick Look | Preview files from CLI |
| `diskutil` | Disk management | Mount, unmount, partition |
| `networksetup` | Network config | Wi-Fi, DNS, proxy settings |
| `pmset` | Power management | Sleep, wake, display sleep settings |
| `caffeinate` | Prevent sleep | `caffeinate -t 3600` — keep awake for 1 hour |
| `textutil` | Text conversion | Convert between txt, rtf, html, docx, etc. |
| `plutil` | Property list | Read/write plist files |
| `ditto` | Smart copy | Preserves metadata, resource forks |
| `hdiutil` | Disk images | Create, mount, convert DMGs |
| `spctl` | Gatekeeper | Security assessment |
| `codesign` | Code signing | Verify/sign apps |
| `xattr` | Extended attributes | Manage file attributes, quarantine flags |
| `log` | System logs | `log show --predicate 'process == "Safari"'` |

---

## The Sal Connection

Every layer connects:

1. **AppleScript** tells apps what to do → generates data
2. **System Events** bridges gaps where apps lack dictionaries → UI automation
3. **Image Events** processes images without GUI → headless power
4. **Automator** chains actions visually → Sal's patent (US 7,428,535) handles the filtering
5. **Shortcuts** brings it to iOS → Sal's vision reaching mobile
6. **Terminal** (`osascript`, `automator`, `shortcuts`) → runs everything from CLI
7. **Loupedeck Live** triggers Terminal commands → physical buttons for automation

This is the chain. Every pearl connects to the next.
