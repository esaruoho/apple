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
| 💾 Disk | free / total on the boot volume |
| 📶 Wi-Fi | SSID + signal strength |
| 📧 Mail | unread count |
| 🎵 Now Playing | current track from Music / Spotify |
| 🗂 Sal | recovered / total + missing count (regenerates `current-status.md` on read) |
| 🎙 Whisp | queue depth on the Mac Mini transcription worker |

**Click-to-run actions (below):**

| Entry | What it does |
|---|---|
| 🔇 Stop Voicebox | runs `~/bin/voicebox-stop` |
| 🔊 Read Clipboard / ⏹ Stop Reading | Kokoro TTS of macOS clipboard via Voicebox |
| 🗑 Empty Trash | tells Finder to empty trash |
| 👁 / 👀 Desktop Icons | hide / show desktop icons |
| 🙈 Hide All Other Apps | classic macOS "hide all others" via System Events |
| **🪟 Snap Windows ▸** | Side-by-side / Top-Bottom / Thirds / Mosaic / **Dock Snap (every running app, auto-grid)** / **📐 Snap App ▸** (lists every running app — click one to tile *that* app's windows into a grid via `bin/dock snap <appname>`) |
| System ▸ | Toggle Dark / Light Mode, Lock Screen, Sleep, Screenshot ▸ (full / selection / window / front window), Restart Menu Bar, Grant All Permissions… |
| Audio ▸ | mute / unmute / volume presets (25/50/75) |
| Finder ▸ | Send Selection to Media Editor, Conversations for this Folder, Rebuild Conversation Index, Kill Finder, show / hide hidden files |
| 🏷 Tags ▸ | Tag Finder selection (prompt, trinity-link, list, clear), one-click color tags, Find Files by Tag, Open Tag Smart Folder, Send Selection to OCR (Mac Mini), Run Tag Watcher Now, Retry OCR-failed, Smart Folders ▸, Pin All Smart Folders to Dock |
| Slashes ▸ | Hey Sal…, Grand Search…, QR…, Wi-Fi QR…, Webcam Photo, Apple Report, Grand Export (--quick) |
| 🔄 Refresh | re-reads live status + rebuilds menu |
| Quit | terminate AppleToolbox |

The **Snap App** submenu is rebuilt every time the menu opens (via
`NSWorkspace.shared.runningApplications` filtered to `.regular`
activation policy) so newly-launched apps appear automatically.

## Global keyboard shortcuts

Registered via Carbon `RegisterEventHotKey`. Apple-shipped API, no
Homebrew, no Input Monitoring permission needed. Works regardless of
the frontmost app — Services-menu shortcuts go through the foreground
app's Services dispatcher and get swallowed by anything that binds the
same combination internally; Carbon hotkeys don't.

**Two registration sites** depending on whether the handler needs the
`--live` panel:

- `AppDelegate.registerMenuBarHotKeys()` — owns keyboard shortcuts that work whenever
  🧰 is in the menu bar. UI-independent handlers go here.
- `LiveViewportDelegate.registerGlobalHotKey()` — owns keyboard shortcuts whose
  handler manipulates the `--live` panel UI. Currently just ⌃⌥⌘D.

| Keys | Action | Owner | Why this combination |
|---|---|---|---|
| ⌃⌥⌘D | Toggle smart dictation | `--live` panel | Triple-modifier + D, no system collision. Needs `/topbar-live` running. |
| ⌃⌥⌘. | Stop Voicebox (`~/bin/voicebox-stop`) | menu-bar (always on) | ⌘. alone is AppKit's universal Cancel; ⇧⌥⌘. is eaten by iTerm2's View menu; ⌃⌥⌘. fires cleanly |
| ⌃⌥⌘T | Open Finder's selection in AppleToolbox browser | menu-bar (always on) | ⌥T / ⌃⌥T got eaten by Finder type-ahead and Rectangle; adding ⌘ clears both |
| ⌃⌥⌘S | Toggle: tile all ↔ un-tile all (SnapEngine / AXUIElement) | menu-bar (always on) | Focused window full → press tiles every window into a grid (overview). Focused window tiled/partial → press maximizes *every* window back to full width + height (stacked, ready to Cmd-` between them). Stateless. See "SnapEngine" below. Needs Accessibility permission for `com.esaruoho.appletoolbox`. |

Adding more: pick the right registration site (UI-independent → AppDelegate;
panel UI → LiveViewportDelegate), extend the `switch hkID.id`, register a
new `EventHotKeyID` with the next free id, point it at a new method.
FourCharCode signatures used so far: `ATBD` (dictate), `ATBS` (stop),
`ATBG` (goto Finder), `ATBN` (snap). Full pattern in
`wiki/concepts/global-keyboard-shortcuts.md`.

### SnapEngine — in-process window tiler + toggle

The ⌃⌥⌘S keyboard shortcut does NOT call `bin/snap`. Instead, AppleToolbox
includes `SnapEngine` (Swift enum near the bottom of `AppleToolbox.swift`)
which talks directly to **AXUIElement** — Apple's Accessibility API — to
move and resize the frontmost app's windows in-process.

**Toggle behavior:** on each press, `SnapEngine` reads the current frame
of the **focused window** (the one with keyboard focus; falls back to the
app's main window, then to any window) to decide the direction of the
toggle. The action then applies to **every** window of that app:

- Focused window matches the screen's visibleFrame within ±30 px → tile
  all into a grid (overview)
- Otherwise → un-tile: every window gets resized to fill the visibleFrame,
  so they all stack at full width + height (use Cmd-` to flip between
  them)

Typical workflow:

- Working in one big maximized window → press 1: tiles every window into
  a grid; you can see them all at once
- Press 2: un-tile — every window jumps back to full width + height,
  stacked, focused one on top
- Press 3: tile again; overview returns

The toggle is **stateless** — no flag is stored, no per-app history is
tracked. The decision is made from current AX geometry each time, so the
behavior survives manual drag, app restart, or any external resize
between presses.

Why it's faster than the CLI:

| Layer | `bin/snap` path | `SnapEngine` path |
|---|---|---|
| Process spawn | `Process()` → `bin/snap` (~10ms) | none — same process |
| osascript JIT | ~250-400ms per pass | none |
| Per-window mutation | System Events Apple Event RPC | AXUIElement direct RPC |
| Convergence loop | 2-3 passes × snapshot + Python compare + 0.25s sleep | none — AX is synchronous |
| Total for 9 windows | ~5s | ~0.4s |

Same grid math (`rowLayout(n)` ported line-for-line from
`DockSnap.applescript`), same target frame (`NSScreen.main.visibleFrame`,
which already has menubar + Dock subtracted).

Requires Accessibility permission for AppleToolbox.app — already granted
via `/grant-perms`. If AX writes fail silently, check
**System Settings → Privacy & Security → Accessibility** and confirm
AppleToolbox is enabled.

The `bin/snap` CLI remains the way to tile from the terminal, slash
commands, and the menu — it doesn't share AppleToolbox's permission
context. Both routes converge on the same grid layout.

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
