# apple

### Apple Automation Architecture & Workflows — preserving the automation work Apple did not preserve institutionally, and continuing [Sal Soghoian's](sal-soghoian.md) vision.

[![macOS](https://img.shields.io/badge/macOS-Sequoia-000000?style=flat-square&logo=apple&logoColor=white)](https://www.apple.com/macos/)
[![AppleScript](https://img.shields.io/badge/AppleScript-Automation-blue?style=flat-square)](https://developer.apple.com/library/archive/documentation/AppleScript/Conceptual/AppleScriptLangGuide/introduction/ASLR_intro.html)
[![Built with Claude Code](https://img.shields.io/badge/Built_with-Claude_Code-blueviolet?style=flat-square)](https://claude.ai/)
[![License: MIT](https://img.shields.io/badge/License-MIT-green?style=flat-square)](LICENSE)

---

## What is this?

In November 2016, Apple eliminated the position of **Product Manager of Automation Technologies** — the role [Sal Soghoian](sal-soghoian.md) held for nearly 20 years. The person who built Automator, championed AppleScript, and believed *"the power of the computer should reside in the hands of the one using it"* was told his job no longer existed.

This repo picks up where that role left off.

> "It's very empowering to give somebody that ability to suddenly change the way they work and enable them to do great, complex things to grow their business." — Sal Soghoian ([WIRED, 2018](sources/sal/articles/wired-soghoian-automation-2018.md))

Apple did not preserve this material institutionally. This repo does: the scripts, the site corpus, the lesson structure, the downloads, the demo media, and the philosophy behind them.

**288 workflow scripts** across 31 apps. A four-stage pipeline that extracts what apps can do, writes scripts, makes them Spotlight-searchable, and creates Siri-speakable Shortcuts — all from a single Python run. Plus 121 auto-generated scripts from YAML dictionaries, a HomePod climate sensor bridge, and the full [10-tier automation atlas](automation-tiers.md) mapping every layer from AppleScript to IOKit.

## Sal Archive Layout

Sal source preservation now has a dedicated structure:

- [`sources/sal/`](sources/sal/) for verbatim site mirrors and manifests
- [`scripts/sal/`](scripts/sal/) for normalized runnable code extracted from Sal sites
- [`analysis/sal/`](analysis/sal/) for page notes, site maps, and concept notes
- [`analysis/sal/current-status.md`](analysis/sal/current-status.md) for the live archive dashboard and remaining-work list
- [`indexes/sal-sites.yaml`](indexes/sal-sites.yaml), [`indexes/sal-scripts.yaml`](indexes/sal-scripts.yaml), and [`indexes/sal-concepts.yaml`](indexes/sal-concepts.yaml) for machine-readable lookup data

Use this split to preserve original material while building reusable knowledge on top of it.

### Sal Interview Corpus — Six Talks, ~155 Minutes, 50 Stories

Six primary-source talks have been transcribed and analyzed. The full corpus is **~155 minutes of Sal in his own voice**, yielding **50 distinct stories** and a complete read of his method. Transcripts under [`sources/sal/transcripts/youtube/`](sources/sal/transcripts/youtube/); deep analyses at [`analysis/sal/transcripts-analysis.md`](analysis/sal/transcripts-analysis.md) and [`analysis/sal/transcripts-analysis-pass2.md`](analysis/sal/transcripts-analysis-pass2.md).

| Talk | Year | Length | Key new material |
|------|------|--------|------------------|
| TWiT MacWorld interview (Leo Laporte) | 2012 | 2.6 min | Berklee 1974-79, MIDI guitar, wife Naomi, Kevin Eubanks / Ralph Moore peers |
| MacVoices #17175 (Chuck Joyner) | 2017 | 31 min | Carpenter-father origin of "underlying principle" method, Command-D conference, Omni JavaScript thesis |
| TWiT — *The Accidental Apple Career* | 2018 | 5.5 min | The 1993 *"set color of current box to blue → Boing"* awakening, dropping all clients, hire #2 before Federighi |
| TWiT — *Standing Up to Steve Jobs* | 2018 | 7.7 min | Town Hall confrontation in full, the 1997 product manager bench (Weinstock, Ford, Zelinka), "people falling off the roof — splop!" |
| MTC2019 — *Insider's Look at APU* | 2019 | 50 min | *Insight = Perspective × Time*, the enterprise-strategy decode (GE/Salesforce/IBM/SAP), the attachment principle |
| ProGuide Episode 067 (Andrew J. Mason) | 2023 | 57 min | The Patton midnight email, code bounties, Lego Millennium Falcon payments, the killed Siri-on-Mac prototype, WWDC 2016 session 717 pulled |

**The most consequential single revelation** comes from the ProGuide interview: **Sal had a working Siri-on-Mac prototype with hundreds of natural-language voice commands** controlling all iWork apps + Photos + Finder. It was demoed to top execs to silent-then-applauding rooms and **killed because shipping it would have made iOS Siri look weaker.** Apple has been trying to ship exactly this product as "Apple Intelligence" for the last two years.

The **WWDC 2016 session 717** (Sal's dictation/automation talk) was **pulled a week after he gave it. Four months later his position was eliminated.** **Session 717 was recovered on 2026-05-07 from archive.org** — full 33-minute transcript at [`sources/sal/wwdc2016-session-717/717-transcript.txt`](sources/sal/wwdc2016-session-717/717-transcript.txt) (524 lines, titled *"Beyond Dictation: Enhanced Voice Control for macOS Apps"*). Three deep analyses cover the recovery: [`analysis/sal/wwdc2016-session-717-transcript-analysis.md`](analysis/sal/wwdc2016-session-717-transcript-analysis.md) (line-by-line of the recovered talk), [`analysis/sal/wwdc2016-session-717-deep-analysis.md`](analysis/sal/wwdc2016-session-717-deep-analysis.md) (CitrusPeel engine + public-surrogate cross-reference), and [`analysis/sal/wwdc2016-session-717-replication-plan.md`](analysis/sal/wwdc2016-session-717-replication-plan.md) (concrete steps to replicate the entire stack on current macOS). Best inference for why it was pulled: Sal's closing thesis *"voice is a peer to touch keys and cursor… it's only something that can happen on a Mac"* (line 515–519) directly contradicted Apple's upcoming Siri-on-Mac launch positioning for fall 2016.

The analyses derive **30 sourced "What Would Sal Do" (WWSD) principles** from primary-source spoken Sal — including the Carpenter Move (look for the underlying principle, sourced to his master-carpenter father), Observer + Participant simultaneously, Forward Motion with a paddle, Speak the Receiver's Language, Pay in What Cash Can't Buy, Authorization as Bridge, Identify the Trigger Phrases, **Procedural-vs-Task commands** (#28, session 717), **Voice as Peer Modality** (#29, session 717), and **the Seven-Purpose Framework** for when to build a voice command (#30, session 717). Full list in [`sal-soghoian.md`](sal-soghoian.md).

### Session 717 Replication — Hey Sal v1 (2026-05-08)

**The thing Apple killed in 2016 runs on macOS Sequoia, voice-driven.** Built end-to-end this session on top of the 2026-05-07 recovery.

**Architecture:**

```
Vocal Shortcut "Hey Sal" (Apple Silicon, System Settings → Accessibility → Speech)
  → Hey Sal Shortcut: Dictate Text → Run AppleScript (input wired to Dictated Text)
  → bin/sal-siri-match.py — fuzzy keyword matcher across 588 Sal commands + N user Shortcuts
  → matcher prefers user Shortcuts (USER_BOOST 1.5x), filters out broken Sal handlers
  → either runs user Shortcut via shortcuts CLI, or runs Sal handler via DC-XXX library
```

**~32 user Shortcuts in a `Sal Demo` folder** (Shortcuts.app sidebar) covering most of the WWDC 717 demo arc — all native-AppleScript bypassing broken Sal handlers:

- **Stage 1-2** (Photos, Keynote build): Switch To Photos, Select All Photos, Make A New Presentation, Add A Blank Slide, Go To First/Last/Next/Previous Slide, Save Front Document
- **Stage 5** (visual polish): Apply Magic Move, Apply Dissolve, No Transition
- **Stage 8** (misc): Duplicate Current Slide, Delete Current Slide, **QR This** (native CIQRCodeGenerator → Keynote insert), **QR My Clipboard**
- **Clipboard ↔ Slide**: Insert Clipboard To Slide Title, Insert Clipboard To Slide Body
- **System**: Display Wifi Network Name, Hide Other Applications, Open Documents/Pictures/Downloads Folder, Close All Finder Windows
- **Engine**: Hey Sal (the router), **Take My Picture** (native AVFoundation Swift binary, replaces Sal's broken IKPictureTaker)
- **Master orchestrator**: **Sal Demo Guide** — display-dialog walkthrough that prompts the user to speak each command via Hey Sal in sequence

**New Apple-native binaries** (zero third-party deps, Apple-shipped Swift compiler only):

- [`bin/sal-take-photo.swift`](bin/sal-take-photo.swift) — webcam capture via AVCaptureVideoDataOutput + CIImage. Self-bootstraps via swiftc on first run. Replaces Sal's 2016 PictureTaker Helper which on Sequoia opens the legacy IKPictureTaker avatar picker (flowers/yin-yang) instead of the camera.
- [`bin/sal-qr.swift`](bin/sal-qr.swift) — QR code generation via Core Image's CIQRCodeGenerator. Compile once, voice-trigger via "QR This" or "QR My Clipboard".

**Findings codified today:**

1. **Vocal Shortcuts storage** is `~/Library/Preferences/com.apple.Accessibility.plist` → key `AVSPreferenceKey` → bytes containing UTF-8 JSON array. Apple did not document this. Reverse-engineered from a live entry. Reader at [`bin/list-vocal-shortcuts.py`](bin/list-vocal-shortcuts.py); full schema at [`analysis/sal/vocal-shortcuts-storage-format.md`](analysis/sal/vocal-shortcuts-storage-format.md).
2. **Apple changed iWork bundle IDs** post-2016: `com.apple.iWork.Keynote` / `iWork.Pages` / `iWork.Numbers` are gone, replaced by `com.apple.Keynote` / `com.apple.Pages` / `com.apple.Numbers`. Sal's hardcoded-bundle-ID DC-Keynote / DC-Pages / DC-Numbers handlers always error -1728 ("Can't get application id"). The matcher now skips them (dead-bundle filter); native user Shortcuts replace them.
3. **macOS Sequoia removed the Custom Commands plist runtime** entirely — `com.apple.speech.recognition.AppleSpeechRecognition.CustomCommands.plist` is gone, no daemon reads it. Vocal Shortcuts (Apple Silicon only) is the canonical replacement.
4. **Audio input device drift** is the first thing to check when dictation appears broken. We spent 2 hours debugging TCC, plist formats, Sequoia bugs — actual cause was macOS listening to a non-microphone input. Codified as the global rule: query `system_profiler SPAudioDataType` BEFORE blaming software. See [`feedback_check_audio_input_first.md`](https://github.com/esaruoho/apple/blob/main/.claude-feedback-stub) (lives in `~/.claude/projects/.../memory/`).
5. **Vocal Shortcuts occupies a unique cell in the trigger-surface matrix** — the only Mac surface that is *simultaneously* hands-free, offline (on-device Neural Engine), latency-free, and **UUID-stable** across Shortcut renames. Every other voice path fails one of those: "Hey Siri + Shortcut name" needs the wake-word and matches by name (breaks on rename); manual Siri isn't hands-free; Spotlight/hotkey/Loupedeck aren't voice. Full surface-vs-surface matrix in [`analysis/sal/vocal-shortcuts-in-the-trigger-stack.md`](analysis/sal/vocal-shortcuts-in-the-trigger-stack.md).
6. **Shortcuts.sqlite is the other half of the binding**: `ZSHORTCUT.ZWORKFLOWID` (at `~/Library/Shortcuts/Shortcuts.sqlite`) is the UUID column that pairs with `associatedShortcut.type.siriShortcut.id` from `AVSPreferenceKey`. Confirmed empirically against both live entries. This is what makes the binding UUID-stable: renaming a Shortcut in Shortcuts.app does **not** break its Vocal binding — only its cached `associatedShortcut.name` drifts (cosmetic).
7. **Coverage gap on this Mac: 2 / 277 = 0.7%.** Only "Hey Sal" and "wheres olga" are bound. The structural bottleneck is the 3-rep per-phrase manual training requirement (no public API to install trained-audio models). The **single-phrase router pattern** ("Hey Sal" → matcher → N targets) is the bypass — collapses N trainings into 1.
8. **`siriRequest` and `accessibility` action kinds are still unobserved.** The schema doc lists them inferred-from-UI, but no live JSON example has been captured yet. Capturing a Voice-Control-toggle Vocal Shortcut would lock down the `accessibility` shape.

**New tool, built [`2026-05-11`]:** [`bin/vocal-shortcuts-suggest.py`](bin/vocal-shortcuts-suggest.py) — joins `AVSPreferenceKey` ↔ `Shortcuts.sqlite` ↔ [`seven-purpose-audit.md`](analysis/sal/seven-purpose-audit.md) and reports:

- **Orphans** — Vocal Shortcut binds a UUID no longer in `Shortcuts.sqlite` (or tombstoned). Binding will silently fail.
- **Drift** — cached `associatedShortcut.name` ≠ live `ZNAME`. Cosmetic; the binding still works.
- **Suggestions** — Shortcuts with no Vocal binding. `--audit-only` filters to fuzzy-matches against the 73 triple-channel audit candidates.

Modes: text (default), `--json`, `--write [PATH]` (markdown to [`analysis/sal/vocal-shortcuts-coverage.md`](analysis/sal/vocal-shortcuts-coverage.md)). Snapshots `Shortcuts.sqlite` + WAL/SHM to a temp dir before opening read-only so it doesn't fight the running Shortcuts.app for the WAL.

First reading on this Mac: **39 audit-matched candidates ready for binding** (`finder-compress-selected`, `system-events-wifi-toggle`, `mail-unread-count`, `homepod-climate-reading`, `system-events-screenshot-area`, et al.) — these are the highest-leverage next Vocal targets per Sal's seven-purpose framework.

**Build pipeline:**

| Stage | Tool | What it does |
|---|---|---|
| Engine | [`bin/dictation-commands-install.sh`](bin/dictation-commands-install.sh) | Copies 18 `.scptd` libraries to `~/Library/Script Libraries/` and 5 helper apps to `~/Applications/Dictation Helper Apps/` |
| Granular Shortcuts | [`bin/build-sal-demo-shortcuts.py`](bin/build-sal-demo-shortcuts.py) | Builds ~32 native-AppleScript user Shortcuts |
| Specials | [`bin/build-take-my-picture-shortcut.py`](bin/build-take-my-picture-shortcut.py), [`bin/build-sal-demo-guide.py`](bin/build-sal-demo-guide.py) | Take My Picture (AVFoundation binary), Sal Demo Guide (display-dialog walkthrough) |
| Folder organize | [`bin/organize-sal-shortcuts-into-folder.applescript`](bin/organize-sal-shortcuts-into-folder.applescript) | Creates `Sal Demo` folder in Shortcuts.app and moves all related Shortcuts into it |
| Matcher | [`bin/sal-siri-match.py`](bin/sal-siri-match.py) | Fuzzy keyword matcher: 588 Sal phrasings + auto-discovered user Shortcuts (5-min cache); USER_BOOST=1.5; dead-bundle filter |
| One-command installer | [`bin/install-sal-demo-library.sh`](bin/install-sal-demo-library.sh) | Builds → opens .shortcut files for batch import → runs folder organizer |

**Demo runbook**: [`analysis/sal/sal-demo-script.md`](analysis/sal/sal-demo-script.md) — printable script of 9 phrases to speak via Hey Sal that recreate the spine of WWDC 717 on a 2026 Mac.

### Sal Archive TODO

- [x] Mirror the main Sal sites into [`sources/sal/`](sources/sal/)
- [x] Extract inline AppleScript examples into [`scripts/sal/`](scripts/sal/)
- [x] Build machine-readable archive indexes in [`indexes/`](indexes/)
- [x] Recover linked ZIP bundles where the live site or Wayback still serves them
- [x] Keep recovered media local-only via `.gitignore` so large `.mp4`, `.m4v`, and `.mov` files can be processed later without bloating git history
- [x] Transcribe core Sal interviews — 6 talks (~155 min) committed under [`sources/sal/transcripts/youtube/`](sources/sal/transcripts/youtube/); deep analysis in [`analysis/sal/transcripts-analysis.md`](analysis/sal/transcripts-analysis.md) and [`analysis/sal/transcripts-analysis-pass2.md`](analysis/sal/transcripts-analysis-pass2.md)
- [ ] Continue transcription on the remaining Apple Podcasts episodes and YouTube interviews discovered by [`bin/sal-discover-interviews.py`](bin/sal-discover-interviews.py)
- [x] **Recover WWDC 2016 session 717** — recovered 2026-05-07 from archive.org, 524-line transcript at [`sources/sal/wwdc2016-session-717/`](sources/sal/wwdc2016-session-717/), three deep analyses written, three new WWSD principles (#28-#30) derived, replication plan drafted
- [ ] Hunt for any external trace of the **Siri-on-Mac prototype** Sal demoed pre-2016 (most important missing artifact in his career)
- [ ] Extract runnable scripts and assets from recovered ZIP bundles into curated lesson/example sets
- [ ] Finish the remaining missing package targets:
  - `macosxautomation.com/405/us/media/apple/applescript/2008/aperturepdfworkflows.zip`
  - `macosxautomation.com/applescript/apps/Script_Geek.zip`
  - `macosxautomation.com/applescript/apps/Script_Geek_old.zip`
  - `iworkautomation.com/numbers/PresidentsSQLiteDB.zip`
  - `photosautomation.com/installer.zip`
- [ ] Recover the last missing archived video:
  - `photosautomation.com/Photos-to-Keynote.mp4`
- [ ] Map every recovered artifact to a lesson in [`analysis/sal/lessons/`](analysis/sal/lessons/)
- [ ] Add transcript-aware metadata to the indexes so source page, ZIP, script, video, and lesson all cross-reference cleanly

### Sal Archive Call To Action

If you have any of these six missing artifacts from Sal's sites, please get in touch or open a PR:

- `macosxautomation.com/405/us/media/apple/applescript/2008/aperturepdfworkflows.zip`
- `macosxautomation.com/applescript/apps/Script_Geek.zip`
- `macosxautomation.com/applescript/apps/Script_Geek_old.zip`
- `iworkautomation.com/numbers/PresidentsSQLiteDB.zip`
- `photosautomation.com/installer.zip`
- `photosautomation.com/Photos-to-Keynote.mp4`

These are the remaining known gaps in the preserved Sal corpus. Local copies, old backups, mirrored conference kits, or archived installer folders could complete the record.

---

## The Pipeline

```
sdef-extract.py → workflow-gen.py → spotlight-export.sh → shortcut-gen.py
"what can apps do"  "write scripts"   "make findable"       "make speakable"
```

Each tool's output feeds the next. Add a recipe, run the chain, and it appears in Spotlight AND Siri automatically.

| Stage | Tool | What it does |
|-------|------|-------------|
| 1. Extract | [`bin/sdef-extract.py`](bin/sdef-extract.py) | Parse AppleScript dictionaries (sdef) into structured YAML |
| 2. Generate | [`bin/workflow-gen.py`](bin/workflow-gen.py) | 288 curated workflow recipes → `.applescript` files with teaching comments |
| 2b. Auto-gen | [`bin/auto-gen.py`](bin/auto-gen.py) | 121 additional scripts auto-generated from YAML dictionaries |
| 3. Export | [`bin/spotlight-export.sh`](bin/spotlight-export.sh) | Compile to `.app` bundles in `/Applications/Apple-Workflows/` for Spotlight |
| 4. Shortcut | [`bin/shortcut-gen.py`](bin/shortcut-gen.py) | Generate signed `.shortcut` files for Siri and Shortcuts app |
| 5. Import | [`bin/batch-import.sh`](bin/batch-import.sh) | Batch-import all shortcuts into Shortcuts.app with folder organization |

---

## 288 Workflow Scripts

Every script in [`scripts/workflows/`](scripts/workflows/) is a real automation — not just an app launcher. Skip a song, empty the trash, toggle dark mode, copy the current Safari URL, create a calendar event, check battery status, open System Settings panes.

Each script includes **teaching comments** that explain the AppleScript concepts used (tell blocks, error handling, notifications, shell scripts, etc.).

```
Finder ............. 28    Music .............. 37    System Events ...... 26
Safari ............. 15    Mail ............... 13    Calendar ............ 9
Reminders ........... 9    Photos .............. 9    Notes ............... 8
Keynote ............ 10    TV ................. 10    System Settings ..... 8
Terminal ............ 6    QuickTime ........... 6    Pages ............... 6
Numbers ............ 6    Automator ........... 5    Image Events ........ 5
Script Editor ....... 5    Screenshot .......... 4    Contacts ............ 4
Shortcuts ........... 4    HomePod ............ 11    Time Machine ........ 4
System Information .. 4    Disk Utility ........ 3    Console ............. 3
Preview ............ 4    Messages ............ 3    iMovie .............. 2
TextEdit ............ 5    Accessibility ....... 8    Hardware ............ 8
```

**v3.2:** Added 15 new apps: TV, Keynote, Pages, Numbers, Automator, Script Editor, Image Events, iMovie, System Information, Preview, System Settings, Disk Utility, Screenshot, Console, Time Machine. Plus Accessibility API (Tier 8) and Hardware/IOKit (Tier 10) scripts.

```bash
# Run any workflow directly
osascript scripts/workflows/music/music-playpause.applescript
osascript scripts/workflows/finder/finder-empty-trash.applescript
osascript scripts/workflows/system-events/system-events-dark-mode-toggle.applescript

# Generate all 288 scripts from recipes
python3 bin/workflow-gen.py

# Compile to Spotlight-searchable .app bundles
bin/spotlight-export.sh

# Generate Siri Shortcuts
python3 bin/shortcut-gen.py
```

### Auto-Generated Scripts (121 additional)

[`bin/auto-gen.py`](bin/auto-gen.py) reads the YAML scripting dictionaries and auto-generates workflow scripts for every safe no-arg command and readable property. It skips anything already covered by the 288 hand-curated scripts.

```bash
python3 bin/auto-gen.py              # Generate all 121 auto-workflows
python3 bin/auto-gen.py --app music  # Generate for one app
python3 bin/auto-gen.py --list       # Dry run — show what would be generated
```

Output: [`scripts/auto-workflows/`](scripts/auto-workflows/) — 121 scripts across 10 apps (Music: 69, System Events: 30, Finder: 6, Safari: 6, Photos: 4, QuickTime: 3, Messages: 2, Calendar: 1).

### Batch Import to Shortcuts.app

[`bin/batch-import.sh`](bin/batch-import.sh) imports all generated `.shortcut` files into Shortcuts.app, creates an "Apple Workflows" folder, and organizes everything automatically.

```bash
bin/batch-import.sh                    # Import all shortcuts
bin/batch-import.sh finder             # Import one app's shortcuts
bin/batch-import.sh --dry-run          # Show what would be imported
bin/batch-import.sh --count            # Count available shortcuts
bin/batch-import.sh --folder "My Name" # Custom folder name
```

---

## Unlocking Apple — Today's Build (2026-05-08)

The thesis of this repo, said plainly: **the apple repo is the keys to the kingdom for any Apple user.** Apple shipped 66 first-party apps with rich user data; the official scripting story stops at maybe a third of them. Today we made the surface durable across the rest.

Nine packages now exist, each one a `<name>-exporter` that turns a single Apple app into a markdown vault you can browse, grep, dedupe, and feed into Obsidian or any AI assistant — without copying media you already have, without any third-party dependency.

| # | Package | Surface | What we cracked | Live cardinality |
|---|---------|---------|---|---|
| 1 | [`notes-exporter`](notes-exporter/) | Notes.app SQLite + AppleScript | Folder → markdown vault, attachments + audio symlinks, Whisper transcription hook | (run when you want) |
| 2 | [`imessage-exporter`](imessage-exporter/) | chat.db | Per-contact link extraction, full conversation export, og: metadata enrichment | (run when you want) |
| 3 | [`reminders-exporter`](reminders-exporter/) | Reminders sdef (parallel-array fetch) | 23 lists / 520 active reminders → markdown by list folder | 2.0 MB vault |
| 4 | [`voice-memos-exporter`](voice-memos-exporter/) | CloudRecordings.db + m4a + **the `tsrp` atom** | 392 recordings, 13 with Apple-generated transcripts (English-only) embedded as JSON in the m4a trailer; ZFLAGS bit 3 marks them | 1.6 MB |
| 5 | [`safari-exporter`](safari-exporter/) | SafariTabs.db + CloudTabs.db + History.db | 6 windows / 2,477 open tabs / 20 tab groups / 2,886 bookmarks / 1,899 iCloud tabs / 52,442 history URLs. **`dedupe` subcommand** writes one .md per unique URL across all sources — 4,769 instances → 3,088 unique → 1,391 duplicated in 2+ places | 14 MB |
| 6 | [`stickies-exporter`](stickies-exporter/) | `.rtfd` + `textutil` | All 10 stickies, RTF colors parsed from `\colortbl`, .rtfd symlinks for round-trip in TextEdit | 40 KB |
| 7 | [`console-exporter`](console-exporter/) | `log` CLI + DiagnosticReports | Predicate-filtered queries (`--last 1h --process X --error`), 30 user + 136 system diagnostic reports indexed | (per query) |
| 8 | [`audio-midi-exporter`](audio-midi-exporter/) | `system_profiler SPAudioDataType / SPMIDIDataType` + `.mcfg` | 8 audio devices, 0 MIDI currently, 1 saved MIDI Studio config | <50 KB |
| 9 | [`image-capture-exporter`](image-capture-exporter/) | AVFoundation via `/usr/bin/swift` + `SPUSBDataType` | 3 cameras, iOS device detection, **`snap` writes a JPG via Swift+AVFoundation** (replaces Photo Booth's main job) | <20 KB |

Plus a meta-tool — [`bin/app-plist-probe.py`](bin/app-plist-probe.py) — that scanned every Apple-app plist (1,934 plists across 518 apps) and produced a 3,246-line survey at [`dictionaries/all-apps-plist-survey.md`](dictionaries/all-apps-plist-survey.md). It tells us which apps deserve a dedicated exporter without per-app probing.

### Two patterns codified today

**1. The Tier 5 dark back-door pattern.** Every "nearly dark" Apple app (no AppleScript dictionary, no App Intents, no URL scheme) is reachable via exactly one of three back-doors:

- **A CLI tool that's strictly more powerful than the GUI** — `log` for Console, `system_profiler` for Audio MIDI Setup and USB peripherals, `defaults` for menu-bar items, `tmutil` for Time Machine, `diskutil` for Disk Utility, `screencapture` for Screenshot, `mdfind` for Spotlight.
- **A framework call via `/usr/bin/swift` one-liner** — AVFoundation for cameras (Image Capture, Photo Booth), Core Audio + Core MIDI for device events, IOKit for hot-plug events.
- **The plist or filesystem store the app actually persists to** — `.rtfd` + textutil for Stickies, `~/Library/Preferences/com.apple.spaces.plist` for Mission Control, `~/Library/Containers/com.apple.clock/...mobiletimer.plist` for World Clock, `~/Pictures/Photo Booth Library/Pictures/*` for Photo Booth.

This means the only TRULY dark apps left in Tier 6 are **Launchpad** (no on-disk model of its grid) and **Time Machine for browsing backup content** (`tmutil` covers operations but not content). Mission Control was reclassified from Tier 6 to Tier 5 today because `com.apple.spaces.plist` exposes the full Monitor → Spaces tree.

**2. The exporter shape generalises.** Every package follows the same skeleton:

```
<name>-exporter/
├── README.md
├── .env.example          VAULT_PATH=~/work/apple/exported/<name>
├── .gitignore            (.env)
└── scripts/
    ├── <name>-exporter        bash wrapper
    └── <name>_exporter.py     argparse with subcommands status / list / export
```

Subcommands always include `status`, listing-style commands appropriate to the data shape, and `export` that writes a markdown vault under `~/work/apple/exported/<name>/`. Selector grammar is shared across packages (UUID prefix / title substring / `#N` / `latest`). Disk-lean by default: symlinks for media, full-text only for the small stuff. The whole pattern moved from "build" to "template-plus-customisation" within an afternoon.

### Disk math

The full exporter family running across all of Esa's archive:

```
exported/safari         14 MB    3,088 per-URL pages + windows + bookmarks + history
exported/voice-memos    1.6 MB   392 .md sidecars + 327 m4a symlinks (3.4 GB stays at Apple)
exported/reminders      2.0 MB   520 reminders across 19 list folders
exported/stickies       40 KB    10 sticky notes
exported/audio-midi     <50 KB   8 audio devices, 1 MIDI config
exported/image-capture  <20 KB   3 cameras + USB device list
exported/console        per-query
exported/notes          (run when you want)
exported/imessage       (run when you want)
─────────────────────────────────
total                   ~18 MB   for an archive that mirrors gigabytes of live Apple data
```

Symlinks make the difference. `voice-memos-exporter` ships with `.m4a` symlinks back into Apple's container by default (the audio never leaves Apple's protected directory; the vault stays tiny). Same trick for stickies' `.rtfd` and Audio MIDI's `.mcfg`.

---

## Roadmap to the Full Apple Experience

What's left to make this repo a **complete** unlock of every Apple-shipped app for any user. Ordered by impact × clarity-of-path. Each entry below is a future package or extension.

### Tier 1 priorities — ✅ ALL SHIPPED 2026-05-08

- [x] **`music-exporter`** — Music.app sdef (Tier 1) + 80,444 tracks / 147 playlists across the Library source. Subcommands: `status`, `playlists [--smart-only]`, `smart`, `tracks [--playlist NAME]`, `artists`, `albums`, `export [--with-tracks]`. Three AppleScript landmines worked around (playlists nest under sources; `count of tracks of playlists` raises -1727; `every X whose Y` raises -1700 on zero matches).
- [x] **`photos-exporter`** — `Photos.sqlite` (3.4 GB) `?mode=ro&immutable=1`. **77,033 assets / 4,787 albums (23 smart) / 51,234 with GPS / 585 favorites**. Subcommands: `status`, `albums`, `album <title>`, `keywords`, `places`, `favorites`, `export [--heads-only]`. Schema gotcha codified: album↔asset join is `Z_<N>ASSETS` where `<N>` changes with macOS version (auto-detected at runtime); `ZASSET.ZLATITUDE = -180` is the no-GPS sentinel.
- [x] **`mail-exporter`** — Envelope Index SQLite at `~/Library/Mail/V*/MailData/Envelope Index`. **331,866 messages / 72 mailboxes / 181,695 unique subjects**. Subcommands: `status`, `mailboxes`, `top-senders`, `subjects --match`, `search --sender --since --subject`, `export`. Top sender: Esa Ruoho (25,040, mostly self-Cc); Bandcamp (17,682); GitHub notifications (9,133).
- [x] **`calendar-exporter`** — `Calendar.sqlitedb` from the Group Container. **24 calendars / 9,457 events / 1.6 MB vault**. Subcommands: `status`, `calendars`, `events --since --until --calendar --match`, `upcoming -n N`, `export`. Per-calendar md + per-year md.
- [x] **`finder-exporter`** — Finder tags via `mdfind 'kMDItemUserTags == "*"'` + 232 .sfl3 LSSharedFileList lists. **865 tagged files** across ~24 unique tags. Subcommands: `status`, `tags`, `tag-files`, `recents`, `favorites`, `export`. (.sfl3 NSKeyedArchiver decoder needs the iwork-exporter v2 backport for proper recents.)
- [x] **`iwork-exporter`** — Pages / Numbers / Keynote in BOTH variants installed at `/Applications/`: regular iWork (App Store, `com.apple.iWork.*`, v14.5) AND Creator Studio (newer, `com.apple.*`, v15.2.1). Both have full sdefs. Recent docs from .sfl3 NSKeyedArchiver bplists shared across variants. **5 apps, 31 + 13 + 1 recent docs.** Ships the family's first proper .sfl3 UID resolver + a `resolve_bookmark.swift` Foundation helper that turns Apple bookmark blobs into resolved file paths.

### Tier 2 — everything else with a real sdef

- [ ] **`preview-exporter`** — recent docs, annotation history (109 plist keys + per-doc PDF metadata).
- [ ] **`podcasts-exporter`** — subscriptions + listening progress + downloaded episodes (105 plist keys + Podcasts SQLite under `~/Library/Group Containers/`).
- [ ] **`books-exporter`** — library + annotations + highlights (`~/Library/Containers/com.apple.iBooksX/Data/Documents/`).
- [ ] **`tv-exporter`** — same idea as Books for the TV app library.
- [ ] **`contacts-exporter`** — Contacts sdef + `~/Library/Application Support/AddressBook/AddressBook-v22.abcddb` SQLite. Already the back-door for the email/phone-number index Mail and Messages tap into.
- [ ] **`shortcuts-exporter`** — `shortcuts list` CLI + `~/Library/Group Containers/group.com.apple.shortcuts/...` per-shortcut plist data. Export every shortcut as readable markdown so AI assistants can study the user's automation library.

### Tier 5 dark — apply the back-door pattern

- [ ] **`disk-utility-exporter`** — wrap `diskutil list` / `diskutil info` / `diskutil apfs list` for catalog-style views of every drive, partition, APFS container, snapshot.
- [ ] **`activity-monitor-exporter`** — `ps`/`top`/`vmstat`/`iotop` snapshots into a vault. Combined with `ioreg` for hardware state.
- [ ] **`screenshot-exporter`** — wrap `screencapture` with named regions, scheduled captures, OCR via macOS Vision (Swift one-liner) → searchable markdown of every screenshot.
- [ ] **`photo-booth-exporter`** — `~/Pictures/Photo Booth Library/Pictures/*` + `Recents.plist` + AVFoundation `take`. We already have the take-photo Swift snippet from `image-capture-exporter`; this one just adds library cataloging.
- [ ] **`clock-exporter`** — `mobiletimer.plist` for World Clock cities + `defaults` for menu-bar clock prefs + alarms/timers if Mac Clock persists them.
- [ ] **`spaces-exporter`** (a.k.a. mission-control-exporter) — Mission Control's `com.apple.spaces.plist` per-monitor Space tree. Useful for "track how my workspace evolves over a month".
- [ ] **`system-settings-exporter`** — meta-package over `defaults` reads of every settings domain. Diff snapshots over time to see what changed.

### Tier 4 — URL schemes only

- [ ] **`facetime-exporter`** — recent calls if any persist; ContactsKit cross-reference.
- [ ] **`stocks-exporter`** — Stocks app's tracked tickers + alerts (Tier 4 URL scheme + plist).
- [ ] **`weather-exporter`** — saved locations + alert conditions (Tier 3 App Intents + plist).
- [ ] **`maps-exporter`** — saved locations + recent searches + favorite places + offline regions.

### Phase 2 across existing packages — write actions

- [ ] `voice-memos-exporter transcribe` — `whisp` wrapper for bulk Whisper transcription with `--lang fi/en` and chunked-mode for long recordings. Currently only Apple's transcripts (poor on Finnish) are extracted; Whisper is the real path.
- [ ] `voice-memos-exporter watch` — fswatch on Recordings/, auto-transcribe new m4a, Discord ping via pakettibot.
- [ ] `safari-exporter close-tab <selector>` — UI-script Safari to close a specific tab from a per-URL .md file.
- [ ] `safari-exporter consolidate --to-bookmarks` — for each duplicate URL in `_duplicates.md`, keep one tab in its themed group, bookmark the rest, close the rest.
- [ ] `stickies-exporter create / append / delete` — quit-Stickies-first-then-write, with `--write` confirmation flag.
- [ ] `reminders-exporter create / complete` — AppleScript via Reminders' sdef.
- [ ] `image-capture-exporter download-from-ios <device>` — ImageCaptureCore framework via Objective-C bridging.
- [ ] `image-capture-exporter watch` — IOKit DAEvents observer for USB attach/detach with hook command.

### Cross-package — the unified-vault layer ✅ SHIPPED 2026-05-08

- [x] **[`bin/apple-grand-search`](bin/apple-grand-search)** — unified ripgrep across every exporter vault. `apple-grand-search "Kortela"` returns 16 hits across voice-memos + safari + 11 other vaults, per-vault clustered. Falls back to `grep -r` when ripgrep isn't installed.
- [x] **[`bin/apple-grand-export`](bin/apple-grand-export)** — runs all 13 read-only exporters in dependency order. `--quick` skips the slow ones (mail / photos / music / finder). 9 exporters in 28s on this Mac. `--only`, `--skip`, `--dry-run`.
- [x] **[`voice-memos-exporter xref --calendar`](voice-memos-exporter/scripts/voice_memos_exporter.py)** — first cross-package xref. Matches each recording timestamp to ±N min Calendar events directly from Calendar.sqlitedb. Live: Lintuparvenkuja recording → "Esko" appointment at that street; Sahaajankatu → Weekly All-hands; Recording 169 → Daily Core Team. Same idiom should drop into `mail xref --calendar`, `photos xref --calendar`, `safari xref --notes`.
- [ ] **`apple-grand-stats`** — daily / weekly / monthly digest derived from all the per-package exports. Hours recorded today (Voice Memos), URLs visited (Safari history), reminders completed, Photo Booth captures, etc.

### Apple Intelligence + AI integration ✅ STUB SHIPPED

- [x] **[`bin/apple-summarize`](bin/apple-summarize)** — Foundation Models Swift framework wrapper. Auto-detects whether `LanguageModelSession()` instantiates (macOS 26+ ships the public API; macOS 15.6.1 has the framework header but the API is unavailable). Falls back to a rule-based heuristic bullet extractor that picks the most info-rich lines until macOS 26 lands. **Critical detection lesson** (codified in memory): test `LanguageModelSession()` instantiation, NOT `import FoundationModels` — the import succeeds on 15.6.1 but the API is `@available(macOS 26.0, *)`.
- [x] **[`bin/hey-sal`](bin/hey-sal)** — Sal's WWDC 2016 session 717 vision realised. Natural-language utterance → rule-based intent classifier (13 patterns) → exporter dispatch → optional `say` voice output. Live verified: "what did I record on Mauri Rantala", "when did I last visit forum.renoise.com", "what's on my calendar today" (returns today's actual 3 events: Joshua Paketti 1-on-1, VASU päiväkoti, äitienpiävän aamupala), "find email from kortela about pyrolysis", "show me my pages CVs", "take my photo". Six [`scripts/exporter-loupedeck/*.applescript`](scripts/exporter-loupedeck/) wrappers bind the same actions to physical buttons.

### Sal philosophy threading

- [ ] **The Cellular Trinity** — link each exporter to one of Sal's automation-architecture layers (URL schemes / AppleScript / Shortcuts / App Intents). Each package's README declares which layer(s) it operates at, so a contributor scanning the family understands the architecture as Sal designed it.
- [ ] **The Carpenter Move** — every exporter, in its README's "Phase 2" section, names the *underlying principle* it shares with at least one other package. This builds a navigable mesh of pattern-reuse rather than nine independent silos.

### Documentation

- [ ] **`automation-tiers.md` refresh** — promote Mission Control from Tier 6 to Tier 5 (already done in skill.md but not in the standalone file).
- [ ] **`exported/README.md` cardinality refresh** — auto-update the live numbers each time `apple-grand-export` runs.
- [ ] **`bin/app-plist-probe.py --diff`** — diff two snapshots of the survey to catch new apps / new keys after macOS updates. Run after each system update; commit the diff so the repo tracks Apple's evolution.

### Bootstrap ✅ SHIPPED

- [x] **[`bin/apple-bootstrap`](bin/apple-bootstrap)** — one-command setup for any cloning user. Verifies macOS + Python + ripgrep + swift; copies every `<name>-exporter/.env.example` to `.env` (skips existing); reminds about Full Disk Access; runs the plist probe; runs every read-only exporter via `apple-grand-export`; writes `~/work/apple/exported/INDEX.md` and opens it. `--check` (validates only), `--quick` (skip slow exporters).

### Status as of 2026-05-08

**21 user-runnable tools shipped today** (15 -exporter packages + 5 cross-package bin tools + the meta plist-probe). The Tier 1 list is fully green. The unified-vault layer is live. Hey Sal v0 routes natural language into the exporter family. The apple repo is — in a real sense — **what Sal would have built if Apple hadn't eliminated his role in November 2016.**

What's next: the [Hey Sal roadmap](dictionaries/hey-sal/hey-sal-roadmap.md) lists the longer-arc layers (BBS / Cloudcity integration, additional `xref` subcommands, cross-package `apple-grand-stats`, and the macOS 26 FoundationModels swap). The [WWSD-applied-2026-05-08](analysis/sal/wwsd-applied-2026-05-08.md) walks today's build through Sal's 30 sourced principles.

---

## Bulk Exporters — Reminders, Voice Memos, Safari, Stickies, Console, Audio MIDI, Image Capture

> **Convention**: every bulk exporter writes its vault into
> [`exported/<package>/`](exported/) under the repo. The `exported/`
> directory is gitignored (only its README is tracked) so cloning this
> repo never carries anyone's private data — but each contributor gets
> their own tooling-and-data side by side. Override the path per
> package via `<package>-export/.env` if you'd rather put your vault
> somewhere else.



Two read-only catalog/export packages that turn Apple data into clean
markdown vaults without copying audio or modifying Apple's stores. Same
pattern as the older [`notes-exporter/`](notes-exporter/) and
[`imessage-exporter/`](imessage-exporter/).

### [`reminders-exporter/`](reminders-exporter/) — 23 lists / 2,547 reminders

```bash
reminders-export lists                         # list every Reminders list + count
reminders-export export --lists Work,Home      # export specific lists
reminders-export export --all                  # everything in config.json
reminders-export export --include-completed
reminders-export status                        # last run / per-list counts
```

AppleScript-driven via parallel-array fetch. Worked around two
landmines on macOS 15.6.1: `«class isot»` ISO date coercion hangs
osascript indefinitely on Reminders objects (replaced with manual
year/month/day component assembly), and `id of <saved-list-variable>`
returns reference list rather than strings (use
`id of (every reminder of theList whose ...)` directly).

### [`voice-memos-exporter/`](voice-memos-exporter/) — 392 recordings / 98.6 hours

```bash
voice-memos-export list --audio                # codec, sample rate, channels, device
voice-memos-export list --with-transcripts     # only recordings Apple already transcribed
voice-memos-export stats                       # by-year + place clusters
voice-memos-export open "Mauri Rantala"        # in Voice Memos / QuickTime / Finder
voice-memos-export export --all --audio        # vault: 1.6 MB symlinks + sidecars
voice-memos-export transcripts                 # which recordings have Apple transcripts
voice-memos-export transcripts --extract --print "Jon C. Fox"
voice-memos-export transcripts --extract --all # write .apple-transcript.txt files
```

Voice Memos has **no AppleScript dictionary** (`sdef` errors -192).
Direct SQLite read of `CloudRecordings.db` + plain-m4a filesystem.

**The `tsrp` discovery (2026-05-08)**: Apple's auto-generated transcripts
are persisted to disk after all — appended to the .m4a file itself in a
custom trailer atom. ZFLAGS bit 3 (mask `0x08`) on `ZCLOUDRECORDING`
indicates presence; the m4a tail contains the ASCII marker `tsrp`
followed by an NSAttributedString JSON with time-aligned word runs. We
detect (13 transcripts on this Mac) and extract (with `[MM:SS]`
timestamps) without any UI scripting or Whisper. Quality is poor on
Finnish-mixed speech though — Apple's engine is English-only on macOS
15.6.1 — so use Whisper (`whisp --fi`) for real transcripts and keep the
Apple-generated ones for inventory + comparison.

Detail in
[`dictionaries/voice-memos/voice-memos-extraction-research.md`](dictionaries/voice-memos/voice-memos-extraction-research.md),
[`voice-memos-cli-feasibility.md`](dictionaries/voice-memos/voice-memos-cli-feasibility.md),
[`voice-memos-capability-map.md`](dictionaries/voice-memos/voice-memos-capability-map.md),
[`voice-memos-disk-lean-ops.md`](dictionaries/voice-memos/voice-memos-disk-lean-ops.md).

### [`safari-exporter/`](safari-exporter/) — windows / tab groups / open tabs / bookmarks / iCloud tabs / history

```bash
safari-export status                              # 6 windows, 2,477 tabs, 1,899 iCloud tabs, 52k history
safari-export windows                             # per-window tab-group breakdown
safari-export tabgroups                           # 20 named tab groups, by tab count
safari-export tabs --tabgroup "Free Energy"       # tabs in one named group
safari-export tabs --match 'kortela|grotz|tesla'  # regex over title + URL
safari-export tabs --domain youtube.com
safari-export bookmarks --tree --depth 3
safari-export icloud-tabs --device iPhone         # tabs from another device
safari-export history --last 7d --match russell
safari-export search "kortela"                    # tabs + bookmarks + history
safari-export export --with-history --history-days 90
```

Reads three SQLite stores in `?mode=ro&immutable=1`:
`SafariTabs.db`, `CloudTabs.db`, `History.db`. Never modifies Safari.

**Vault layout** (~`$VAULT_PATH`, default `~/safari-vault`):

```
INDEX.md                       navigation
windows/window-N.md            per window, tabs grouped by tab-group
tabgroups/<slug>.md            per tab group, full tab list (nesting preserved)
bookmarks/<topic>.md           per top-level folder, full nested tree
cloud-tabs/<device>.md         per remote device (RayMac, iPhone, …)
history/YYYY-MM.md             per month
```

**Schema gotchas** (encoded so future archaeology doesn't repeat
yesterday's): `bookmarks.type 0`=leaf, `1`=folder/tab-group, all in
one table. `windows_tab_groups.tab_group_id = 0` is the synthetic
bookmarks root — exclude or your window tab counts inflate by 1,300+
phantoms. `cloud_tabs.last_viewed_time` (not `last_modified`).
`history_visits.visit_time` (not `last_visit`). Top-level bookmark
folder filter needs `special_id = 0 AND num_children > 0` plus an
exclusion list of reserved system titles.

Detail in
[`dictionaries/safari/safari-extraction-research.md`](dictionaries/safari/safari-extraction-research.md).

### [`stickies-exporter/`](stickies-exporter/) — Tier 5 dark, unlocked via textutil

Stickies has no AppleScript dictionary, no App Intents, no URL
scheme. But every note is a `.rtfd` bundle in the app container, and
`textutil` (ships with macOS) converts to text / html / rtf.

```bash
stickies-exporter status                      # 10 stickies, 18 KB on disk
stickies-exporter list                        # UUID + title + char count + modified
stickies-exporter list --match 'tesla|beatty|manning'
stickies-exporter cat "Stubblefield"          # plain text
stickies-exporter cat 1ECCD6E3 --rtf          # raw RTF
stickies-exporter cat #0 --with-meta
stickies-exporter export --include-rtf        # markdown vault + .rtfd symlinks
```

Sticky background color and window position are NOT persisted to
disk; they're per-window UI choices in Stickies. Text and link
colors ARE in the `\colortbl` and surfaced in the .md frontmatter.

Detail in
[`dictionaries/stickies/stickies-extraction-research.md`](dictionaries/stickies/stickies-extraction-research.md).

### Tier 5 dark unlocked: Console, Audio MIDI Setup, Image Capture

These three apps have no AppleScript dictionary, no App Intents, no URL scheme. But each has a clean back-door — a CLI tool or framework call that's strictly more powerful than the GUI:

| Package | Back-door | Output |
|---------|-----------|--------|
| [`console-exporter/`](console-exporter/) | `log show` + `~/Library/Logs/DiagnosticReports/` | filtered log queries as markdown vault pages, diagnostic-report symlinks |
| [`audio-midi-exporter/`](audio-midi-exporter/) | `system_profiler SPAudioDataType` / `SPMIDIDataType` + `.mcfg` plists | audio.md / midi.md / configurations index |
| [`image-capture-exporter/`](image-capture-exporter/) | AVFoundation via `/usr/bin/swift` + `system_profiler SPUSBDataType` | cameras.md / ios-devices.md / scanners.md / `snap` JPGs |

```bash
console-exporter status                         # 30 user + 136 system diagnostic reports
console-exporter show --last 1h --error
console-exporter export --last 1d --process Safari --label safari-1d

audio-midi-exporter status                      # 8 audio devices + saved MIDI config
audio-midi-exporter audio --json
audio-midi-exporter export

image-capture-exporter status                   # 3 cameras + USB iOS / scanner enumeration
image-capture-exporter snap --camera FaceTime   # captures one JPG via Swift+AVFoundation
image-capture-exporter export
```

### Meta tool: [`bin/app-plist-probe.py`](bin/app-plist-probe.py)

Scans **every** Apple-app plist (`~/Library/Containers/com.apple.*/...` + `~/Library/Preferences/com.apple.*.plist`), decodes top-level keys, recursively unwraps `NSKeyedArchiver` blobs, and reports which apps actually persist user data worth exporting.

Live on this Mac: **1,934 plists across 518 apps; 576 with non-trivial user data across 481 apps.** Top hits: `mobilelogic` 635 keys, `logic10` 522, `Music` 461, `Safari` 156, `iMovieApp` 147, `Preview` 109, `podcasts` 105, `finder` 100. Full survey at [`dictionaries/all-apps-plist-survey.md`](dictionaries/all-apps-plist-survey.md) (3,246 lines).

Use it to:
- find the next exporter target without per-app probing
- grep across plist values: `bin/app-plist-probe.py --grep tesla`
- inspect one app: `bin/app-plist-probe.py --md --app keynote`

---

## HomePod Climate Sensor

Reads temperature and humidity from a HomePod's hidden sensor via the Shortcuts CLI, logs to JSONL, and serves a live dashboard.

```
HomePod sensor → Shortcuts app → shortcuts run CLI → bash script → JSONL log → live graph
```

```bash
cd homepod/
./homepod-climate.sh              # Single reading — log + graph
./homepod-climate.sh --stdout     # Print JSON only
./homepod-climate.sh --dump       # Show today's readings
./climate-summary.sh              # Daily min/max/avg
./start.sh                        # Continuous logger + dashboard server (port 3007)
```

Calibrated against a professional sensor (Feb 2026): +0.45C temperature, +4.5% humidity. Runs as a LaunchAgent every 10 minutes. See [`homepod/README.md`](homepod/README.md) for setup.

---

## GitHub Watcher — PR & CI Awareness

Monitors your open-source repos for PR and CI changes — macOS notifications + live dashboard. Same architecture as the HomePod climate sensor: periodic poll → state diff → notification → dashboard.

```
gh CLI (poll) → JSON state (diff) → display notification (alert) → Python server (dashboard)
```

```bash
cd github-watcher/
./github-watcher.sh              # Run once — notify on changes
./github-watcher.sh --stdout     # Print status to terminal
./github-watcher.sh --reset      # Clear state, start fresh
python3 prwhy.py                 # Strategic view — PRs grouped by pillar
python3 prwhy.py --all           # All watched repos
props                            # Interactive TUI — triage PRs with CI, rebase, builds
props 2373                       # Jump straight to PR #2373
props --status                   # One-line status overview (no TUI)
prbuild 2373                     # Trigger Mac DMG build for a PR
```

**`prwhy`** groups PRs by *what they advance*, not when they were created. Each project gets its own strategic pillars:

| Project | Pillars |
|---------|---------|
| **Apple** | Automation, Probing, Tools, Documentation |
| **Paketti** | Workflow, Instruments, Import/Export, UI, Bug Fixes |
| **CircuitJS1** | Simulation Accuracy, New Components, Visual/UX, Import/Export, Example Circuits |
| **LENR Academy** | Content, Discovery, UI/UX, Infrastructure |

Runs as a LaunchAgent every 10 minutes. Dashboard at `http://localhost:3008`. See `github-watcher/repos.json` to configure which repos to watch.

---

## The Automation Atlas — 66 Apps, 13 Layers

`bin/app-probe.py` extracts **13 layers of automation intelligence** from every Apple app in a single 60-second pass — the complete automation surface of macOS that no one else has mapped.

```
66 apps probed · 378 layer hits · 31 with scripting dictionaries
20 with App Intents · 35 with URL schemes · 11 with Services menu
```

### Tier 1: Fully Automatable (AppleScript + Intents + URL schemes)

These apps can be controlled from every angle — deep scripting, Shortcuts actions, Siri voice commands, and URL invocation.

| App | AppleScript | App Intents | URL Schemes | Services | Also |
|-----|:-----------:|:-----------:|:-----------:|:--------:|------|
| **Mail** | 16 cmds, 25 classes | 26 actions, 164 Siri phrases | `mailto:`, `message:` | 2 | 6 plugins, 6 notification actions |
| **Notes** | 2 cmds, 4 classes | 50 actions, **318 Siri phrases** | `applenotes:`, `notes:` | — | 5 plugins |
| **Finder** | 25 cmds, 32 classes | 16 actions, 67 Siri phrases | `file:`, `afp:`, `smb:`, `ftp:` +5 | 3 | 1 plugin |
| **Music** | 31 cmds, 26 classes | 23 actions, 123 Siri phrases | `music:`, `itunes:`, `itms:` +10 | — | 2 plugins |
| **Keynote** | 28 cmds, 22 classes | 2 actions | `com.apple.iwork.keynote-share:` | — | 1 plugin |
| **Numbers** | 16 cmds, 21 classes | 2 actions | `com.apple.iwork.numbers-share:` | — | 1 plugin |
| **Pages** | 11 cmds, 23 classes | 2 actions | `com.apple.iwork.pages-share:` | — | 1 plugin |
| **Reminders** | 1 cmd, 3 classes | 1 action | `x-apple-reminderkit:` | — | 5 plugins |
| **Shortcuts** | 1 cmd, 2 classes | 13 actions, 49 Siri phrases | `shortcuts:`, `workflow:` | — | 4 plugins |

**Notes is the Siri champion** with 318 phrases and 50 actions — Apple's most intent-rich app. Mail is the deepest overall with 10 automation layers active.

### Tier 2: Deep AppleScript, No Intents

Rich scripting dictionaries for programmatic control, but Apple hasn't added Shortcuts/Siri integration yet. These are the power user apps.

| App | AppleScript | URL Schemes | Services | Notes |
|-----|:-----------:|:-----------:|:--------:|-------|
| **System Events** | **31 cmds, 89 classes** | — | — | The deepest dictionary on macOS. UI scripting, processes, property lists, disk management. The Swiss army knife. |
| **TV** | 29 cmds, 16 classes | `com.apple.tv:`, `videos:` +5 | — | Full media library control |
| **Photos** | 18 cmds, 5 classes | `photos:`, `cloudphoto:` | — | Album/media management |
| **QuickTime Player** | 15 cmds, 5 classes | — | — | Recording and playback control |
| **Logic Pro** | 13 cmds, 12 classes | `logicpro:`, `applelogicpro:` | — | Track, region, and mixing automation |
| **iMovie** | 13 cmds, 12 classes | — | — | Project and event scripting |
| **Terminal** | 13 cmds, 4 classes | `ssh:`, `telnet:`, `x-man-page:` | 4 | The bridge between GUI and CLI |
| **TextEdit** | 13 cmds, 12 classes | — | 2 | Rich text automation |
| **Script Editor** | 16 cmds, 16 classes | `applescript:` | 3 | Meta: scripting the scripting tool |
| **Safari** | 10 cmds, 1 class | `http:`, `https:` +3 | 2 | Tab/window/URL control |
| **Calendar** | 8 cmds, 7 classes | `ical:`, `webcal:` | — | Event and calendar management |
| **Contacts** | 8 cmds, 12 classes | `addressbook:` | — | People data access |
| **Messages** | 3 cmds, 4 classes | `imessage:`, `sms:` +5 | — | Send/receive automation |
| **Final Cut Pro** | 1 cmd, 5 classes | — | — | Minimal sdef, mostly XML workflow |
| **Automator** | 16 cmds, 17 classes | — | 2 | Sal's creation, still scriptable |

**System Events** (31 commands, 89 classes) is the most powerful scripting dictionary on the platform — and it has zero Intents. It's the foundation for UI scripting everything else.

### Tier 3: Intents But No AppleScript

These apps went straight to Shortcuts/Siri without adding AppleScript. Modern automation — wide but not deep.

| App | App Intents | URL Schemes | How to automate deeper |
|-----|:-----------:|:-----------:|------------------------|
| **Freeform** | 23 actions, 144 phrases | `freeform:` | System Events UI scripting for board manipulation |
| **Books** | 27 actions, 125 phrases | `ibooks:`, `itms-books:` | URL schemes for navigation, Intents for library management |
| **Weather** | 6 actions, **149 Siri phrases** | `weather:` | Intents-only — "Hey Siri" is the primary interface |
| **Maps** | 16 actions, 17 queries | `maps:`, `map:`, `mapitem:` +4 | URL schemes are powerful: pass addresses, coordinates directly |
| **Preview** | 17 actions, 35 phrases | — | System Events for window/document control; `qlmanage` CLI for Quick Look |
| **Voice Memos** | 14 actions, 45 phrases | — | Intents for recording control; files in `~/Library/Group Containers/` |
| **Home** | 4 actions | — | HomeKit framework; `shortcuts run` for scene triggers |
| **Calculator** | 1 action | — | `python3 -c` or `bc` from Terminal. Calculator is a UI, not an API. |
| **App Store** | 1 action, 27 phrases | `itms-apps:`, `macappstore:` | URL schemes to open specific app pages |
| **News** | 1 action | `applenews:` | URL scheme to open articles; limited automation surface |
| **Tips** | 1 action, 8 phrases | `help:`, `x-apple-tips:` | URL scheme only |

### Tier 4: URL Schemes Only

Not scriptable, no Intents, but you can launch and navigate via URL.

| App | URL Schemes | Workaround |
|-----|:-----------:|------------|
| **FaceTime** | `facetime:`, `facetime-audio:`, `tel:` +3 | URL to call specific contacts. System Events for UI. |
| **Passwords** | `otpauth:`, `apple-otpauth:` +2 | OTP URL scheme. Keychain CLI: `security find-generic-password` |
| **Podcasts** | `pcast:`, `podcast:`, `itms-podcasts:` | URL to open specific podcasts. No scripting at all. |
| **Stocks** | `stocks:` | URL to open specific tickers. System Events for UI. |
| **Find My** | `findmy:`, `fmf1:`, `fmip1:` +2 | URL only. No scripting, no Intents. |
| **Font Book** | `fontbook:` | URL to open fonts. `atsutil` CLI for font management. |
| **Dictionary** | `dict:`, `x-dictionary:` | URL + Services menu ("Look Up in Dictionary"). |
| **Screen Sharing** | `vnc:` | 1 sdef command. `open vnc://host` from CLI. |

### Tier 5: Nearly Dark — Minimal Automation

These apps have almost no automation surface. The only way in is System Events UI scripting (click menus, press buttons by accessibility label) or CLI tools.

| App | What it has | The only way in |
|-----|-------------|-----------------|
| **Activity Monitor** | entitlements only | `top`, `ps`, `vm_stat`, `iostat` from CLI. The app is just a GUI for these. |
| **Audio MIDI Setup** | entitlements only | `system_profiler SPAudioDataType`, `coreaudiod`. The app is a GUI wrapper. |
| **Disk Utility** | entitlements only | `diskutil` CLI does everything the app does. `hdiutil` for disk images. |
| **Image Capture** | entitlements only | `system_profiler SPUSBDataType` for device detection. `sips` for image processing. |
| **Screenshot** | entitlements only | `screencapture` CLI. More flags than the GUI offers. |
| **Digital Color Meter** | entitlements only | System Events UI scripting or `colorpicker` third-party tools. |
| **System Settings** | 3 cmds, 2 classes + URL | `open "x-apple.systempreferences:..."` for specific panes. `defaults` CLI for all prefs. |
| **Photo Booth** | document types only | System Events UI scripting. `imagecapture` framework. |
| **Stickies** | document types + 1 service | "Make Sticky" service from any text selection. That's it. |
| **Console** | 1 sdef command | `log` CLI. `log show --predicate '...'` is more powerful than the GUI. |
| **Chess** | document types only | PGN file format. No scripting. |
| **Grapher** | document types only | GCX file format. System Events UI only. |
| **VoiceOver Utility** | document types only | `VoiceOver` CLI. Accessibility API scripting. |
| **Clock** | activity_types + plugin | Widget only. System Events or `date` CLI. |
| **Migration Assistant** | activity_types only | Not meaningfully automatable — it's a one-time wizard. |

### Tier 6: Completely Dark

| App | Layers | Reality |
|-----|--------|---------|
| **Launchpad** | 2 (frameworks, spotlight) | It's just a view of `/Applications`. Use `open -a` instead. |
| **Mission Control** | 2 (frameworks, spotlight) | `defaults write com.apple.dock` + `killall Dock`. Or keyboard shortcut via System Events. |
| **Time Machine** | 2 (frameworks, spotlight) | `tmutil` CLI does everything. `tmutil startbackup`, `tmutil listbackups`, etc. |

---

## The Pattern: Everything Dark Has a CLI

The key insight from the probe: **every "dark" app is a GUI wrapper around a CLI tool that's more powerful.**

| Dark App | Its CLI Equivalent | More Powerful? |
|----------|--------------------|:--------------:|
| Activity Monitor | `top`, `ps`, `vm_stat` | Yes |
| Disk Utility | `diskutil`, `hdiutil` | Yes |
| Screenshot | `screencapture` | Yes |
| Console | `log show` | Yes |
| Time Machine | `tmutil` | Yes |
| System Settings | `defaults` | Yes |
| Image Capture | `sips`, `system_profiler` | Yes |
| Launchpad | `open -a` | Same |
| Mission Control | `defaults write com.apple.dock` | Same |

**Sal knew this.** His "use the whole toolkit" principle (#6 from [WWSD](sal-soghoian.md)) — AppleScript is the hub, but chain with `do shell script` for anything the GUI can't reach. The CLI tools ARE the automation surface for these apps.

---

## Sal-Like Tools

Tools in this repo that follow [Sal Soghoian's automation philosophy](sal-like.md): one action, one result.

| Tool | Command | What it does |
|------|---------|-------------|
| [`ghc`](bin/ghc) | `ghc owner/repo` | Clone a GitHub repo + launch Claude Code + generate a permanent project skill. 7 steps -> 1. |
| [`ask`](bin/ask) | `ask` | Launch Claude Code + trigger macOS dictation simultaneously. AppleScript + CLI fusion. |
| [`app-probe`](bin/app-probe.py) | `python3 bin/app-probe.py` | Extract 13 automation layers from 66 apps in 60 seconds. The census Sal never had. |
| [`workflow-gen`](bin/workflow-gen.py) | `python3 bin/workflow-gen.py` | Generate 288 workflow scripts from curated recipes with teaching comments. |
| [`spotlight-export`](bin/spotlight-export.sh) | `bin/spotlight-export.sh` | Compile all workflows to Spotlight-searchable `.app` bundles. |
| [`shortcut-gen`](bin/shortcut-gen.py) | `python3 bin/shortcut-gen.py` | Generate signed Siri Shortcuts from AppleScript workflows. |
| [`auto-gen`](bin/auto-gen.py) | `python3 bin/auto-gen.py` | Auto-generate 121 scripts from YAML dictionaries. Fill the gaps. |
| [`batch-import`](bin/batch-import.sh) | `bin/batch-import.sh` | Import all shortcuts into Shortcuts.app with folder organization. |
| [`xpc-probe`](bin/xpc-probe.py) | `python3 bin/xpc-probe.py` | Map 2,359 XPC services — the hidden automation layer. |
| [`github-watcher`](github-watcher/github-watcher.sh) | `github-watcher.sh` | PR & CI awareness bot — polls repos, macOS notifications on changes. |
| [`prwhy`](github-watcher/prwhy.py) | `prwhy.py` | Strategic PR viewer — PRs grouped by project pillar with the WHY. |
| [`props`](github-watcher/props.py) | `props` / `props 2373` | PR Operations TUI — curses triage with CI polling, rebase, builds, conflict→Claude resolution. |
| [`prbuild`](github-watcher/prbuild.py) | `prbuild 2373` | Trigger Mac DMG build, watch, download. 9 steps → 1. |

---

## App Automation Probe

```bash
python3 bin/app-probe.py                    # All 66 apps, all layers
python3 bin/app-probe.py Mail               # Single app
python3 bin/app-probe.py --layer intents    # Only App Intents
python3 bin/app-probe.py --cli              # Include CLI tools
python3 bin/app-probe.py --list             # Show available apps
```

Output per app: `dictionaries/<app>/<app>-probe.yaml` + `<app>-probe.md`
Cross-app index: `dictionaries/_probe-index.yaml`

---

## Launcher Scripts

64 one-liner AppleScripts in [`scripts/launchers/`](scripts/launchers/) — one per Apple app. Use from Terminal, Loupedeck Live buttons, or any automation tool:

```bash
osascript scripts/launchers/activate-mail.applescript
osascript scripts/launchers/activate-logic-pro.applescript
```

---

## Thought Multiplier

**Type once, radiate to many, catch every rebound.**

A system built inside [Ray Browser](https://nicedayfor.ai/) that turns a single typed thought into 5 simultaneous outputs — archive, LLM refinement, web publish, email, and visual graph. Combines Ray's AI Agent (18 tools), Agent Scripter (visual pipelines), Studio (app factory), and local Phi-4 inference into a single multiplication pipeline.

Three lineages converge: **Sal Soghoian** (data type chaining), **Walter Russell** (RBI self-multiplication), and **BBS/Cloudcity** (the personal operating system).

```
Seed Capture → The Fork → 5 parallel branches → Rebound Dashboard
  (Studio)    (Agent Scripter)  archive/LLM/web/email/graph  (Studio)
```

| File | What |
|------|------|
| [`architecture.md`](thought-multiplier/architecture.md) | Full architecture + RBI mapping |
| [`studio-prompts.md`](thought-multiplier/studio-prompts.md) | Paste-ready prompts for Ray Studio |
| [`agent-scripter-pipeline.md`](thought-multiplier/agent-scripter-pipeline.md) | Agent Scripter JSON pipeline specs |
| [`studio-apps/`](thought-multiplier/studio-apps/) | Working HTML/CSS/JS for all 3 Studio apps |
| [`bin/thought-archive.py`](bin/thought-archive.py) | CLI archive manager |

---

## Deep Dives

| Document | What it covers |
|----------|---------------|
| [**Automation Tiers**](automation-tiers.md) | Full 10-tier stack: AppleScript → XPC → Accessibility → IOKit. Coverage matrix. |
| [**XPC Atlas**](xpc-atlas.md) | 2,359 XPC services mapped across 18 app categories. The hidden 87%. |
| [**Data Type Chaining**](data-type-chaining.md) | How apps pass data between each other. The Automator patent vision. |
| [**WWSD Decision Tree**](wwsd-decision-tree.md) | "What Would Sal Do?" — choosing the right automation approach. |
| [**Siri Phrases**](siri-phrases.md) | All 288 voice commands for generated shortcuts in a browsable table. |
| [**Compatibility**](compatibility.md) | Apple Silicon vs Intel, macOS version requirements. |
| [**Automator vs Shortcuts**](automator-vs-shortcuts.md) | 227 vs 246 actions. The gap analysis. |
| [**Spotlight Automation**](spotlight-automation.md) | 5 paths to make scripts Cmd+Space searchable. TCC fix for Sequoia. |
| [**Apple Driver's License**](apple-drivers-license.md) | The user knowledge layer: where your data lives, what you own vs. rent, what breaks when. |
| [**Loupedeck Guide**](loupedeck-guide.md) | Setup guide for Loupedeck Live, Stream Deck, and hardware controllers. |
| [**Thought Multiplier**](thought-multiplier/architecture.md) | BBS meets Ray Browser: type once, radiate to 5 destinations, catch every rebound. |
| [**How It Was Built**](how-it-was-built.md) | One conversation, 167 files — the build story. |
| [**App Probe Pitch**](app-probe-sal-pitch.md) | Why app-probe.py is the tool Sal would have killed for in 1997. |
| [**Video Script**](video-script.md) | Demo script for the "288 Workflows, One Pipeline" walkthrough. |
| [**iCloud URL Shortcuts**](https://esaruoho.medium.com/apples-icloud-services-quick-urls-and-future-improvements-67256b841809) | 12 working `x.icloud.com` direct-access subdomains mapped (2016, updated 2023). |

---

## Painpoints

UX evaluations by **[@esaruoho](https://github.com/esaruoho)** (Esa Juhani Ruoho) — software tester, UI enthusiast, amateur scripter, automation/workflow obsessive, and user experience evaluator. These are my takes on Apple's current state, reported one at a time: the missing bits and pieces where the automation surface fails the user. Filed with click counts, Sal's principles, and fix paths.

| ID | App | Issue | Status |
|----|-----|-------|--------|
| [PLATFORM-001](painpoints/PLATFORM-001-automation-fragmentation.md) | macOS | Automation splintered across 5 incompatible layers | Open |
| [SYSTEM-SETTINGS-001](painpoints/SYSTEM-SETTINGS-001-most-important-app-least-scriptable.md) | System Settings | Most-used app, least scriptable (3 commands) | Open |
| [PREVIEW-001](painpoints/PREVIEW-001-no-applescript-despite-being-default-viewer.md) | Preview | Default viewer with zero AppleScript support | Open |
| [HOME-001](painpoints/HOME-001-no-applescript-homekit-cli.md) | Home | No AppleScript, no CLI for HomeKit | Open |
| [PHOTOS-001](painpoints/PHOTOS-001-shallow-scripting-dictionary.md) | Photos | Shallow scripting dictionary (read-only) | Open |
| [MESSAGES-001](painpoints/MESSAGES-001-write-only-automation.md) | Messages | Write-only automation (can send, can't read) | Open |
| [NOTES-001](painpoints/NOTES-001-record-audio.md) | Notes | Recording audio should be one action, not five clicks | Open |
| [DISK-UTILITY-001](painpoints/DISK-UTILITY-001-no-scripting-for-disk-management.md) | Disk Utility | Zero scripting for the only disk management GUI | Open |
| [ACTIVITY-MONITOR-001](painpoints/ACTIVITY-MONITOR-001-no-scripting-for-process-management.md) | Activity Monitor | Zero scripting for process monitoring and management | Open |
| [TIME-MACHINE-001](painpoints/TIME-MACHINE-001-no-scripting-for-backups.md) | Time Machine | Zero scripting for the most critical data protection app | Open |
| [SCREENSHOT-001](painpoints/SCREENSHOT-001-no-scripting-for-screen-capture.md) | Screenshot | CLI is more powerful than the GUI, neither connects to Shortcuts | Open |

---

## Automator vs Shortcuts

[**The Gap Analysis**](automator-vs-shortcuts.md) — 227 Automator actions vs 246 Shortcuts actions. What each can do that the other can't. And the bridge that doesn't exist: Shortcuts has no `Run AppleScript` action, so 30 apps with rich scripting dictionaries are invisible to it. 36 apps have zero sdef. 20 apps have zero automation surface at all. The whole sausage.

---

## Live Automation via Claude Code

This repo isn't just scripts on disk — it's a **live automation surface**. With the Apple skill loaded, you can tell Claude what you want and it happens immediately:

```
You: "hide the desktop icons on my macOS"
Claude: runs `defaults write com.apple.finder CreateDesktop -bool false && killall Finder`
→ Desktop icons disappear instantly.

You: "show them again"
Claude: runs `defaults write com.apple.finder CreateDesktop -bool true && killall Finder`
→ Desktop icons reappear.
```

This works because the skill knows the `defaults` commands, `osascript` patterns, and CLI equivalents for dark apps. Every recipe in this repo — the 288 workflow scripts, the bash aliases, the CLI equivalents table — becomes something Claude can execute on demand, in natural language.

**What this unlocks:**
- No need to remember command syntax — just describe what you want
- Claude chains multiple commands when needed (toggle dark mode + hide dock + set wallpaper)
- The [bash aliases](bash-aliases.md) and [workflow scripts](scripts.md) serve as Claude's playbook
- Every "dark app" CLI equivalent (see table above) is directly invocable

This is Sal's vision realized differently: instead of Automator's drag-and-drop, you get **natural language automation** backed by the same AppleScript and CLI toolkit.

---

## How It All Connects

[**From Publishing Consultant to Patent to This Repo**](sal-career-to-code.md) — the cross-analysis tracing Sal's career arc through the Automator patent to what this repository builds. Publishing automation in the 1990s -> Automator at Apple -> context-aware relevance filtering -> scripting dictionaries -> departure -> this repo as open-source continuation.

---

## A Note to Sal

Sal, if you ever find this: hello. My name is Esa Ruoho. I'm a software tester and workflow obsessive from Finland. I've been studying your work — the sites, the talks, the patent, the philosophy — and building on it in the open.

This repo contains a [detailed profile of your career and thinking](sal-soghoian.md), sourced from your own websites, your MacStories piece, the Omni Show, the Rebooting interview, and your 2018 conversation with Allison Sheridan and Ray Robertson on Chit Chat Across the Pond. Everything is attributed. Everything links back to you.

I've also been cataloguing your websites — [macosxautomation.com](http://macosxautomation.com), [iworkautomation.com](http://iworkautomation.com), [photosautomation.com](http://photosautomation.com), [configautomation.com](http://configautomation.com), [dictationcommands.com](http://dictationcommands.com), [omni-automation.com](http://omni-automation.com), and [cmddconf.com](http://cmddconf.com) — because they represent decades of automation knowledge that exists on self-hosted infrastructure with no institutional backing. You said it yourself: *"Many times I put those examples up there for me so that I can go back later on."* We'd like to make sure those examples stay findable — for you and for everyone else.

**What this repo does with your legacy:**

- Your 10 automation principles ([WWSD](sal-soghoian.md#what-would-sal-do--the-10-principles)) guide every script we write
- Your Automator patent's data-type-chaining concept is realized as a [lookup table](data-type-chaining.md) across 31 apps
- Your iWork scripting dictionaries (which you wrote at Apple) are extracted, structured, and paired with 288 runnable workflow scripts
- Your "everyone can automate" philosophy drives the pipeline: one command generates scripts, compiles them for Spotlight, and creates Siri Shortcuts — so the barrier to automation keeps dropping
- Your iWorkAutomation.com examples are being cross-referenced with our machine-readable dictionaries to create the complete picture you always intended: human-readable pedagogy on top of structured data

You said: *"The power of the computer should reside in the hands of the one using it."* You also said: *"Everything I've been able to accomplish in my life is because of others and their generosity and them blazing the path and helping me. And I have a responsibility to return that kindness."*

This repo is that responsibility being returned. If anything here misrepresents your work or your wishes, please reach out — I'll fix it immediately. But I believe you'd approve of making automation knowledge more accessible. That's what you've been doing your whole career.

*"If I have seen further, it is by standing on the shoulders of giants."* — Isaac Newton

— [Esa Ruoho](https://github.com/esaruoho) ([@esaruoho](https://github.com/esaruoho))

---

## About

**Esa Ruoho** — user automation practitioner, software developer, musician (30+ albums, 203 gigs, 20 countries), and workflow optimizer. Works at [Ray Browser](https://raybrowser.com). Creator of [Paketti](https://github.com/esaruoho/paketti) (3,022-feature workflow suite for Renoise). Believes automation is a right, not a feature.

Built with [Claude Code](https://claude.ai/) and a custom [Apple skill](https://github.com/esaruoho/esa-skills).

Inspired by **Sal Soghoian** — Apple's Product Manager of Automation Technologies (1997-2016), co-inventor of Automator ([US Patent 7,428,535](patents/US7428535-analysis.md)), and the person who proved that the power of the computer should reside in the hands of the one using it. [Read the full profile ->](sal-soghoian.md)

---

*The power of the computer should reside in the hands of the one using it.*
