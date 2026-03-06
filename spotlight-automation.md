# Spotlight + Automation — The Final Sal Mile

> "The final Sal mile: should eventually work from Spotlight."
> Every script in this repo should be one Cmd+Space away.

## The 5 Paths to Spotlight

There are exactly **5 ways** to make automation reachable from Spotlight on macOS:

### Path 1: osacompile to .app (Best for AppleScripts)

Compile any `.applescript` to a standalone `.app` bundle. Spotlight indexes all `.app` bundles automatically via LaunchServices.

```bash
# Compile to app
osacompile -o ~/Applications/Music-PlayPause.app scripts/workflows/music/music-playpause.applescript

# Verify Spotlight sees it
mdls -name kMDItemContentType ~/Applications/Music-PlayPause.app
# → "com.apple.application-bundle"

# Now Cmd+Space → "Music PlayPause" → Enter → plays/pauses
```

**Why ~/Applications/?** Spotlight indexes `/Applications/` and `~/Applications/` by default. No configuration needed. The app appears within seconds.

**Metadata Spotlight sees:**
- `kMDItemDisplayName` — the app name (what you type in Spotlight)
- `kMDItemContentType` — `com.apple.application-bundle`
- `kMDItemKind` — "Application"

**Naming matters:** `Music-PlayPause.app` becomes searchable as "Music PlayPause". Use descriptive names — Spotlight matches on any word.

### Path 2: Shortcuts (Best for App Intents Width)

Every Shortcut is automatically Spotlight-indexed. No extra steps.

```bash
# Create a Shortcut that wraps an AppleScript
# Shortcuts app → New Shortcut → Add "Run AppleScript" action → paste code
# Name it descriptively

# From CLI:
shortcuts run "Music PlayPause"

# From Spotlight:
# Cmd+Space → "Music PlayPause" → shows as Shortcut → Enter
```

**Advantage:** Shortcuts also appear in Siri, share sheets, menu bar, and can accept input from other Shortcuts.

**Limitation:** The "Run AppleScript" action in Shortcuts is sandboxed. Some operations (file system access, `do shell script`) may fail or require extra permissions.

### Path 3: Automator Quick Actions / Services

Quick Actions saved to `~/Library/Services/` appear in:
- Finder right-click menu
- Touch Bar
- Services menu
- **Spotlight** (as "Service" type)

```bash
# Create in Automator:
# File → New → Quick Action → Add "Run AppleScript" → Save

# Existing services on this Mac:
# ~/Library/Services/Convert to 320k MP3.workflow
# ~/Library/Services/Send Sample to Renoise.workflow
```

**Best for:** Context-dependent actions (selected files, selected text).

### Path 4: Automator Application (.app workflow)

Automator can save workflows as standalone `.app` bundles:

```bash
# Automator → File → New → Application → Add actions → Save to ~/Applications/
# Spotlight indexes it like any other app
```

**Difference from Path 1:** Automator apps can chain multiple actions (AppleScript + shell + file operations) in a visual pipeline. Path 1 is pure AppleScript.

### Path 5: Shell Scripts via .app Wrapper

For bash/shell scripts that can't be pure AppleScript:

```bash
# Create a minimal .app that runs a shell command
osacompile -o ~/Applications/My-Tool.app -e 'do shell script "/path/to/script.sh"'
```

This wraps any CLI tool (`ghc`, `ask`, `app-probe`, etc.) in a Spotlight-reachable app.

## The Export Pipeline

`bin/spotlight-export.sh` automates Path 1 for all workflow scripts:

```bash
# Export all workflows as Spotlight-reachable apps
./bin/spotlight-export.sh

# Export specific app workflows
./bin/spotlight-export.sh finder
./bin/spotlight-export.sh music safari

# List what would be exported
./bin/spotlight-export.sh --dry-run

# Clean up (remove all exported apps)
./bin/spotlight-export.sh --clean
```

**Output:** `~/Applications/Apple-Workflows/` — one `.app` per workflow script, all Spotlight-indexed.

**Naming convention:** `Finder-Copy-Path.app`, `Music-PlayPause.app`, `Safari-Current-URL.app` — each word is a Spotlight search term.

## Spotlight Search Mechanics

Understanding how Spotlight finds things:

| What you type | What Spotlight matches |
|---------------|----------------------|
| `music play` | Any app with "music" AND "play" in name |
| `finder` | All Finder-related apps + the Finder itself |
| `dark mode` | `System-Events-Dark-Mode-Toggle.app` |
| `screenshot` | `System-Events-Screenshot-Area.app` + built-in Screenshot |

**Spotlight indexes these fields for .app bundles:**
- `kMDItemDisplayName` — filename without .app extension
- `kMDItemCFBundleName` — from Info.plist (if set)
- `kMDItemCFBundleIdentifier` — bundle ID (if set)
- `kMDItemComment` — Spotlight comment (settable via `mdutil` or Finder Get Info)

**Boost trick:** Set Spotlight comments on exported apps for better search:

```bash
# Add keywords as Spotlight comments
mdutil -name "play pause toggle music" ~/Applications/Apple-Workflows/Music-PlayPause.app
# or via AppleScript:
osascript -e 'tell application "Finder" to set comment of (POSIX file "/path/to/app" as alias) to "play pause toggle music"'
```

## What 14 Apple Apps Do With CoreSpotlight

From the probe data, these apps link `CoreSpotlight.framework`:

App Store, Books, Calendar, Freeform, Mail, Maps, News, Notes, Photos, Podcasts, Reminders, System Settings, Tips, Voice Memos

They use Spotlight Index Extensions (`com.apple.spotlight.index`) to make their **content** searchable — not just the app itself, but individual notes, emails, events, etc. This is deeper than what we need for workflow scripts, but it's the same infrastructure.

## Architecture: Where Scripts Live vs Where Apps Live

```
scripts/workflows/           ← Source of truth (.applescript files, in git)
    finder/
    music/
    ...

~/Applications/              ← Spotlight-indexed apps (generated, local-only)
    Apple-Workflows/
        Finder-Copy-Path.app
        Music-PlayPause.app
        ...
```

The `.applescript` files are version-controlled. The `.app` bundles are generated artifacts — like compiled binaries. Regenerate anytime with `spotlight-export.sh`.

## Sal's Vision Realized

Sal's Automator patent (US 7,428,535) described actions that are **discoverable by context**. Spotlight is the modern version of that vision — instead of Automator filtering actions by data type, Spotlight filters by **intent expressed in natural language**.

The pipeline is now:
1. **sdef-extract.py** — extract what's possible (dictionaries)
2. **workflow-gen.py** — generate scripts that do real things (recipes)
3. **spotlight-export.sh** — make them findable (Spotlight)

That's Sal's full circle: know what the computer can do → script it → find it instantly.
