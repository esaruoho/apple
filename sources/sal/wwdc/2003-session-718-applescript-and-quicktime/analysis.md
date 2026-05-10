# WWDC 2003 Session 718 — AppleScript and QuickTime (Analysis)

**Speakers:** Sal Soghoian (main, 1:13:08), Rhonda Stratton (QuickTime team, intro + Q&A traffic), Ryan Lynch (guest demo — QuickTime Compression Helper)
**Track:** unspecified

## Sal's framing — **the four whys of automation**

> *"The story of Apple scripting QuickTime is one of the real unsung success stories at Apple Computer… it basically came down to the same idea that affects every business is how do I get consistency? How do I get accuracy? How do I get speed? How can I scale what I do and make more money and stay competitive? And the answer in any business, whether it's in multimedia or whether it's print or whatever kind of business it is, it's automation is the answer."*

**Four whys**: consistency, accuracy, speed, scale. This is Sal's clearest operational answer to *"why automate?"* — and it's almost identical to his 2019 MTC and 2023 CCATP framings, twenty years later. The vision is **stable across two decades**.

## What Sal covers (the substance)

### 1. The QuickTime scripts collection (~150 scripts)

Apple ships, but you also download a curated bundle from `apple.com/applescript` → Applications → QuickTime Player. Categorized:

**Applets** (self-running, double-click):
- Add to Favorites
- Annotations Drop / All Annotations / Annotations and Credits / Limited Annotations / Clear All Annotations
- Convert to QuickTime / streaming format
- Slideshow from folder / Display folder as slideshow
- Sample audio CD

**Droplets** (drag-files-on, with blue arrow icon, recursive on folders):
- Playback property setters: auto-play, auto-quit, auto-close, full screen, double size, normal size
- Set href / set controller type / set window position
- Save as uneditable / save as hinted / save in various formats
- Media skin builder (the multi-step "Saturday morning cooking show" workflow, automated)

**Script Menu scripts** (~100 of them, install by dropping into `~/Library/Scripts/Applications/QuickTime Player/`):
- Chapter creation / edit / rename / delete
- Editing nuts-and-bolts: cut to new movie, copy selection to new movie, edit frame in Graphic Converter, merge front into second, scale to N%
- Export setting management (the new feature, see below)
- Favorites manipulation
- **HTML embed tag wizard** — analyzes the front movie, walks you through embed-tag generation, copies to clipboard
- Info scripts (source URL of front movie, etc.)
- Smile/S-MIL writers ("if you want to write XML but never got around to it")
- Track/text-track manipulation
- Position-set scripts ("for the anal-retentive")

### 2. The droplet-with-preferences pattern

> *"Each of these droplets, the ones with the blue arrow, are designed to be double-clicked, and you get a preference dialog. All of them have some kind of a dialog… and you can copy the script to keep a couple copies, rename it call one 'internal use,' call one 'website,' call one 'CD use,' and then based upon what you're going to do with your movie, you just drag it on there."*

The pattern:
- **Double-click the droplet** → preferences dialog → settings stored *inside the script* (sometimes in the Finder comment field of the droplet itself)
- **Drag files onto the droplet** → it runs the action with stored settings
- **Want a different preset?** Duplicate the droplet, rename, re-double-click to set new prefs.

No preferences window, no plist, no settings UI. *The Finder comment field IS the configuration UI.* Sal calls this out explicitly multiple times — config-by-duplicate-and-rename is the user model.

### 3. Three new QuickTime API features (the headline)

Sal builds the session around three new commands in the latest QuickTime player dictionary:

#### a) `enter full screen` / `exit full screen`

> *"For smoother presentation, what we've implemented is the ability to first set the monitor to a color, just a plain color that you want… and then we load the movie in behind it and then present the movie. When the movie's done, we close the movie, bring up the next one, play that, then close that one, then bring the screen back to normal."*

Background-color flash → load → play → close → next. Avoids the "movie loading" visible-stutter that plagued earlier presentations. **Critical for client-facing demos** ("when you need to present to somebody who's got a wallet that has money in it").

#### b) `current matrix` (get/set)

3x3 transform matrix on a movie. Get returns three lists of three numbers. Set with a similar list. Lets you skew, rotate, squeeze, flip programmatically from AppleScript. *"You can literally go in and use AppleScript now to morph your movies into any kind of way that you want."* Demo: horizontal squeeze stored in QuickTime Scripts collection.

#### c) `save export settings`

> *"Until now… you would have to say `using a settings preset`… we didn't have the ability in AppleScript to go into the options and really get at all the various settings… So what they've implemented is the ability to actually save an export setting."*

Workflow:
1. Open a movie, open Export, configure all options to taste, Save, then Cancel/Stop (no actual export yet — this just sets the "last used" settings in the QuickTime player)
2. From AppleScript: `save export settings for the front movie for "MPEG-4" to file <path>.qtex`
3. Reuse those `.qtex` files across batch operations

Ryan Lynch's **QuickTime Compression Helper** demo uses this: drag a folder of AIFFs onto the script → it presents a list of saved `.qtex` setting files → you pick "Bob-test 96K" or whatever → batch-encode with that preset.

Sal: *"You can basically set up your own poor man's version of Cleaner."* Ryan: *"I actually like to think of it as the smart man's version of Cleaner. Because the nice thing is this is yours. You customize it the way that you want."*

### 4. AppleScript Studio + QuickTime framework — **call method**

The last 10 minutes show a self-built **MoviePlayer** app — native Mac OS X app with custom controls, fade-in/fade-out, properties dialog, all in AppleScript Studio. The movie file lives inside the app bundle (`Contents/Resources/movie/`); swap it out and the app plays your movie.

Crucial piece: the QuickTime.framework is loaded into the Studio project. The script uses `call method` to invoke native QuickTime API calls:

```applescript
-- AppleScript Studio calling QuickTime's IsMovieDone
set movieIsDone to call method "isMovieFinished" of script ¬
    of window "MoviePlayer" with parameters {theMovie}
```

> *"AppleScript can now communicate directly with any system API or any framework, including the QuickTime framework. So all the commands that you wanted but you couldn't get to, you can now make yourself."*

The Movie Player project on `apple.com/applescript` includes a library of wrapper methods: get/set time value, duration, time scale, bounds, natural bounds, rewind, go to end, is movie done, main screen bounds, set volume.

### 5. The big architecture point

> *"Instead of waiting for a scripting addition to be written by a third party that you have to make sure is installed on every machine, you can now just call the calls directly yourself through AppleScript Studio and create a visual interface that determines what the user sees."*

Pre-Studio: if QuickTime didn't expose a verb in its sdef, you had to wait for someone to write a scripting addition (an OSAX) and install it on every target Mac. Post-Studio: ship a `.app` that bundles whatever framework calls you need. **AppleScript Studio collapsed the bus factor of automation extensions.**

## WWSD-relevant takeaways

- **The four whys** (consistency / accuracy / speed / scale) — stable across two decades, primary-source 2003.
- **Droplet-with-preferences pattern** — config UI via Finder comment + duplicate-and-rename. Should be in the WWSD principle list as an *operational* pattern.
- **`call method` bridge** — *"AppleScript should never be the ceiling"*. If the verb doesn't exist, call the framework directly. Architectural WWSD.
- **"Save export settings"** is the predecessor of every "save my settings as a preset" pattern in modern macOS workflows (Shortcuts, Automator presets, Logic templates).
- The collection-of-droplets-in-the-dock model is exactly the Loupedeck launcher model — *"have them in your dock as well… just have them there all the time."*

## Reusable for the apple repo

- The droplet-with-preferences pattern is directly portable to Renoise / Paketti workflows: drop a `.xrns` on a droplet, droplet has stored settings in its Finder comment (or `~/Library/Application Scripts/com.renoise.Renoise/<settings>.plist`).
- The `call method` bridge is the same pattern as Renoise's `os.execute` / `do shell script` chain — i.e., when the host language's verb set is incomplete, bridge to native code.
- The "QuickTime Compression Helper" pattern (browse saved presets via dialog, pick one, batch-apply) is a UX model worth cloning in `bin/sal-grand-export` for batch-export operations across exporters.
- The MoviePlayer project's bundle-the-asset-inside-the-app pattern is directly applicable to one-off "showcase" apps — e.g., a Loupedeck demo `.app` that bundles a tutorial video for the controller layout.
- HTML embed tag wizard is a generalizable pattern: **wizards as Apple Script** — walk the user through 4-5 questions, generate the boilerplate output. Worth a `bin/wizardize.py` skeleton.
