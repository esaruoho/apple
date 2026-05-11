# WWDC 2003 #718 — AppleScript and QuickTime

**Speakers:** Sal (main, 1:13:08), Rhonda Stratton (QuickTime team), Ryan Lynch (QT Compression Helper demo)
**nonstrict:** https://nonstrict.eu/wwdcindex/wwdc2003/718/

> **For the full QuickTime Pro automation playbook see `01-QUICKTIME-PRO-AUTOMATION.md`.** This file is the session-level bulletpoints.

## The four whys (WWSD #33)

> *"It basically came down to the same idea that affects every business: how do I get **consistency**? How do I get **accuracy**? How do I get **speed**? How can I **scale** what I do and stay competitive? Automation is the answer."*

## What's covered

### The QuickTime Scripts Collection (~150 scripts)
From `apple.com/applescript` → Applications → QuickTime Player. Three buckets:
- **Applets** — self-running (Add to Favorites, Sample Audio CD, Slideshow from Folder)
- **Droplets** (blue-arrow icon) — drag files/folders on (Annotations, Format conversion, Playback properties, HREF, Media Skins)
- **Script Menu scripts** (~100) — Chapters, Editing, Export, Favorites, HTML embed wizard, Info, SMIL writers, Track manipulation

### The droplet-with-preferences pattern (WWSD #38)
- Double-click droplet → preferences dialog → stored in script's Finder comment field (or inline)
- Drag files on → run with stored settings
- Need a preset? Duplicate-and-rename: "internal use", "website", "CD use"
- Finder comment is the config UI. Zero plists. Zero settings panes.

### Three Tiger-era new commands
1. **`enter full screen` / `exit full screen`** with background color — smooth presentations (color flash, load behind, play, close, next)
2. **`current matrix`** get/set — 3×3 transform matrix, skew/rotate/flip movies programmatically
3. **`save export settings`** — save your exact codec settings to `.qtex` files, reuse in batch

### AppleScript Studio + QuickTime.framework
- `call method` bridges from AppleScript into native QT C APIs
- Sal's **Movie Player project** — ships as downloadable Xcode project from `apple.com/applescript`
- Bundles a movie inside `Contents/Resources/movie/` — swap the file, app plays the new movie
- Wrapper library: `getTimeValue`, `setTimeValue`, `isMovieDone`, `getNaturalBounds`, `setVolume`, etc.
- **The 2003 ancestor of JXA's $ bridge (2014)**

### Ryan Lynch's QuickTime Compression Helper
- Drag folder of AIFFs → script presents popup of saved `.qtex` settings → pick one → batch-encode
- Sal: *"Poor man's version of Cleaner."* Ryan: *"Smart man's version of Cleaner. The nice thing is this is yours."*

## Sal's voice quotes

> *"All of our Droplets are designed to handle multi-layered folders of QuickTime content. So if you have a folder of 50 movies with other folders of 50 movies, just drag the whole thing on there and the script will parse it for you and recurse through each level."*

> *"AppleScript can now communicate directly with any system API or any framework, including the QuickTime framework. So all the commands that you wanted but you couldn't get to, you can now make yourself."*

> *"Instead of waiting for a scripting addition to be written by a third party that you have to make sure is installed on every machine, you can now just call the calls directly yourself through AppleScript Studio."*

## Marketing copy version

**Headline:** Take 150 ready-made QuickTime scripts. Drag a folder of 400 movies onto one of them. Go get a donut. Come back, all 400 are annotated, hinted, and ready for your client.

**Power features:** Hidden movie properties NOT in the GUI (auto-close, auto-quit, auto-present). HREF embedding so a movie file IS its own hyperlink. `current matrix` for programmatic transforms. `.qtex` codec presets for batch encoding. The `call method` bridge so AppleScript can reach into the native QuickTime C API directly.

**Audience takeaway:** if you process video for clients, AppleScript + QuickTime collapses your day-rate by 90%. Sal's pitch — *"go get a donut"* — is the literal economic claim.
