# Global Keyboard Shortcuts + SnapEngine — Lessons Learned

> Retrospective from the 2026-05-22 session that wired the fourth zero-roundtrip channel into the Apple skill. Carbon `RegisterEventHotKey` global keyboard shortcuts + an in-process AXUIElement window tiler. Companion to [global-keyboard-shortcuts](../concepts/global-keyboard-shortcuts.md).

## The ten lessons, ranked

### 1. Services-menu keyboard shortcuts aren't global

They go through the foreground app's Services dispatcher and get swallowed by anything that binds the same combination internally. For *real* global keyboard shortcuts on Apple-native, the answer is **Carbon `RegisterEventHotKey`** inside a long-running .app — not Services, not App Shortcuts (System Settings → Keyboard), not Shortcuts.app keyboard shortcuts.

This was the first wrong turn of the session. The Services route is no-code, which made it tempting. Pivot came after the user pushed back: "why isn't it global?" If you ever catch yourself reaching for `~/Library/Services/*.workflow` to bind a global keyboard shortcut: stop. Wrong tool.

### 2. "Registered cleanly" ≠ "fires"

⇧⌥⌘. was accepted by `RegisterEventHotKey` with `status=0` but never reached the handler. Cause: iTerm2's View menu was eating it upstream of HIToolbox. The only proof a keyboard shortcut works is pressing it and seeing the log. The status return is necessary but not sufficient.

**Diagnostic protocol when a hotkey is silent:**

1. Check `RegisterEventHotKey` return status (catches outright rejection — system-reserved combinations like ⌘Space).
2. Watch `log show --predicate 'process == "AppleToolbox"' --info` for the NSLog from the handler.
3. If status was 0 but no log fires, suspect an upstream interceptor: Vocal Shortcuts, BetterTouchTool, Karabiner, some other menu-bar app, an active app's menu (iTerm2 View grabs many keystrokes).
4. Pick a different combination from the ⌃⌥⌘ family — that family has the cleanest track record.

### 3. Two registration sites in AppleToolbox, not one

Hotkeys whose handlers touch the `--live` panel must live in `LiveViewportDelegate.registerGlobalHotKey()`. Hotkeys that work whenever 🧰 is in the menu bar belong in `AppDelegate.registerMenuBarHotKeys()`. Putting them all in the live delegate breaks them when `/topbar-live` isn't running.

This was a refinement after the first commit — I had everything in the live delegate, and stop/snap/goto wouldn't fire when the panel was hidden. Split by handler needs, not by convenience.

### 4. AXUIElement direct beats System Events by ~10×

`bin/snap` was slow because of the layers, not because the actual `set position` was slow:

| Layer | Cost |
|---|---|
| osascript JIT startup | 250–400 ms |
| Per-window mutation via System Events Apple Event proxy | ~200 ms × N × 2 |
| Convergence loop (snapshot + Python compare + sleep) | adds 2–3 passes |
| `Process()` spawn from AppleToolbox | ~10 ms |

Total for 9 windows: ~5 s.

`SnapEngine` uses `AXUIElementCreateApplication(pid)` → enumerate `kAXWindowsAttribute` → `AXUIElementSetAttributeValue` for position and size. Synchronous, no convergence loop, no osascript spawn. 5s → 0.4s.

The CLI path (`bin/snap`) couldn't be simply swapped — it doesn't share AppleToolbox's Accessibility permission context. So two-track: AppleToolbox uses AX, CLI/slash/menu still use osascript. Both converge on the same `rowLayout(n)` grid math.

**Heuristic:** if a script's hot path is "shell to osascript that talks to System Events", and you have a long-running .app with Accessibility, port the hot path into the .app and skip the layers.

### 5. Stateless toggles survive everything

Don't store a per-app "is tiled?" flag. Read current AX geometry each press and decide from there. Survives manual drag, app restart, screen change, external resize, lid close, sleep wake.

For ⌃⌥⌘S, the right signal is the **focused window's** frame, not all windows. If it matches `visibleFrame` within ±30 px → tile every window into a grid (overview). Otherwise → un-tile (resize every window back to full width + height, stacked, Cmd-\` between them).

**Pattern:** for any "X ↔ Y" toggle, find a signal in current observable state that distinguishes X from Y. Read it on every invocation. Don't cache.

### 6. The Apple skill is "the LLM-driven Automator" — every surface routes to the same binaries

Every productive surface — slash commands, AppleToolbox menu rows, Vocal Shortcuts, and now global keyboard shortcuts — converges on the same `~/bin/<verb>` binaries. The keyboard shortcut is just a fourth channel onto the same dispatcher. Don't reinvent; route.

This is why the Carbon dispatcher matters more than any individual hotkey wired through it. The architecture (one `InstallEventHandler`, switch on `hkID.id`, FourCharCode signature registry) makes adding the fifth, sixth, twentieth hotkey a two-edit operation.

When the user mentions a script they invoke frequently, the move is: pick a free ⌃⌥⌘‹letter› combination, add a `case N: me.runThatThing()` to the switch, register a new `EventHotKeyID` with the next free id, rebuild. Three minutes.

### 7. `Process()` PATH is the LaunchAgent's PATH

`/usr/bin:/bin:/usr/sbin:/sbin`. Always absolute paths in dispatched scripts. `~/bin/foo` → `/Users/esaruoho/bin/foo`. `python3` → `/usr/bin/python3`. Tilde expansion still works in Swift string interpolation (`"\(HOME)/bin/foo"`), but anything the dispatched script then shells out to needs full paths internally.

Symptom of forgetting this: the hotkey fires (log shows the NSLog), `Process()` runs (no error), but the actual script silently does nothing because it couldn't find a binary on PATH.

### 8. "Chord" is banned for keyboard combinations

Plain English: **keyboard shortcut**, **key combination**, **keystroke**. Same with **idempotent** and **load-bearing**. Per the global no-jargon rule. If you catch yourself reaching for them, rewrite.

Esa, direct quote: *"if SAL never spoke about CHORDS then why the hell are we talking about CHORDS."* The Apple skill's voice should mirror Sal's — clear, plain, no math/CS jargon as a flex.

Codebase grep confirmed: every remaining "chord" in the repo is a musical Renoise tracker chord — those are legitimate musical usage. (Apple repo itself was swept clean 2026-05-25: all keyboard-shortcut usages rewritten.)

### 9. Don't guess; diagnose

When ⇧⌥⌘. didn't work, my first instinct was to blame AppKit Cancel (plausible for ⌘. alone, but ⇧⌥⌘. shouldn't have been caught by Cancel). The real diagnosis came from explicit `RegisterEventHotKey` return-status logging + watching unified logs.

**Lesson:** confident-sounding guesses pollute the trail. Run the diagnostic before naming a cause. Same lesson applies to "the snap-toggle stopped tiling" — should have asked the user to press once and check the log immediately instead of speculating about which branch ran.

The general form: if the only evidence is "user says it doesn't work", add a log line, ask the user to press it, then read the log. Don't guess.

### 10. Commit logically, push immediately

Five commits this session, each telling a piece of the story:

```
44adeb2  refine global hotkeys + un-tile toggle + Sequoia /show hardening
fb3c58a  indexes + build.sh: catch up to new bin/ + commands/ entries
1bbd9df  toolbox-goto: warm-path Distributed Notification trigger
ad1fb8a  snap: Goldilocks convergence loop with window-frame pre-pass
a61250d  appletoolbox: global keyboard shortcuts via Carbon + in-process AX SnapEngine
```

The cost of `git add -p` hunk splitting is real but the readable diff is worth it. One big "everything" commit doesn't tell a story; five focused commits do.

---

## Bonus gotchas

- **Heredoc commit messages and `+/-` characters don't play nice.** The `+/-2 px` in a commit message body broke git's arg parsing when passed via `-m "$(cat <<'EOF'...EOF)"`. Switched to writing to `/tmp/<name>.txt` and using `git commit -F`. Cleaner and collision-free.
- **`@objc func` is required for Carbon dispatch targets.** The `me.snapFrontmostApp()` call from inside the `InstallEventHandler` C closure needs the method to be Objective-C-visible. Without `@objc`, the dispatch silently no-ops (the function is there but the closure can't find it).
- **`AXUIElementSetAttributeValue` is fire-and-forget.** No callback, no completion. If you need to know whether the set landed, do a follow-up `AXUIElementCopyAttributeValue` and compare. SnapEngine doesn't bother — AX is synchronous enough that failures are rare and the toggle re-checks on every press anyway.
- **`/grant-perms` covers AX, but renamed binaries lose the grant.** AppleToolbox.app keeps its grant across builds because the codesign identity + bundle ID are stable. If those change, the grant needs re-issuing — usually by removing the old entry in System Settings → Privacy & Security → Accessibility and re-launching the app so Sequoia prompts fresh.

---

## See also

- [global-keyboard-shortcuts](../concepts/global-keyboard-shortcuts.md) — the dispatch patterns + gotchas reference
- [window-snap](../concepts/window-snap.md) — tile-dock-snap dispatcher + per-app dictionary path
- `topbar/AppleToolbox.swift` — `registerGlobalHotKey()` + `SnapEngine` enum are the canonical implementations
- `topbar/README.md` — Global keyboard shortcuts section with the registered-list table
