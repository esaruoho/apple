# SCREENSHOT-001: The Screen Capture App That Can't Be Scripted

**App:** Screenshot.app (Cmd+Shift+5)
**Intent:** Programmatically capture screenshots with specific settings — format, region, destination, delay, window targeting — without clicking through the toolbar
**Severity:** UX gap — the GUI has fewer options than its own CLI tool, and neither is scriptable
**Status:** Open
**Filed:** 2026-03-09

---

## The Friction

Screenshot.app has **zero AppleScript commands**. No scripting dictionary. No App Intents. No URL schemes. No Shortcuts actions. 2 entitlements, both private.

| What Screenshot Does | What You Can Script |
|---|---|
| Capture full screen | Nothing |
| Capture window | Nothing |
| Capture selection | Nothing |
| Record screen | Nothing |
| Set output format | Nothing |
| Set save location | Nothing |
| Set timer delay | Nothing |
| **Show/hide pointer** | **Nothing** |

And here's the irony: the `screencapture` CLI tool that ships on every Mac can do **all of this and more**. It has flags for format (`-t png`), clipboard (`-c`), delay (`-T 5`), window mode (`-w`), no sound (`-x`), and output to any path. The GUI is strictly less powerful than the CLI it wraps.

**The practical cost:** "Take a screenshot of this window, save as PNG to ~/Screenshots/, no shadow, no sound" is 1 CLI command but 4+ clicks in the GUI. More importantly, it cannot be triggered from Shortcuts, Automator, or Siri — the tools Apple tells users to use for automation.

---

## What Sal Would Say

> "The power of the computer should reside in the hands of the one using it."

Screenshots are one of the most common computer operations. Documentation, bug reports, tutorials, communication — everyone takes screenshots. The CLI tool is excellent. The GUI tool is adequate. But neither connects to Apple's own automation layer. A Shortcuts user cannot build "screenshot this window and attach it to an email" without dropping to Terminal.

Sal's Principle #6: **Use the whole toolkit.** The toolkit is disconnected. The Screenshot GUI, the `screencapture` CLI, and the Shortcuts app all exist on the same Mac. They don't talk to each other.

Sal's Principle #7: **Think in workflows.** "Capture → annotate → share" is a workflow. "Capture → resize → upload" is a workflow. Today, step 1 requires either a keyboard shortcut (no options) or the CLI (not visual). Neither integrates with steps 2 and 3.

---

## The Automation Surface (from our probe)

From `dictionaries/screenshot/screenshot-probe.yaml`: 3 layers active out of 13.

| Layer | Status |
|-------|--------|
| Scripting Dictionary | None |
| URL Schemes | None |
| App Intents | None |
| Services | None |
| Entitlements | 2 (`screencapture.allow`, `tcc.allow`) |
| Frameworks | 2 |
| Spotlight | Present |
| CLI Tools | `screencapture` |

The app is a launcher that presents the capture toolbar. The actual capture is handled by the `screencaptureui` system service. The `screencapture` CLI talks directly to the same service. Both are invisible to AppleScript and Shortcuts.

---

## What It Should Be

```applescript
-- Screenshot automation like any other app
tell application "Screenshot"
    -- Capture with options
    capture window "Safari" saving to "~/Desktop/safari.png" ¬
        with format PNG without shadow without sound

    -- Capture after delay
    capture full screen saving to "~/Desktop/screen.png" ¬
        with delay 3

    -- Capture to clipboard
    capture selection to clipboard
end tell
```

```bash
# Or Shortcuts actions
shortcuts run "Screenshot Current Window"
shortcuts run "Screenshot to Clipboard"
shortcuts run "Record Screen Region"

# Siri
"Hey Siri, take a screenshot of Safari"
"Hey Siri, screenshot my screen in 5 seconds"
```

---

## Fix Paths

1. **Apple (ideal):** Add App Intents to Screenshot — "Capture Full Screen," "Capture Window," "Capture Selection." Expose format, destination, delay, shadow, sound as parameters. This is a natural fit for Shortcuts — screenshot actions would be among the most-used.
2. **Shortcuts (bridge):** Add a "Run screencapture" Shortcuts action that wraps the CLI tool's flags in a visual interface. Users pick format, region, delay from menus instead of remembering `-t png -T 5 -w -x`.
3. **`screencapture` (workaround today):** The real power. `screencapture -c -w -x` captures a window to clipboard silently. More flags than the GUI offers. But CLI-only — invisible to Shortcuts and non-technical users.
4. **Keyboard shortcuts (limited):** Cmd+Shift+3 (full screen), Cmd+Shift+4 (selection), Cmd+Shift+5 (toolbar). No format control, no destination control, no delay. The bare minimum.
5. **System Events + `do shell script` (hack):** AppleScript wrapping `screencapture` CLI. Works but you're writing shell commands inside AppleScript to automate a screen capture tool that should have been scriptable from day one.

---

## The CLI Gap

`screencapture` proves Apple knows how to build a powerful, automatable screen capture tool. They just didn't connect it to their automation framework:

| Feature | Screenshot.app GUI | `screencapture` CLI | Shortcuts |
|---------|:------------------:|:-------------------:|:---------:|
| Full screen | Yes | Yes | No |
| Window | Yes | Yes (`-w`) | No |
| Selection | Yes | Yes (`-s`) | No |
| Format control | No (always PNG) | Yes (`-t jpg/png/pdf/tiff`) | No |
| Clipboard | No | Yes (`-c`) | No |
| Delay | 5s or 10s only | Yes (`-T n`, any seconds) | No |
| No shadow | No | Yes (`-o`) | No |
| No sound | No | Yes (`-x`) | No |
| Capture to path | Desktop or last used | Yes (any path) | No |
| Include cursor | Toggle | Yes (`-C`) | No |

The CLI is more powerful than the GUI it predates. And neither is accessible to the automation tools Apple promotes.

---

---

*Part of the [Apple Automation Atlas](../README.md). Tagged for the attention of anyone at Apple who still believes the power of the computer should reside in the hands of the one using it.*

**Filed by [@esaruoho](https://github.com/esaruoho)** — software tester, UI enthusiast, amateur scripter, automation/workflow obsessive, and user experience evaluator. Reporting the missing bits and pieces one at a time.
