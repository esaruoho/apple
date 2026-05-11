# QuickTime Player Pro Automation — the complete Sal playbook

**Source:** WWDC 2003 #718 (Sal + Rhonda Stratton + Ryan Lynch) + WWDC 2004 #723 (Sal + Stephen Tonna + Ryan Lynch). Both sessions are scriptable-QuickTime master classes — the same architecture Sal taught carries through both years, with 2004 adding Tiger features + Automator integration.

> **Critical context for 2026:** the modern QuickTime Player (macOS 10.6+) has had its scripting interface **dramatically stripped** vs. QuickTime Player 7 Pro. Most of what's below works on **QT Player 7 Pro** ($29.99 license back in the day; still available as a free download from Apple's support archives if you have the right legacy macOS). Modern QT Player exposes only a tiny subset.

---

## Why automate QuickTime at all — Sal's four whys

> *"The QuickTime team and the AppleScript team focused on delivering core functionality that allows you to automate a lot of the repetitive things that you do with QuickTime content, such as applying annotations to 400 movies that are going to go up on the website. Done by hand, that's very tedious. Done with a script, it's go-get-a-donut."*

The four whys (codified WWSD #33):

- **Consistency** — every movie gets the same metadata, framing, settings
- **Accuracy** — no human typo across 400 files
- **Speed** — 400 movies in the time it takes to drink coffee
- **Scale** — the same droplet handles 1 movie or a folder-of-folders of 50,000

---

## The QuickTime Scripts Collection — ~150 scripts Apple shipped free

Downloaded from `apple.com/applescript` → Applications → QuickTime Player (2003-era URL; mirrored in `sources/sal/macosxautomation.com/` and Internet Archive). The collection breaks into three buckets.

### A) Applets — self-running scripts (.app icon)

Double-click → preferences dialog → close. Then you have a configured tool sitting in the Dock.

- **Add to Favorites**
- **Sample Audio CD** — rip+convert workflow
- **Display Folder as Slideshow** — instant browse without iPhoto

### B) Droplets — drag files/folders onto these (blue-arrow icon)

Recurse into nested folders automatically. Sal's signature pattern. Double-click to set preferences (stored in script's Finder comment field). Duplicate-and-rename to make presets ("internal use", "website", "CD use").

**Annotation droplets:**
- **Annotations Droplet / All Annotations** — set all 40 QT annotation fields
- **Annotations and Credits** — generates a rolling-credits front-pad from the annotations
- **Limited Annotations Droplet** — small subset, configured via Finder comment field (`product:value\nauthor:value\nperformers:value` syntax)
- **Clear All Annotations**

**Format/conversion droplets:**
- **Convert to QuickTime / Streaming Format**
- **Save as Uneditable** — locks the file so customers can't edit
- **Save as Hinted** — for streaming servers
- **Save in QuickTime Format** — re-mux to .mov

**Playback-property droplets** (these expose hidden properties NOT in the GUI):
- **Auto Play** — movie starts on open
- **Auto Close** — closes itself when done
- **Auto Quit** — quits the QT Player when done
- **Auto Present (Full Screen)** — opens full-screen
- **Set Controller Type** — none, default, VR
- **Set Window Position** — pixel-precise, persists in the .mov
- **Set HREF** — embed a URL in the movie file

**The HREF droplet is the secret weapon.** A movie can carry an HREF in its container. When the user views the movie in the right context, that HREF acts as a hyperlink. Combined with the `<self-present.move T<QuickTimePlayer>>` URL syntax embedded in HTML, you can write web pages where clicking opens a full-screen QT movie that closes itself when done — the user never touches the QT controls.

**Media Skins droplet (★ the showpiece):**
- Apply a custom-shape "skin" to a movie so it plays in a non-rectangular shape (plane flying through a "Q" shape, etc.)
- Manual process = 8-10 steps. Sal's `Apply Media Skin Droplet` collapses it to one drag.

### C) Script Menu scripts — ~100 of them

Install by dropping into `~/Library/Scripts/Applications/QuickTime Player/`. Show up in the system-wide Script Menu only when QT Player is frontmost.

- **Chapters:** Create Chapter Track / Add Chapter at Current Time / Rename Chapter / Delete Chapter
  - Sal: *"How do you add chapters into a movie? You shoot yourself. A more pacifist way would be to use AppleScript."*
- **Editing:** Cut Selection to New Movie / Copy Selection to New Movie / Edit Frame in Graphic Converter / Merge Front Movie into Second / Scale Front Movie to N%
- **Export:** Save Export Settings (.qtex files) ← the 2003 NEW feature, see below
- **Favorites manipulation**
- **HTML Embed Tag Wizard** — analyzes front movie, asks 3-4 questions, writes the `<embed>` HTML + copies to clipboard
- **Info:** Get Source URL of Streamed Movie / various property dumps
- **SMIL writers** — Sal: *"If you want to write XML but never got around to it"*
- **Track manipulation** — text tracks, video tracks, audio tracks
- **Position-precision scripts** — *"if you're anal-retentive like me"*
- **Thumbnail-link movie creator** — generates a 1-frame movie with HREF pointing back to the main movie, ready to embed in a web page

---

## Three Tiger-era new commands (WWDC 2003)

Sal made these the headline of WWDC 2003 #718:

### 1. `enter full screen` / `exit full screen` — smooth presentation

The problem: opening a movie full-screen lets the user briefly see the file loading. Ugly for client demos.

The fix:

```applescript
tell application "QuickTime Player"
    enter full screen with background color {65535, 65535, 65535}  -- white flash
    open file "Macintosh HD:Movies:demo.mov"
    play front movie
    -- wait
    close front movie
    exit full screen
end tell
```

Background flashes to your chosen color (white/black/red/teal/chartreuse), movie loads behind it, play, close, next. Sal: *"When you need to present to somebody who's got a wallet that has money in it."*

### 2. `current matrix` — get/set the 3×3 transform

Lets you skew, rotate, squeeze, flip movies programmatically.

```applescript
tell application "QuickTime Player"
    set m to current matrix of front movie
    -- m is a list of three lists of three numbers
    set current matrix of front movie to {{1.0, 0.0, 0.0}, {0.2, 1.0, 0.0}, {0.0, 0.0, 1.0}}  -- horizontal skew
end tell
```

The QT Scripts collection ships **Horizontal Squeeze** as a ready-made example.

Sal: *"You can literally go in and use AppleScript now to morph your movies into any kind of way that you want. The movie actually knows what it originally looked like, so you can really muck it up and get it back to normal."*

### 3. `save export settings` — the killer feature

The old workflow: AppleScript could only export "using a settings preset" — the named presets the QT GUI knew about. You couldn't dial in custom MP4 codec settings, save them, and reuse them via script.

The new workflow:

1. Open a movie, choose File → Export, configure ALL the codec options
2. Click Save, then Stop/Cancel the actual export (this sets "last used" in QT Player)
3. From AppleScript: `save export settings for the front movie for "MPEG-4" to file (...)`
4. You now have a `.qtex` file containing those exact settings
5. Reuse in batch scripts: `export front movie to file (...) using settings (file ".../classical.qtex")`

Ryan Lynch's **QuickTime Compression Helper** uses this: drag a folder of AIFFs → script presents a popup of all your saved `.qtex` files → pick "Bob-test 96K" → batch-encode all files with that preset.

Sal: *"You can basically set up your own poor man's version of Cleaner."* Ryan: *"I actually like to think of it as the smart man's version of Cleaner. The nice thing is this is yours."*

---

## AppleScript Studio + QuickTime.framework — calling the C API directly

When the AppleScript dictionary doesn't expose a verb, you can drop into Studio (now Xcode), load `QuickTime.framework` into your project, and use `call method` to invoke native C APIs.

The example Sal ships as the **Movie Player project** (`apple.com/applescript` → Applications → AppleScript Studio):

```applescript
-- AppleScript Studio calling QuickTime's IsMovieDone
on isMovieFinished(theMovie)
    return call method "IsMovieDone" of class "Movie" with parameter theMovie
end isMovieFinished
```

The Movie Player project bundles a wrapper library exposing:

- `getTimeValue` / `setTimeValue` — current playhead in time-units
- `getDuration` / `getTimeScale`
- `getBounds` / `getNaturalBounds`
- `rewindMovie` / `goToEnd`
- `isMovieDone`
- `getMainScreenBounds` — for full-screen positioning
- `setVolume`

The app bundles the movie file inside `Contents/Resources/movie/` — swap the file, the app plays the new movie. **Distribution pattern: bundle a movie inside an AppleScript Studio app to make a single-file presentation tool.**

Sal: *"Instead of waiting for a scripting addition to be written by a third party that you have to make sure is installed on every machine, you can now just call the calls directly yourself through AppleScript Studio."*

This is **the 2003 ancestor of JXA's 2014 `$.NSMovie` ObjC bridge.** Same idea, eleven years apart.

---

## Tiger-era additions (WWDC 2004 #723)

The 2004 session pulled the same demos forward to Tiger + previewed **Automator integration**.

### Automator + QuickTime: workflow recipes

Sal demos Automator (then in preview) controlling QT:

**Workflow 1 — Batch playback property setter:**
1. *Get Specified Files* (drag movies in)
2. *Set Movie Playback Properties* (auto-play=on, auto-close=on, auto-present=on)
3. Run

Result: all movies set to self-present full-screen and close themselves. Drop them on a customer's machine — they double-click and the movie plays without UI.

**Workflow 2 — Batch annotate + browse:**
1. *Get Specified Files*
2. *Add Movie Annotations* (delete existing, set copyright="Apple Computer", artist="...")
3. *Browse the Movies* — opens each in a web-interface preview
4. Run

**Workflow 3 — Remote broadcasting via QuickTime Broadcaster:**

Ryan Lynch's two-machine demo:
- Local machine: Automator workflow creates a Broadcaster settings file (.bsc)
- *Initiate Remote Broadcast* action sends the .bsc to Sal's IP via Apple Events
- Sal's QuickTime Broadcaster receives it, configures itself, starts broadcasting
- Local machine receives the stream

Requires **Remote Apple Events** enabled in System Preferences → Sharing on the remote machine + the user account configured.

**Marketing payoff:** "Drag a workflow → broadcast video from a Mac across the room without touching it."

### Frame-level scripting

The 2004 session showed **Typewriter Text Movie** — AppleScript creates a movie file from scratch by adding frames one at a time, with each frame's text styled programmatically:

```applescript
tell application "QuickTime Player"
    set newMovie to make new movie
    set textTrack to make new text track at end of tracks of newMovie
    repeat with i from 1 to count of words in "Hello World This Is A Test"
        make new text frame at end of frames of textTrack with properties ¬
            {text: (item i of words), duration: 60, ¬
             foreground color: {65535, 0, 0}, ¬
             background color: {0, 0, 0}, ¬
             default font: "Helvetica", default size: 36}
    end repeat
end tell
```

You can control: text content, duration, foreground/background color, font, size, justification, anti-aliasing, keys. **Every property of a text frame is gettable + settable from AppleScript.**

---

## The 2026-applicable subset (what still works)

Modern macOS (Sequoia 15.x, 2026) ships QuickTime Player X which has a **drastically stripped sdef** vs. QT Player 7 Pro. The 2003/2004 era scripts mostly don't work against the modern player.

**Still scriptable in modern QT Player X (verify against the sdef):**
- `play` / `pause` / `stop` / `start recording` (screen+audio)
- Basic file open
- Window position get/set
- Volume

**Lost / requires QT Player 7 Pro:**
- Annotations (40+ fields)
- Chapter manipulation
- Track-level operations (text tracks, frame-level scripting)
- HREF embedding
- Media skins
- `current matrix` get/set
- `save export settings` (.qtex)
- `enter full screen` / `exit full screen` with background color
- The 150-script collection's most-useful members

**The workaround in 2026:** for the things modern QT Player can't do, drop down to **`avconvert` / `ffmpeg`** for batch encoding, **`avtouch`** (or shell `mdls`) for metadata reads, and **AVFoundation via Swift one-liners** (Sal's 2003 `call method` pattern, recast as `swift -e '...'`) for the property-level surgery the modern AppleScript dictionary lost.

If you still have QuickTime Player 7 Pro installed (it runs on macOS 10.6-10.11; some users keep a legacy Mac for this exact reason), the 2003/2004 scripts work verbatim.

---

## Reusable patterns for the apple repo

- **Droplet-with-preferences (WWSD #38):** the config-in-Finder-comment + duplicate-and-rename pattern is portable to ANY repo. Renoise droplets, Logic droplets, Music droplets. Already used in the QT collection — generalize to other apps.
- **HREF embedding pattern:** for media files that should hyperlink, embed the URL inside the file's metadata, not in an external manifest. Survives copy/move/share. Still works for ID3v2 in MP3 (WXXX frame) and for video container metadata.
- **Save-settings-to-file pattern (.qtex precedent):** save user-tunable settings as small files in a known folder, present them as a popup in batch tools. Same pattern is reborn as **Shortcuts in macOS Sequoia** (Shortcut name = preset name). Reborn again as **`~/Library/Application Scripts/<bundle-id>/`** in WWDC 2012 #206.
- **`call method` bridge → JXA `$` bridge:** when the dictionary's verb set is incomplete, bridge to native code. 2003 = AppleScript Studio + `call method`. 2014 = JXA + `$.ClassName`. **The architectural pattern is identical, the syntax is what changed.**
