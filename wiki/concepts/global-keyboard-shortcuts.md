# Global Keyboard Shortcuts — Carbon RegisterEventHotKey via AppleToolbox

> 📖 **Public:** [Trigger surfaces (public)](https://esaruoho.github.io/apple/triggers)

> True system-wide keyboard shortcuts that don't get swallowed by the foreground app. Apple-shipped Carbon API, no Homebrew, no Karabiner, no Hammerspoon. (Some *handlers* may need Accessibility permission — e.g. SnapEngine driving AXUIElement — but the hotkey *registration* itself doesn't.)

## The breakthrough

Press **⌃⌥⌘.** anywhere — Renoise, full-screen Safari, login window-adjacent, doesn't matter — and `~/bin/voicebox-stop` runs. The dispatcher lives inside `topbar/AppleToolbox.swift` and uses Carbon's `RegisterEventHotKey`. The same dispatcher can fire **anything launchable from the command line**: a shell script, an AppleScript, a Shortcuts.app shortcut, an Automator service, a URL scheme, an `osascript` one-liner, an `open` call.

This is the real macOS power move — bigger than Services-menu shortcuts, bigger than Spotlight, on par with Raycast/Alfred but built from one Apple framework.

## Currently registered keyboard shortcuts

| Shortcut | Action | Registered in | FourCharCode | Notes |
|---|---|---|---|---|
| ⌃⌥⌘D | Toggle smart dictation | `LiveViewportDelegate` | `ATBD` (id=1) | Needs `--live` panel — handler manipulates dictation UI |
| ⌃⌥⌘. | Stop Voicebox (`~/bin/voicebox-stop`) | `AppDelegate` (menu-bar) | `ATBS` (id=2) | UI-independent; always live |
| ⌃⌥⌘T | Goto Finder selection in AppleToolbox browser | `AppDelegate` (menu-bar) | `ATBG` (id=3) | UI-independent; shells out to `bin/toolbox-goto` |
| ⌃⌥⌘S | Toggle tile-all ↔ un-tile-all of the frontmost app's windows (SnapEngine / AXUIElement) | `AppDelegate` (menu-bar) | `ATBN` (id=4) | UI-independent; **handler** needs Accessibility permission. Stateless: each press reads the focused window's current frame — if it matches visibleFrame, tile every window into a grid; otherwise resize every window to full visibleFrame (un-tile, stacked) |

**The split matters.** AppleToolbox runs in two configurations:

- **Menu-bar process** — always running via LaunchAgent (`~/Library/LaunchAgents/com.esaruoho.appletoolbox.plist`). Uses `AppDelegate`. Owns ⌃⌥⌘. / ⌃⌥⌘T / ⌃⌥⌘S.
- **`--live` process** — opt-in floating panel, launched by `/topbar-live`. Uses `LiveViewportDelegate`. Owns ⌃⌥⌘D only.

Any keyboard shortcut whose handler doesn't touch panel state belongs in `AppDelegate.registerMenuBarHotKeys()` so it works even when `--live` is closed. Only put it in `LiveViewportDelegate.registerGlobalHotKey()` if the handler genuinely needs the panel UI (the dictation toggle is the only current example). **Never register the same keyboard shortcut in both** — that's two separate processes racing the Carbon registration last-writer-wins, and it bites you randomly.

## Why it works when Services keyboard shortcuts don't

| Mechanism | Where the key event is caught | When it fails |
|---|---|---|
| Services menu shortcut | The foreground app's Services dispatcher | Any app that binds the same combination internally wins (most apps eat ⌘., ⌘W, ⌘Q, etc.). Full-screen apps may not expose Services at all. |
| App Shortcut (System Settings → Keyboard → App Shortcuts) | The named app's menu-item lookup | Only fires when that app is foreground. |
| Shortcuts.app keyboard shortcut | Shortcuts.app | Per-app activation; not reliably global. |
| **Carbon `RegisterEventHotKey`** | **The HIToolbox event tap, before the foreground app sees the keystroke** | Only fails if (a) the combination is system-reserved like ⌘Space for Spotlight, or (b) two processes register the same combination — last writer wins, often with weird coexistence. |

Carbon hotkeys are **process-global**: the process that registered them catches the key regardless of focus, regardless of app, regardless of full-screen state.

## What you can dispatch from a Carbon hotkey

Inside `stopVoiceboxGlobal()` (the pattern), you can invoke any of these. All paths absolute — `Process()` inherits AppleToolbox's `PATH`, which is whatever the LaunchAgent gave it (usually minimal).

### Shell script
```swift
let t = Process()
t.launchPath = "\(HOME)/bin/voicebox-stop"
try? t.run()
```

### Shortcuts.app shortcut
```swift
let t = Process()
t.launchPath = "/usr/bin/shortcuts"
t.arguments = ["run", "My Shortcut Name"]
try? t.run()
```
Or via URL scheme:
```swift
NSWorkspace.shared.open(URL(string: "shortcuts://run-shortcut?name=My%20Shortcut")!)
```

### Automator service / workflow
```swift
let t = Process()
t.launchPath = "/usr/bin/automator"
t.arguments = ["-i", "", "/Users/esaruoho/Library/Services/Foo.workflow"]
try? t.run()
```

### AppleScript / JXA
```swift
let t = Process()
t.launchPath = "/usr/bin/osascript"
t.arguments = ["-e", "tell application \"Finder\" to make new Finder window"]
try? t.run()
```
Or in-process via `NSAppleScript`:
```swift
NSAppleScript(source: "display notification \"hi\"")?.executeAndReturnError(nil)
```

### URL scheme (any app that registers one)
```swift
NSWorkspace.shared.open(URL(string: "x-apple-shortcuts://run-shortcut?name=Whatever")!)
NSWorkspace.shared.open(URL(string: "things:///add?title=ping")!)
NSWorkspace.shared.open(URL(string: "raycast://extensions/raycast/clipboard-history/clipboard-history")!)
```

### Inline AppKit / Cocoa
The hotkey handler can also just *do work directly*: toggle dictation, snap windows via CGWindow, post a `DistributedNotification`, read the clipboard, write a file, ring `NSSound.beep()`. The whole AppKit/Foundation surface is available.

## The pattern — adding a new hotkey

**First decide which class owns it.** If the handler needs the `--live` panel UI, add it to `LiveViewportDelegate.registerGlobalHotKey()`. Otherwise (the default for almost everything), add it to `AppDelegate.registerMenuBarHotKeys()` so it works without `--live`.

Open `topbar/AppleToolbox.swift`. Two edits to the chosen registration function:

**1.** Extend the dispatch `switch` with a new id:
```swift
switch hkID.id {
case 2: me.stopVoiceboxGlobal()
case 3: me.fireGotoFinderSelection()
case 4: me.snapFrontmostApp()
case 5: me.runMyNewThing()        // ← add
default: break
}
```

**2.** Register the new combination below the existing ones:
```swift
var newRef: EventHotKeyRef?
let newID = EventHotKeyID(signature: OSType(0x41544258), id: 5)  // 'ATBX'
let newStatus = RegisterEventHotKey(UInt32(kVK_F19), mods, newID,
                                    GetApplicationEventTarget(), 0, &newRef)
if newStatus != noErr {
    NSLog("AppleToolbox: ⌃⌥⌘F19 registration failed with OSStatus \(newStatus)")
}
myHotKeyRef = newRef  // hold the ref as a class ivar
```

Then write the method (`runMyNewThing()`) using one of the dispatch patterns above. Build with `./topbar/build.sh`. The build script kills + relaunches the menu-bar instance so the new registration takes effect immediately.

### FourCharCode registry (so signatures don't collide)

| Code | Hex | Purpose | id | Registered in |
|---|---|---|---|---|
| ATBD | `0x41544244` | Dictate toggle | 1 | `LiveViewportDelegate` |
| ATBS | `0x41544253` | Stop Voicebox | 2 | `AppDelegate` |
| ATBG | `0x41544247` | Goto Finder selection | 3 | `AppDelegate` |
| ATBN | `0x4154424E` | sNap frontmost app | 4 | `AppDelegate` |

Add new ones here when you wire them.

## Gotchas

**⌘. is AppKit's universal Cancel.** Don't try to bind it. AppKit intercepts it before Carbon's tap can fire, and any text-entry dialog will steal it back. ⌃⌥⌘. is free (used here), ⇧⌘. is "Show hidden files" in Finder (Finder-foreground only), ⌥⌘. is unclaimed. **⇧⌥⌘. is NOT free** — `RegisterEventHotKey` accepts it without error but the keystroke never reaches the handler in practice; something upstream of HIToolbox swallows it. Stick to the ⌃⌥⌘‹letter/period› family.

**System-reserved combinations refuse to register.** `RegisterEventHotKey` returns non-zero status for things like ⌘Space (Spotlight), ⌃Space (input switcher), ⌘Tab (app switcher). Check the return value if a binding mysteriously doesn't fire.

**The process must be running.** Carbon hotkeys live in the AppleToolbox process. If AppleToolbox is killed, hotkeys go with it. The LaunchAgent at `~/Library/LaunchAgents/com.esaruoho.appletoolbox.plist` brings it back on login. Verify with `pgrep -lf AppleToolbox` — the menu-bar instance has no `--live` in its argv.

**Menu-bar vs `--live` ownership matters.** AppleToolbox is two separate processes when `--live` is open. Each process registers its own Carbon hotkeys (see "Currently registered keyboard shortcuts" above). If a keyboard shortcut was historically only registered by `LiveViewportDelegate` (the `--live` instance), it silently stops working the moment you close the panel — Carbon de-registers when the owning process exits. The fix is always to move UI-independent keyboard shortcuts to `AppDelegate.registerMenuBarHotKeys()`. This bit me on 2026-05-22: `⌃⌥⌘S` and `⌃⌥⌘.` only worked when `/topbar-live` was running, because both were inside `LiveViewportDelegate`. Moved both to `AppDelegate`; they now work whenever 🧰 is in the menu bar.

**Frontmost-app menu accelerators win over Carbon hotkeys for that app.** Carbon `RegisterEventHotKey` is process-global from AppleToolbox's perspective, but a Cocoa main-menu key equivalent in the *frontmost* app gets first crack at the event before HIToolbox dispatches to Carbon hotkey handlers in other processes. On 2026-05-22 we discovered iTerm2 swallows `⇧⌥⌘.` (its View menu binds it) — you'd see iTerm2's View menu flash but AppleToolbox never fired. Switching to `⌃⌥⌘.` avoided the iTerm2 binding. Lesson: if a keyboard shortcut "doesn't work" in one specific app, that app probably has a menu accelerator on the same combination. Test in Finder (sparse menu) first.

**AX-driven handlers need Accessibility permission for the AppleToolbox.app bundle id.** SnapEngine, AppleScript that talks to System Events, anything driving AXUIElement — Carbon registration succeeds without it, but the handler fails with `AXError -25211 = kAXErrorAPIDisabled` at fire time. Check current bundle id with `defaults read /Applications/AppleToolbox/AppleToolbox.app/Contents/Info.plist CFBundleIdentifier` and confirm that string is in System Settings → Privacy & Security → Accessibility. If the bundle id was ever renamed (we did, from `com.esaruoho.apple-workflows` → `com.esaruoho.appletoolbox`), the old TCC entry is stale; add the new one and remove the old. `/grant-perms` queues all the privacy prompts in one go.

**`Process()` inherits the LaunchAgent's `PATH`**, which is minimal (`/usr/bin:/bin:/usr/sbin:/sbin`). Always use absolute paths in the dispatched scripts and binaries. `~/bin/foo` → `/Users/esaruoho/bin/foo`. `python3` → `/usr/bin/python3` or `/opt/homebrew/bin/python3`. (`HOME` is fine.)

**Two processes registering the same combination = unpredictable.** Last writer often wins, but I've seen both fire, neither fire, or random alternation. If a hotkey suddenly stops working, check `pgrep -fl` for another app registering it (Raycast, Alfred, BetterTouchTool, Karabiner, system Shortcuts).

**Carbon modifier flags are NOT NSEvent flags.** Use `controlKey | optionKey | cmdKey | shiftKey` from Carbon — NOT `.command`/`.option` from NSEvent.modifierFlags. They're different bit layouts and silently swapping them gives a hotkey that never fires.

**Key codes are `kVK_ANSI_*` / `kVK_*` from HIToolbox.** Period is `kVK_ANSI_Period` (0x2F=47). Comma is `kVK_ANSI_Comma`. Function keys are `kVK_F1` through `kVK_F20`. There's no string-based "press the . key" — you need the keycode.

**The handler runs on a Carbon dispatch thread.** Always `DispatchQueue.main.async { ... }` before touching AppKit / SwiftUI / `Process()`. The existing pattern in `registerGlobalHotKey()` already wraps the dispatch on `main` — copy it.

**`Process()` is fire-and-forget by default.** No completion callback, no return value. If you need to know whether the script succeeded, wire stdout/stderr pipes — but for "press hotkey, thing happens", `try? task.run()` is enough.

**Modifier-only hotkeys don't exist via this API.** You can't bind "tap left-⌘ twice" or "hold ⌥ for 200ms" with `RegisterEventHotKey` — that's `NSEvent.addGlobalMonitorForEvents` territory and requires Accessibility permission. Stick to shortcut-style key+modifier combinations here.

**Hotkeys don't fire in the login window, screen lock, or recovery mode.** AppleToolbox isn't running in those contexts.

## Why this is a big deal

Before this: every script in `~/bin/` lived behind a click — Spotlight (3 keystrokes + return), Loupedeck button, menu-bar dropdown. Each one ~1 second of friction. Sal's WWDC point about *"reducing 50 keystrokes to one click"* — Carbon hotkeys reduce one click to **zero clicks**.

And it's the same dispatcher for everything. The 65 CLI tools in `~/work/apple/bin/`, the 301 workflow scripts, the 588 Siri phrases, the entire grand-search/grand-export family — any of them can hang off a global keyboard shortcut now. Pick the keystroke, edit `registerGlobalHotKey()`, rebuild, done.

This is the **fourth zero-roundtrip channel**, alongside slash commands, AppleToolbox menu rows, and Vocal Shortcuts:

1. `/voiceboxstop` slash in Claude Code
2. 🧰 menu-bar → 🔇 Stop Voicebox
3. Vocal: "Hey Sal, stop voicebox" → Shortcut → script
4. **⌃⌥⌘. global keyboard shortcut → Carbon dispatch → script** ← new

Every macOS automation surface eventually converges on the same `~/bin/<verb>` binary. The hotkey just makes it instantaneous.

## See also

- `topbar/AppleToolbox.swift` — `AppDelegate.registerMenuBarHotKeys()` (UI-independent keyboard shortcuts) and `LiveViewportDelegate.registerGlobalHotKey()` (panel-dependent keyboard shortcuts) are the two registration sites
- `topbar/README.md` — "Global keyboard shortcuts" section, registered list
- `appletoolbox_third_channel.md` (memory) — the architectural roof this slots into
- `zero_roundtrip_pattern.md` (memory) — the broader principle
- `wwsd-decision-tree.md` — Sal's framework for picking the right automation surface
