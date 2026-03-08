# Loupedeck Live Setup Guide for Apple Workflows

Use your Loupedeck Live to trigger any of the 288 workflow scripts and 64 launcher scripts in this repo via shell commands.

---

## Prerequisites

1. Clone this repo
2. Run `bin/spotlight-export.sh` to compile all workflow scripts to `.app` bundles in `/Applications/Apple-Workflows/`
3. Run `bin/shortcut-gen.py` to generate `.shortcut` files, then `bin/batch-import.sh` to import them into Shortcuts.app
4. In Shortcuts.app, go to Settings > Advanced > enable "Allow Running Scripts"

---

## Adding a Custom Action (AppleScript via osascript)

In the Loupedeck software:

1. Open the Loupedeck app and go to your profile
2. Drag a **Custom > Run** action onto a button, dial, or touch screen slot
3. In the command field, enter the `osascript` command pointing to the script:

```
osascript /path/to/apple/scripts/workflows/finder/finder-empty-trash.applescript
```

4. Name the button and optionally assign an icon (see Icons section below)
5. Save the profile

### For launcher scripts

Launcher scripts activate a specific app:

```
osascript /path/to/apple/scripts/launchers/activate-finder.applescript
```

This is how you work around Loupedeck not listing certain apps (like Finder) in its built-in app launcher.

---

## Adding a Shortcut Action

If you imported the shortcuts via `batch-import.sh`, you can trigger them from the CLI:

```
shortcuts run "Finder-EmptyTrash"
```

Use this in a Loupedeck **Custom > Run** action the same way as above.

---

## Example Button Configurations

### Activate Finder
- **Command:** `osascript /path/to/apple/scripts/launchers/activate-finder.applescript`
- **Icon:** `icons/finder.png`

### Play/Pause Music
- **Command:** `osascript /path/to/apple/scripts/workflows/music/music-play-pause.applescript`
- **Icon:** `icons/music.png`

### Toggle Dark Mode
- **Command:** `osascript /path/to/apple/scripts/workflows/system-events/system-events-dark-mode-toggle.applescript`
- **Icon:** `icons/system-events.png`

### Empty Trash
- **Command:** `osascript /path/to/apple/scripts/workflows/finder/finder-empty-trash.applescript`
- **Icon:** `icons/finder.png`

### Skip to Next Track
- **Command:** `osascript /path/to/apple/scripts/workflows/music/music-next-track.applescript`
- **Icon:** `icons/music.png`

### Battery Status
- **Command:** `osascript /path/to/apple/scripts/workflows/system-events/system-events-battery-status.applescript`
- **Icon:** `icons/system-events.png`

### New Safari Window
- **Command:** `osascript /path/to/apple/scripts/workflows/safari/safari-new-window.applescript`
- **Icon:** `icons/safari.png`

---

## Icons

The `icons/` directory contains 64 PNG app icons extracted from the actual macOS app bundles. Use these as button icons in Loupedeck:

- `icons/finder.png`
- `icons/music.png`
- `icons/safari.png`
- `icons/mail.png`
- `icons/photos.png`
- `icons/calendar.png`

Full path: `icons/` in the repo root.

To use in Loupedeck: click the button icon area and select the PNG from the `icons/` directory.

---

## Tips

- **Naming buttons:** Use short labels that match the script purpose: "Empty Trash", "Dark Mode", "Play/Pause". The script filenames follow the pattern `app-action.applescript` which maps naturally to button labels.

- **Organizing pages:** Group buttons by app. The 33 workflow categories map well to Loupedeck pages:
  - Media page: Music, QuickTime, Photos, TV, iMovie
  - Productivity page: Finder, Mail, Safari, Calendar, Reminders, Notes
  - System page: System Events, System Settings, Terminal, Accessibility

- **Dials for media:** Assign music volume scripts to a dial's rotation for physical volume control.

- **Compiled .app bundles:** Instead of `osascript`, you can also launch the compiled apps directly:
  ```
  open /Applications/Apple-Workflows/Music-PlayPause.app
  ```
  These are the same scripts compiled by `bin/spotlight-export.sh`.

- **Full script list:** Run `bin/workflow-gen.py --catalog` to regenerate `scripts.md` with the complete catalog of all available workflows.

---

## Other Hardware Controllers

This approach works with any programmable controller that can execute shell commands:

- **Stream Deck** -- Use the System > Open action to run shell commands
- **Contour Shuttle Pro** -- Map shell commands to buttons and jog wheel positions
- **Any HID controller** with macro software that supports "run command" or "execute shell"

The commands are identical across all controllers. Only the UI for assigning commands to buttons differs.

---

## Script Directory Reference

| Directory | Scripts | Description |
|-----------|---------|-------------|
| `scripts/launchers/` | 64 | Activate/bring apps to foreground |
| `scripts/workflows/finder/` | varies | Finder file operations |
| `scripts/workflows/music/` | varies | Music playback and library |
| `scripts/workflows/safari/` | varies | Safari tabs and windows |
| `scripts/workflows/system-events/` | varies | Dark mode, clipboard, notifications |
| `scripts/workflows/mail/` | varies | Mail compose and management |
| `scripts/workflows/calendar/` | varies | Calendar events and reminders |
| `scripts/workflows/photos/` | varies | Photos library and export |
| `scripts/workflows/terminal/` | varies | Terminal window management |

Full list: 33 app categories across `scripts/workflows/`. See `scripts.md` for the complete catalog.
