# Spotlight + Automation — The Final Sal Mile

> "The final Sal mile: should eventually work from Spotlight."
> Every script in this repo should be one Cmd+Space away.

## The 5 Paths to Spotlight

There are exactly **5 ways** to make automation reachable from Spotlight on macOS:

### Path 1: osacompile to .app (Best for AppleScripts)

Compile any `.applescript` to a standalone `.app` bundle. Spotlight indexes all `.app` bundles automatically via LaunchServices.

```bash
# Compile to app
osacompile -o /Applications/Apple-Workflows/Music-PlayPause.app scripts/workflows/music/music-playpause.applescript

# Verify Spotlight sees it
mdls -name kMDItemContentType /Applications/Apple-Workflows/Music-PlayPause.app
# -> "com.apple.application-bundle"

# Now Cmd+Space -> "Music PlayPause" -> Enter -> plays/pauses
```

**Critical:** The compiled `.app` must have a `CFBundleIdentifier` in its `Info.plist` for Spotlight to index it. `osacompile` does NOT add one by default. Fix with:

```bash
/usr/libexec/PlistBuddy -c "Add :CFBundleIdentifier string com.example.my-script" MyScript.app/Contents/Info.plist
```

Our `spotlight-export.sh` does this automatically.

**Naming matters:** `Music-PlayPause.app` becomes searchable as "Music PlayPause". Use descriptive names -- Spotlight matches on any word.

### Path 2: Shortcuts (Best for App Intents Width)

Every Shortcut is automatically Spotlight-indexed. No extra steps.

```bash
# Create a Shortcut that wraps an AppleScript
# Shortcuts app -> New Shortcut -> Add "Run AppleScript" action -> paste code
# Name it descriptively

# From CLI:
shortcuts run "Music PlayPause"

# From Spotlight:
# Cmd+Space -> "Music PlayPause" -> shows as Shortcut -> Enter
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
# File -> New -> Quick Action -> Add "Run AppleScript" -> Save

# Existing services on this Mac:
# ~/Library/Services/Convert to 320k MP3.workflow
# ~/Library/Services/Send Sample to Renoise.workflow
```

**Best for:** Context-dependent actions (selected files, selected text).

### Path 4: Automator Application (.app workflow)

Automator can save workflows as standalone `.app` bundles:

```bash
# Automator -> File -> New -> Application -> Add actions -> Save to /Applications/
# Spotlight indexes it like any other app
```

**Difference from Path 1:** Automator apps can chain multiple actions (AppleScript + shell + file operations) in a visual pipeline. Path 1 is pure AppleScript.

### Path 5: Shell Scripts via .app Wrapper

For bash/shell scripts that can't be pure AppleScript:

```bash
# Create a minimal .app that runs a shell command
osacompile -o /Applications/My-Tool.app -e 'do shell script "/path/to/script.sh"'
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

**Output:** `/Applications/Apple-Workflows/` -- one `.app` per workflow script, all Spotlight-indexed.

**What spotlight-export.sh does for each script:**
1. `osacompile` -- compile `.applescript` to `.app` bundle
2. Inject `CFBundleIdentifier` via PlistBuddy (required for indexing)
3. Set Spotlight comment from the script's description line
4. Register with LaunchServices via `lsregister`

**Naming convention:** `Finder-Copy-Path.app`, `Music-PlayPause.app`, `Safari-Current-URL.app` -- each word is a Spotlight search term.

## Spotlight Search Mechanics

Understanding how Spotlight finds things:

| What you type | What Spotlight matches |
|---------------|----------------------|
| `music play` | Any app with "music" AND "play" in name |
| `finder` | All Finder-related apps + the Finder itself |
| `dark mode` | `System-Events-Dark-Mode-Toggle.app` |
| `screenshot` | `System-Events-Screenshot-Area.app` + built-in Screenshot |

**Spotlight indexes these fields for .app bundles:**
- `kMDItemDisplayName` -- filename without .app extension
- `kMDItemCFBundleName` -- from Info.plist (if set)
- `kMDItemCFBundleIdentifier` -- bundle ID (required for indexing)
- `kMDItemComment` -- Spotlight comment (settable via Finder Get Info or AppleScript)

**Boost trick:** Set Spotlight comments on exported apps for better search:

```bash
# via AppleScript:
osascript -e 'tell application "Finder" to set comment of (POSIX file "/path/to/app" as alias) to "play pause toggle music"'
```

## Spotlight Troubleshooting

### Monitoring Indexing Progress

After `sudo mdutil -E`, Spotlight rebuilds the entire index. Here's how to track it:

```bash
# Quick status — is indexing still running?
mdutil -s /System/Volumes/Data
# "Indexing enabled." = done or idle
# "Indexing enabled. Scan in progress." = still working

# Watch the mds process — high CPU means still indexing
top -l 1 -stats pid,command,cpu | grep -E "mds|mdworker"
# mds_stores at 0% CPU = indexing complete

# Monitor indexing in real-time (Ctrl+C to stop)
while true; do
    indexed=$(mdfind "kMDItemContentType == 'com.apple.application-bundle'" 2>/dev/null | grep "/Applications/" | wc -l)
    workflows=$(mdfind "kMDItemContentType == 'com.apple.application-bundle'" 2>/dev/null | grep "Apple-Workflows" | wc -l)
    cpu=$(ps aux | grep "[m]ds_stores" | awk '{print $3}')
    echo "$(date +%H:%M:%S) | Apps: $indexed | Workflows: $workflows/109 | mds_stores CPU: ${cpu:-0}%"
    sleep 10
done

# Check Spotlight index size (growing = still indexing)
du -sh /System/Volumes/Data/.Spotlight-V100 2>/dev/null

# Count total indexed items
mdimport -L 2>/dev/null | wc -l

# Check what mds is currently doing (log stream)
log stream --predicate 'subsystem == "com.apple.spotlight"' --info --style compact 2>/dev/null | head -20
```

**How to know indexing is done:**
1. The progress bar in Spotlight (Cmd+Space) disappears
2. `mds_stores` CPU drops to 0%
3. `mdfind` returns your expected results
4. `/System/Volumes/Data/.Spotlight-V100` stops growing

### Diagnostic Commands

```bash
# Check indexing status for all volumes
mdutil -sa

# Check a specific volume
mdutil -s /System/Volumes/Data

# Search for an app by name
mdfind "kMDItemDisplayName == 'MyApp'"

# Search by bundle ID
mdfind "kMDItemCFBundleIdentifier == 'com.example.myapp'"

# Search for all apps
mdfind "kMDItemContentType == 'com.apple.application-bundle'"

# Count apps found in /Applications/
mdfind "kMDItemContentType == 'com.apple.application-bundle'" | grep "^/Applications/" | wc -l

# Inspect what Spotlight knows about a file
mdls /Applications/Safari.app
mdls -name kMDItemDisplayName -name kMDItemContentType -name kMDItemCFBundleIdentifier /path/to/app

# Force Spotlight to import a single file
mdimport /path/to/file

# Register an app with LaunchServices (makes it launchable)
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f /path/to/app
```

### The APFS Volume Problem (Real Bug, Hit March 2026)

**Symptom:** Spotlight can't find any installed apps. Only system apps (Calculator, Mail, etc.) appear. Has been broken for months.

**Root cause:** On APFS Macs, user data lives on a separate "Data" volume:

```
disk3s1 (System)  -> /              <- Indexing enabled (has /System/Applications/)
disk3s5 (Data)    -> /System/Volumes/Data  <- Indexing DISABLED
```

`/Applications/`, `~/`, and all user files are firmlinks to `/System/Volumes/Data/`. When indexing is disabled on the Data volume, Spotlight can't find anything the user installed or created.

**Diagnosis:**

```bash
# Check volume indexing status
mdutil -sa
# If you see "/System/Volumes/Data: Indexing disabled." -- that's the bug

# Confirm where /Applications/ lives
stat -f "%Sd" /Applications
# -> disk3s5 (Data volume)

# Check APFS layout
diskutil apfs list | grep -E "Volume|Role|Mount"
```

**Fix:**

```bash
# Step 1: Enable indexing on the Data volume
sudo mdutil -i on /System/Volumes/Data

# Step 2: Rebuild the index (old index is stale/empty)
sudo mdutil -E /System/Volumes/Data
```

Step 2 triggers a full re-index (15-60 minutes depending on disk size). The Mac may warm up and fans may spin. After completion, Spotlight finds everything again.

**What caused it:** Unknown -- possibly CleanMyMac, OnyX, a `sudo mdutil -d` command, or a macOS update gone wrong. The Data volume indexing state can be silently disabled without any user-facing warning.

**How to detect early:** If `mdfind "kMDItemContentType == 'com.apple.application-bundle'" | grep "^/Applications/" | wc -l` returns a suspiciously low number (single digits when you have hundreds of apps installed), check `mdutil -s /System/Volumes/Data`.

### osacompile Apps Not Appearing in Spotlight

**Symptom:** You compiled a `.applescript` to `.app` with `osacompile`, but Spotlight doesn't find it.

**Cause:** `osacompile` does not add a `CFBundleIdentifier` to `Info.plist`. Without a bundle ID, Spotlight may ignore the app even if LaunchServices can see it.

**Fix:**

```bash
# Add bundle ID
/usr/libexec/PlistBuddy -c "Add :CFBundleIdentifier string com.yourname.script-name" YourApp.app/Contents/Info.plist

# Register with LaunchServices
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f YourApp.app
```

### Other Common Issues

| Symptom | Cause | Fix |
|---------|-------|-----|
| Spotlight returns no results at all | Index corrupt or volume not indexed | `sudo mdutil -E /` to rebuild |
| Spotlight finds old/deleted files | Stale index | `sudo mdutil -E /System/Volumes/Data` |
| Specific folder not indexed | Folder in Spotlight Privacy exclusions | System Settings > Spotlight > Privacy, remove folder |
| `.metadata_never_index` file present | Prevents indexing of that directory | Remove the file: `rm /path/to/.metadata_never_index` |
| Apps in subfolder not found | LaunchServices didn't crawl subfolder | `lsregister -f /path/to/app` for each app |
| Spotlight slow after re-index | Normal during indexing | Wait 15-60 minutes for completion |

### Key Files and Paths

| Path | What |
|------|------|
| `/.Spotlight-V100/` | Spotlight index for root volume |
| `/System/Volumes/Data/.Spotlight-V100/` | Spotlight index for Data volume |
| `~/Library/Metadata/` | Per-user Spotlight metadata |
| `/System/Library/Spotlight/` | Spotlight importer plugins |
| `/usr/bin/mdutil` | Manage Spotlight indexes |
| `/usr/bin/mdfind` | Search Spotlight index |
| `/usr/bin/mdls` | List Spotlight metadata for a file |
| `/usr/bin/mdimport` | Import/test-import files into Spotlight |

## What 14 Apple Apps Do With CoreSpotlight

From the probe data, these apps link `CoreSpotlight.framework`:

App Store, Books, Calendar, Freeform, Mail, Maps, News, Notes, Photos, Podcasts, Reminders, System Settings, Tips, Voice Memos

They use Spotlight Index Extensions (`com.apple.spotlight.index`) to make their **content** searchable -- not just the app itself, but individual notes, emails, events, etc. This is deeper than what we need for workflow scripts, but it's the same infrastructure.

## Architecture: Where Scripts Live vs Where Apps Live

```
scripts/workflows/           <- Source of truth (.applescript files, in git)
    finder/
    music/
    ...

/Applications/               <- Spotlight-indexed apps (generated, local-only)
    Apple-Workflows/
        Finder-Copy-Path.app
        Music-PlayPause.app
        ...
```

The `.applescript` files are version-controlled. The `.app` bundles are generated artifacts -- like compiled binaries. Regenerate anytime with `spotlight-export.sh`.

## Sal's Vision Realized

Sal's Automator patent (US 7,428,535) described actions that are **discoverable by context**. Spotlight is the modern version of that vision -- instead of Automator filtering actions by data type, Spotlight filters by **intent expressed in natural language**.

The pipeline is now:
1. **sdef-extract.py** -- extract what's possible (dictionaries)
2. **workflow-gen.py** -- generate scripts that do real things (recipes)
3. **spotlight-export.sh** -- make them findable (Spotlight)

That's Sal's full circle: know what the computer can do -> script it -> find it instantly.
