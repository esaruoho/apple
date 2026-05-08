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
