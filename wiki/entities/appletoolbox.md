# AppleToolbox — Apple Automation Workflow Toolbox (rayOS-style launcher)

**Single source of truth:** `topbar/AppleToolbox.swift`. One Swift file,
~700 lines, no third-party dependencies. Built with `xcrun swiftc`,
bundled as `AppleToolbox.app` (LSUIElement=true → no Dock icon),
ad-hoc codesigned, optionally auto-launched via `topbar/launchagent.plist`.

**Conceptual frame.** AppleToolbox is to the Mac what rayOS is to the
browser: a single always-present surface that (a) reads live state from
every probed Apple subsystem, and (b) launches any verb of the right
pedigree. The pedigree filter is the **Apple-Native Only** rule lower
in this skill — every reader and every action chain ends in Apple-shipped
binaries (`osascript`, `pmset`, `sqlite3`, `networksetup`, `sips`,
`shortcuts`, `open`, `defaults`, etc.) or one of the repo's own
`bin/<tool>` scripts. No Homebrew, no daemons, no plugin formats.

### Two modes, one binary

| Mode | Invocation | UI | Use it for |
|------|-----------|----|------------|
| **Menu-bar** (default) | `AppleToolbox` | 🧰 in the system menu bar with `NSMenu` dropdown | Always-on glanceable launcher |
| **Live panel** | `AppleToolbox --live` | Floating always-on-top `KeyablePanel` listing status rows | Keyboard-driven cockpit + hot-reload dev loop |

Both modes share the same readers and the same action selectors. The
menu-bar mode rebuilds the whole `NSMenu` every 5 min; the live panel
rebuilds the row stack every 5 sec **and** stat-polls
`AppleToolbox.swift` every 1 sec — edit the Swift source, save, the
panel runs `build.sh` and `execv`'s itself in place within 1–2 sec.

### File layout

```
topbar/
├── AppleToolbox.swift         ← THE file. Readers + delegates + menu.
├── build.sh                   ← xcrun swiftc + PlistBuddy + codesign
├── install.sh                 ← copies .app into ~/Applications/AppleToolbox/Apple-Workflows + LaunchAgent
├── launchagent.plist          ← com.esaruoho.appletoolbox  (login + KeepAlive)
├── AppleToolbox.app/          ← built artifact (gitignored)
└── scripts/
    ├── hide-desktop.sh        ← shellable verbs the menu calls via `cmd:`/`args:`
    ├── show-desktop.sh
    ├── hide-hidden.sh
    ├── show-hidden.sh
    └── live.sh                ← convenience launcher for --live mode
```

### Anatomy of `AppleToolbox.swift`

Three layers, top-down in the file:

1. **Shell helpers** — `run()` (capture stdout with timeout), `runDetached()`
   (fire-and-forget), `openFile()`, `notify()`. All process spawning goes
   through these — never `Process()` inline.
2. **Live status readers** — pure functions returning `String` or `String?`:
   `climateRead`, `batteryRead`, `diskRead`, `wifiRead`, `mailUnreadRead`,
   `nowPlayingRead`, `whispQueueRead`. Each is a thin wrapper around one
   Apple-shipped command and some parsing. A reader returning `nil` or `"—"`
   makes its row vanish from both UIs — no clutter.
3. **Delegates**:
   - `AppDelegate` (menu-bar) — builds the `NSMenu` in `rebuildMenu()`.
   - `LiveViewportDelegate` (panel) — `KeyablePanel` (NSPanel subclass
     overriding `canBecomeKey`/`canBecomeMain`), `NSStackView` of
     `LiveRowButton`s inside a `FlippedView`, an `NSEvent.addLocalMonitorForEvents`
     handling ↑/↓/⏎, an `applyHighlight()` painter for the selected row,
     and a `checkSource()` source-watcher driving `execv`-self hot reload.

### The four action verbs

Every menu entry is built by one of these helpers on `AppDelegate`:

| Helper | Use it when | Example |
|--------|-------------|---------|
| `action(title, cmd:, args:)` | Verb maps 1:1 to a shell command | `action("🔇 Mute", cmd: "/usr/bin/osascript", args: ["-e", "set volume with output muted"])` |
| `promptAction(title, message:, cmd:, argsPrefix:, argsSuffix:, toast:)` | Verb needs one text input from the user (NSAlert with NSTextField) | `promptAction("🔍 Grand Search…", message: "Search:", cmd: "\(APPLE_DIR)/bin/apple-grand-search")` |
| `customAction(title, selector:)` | Verb needs Swift glue (timestamped output path, multi-step prompt, file open after run) | `customAction("📷 QR…", selector: #selector(runQR(_:)))` |
| `statusRow(title, body:, open:, args:)` | Clickable label row that doubles as a status display | Used by `addIf()` inside `rebuildMenu()` and `add()` inside `renderStatus()` |

### Submenu structure (canonical groupings)

The menu mirrors how a user thinks about their Mac, not how Apple
ships frameworks. Current shape — keep additions in the matching group:

- **Live status** (top, no header) — readers; each row is a `statusRow`
  that opens the relevant pane/app/file when clicked.
- **Quick actions** — most-pressed verbs at one click depth: Stop
  Voicebox, Empty Trash, Hide/Show Desktop Icons, Hide-Other-Apps.
- **System ▸** — Dark mode toggle, Lock, Sleep, Screenshot ▸ (full /
  selection / window), Snap Windows ▸ (tile-side-by-side / tile-top-bottom / tile-thirds /
  Mosaic), Restart Menu Bar.
- **Audio ▸** — Mute / Unmute / Volume 25 / 50 / 75.
- **Finder ▸** — Kill, Show/Hide Hidden Files.
- **Slashes ▸** — every `apple/bin/` verb that takes 0–1 text inputs
  (Hey Sal, Grand Search, QR, Wi-Fi QR, Webcam Photo, Apple Report,
  Grand Export). This is how a `bin/` script earns mouse-reachability.
- **Refresh / Quit** at the bottom.

### Keyboard navigation contract (`--live` only)

- ↑ / ↓ move `selectedIndex` within `rowButtons` (clamped).
- ⏎ / keypad-Enter invokes the selected row's command via `runDetached`.
- Selection is preserved across the 5-sec re-render; row-vanishing
  clamps the index.
- Highlight: `selectedContentBackgroundColor` at 40 % alpha, 4 px
  corner radius, applied via `wantsLayer`.

Adding a new key binding lives in `LiveViewportDelegate.handleKey(_:)`
— switch on `event.keyCode` (35 = `p`, 12 = `q`, etc.) and return `nil`
to consume the event.

### Recipes — "if the user asks for X, do Y"

| User says… | What to do | Files to touch |
|------------|-----------|---------------|
| "Add a status row for FOO" | Write `fooRead() -> String?` in the readers section. Add one `addIf(...)` line in `rebuildMenu()` AND one `add(...)` line in `renderStatus()` — same emoji-prefixed title in both so the menu and panel stay aligned. | `topbar/AppleToolbox.swift` |
| "Add a one-click action" | Pick the matching submenu (System / Audio / Finder / Slashes / Quick actions). Add `action(...)` or, if it needs input, `promptAction(...)`. | `topbar/AppleToolbox.swift` |
| "Add a verb that needs multi-step Swift glue" | Add `@objc func runFoo(_:)` near `runQR`. Wire it via `customAction("…", selector: #selector(runFoo(_:)))`. | `topbar/AppleToolbox.swift` |
| "Surface `bin/<tool>` in the menu" | Add to **Slashes ▸** submenu. If it takes input → `promptAction`. If not → `action`. Path is always `\(APPLE_DIR)/bin/<tool>`. | `topbar/AppleToolbox.swift` |
| "Add a new submenu group" | Add `menu.addItem(submenu("Name", items: [...]))` between existing submenus in `rebuildMenu()`. | `topbar/AppleToolbox.swift` |
| "I want ↑/↓ in the live panel to do X" | Edit `handleKey(_:)` switch in `LiveViewportDelegate`. Hardware keyCodes from `Carbon/Events.h`. | `topbar/AppleToolbox.swift` |
| "Reader is slow — readouts hang" | Lower `timeout:` on the offending `run()` call; readers run on the main thread inside the 5-sec timer. Cap at 2–3 sec. | `topbar/AppleToolbox.swift` |
| "Rebuild + relaunch now" | `bash topbar/build.sh && /usr/bin/killall AppleToolbox; open topbar/AppleToolbox.app` — or, if `--live` is running, just save the file. | terminal |
| "Install / reinstall the LaunchAgent" | `bash topbar/install.sh` (or `/topbar`). | terminal |

### Launch Services registration — MANDATORY after Info.plist changes

After **any** edit to keys Launch Services reads (`CFBundleDocumentTypes`, `CFBundleURLTypes`, `UTExportedTypeDeclarations`, `LSItemContentTypes`, `LSHandlerRank`), the .app bundle MUST be re-registered with `lsregister -f`, or Finder will refuse drops (showing the (X) cursor), URL schemes won't resolve, and "Open With" will omit AppleToolbox. Launch Services caches Info.plist contents per-bundle-path and never re-reads them on its own.

`build.sh` already does this automatically: after the `cp -R` install step it runs `lsregister -f` on **both** the source build (`topbar/AppleToolbox.app`) and the installed bundle (`/Applications/AppleToolbox/AppleToolbox.app`). Any future build script that produces an .app MUST do the same — copy that pattern.

Manual one-liner when debugging:

```bash
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f /Applications/AppleToolbox/AppleToolbox.app
```

If `lsregister -f` doesn't fix the symptom, nuke and rebuild the entire LS database (~30s, rarely needed):

```bash
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -kill -r -domain local -domain system -domain user
```

Memory rule: `feedback_lsregister_after_app_bundle_changes.md`.

### Reader pattern (canonical)

```swift
func fooRead() -> String? {                  // String? — nil hides the row
    let out = run("/usr/bin/apple-shipped-cli", ["arg1"], timeout: 2)
    guard !out.isEmpty else { return nil }
    // …parse out, return a short human string like "42 unread"…
    return formatted
}
```

Rules: Apple-shipped binaries only, hard timeout, return `nil` (not `"—"`)
when there is genuinely no data, keep the rendered string under ~40 chars.

### Pedigree rule (why this matters)

AppleToolbox is the LLM-driven Automator made glanceable. Any action
that earns a slot here must satisfy the **Apple-Native Only** rule
defined below in this skill (no Homebrew, no Node, no Python venvs at
launch time). `bin/<tool>` scripts written for the apple repo all
satisfy it by construction — that's why the **Slashes ▸** submenu is
the easy on-ramp for any new verb.

### Channel-selection guide

Anything the user runs frequently belongs in 1–3 of these channels:

- **Slash** (`/qr`) — keyboard, scriptable, batch jobs, text input
- **Loupedeck / Stream Deck** — physical, hands-free, DAW workflow
- **AppleToolbox menu-bar** — mouse, glanceable, live status
- **AppleToolbox `--live`** — keyboard-first cockpit, hot-reload dev loop
- **Vocal Shortcut** (Hey Sal) — hands-free, offline, latency-free

The same `bin/<tool>` script is reached from all five. AppleToolbox is
the discovery surface — if it lives in the menu, the user remembers it
exists.

See `topbar/README.md` for build-chain detail.

