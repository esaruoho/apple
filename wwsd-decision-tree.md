# What Would Sal Do? — macOS Automation Decision Tree

> "The power of the computer should reside in the hands of the one using it."
> — Sal Soghoian

This document is a practical guide for choosing the right macOS automation approach.
It is rooted in Sal Soghoian's philosophy: every automation should be triggerable with
one action, produce one clear result, and survive the next macOS update.

---

## 1. Decision Tree

Start here. Ask yourself: **"What am I trying to automate?"**

```
What are you trying to automate?
│
├─── App Control (launch, switch, manipulate windows, in-app actions)
│    │
│    ├─ App has sdef (scripting dictionary)?
│    │  YES → AppleScript (`tell application "AppName"`)
│    │         Tool: bin/workflow-gen.py covers 16 apps, 186 recipes
│    │  NO  ↓
│    │
│    ├─ App has URL scheme?
│    │  YES → `open "urlscheme://action"`
│    │         Tool: bin/app-probe.py maps 35 apps with URL schemes
│    │  NO  ↓
│    │
│    ├─ App has App Intents?
│    │  YES → Shortcuts (20 apps expose App Intents)
│    │         Tool: bin/shortcut-gen.py generates .shortcut files
│    │  NO  ↓
│    │
│    └─ Last resort → Accessibility API (System Events GUI scripting)
│         Fragile. Only when nothing else works.
│
├─── System Settings (Wi-Fi, Bluetooth, display, sound, defaults)
│    │
│    ├─ Has a `defaults` domain?
│    │  YES → CLI: `defaults write/read domain key value`
│    │  NO  ↓
│    │
│    ├─ Has a URL scheme (x-apple.systempreferences:...)?
│    │  YES → `open "x-apple.systempreferences:com.apple.xxx-extension"`
│    │  NO  ↓
│    │
│    ├─ Has a CLI tool? (networksetup, pmset, systemsetup, nvram)
│    │  YES → CLI directly, or AppleScript via `do shell script`
│    │  NO  ↓
│    │
│    └─ Accessibility API → script System Settings UI elements
│         Breaks on every major macOS release. Document the version.
│
├─── Hardware (audio devices, displays, battery, sensors)
│    │
│    ├─ Has a CLI tool? (system_profiler, ioreg, pmset, brightness)
│    │  YES → CLI: wrap in `do shell script` if you need AppleScript glue
│    │  NO  ↓
│    │
│    ├─ Exposed via HomeKit?
│    │  YES → Shortcuts: `shortcuts run "Sensor Name"`
│    │         Example: homepod/homepod-climate.sh
│    │  NO  ↓
│    │
│    └─ IOKit / IORegistry → `ioreg -rc ClassName`
│         Low-level but stable across updates.
│
├─── File Operations (move, rename, tag, compress, organize)
│    │
│    ├─ Finder-level operation? (trash, tag, label, comment, reveal)
│    │  YES → AppleScript: `tell application "Finder"`
│    │  NO  ↓
│    │
│    ├─ Bulk/fast operation? (thousands of files, no GUI needed)
│    │  YES → CLI: mv, cp, rsync, find, xattr, mdls, mdfind
│    │  NO  ↓
│    │
│    └─ Need both? → AppleScript + `do shell script` bridge
│
├─── Web / Network (HTTP requests, downloads, scraping)
│    │
│    ├─ Simple fetch or download?
│    │  YES → CLI: `curl`, `wget`
│    │  NO  ↓
│    │
│    ├─ Browser automation?
│    │  YES → AppleScript: `tell application "Safari"` (has full sdef)
│    │  NO  ↓
│    │
│    └─ Network config? → CLI: `networksetup`, `scutil`, `dns-sd`
│
└─── Scheduling (run at time, run on event, run periodically)
     │
     ├─ Simple recurring task?
     │  YES → launchd plist (LaunchAgent for user, LaunchDaemon for system)
     │         Example: com.esa.homepod-climate.plist (every 10 min)
     │  NO  ↓
     │
     ├─ Triggered by system event? (login, wake, network change)
     │  YES → launchd WatchPaths / StartOnMount / KeepAlive keys
     │  NO  ↓
     │
     └─ One-time future task? → `at` command or Shortcuts Automation
```

---

## 2. Comparison Matrix

| Approach | Best For | Depth | Ease | Siri | Spotlight | Hardware Buttons |
|---|---|---|---|---|---|---|
| **AppleScript** | App control, dialogs, Finder ops | Deep — full scripting dictionaries | Medium | Via Shortcuts wrapper | Via osacompile .app | Via Loupedeck/Stream Deck |
| **Shortcuts** | HomeKit, App Intents, chaining | Medium — limited to exposed intents | Easy | Native ("Hey Siri, ...") | Native (by name) | Via Loupedeck/Stream Deck |
| **CLI / shell** | System config, file ops, network | Deep — full UNIX toolbox | Hard (for non-devs) | Via Shortcuts + shell action | Via shell wrapper .app | Via Loupedeck/Stream Deck |
| **Accessibility API** | Unscriptable apps, UI clicking | Shallow — fragile, version-dependent | Hard | Via Shortcuts wrapper | Via osacompile .app | Via Loupedeck/Stream Deck |
| **URL schemes** | Opening apps to specific views | Shallow — only what the app exposes | Easy | Via Shortcuts "Open URL" | Via osacompile .app | Via Loupedeck/Stream Deck |
| **`defaults` command** | Hidden prefs, system tweaks | Medium — undocumented but stable | Medium | Via Shortcuts + shell action | Via shell wrapper .app | Via Loupedeck/Stream Deck |
| **XPC (future)** | Inter-process communication | Very deep — requires Swift/ObjC | Very hard | No | No | No |

**Key insight:** Every approach can reach Siri, Spotlight, and hardware buttons — the
question is how many wrappers you need. AppleScript + osacompile is the most direct
path to all three surfaces. Shortcuts is the most direct path to Siri.

---

## 3. Sal's 7 WWSD Principles — Mapped to Decisions

### Principle 1: "Power in the user's hands"
**Prefer open approaches over locked-down ones.**

- Choose AppleScript (open, inspectable, editable) over Automator (binary blob).
- Choose CLI tools (composable, scriptable) over GUI-only settings.
- Choose Shortcuts with AppleScript actions over Shortcuts-only flows — the AppleScript
  is visible and debuggable; a pure Shortcuts flow is opaque JSON.
- Store scripts as `.applescript` text files in git, not as compiled `.scpt` binaries.

### Principle 2: "Automate the tedious"
**If it takes more than 3 clicks, script it.**

- 1 click (launch app) → probably not worth scripting.
- 2 clicks (launch app, pick menu item) → borderline. Script it if you do it daily.
- 3+ clicks (open System Settings, navigate pane, toggle switch, confirm dialog) → script it.
- Example: Toggling Do Not Disturb is buried 4 clicks deep. Script: `shortcuts run "Toggle Focus"`.

### Principle 3: "One action, one result"
**Each script does exactly one thing.**

- `empty-trash.applescript` empties the trash. It does not also clean caches.
- `music-play-pause.applescript` toggles playback. It does not also set volume.
- If you need both, make two scripts and a third that calls them.
- Test: can you name the script with a verb-noun pair? (`empty-trash`, `toggle-wifi`,
  `play-playlist`). If you need "and" in the name, split it.

### Principle 4: "Chain, don't monolith"
**Pipe small scripts together.**

- Wrong: one 200-line script that backs up, compresses, uploads, and notifies.
- Right: `backup.sh | compress.sh | upload.sh && notify.applescript`
- In Shortcuts: each action is a step. In AppleScript: use `run script` to call
  other scripts. In shell: use pipes and `&&`.
- The workflow-gen.py recipes follow this — each is a self-contained unit that can
  be composed with others.

### Principle 5: "Bridge, don't rebuild"
**Use `do shell script` to reach CLI tools from AppleScript.**

- Need the current Wi-Fi network name in AppleScript?
  Do not parse System Events. Instead:
  `do shell script "networksetup -getairportnetwork en0 | cut -d: -f2 | xargs"`
- Need to read a JSON file? `do shell script "cat file.json | python3 -c 'import sys,json; ...'"`
- Need hardware info? `do shell script "ioreg -rc AppleSmartBattery | grep Capacity"`
- The bridge goes both ways: from shell, use `osascript -e 'tell app ...'` to reach
  AppleScript-only features like dialogs and Finder metadata.

### Principle 6: "Use the whole toolkit"
**AppleScript + CLI + Shortcuts together.**

- Real example from this repo:
  - `workflow-gen.py` (Python) generates `.applescript` files
  - `spotlight-export.sh` (bash) compiles them to `.app` bundles via `osacompile`
  - `shortcut-gen.py` (Python) wraps them in signed `.shortcut` files
  - Result: 186 workflows accessible via Spotlight, Siri, and hardware buttons
- The best automation uses whatever tool is strongest for each layer:
  Python for generation, shell for compilation, AppleScript for app control,
  Shortcuts for Siri/HomeKit, launchd for scheduling.

### Principle 7: "Think in workflows"
**Design for the user's real task, not the API.**

- The user does not think "I want to send an Apple Event to com.apple.finder with
  a `make` command of class `cfol`." The user thinks "I want to create a new folder
  on my Desktop."
- Name scripts after the task: `new-desktop-folder`, not `finder-make-cfol`.
- Group scripts by what the user is doing, not by which API they use.
  The `scripts.md` catalog is organized by app because that matches how users think:
  "I want to do something with Music" not "I want to use the `play` command."

---

## 4. Decision Examples

### "I want to toggle Wi-Fi"
**Use CLI.**
```bash
networksetup -setairportpower en0 off
networksetup -setairportpower en0 on
```
Why not AppleScript? There is no scripting dictionary for Wi-Fi. Why not System Settings
UI scripting? It breaks every macOS release. `networksetup` has been stable since 10.5.

---

### "I want to empty the trash"
**Use AppleScript.**
```applescript
tell application "Finder" to empty trash
```
Why AppleScript? Finder has a deep scripting dictionary. This is a one-liner. It also
handles the confirmation dialog and secure empty if configured.

---

### "I want to read my battery level"
**Use CLI.**
```bash
pmset -g batt
```
Or for structured data:
```bash
ioreg -rc AppleSmartBattery | grep -E "CurrentCapacity|MaxCapacity"
```
Why CLI? Battery data is exposed via IOKit, not via any app's scripting dictionary.
Wrap in `do shell script` if you need it inside an AppleScript.

---

### "I want to control HomeKit"
**Use Shortcuts.**
```bash
shortcuts run "Good Morning"
shortcuts run "HomePod Sensors"
```
Why Shortcuts? HomeKit has no AppleScript dictionary and no public CLI. Shortcuts is
the only sanctioned bridge between the command line and HomeKit. Create the Shortcut
in the Shortcuts app (or via shortcut-gen.py), then trigger it from shell/AppleScript.

---

### "I want to open a specific System Settings pane"
**Use URL scheme.**
```bash
open "x-apple.systempreferences:com.apple.wifi-settings-extension"
open "x-apple.systempreferences:com.apple.Bluetooth-Settings.extension"
open "x-apple.systempreferences:com.apple.Sound-Settings.extension"
```
Why URL scheme? It is a single command, it survives macOS updates (the identifiers
are stable), and it does not require Accessibility permissions. For actually changing
a setting, you will need `defaults`, `networksetup`, or (last resort) Accessibility API.

---

### "I want to play a specific playlist"
**Use AppleScript.**
```applescript
tell application "Music"
    play playlist "Focus"
end tell
```
Why AppleScript? Music has one of the deepest scripting dictionaries on macOS. You can
control playback, search the library, manage playlists, set shuffle/repeat, read track
metadata — all via AppleScript.

---

### "I want to monitor dark mode changes"
**Use Distributed Notifications.**
```bash
# One-shot check:
defaults read -g AppleInterfaceStyle 2>/dev/null || echo "Light"

# Live monitoring:
# Listen for com.apple.darkmode.change via DistributedNotificationCenter
# In AppleScript, poll periodically; in Swift/ObjC, observe directly.
```
Why notifications? Dark mode changes are broadcast system-wide via
`com.apple.darkmode.change`. Polling `defaults` works for one-shot checks; for live
reaction, you need a notification observer (Swift helper or shell + `defaults` in a
launchd WatchPaths loop on `~/Library/Preferences/.GlobalPreferences.plist`).

---

## 5. The Sal Test

Before choosing an approach, ask these three questions:

### Question 1: Can the user trigger it with one action?

- A button press on Loupedeck Live, Stream Deck, or Contour Shuttle Pro
- A voice command: "Hey Siri, empty the trash"
- A Spotlight search: type the workflow name, hit Enter
- A keyboard shortcut

If triggering requires opening an app first, navigating a menu, or remembering a
terminal command — it fails the test. Wrap it until it passes.

**Pipeline:** `.applescript` → `osacompile` → signed `.app` → Spotlight / Loupedeck / Siri

### Question 2: Does it produce one clear result?

- A notification ("Wi-Fi is now off")
- A visible state change (Finder window appears, music starts playing)
- A file created (screenshot saved, export completed)
- A sound (system beep, spoken confirmation)

If the script runs silently with no feedback, add a `display notification` at the end.
The user should never wonder "did it work?"

### Question 3: Will it still work after the next macOS update?

Stability ranking (most stable to least):

1. **CLI tools** (`defaults`, `networksetup`, `pmset`, `mdfind`) — decades-stable
2. **AppleScript dictionaries** (Finder, Music, Safari, Mail) — very stable
3. **URL schemes** (`x-apple.systempreferences:`) — stable since introduction
4. **Shortcuts actions** — stable but actions get renamed between versions
5. **App Intents** — still evolving, may change year to year
6. **Accessibility API / GUI scripting** — breaks on nearly every major release

**Rule of thumb:** If you are using `click button 3 of group 2 of window 1`, you are
building on sand. Find a stable API. If none exists, file it as a painpoint (see
`painpoints/`) and use Accessibility as a stopgap with a comment marking the macOS
version it was tested on.

---

## Quick Reference: When to Use What

| I want to... | Use | Command/Pattern |
|---|---|---|
| Launch/activate an app | AppleScript | `tell application "X" to activate` |
| Toggle a system setting | CLI | `defaults write`, `networksetup` |
| Run a HomeKit scene | Shortcuts | `shortcuts run "Scene"` |
| Open a Settings pane | URL scheme | `open "x-apple.systempreferences:..."` |
| Move/copy/tag files | CLI or Finder AS | `mv`/`cp` or `tell application "Finder"` |
| Get hardware info | CLI | `ioreg`, `pmset`, `system_profiler` |
| Schedule a task | launchd | `.plist` in `~/Library/LaunchAgents/` |
| Click a button in an unscriptable app | Accessibility | `tell application "System Events"` |
| Make it voice-triggerable | Shortcuts | shortcut-gen.py wraps any AppleScript |
| Make it Spotlight-searchable | osacompile | spotlight-export.sh compiles to .app |
| Make it hardware-button-triggerable | Any of the above | Loupedeck/Stream Deck runs .app or osascript |

---

*This decision tree is a living document. When you find a new automation surface or
a better approach for an existing task, update this file.*
