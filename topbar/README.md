# Apple Toolbox — Menu Bar Script Launcher & Live Dashboard

**Apple-native. No third-party dependencies.** A 🧰 icon in the macOS menu
bar with a dropdown of one-click scripts and live status (HomePod climate,
battery, Sal archive). Built on `NSStatusItem` + `NSMenu`, compiled with
the Swift compiler that ships with Apple's Developer Tools (`xcrun swiftc`).

Zero roundtrip: click → script runs. No daemon, no plugin format, no Homebrew.

## Install (once)

```bash
bash ~/work/apple/topbar/install.sh
```

Or use the slash: `/topbar`.

This compiles `AppleToolbox.swift` into a `.app` bundle with
`LSUIElement=true` (menu bar only, no Dock icon), ad-hoc codesigns it,
installs into `/Applications/Apple-Workflows/AppleToolbox.app`, launches it.

## What's in the toolbox

One unified status item in the menu bar:

```
🧰
```

Click for the dropdown. Refreshes every 5 minutes (and again every time
you open it via the 🔄 Refresh item).

**Live status (top — informational, disabled rows):**

| Section | Shows |
|---|---|
| 🌡 Climate | latest temp + humidity from `~/work/homepod-watcher/climate-logs/*.jsonl` |
| 🔋 Battery | % + state + time remaining (`pmset -g batt`) |
| 🗂 Sal | recovered / total + missing count (regenerates `current-status.md` on read) |

**Click-to-run actions (below):**

| Entry | What it does |
|---|---|
| 🔇 Stop Voicebox | runs `~/bin/voicebox-stop` (same as `vstop` alias) |
| 🗑 Empty Trash | tells Finder to empty trash |
| 👁 / 👀 Desktop Icons | hide / show desktop icons |
| Audio ▸ | mute / unmute / volume presets (25/50/75) |
| Finder ▸ | kill Finder, show/hide hidden files, restart menu bar |
| 🔄 Refresh | re-reads live status + rebuilds menu |
| Quit | terminate AppleToolbox |

## Adding a new entry

Edit `AppleToolbox.swift` — find the `rebuildMenu()` function. Each entry
is one line:

```swift
menu.addItem(action("🎵 Pause Music",
    cmd: "/usr/bin/osascript",
    args: ["-e", "tell app \"Music\" to pause"]))
```

For multi-command actions, drop a script into `scripts/`, `chmod +x` it,
and call it directly:

```swift
menu.addItem(action("🌑 Dark Mode", cmd: "\(TOPBAR)/scripts/dark-mode.sh"))
```

Submenus:

```swift
let root = NSMenuItem(title: "Devices", action: nil, keyEquivalent: "")
let sub = NSMenu()
sub.addItem(action("Reset Bluetooth", cmd: "/usr/bin/sudo", args: ["pkill", "bluetoothd"]))
root.submenu = sub
menu.addItem(root)
```

Save the file, then re-run `./install.sh` (it quits, rebuilds, relaunches).

## Adding a new live-status reader

Add a function like `climateRead()` / `batteryRead()` / `salRead()` and
call it from `rebuildMenu()` via `menu.addItem(header("Title", body: reader()))`.

## Files

```
topbar/
├── AppleToolbox.swift      # the entire app — NSStatusItem + NSMenu + data readers
├── build.sh                # compile + bundle into AppleToolbox.app
├── install.sh              # build, move to /Applications/Apple-Workflows/, launch
├── scripts/                # multi-line helper scripts (called by menu actions)
│   ├── hide-desktop.sh
│   ├── show-desktop.sh
│   ├── show-hidden.sh
│   └── hide-hidden.sh
└── README.md               # this file
```

## Why Apple-native (not SwiftBar via Homebrew)

The apple skill's first rule is **"Apple-Native Only — No Third-Party
Dependencies"** (see `skill.md`). SwiftBar via Homebrew violates that:
- Adds an outside daemon to maintain
- Sandboxing forces a security-scoped folder bookmark that only the Finder
  picker can grant — fragile, repeatedly broke during install
- Plugin format is a SwiftBar-specific text protocol
- Removes if Homebrew goes away

The native path uses tools Apple already ships:
- `xcrun swiftc` — Apple's Swift compiler
- `Cocoa` / `AppKit` — Apple's UI framework
- `/usr/libexec/PlistBuddy` — Apple's plist editor
- `codesign` — Apple's signing tool

The whole app is one 215-line Swift file that compiles to a 108KB binary.
This is the [Tier 5 dark — three back-door pattern](`~/.claude/projects/-Users-esaruoho-work-apple/memory/tier_5_backdoor_pattern.md`)
"framework via Swift one-liner" branch, formalized.

## The third zero-roundtrip channel

This is the third channel alongside slash commands and Loupedeck buttons:

| Channel | Strength | Best for |
|---|---|---|
| Slash (`/qr`) | keyboard, instant, scriptable | text input, batch jobs |
| Loupedeck button | physical, hands-free | DAW workflow, single verbs |
| Menu-bar app | mouse, glanceable, *live* | quick actions + status display |

Anything you currently run via slash or Loupedeck has a 3-line Swift entry
here. Pick the channel that fits the moment.
