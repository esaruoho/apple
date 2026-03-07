# SYSTEM-SETTINGS-001: The Most Important Config App on macOS Has Almost No Automation

**App:** System Settings.app (formerly System Preferences)
**Intent:** Programmatically read or change system configuration — display brightness, default browser, network settings, accessibility toggles, anything
**Severity:** Architectural gap — the single app that controls macOS configuration is nearly opaque to automation
**Status:** Open
**Filed:** 2026-03-07

---

## The Friction

System Settings has **3 AppleScript commands** and **2 classes**. Three commands. For the app that controls every configurable aspect of macOS.

| What System Settings Controls | What You Can Script |
|---|---|
| Display brightness, resolution, Night Shift | Nothing |
| Wi-Fi, Bluetooth, VPN | Nothing |
| Default browser, mail client | Nothing |
| Accessibility features (VoiceOver, zoom, reduce motion) | Nothing |
| Keyboard shortcuts, input sources | Nothing |
| Notifications per app | Nothing |
| FileVault, Firewall | Nothing |
| Sound input/output, volume | Nothing |
| **Opening a specific pane** | **Yes, that's about it** |

You can tell System Settings to reveal a pane. You cannot tell it to change anything once it gets there.

**The practical cost:** Every IT admin, every accessibility user, every power user who provisions machines — all of them resort to `defaults write` shell commands scraped from blog posts. There is no sanctioned, stable, documented automation path for system configuration.

---

## What Sal Would Say

> "The power of the computer should reside in the hands of the one using it."

System Settings is the control panel of the entire computer. If this app isn't scriptable, then the computer's own configuration doesn't reside in the hands of the user. It resides behind a GUI that must be clicked through manually, every time, on every machine.

Sal's Principle #2: **Solve a real problem.** "I just got a new Mac and I need to configure 40 settings" is a real problem that every Mac user faces. "I manage 200 Macs and need consistent configuration" is a real problem every IT admin faces. Neither has an Apple-supported scripted solution.

Sal's Principle #7: **Think in workflows.** Machine setup is a workflow. Accessibility configuration is a workflow. Apple treats both as "go click through 15 different panes."

---

## The Automation Surface (from our probe)

From the probe data: System Settings has **3 AppleScript commands** and **2 classes** (`application`, `pane`). The `reveal` command can open a specific preference pane, but no commands exist to read or write any setting.

System Settings has **no App Intents**, **no URL scheme** for setting values, and **no CLI tool** for configuration. The old `systemsetup` CLI tool is deprecated and covers only a handful of settings.

The reality is that macOS system configuration is scattered across:
- `defaults` (UserDefaults plist files) — undocumented, keys change between releases
- `systemsetup` — deprecated, limited scope
- `pmset` — power management only
- `networksetup` — networking only
- `scutil` — system configuration only
- Various per-subsystem CLIs with no unified interface

---

## What It Should Be

```applescript
-- Configure a new Mac in one script
tell application "System Settings"
    -- Display
    set display brightness to 75
    set Night Shift schedule to "sunset to sunrise"

    -- Accessibility
    set reduce motion to true
    set increase contrast to true

    -- General
    set default web browser to "Safari"

    -- Notifications
    tell notification settings of application "Mail"
        set show previews to "when unlocked"
        set play sound to false
    end tell
end tell
```

```bash
# Or a proper CLI
macos-config set display.brightness 75
macos-config set accessibility.reduce-motion true
macos-config set general.default-browser "com.apple.Safari"
macos-config export ~/mac-setup.json   # portable config
macos-config import ~/mac-setup.json   # apply to new machine
```

One script to configure a Mac. Portable, version-controllable, shareable.

---

## Fix Paths

1. **Apple (ideal):** Expand the System Settings scripting dictionary to cover every pane — expose settings as readable/writable properties organized by category. Or ship a `macos-config` CLI tool with a stable, documented schema.
2. **Shortcuts (partial):** Add Shortcuts actions for common settings: "Set Brightness," "Toggle Do Not Disturb," "Set Default Browser." Focus Mode already has some of this — extend it to everything.
3. **`defaults write` (workaround today):** The unofficial standard. Undocumented, keys change between macOS versions, some require `killall` to take effect, some require logout/restart. Fragile but ubiquitous. Every "new Mac setup" blog post is a `defaults write` script.
4. **MDM profiles (enterprise):** Configuration profiles (.mobileconfig) can set many system preferences, but they're designed for IT management, not personal automation. Creating them requires Apple Configurator or Profile Manager.
5. **System Events UI scripting (hack):** Click through System Settings via accessibility APIs. Extremely fragile — the SwiftUI rewrite in Ventura broke every existing UI script.

---

## The `defaults write` Problem

`defaults write` is not a solution. It is a symptom of the problem:

- **Undocumented:** No official list of keys exists. Users reverse-engineer them.
- **Unstable:** Keys change between macOS versions with no deprecation notice.
- **Incomplete:** Many settings have no `defaults` equivalent.
- **Side effects:** Some changes require process restarts (`killall Finder`, `killall Dock`), others require logout, others take effect immediately. No documentation says which.
- **No validation:** `defaults write` will happily accept invalid values and silently do nothing.

Users should not have to reverse-engineer their own operating system's configuration layer.

---

---

*Part of the [Apple Automation Atlas](../README.md). Tagged for the attention of anyone at Apple who still believes the power of the computer should reside in the hands of the one using it.*

**Filed by [@esaruoho](https://github.com/esaruoho)** -- software tester, UI enthusiast, amateur scripter, automation/workflow obsessive, and user experience evaluator. Reporting the missing bits and pieces one at a time.