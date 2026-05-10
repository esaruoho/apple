# WWDC sessions — Sal Soghoian archive

> Apple's automation gospel, 2003–2016, as Sal preached it from the stage.

This directory contains every WWDC presentation we've identified Sal Soghoian in, along with their durable artifacts (PDFs where Apple posted them, Whisper-generated transcripts where they didn't). The 2003 sessions are the earliest primary-source spoken Sal in the entire archive — they predate the existing interview corpus (2012–2023) by 9 years.

## All known Sal WWDC sessions

| Year | # | Title | Co-presenters | Duration | Track | Status |
|------|---|-------|---------------|----------|-------|--------|
| 2003 | [306](2003-session-306-applescript-studio/) | AppleScript Studio | Tim Bumgarner, John Coelho | 56:30 | — | metadata + transcript + analysis |
| 2003 | [401](2003-session-401-applescript-update/) | AppleScript Update | Todd Fernandez, Tim Bumgarner, Chris Nebel | 58:53 | Application Frameworks | metadata + transcript + analysis |
| 2003 | [414](#wwdc-2003-414) | Making Your Carbon and Cocoa Applications Scriptable | Chris Nebel et al | — | — | *not yet archived* |
| 2003 | [623](2003-session-623-applescript-for-sysadmins/) | AppleScript for SysAdmins | (solo) | 1:14:11 | Enterprise IT | metadata + transcript + analysis *(unlisted on apple.com)* |
| 2003 | [718](2003-session-718-applescript-and-quicktime/) | AppleScript and QuickTime | Rhonda Stratton, Ryan Lynch | 1:13:08 | — | metadata + transcript + analysis |
| 2003 | [311](#wwdc-2003-311) | Automated GUI Testing | John Comiskey | — | — | *referenced; not yet archived* |
| 2012 | [206](2012-session-206/) | Secure Automation Techniques in OS X | Chris Nebel | 50:13 | — | metadata + transcript + analysis |
| 2014 | [306](2014-session-306/) | JavaScript for Automation | David Steinberg | 52:33 | Services | **PDF (204 pp)** + analysis |
| 2016 | [717](../wwdc2016-session-717/) | Introduction to Siri Shortcuts and AppleScript | — | — | *separate directory*; full transcript + analysis |

## How to get each one

### 1. The reliable source: nonstrict.eu's WWDC Index

Every session above has a `nonstrict.eu/wwdcindex/wwdc<year>/<num>/` page that contains:
- Title, speakers, duration, track, abstract
- Direct URLs to Apple's `devstreaming-cdn.apple.com` PDF and video assets (where Apple posted them)
- A Whisper-generated transcript inline on the page (older sessions; Apple-posted transcripts for newer ones)

Pattern: `https://nonstrict.eu/wwdcindex/wwdc<YEAR>/<SESSION>/`

Examples:
- https://nonstrict.eu/wwdcindex/wwdc2014/306/
- https://nonstrict.eu/wwdcindex/wwdc2003/623/

### 2. Apple-posted PDFs (when they exist)

Pattern: `https://devstreaming-cdn.apple.com/videos/wwdc/<YEAR>/<HASHED-PATH>/<SESSION>/<SESSION>_<slug>.pdf`

The hashed path is unguessable; get the URL from nonstrict.eu. We've already captured:
- `2014-session-306/306_javascript_for_automation.pdf` (204 pp, 2.9 MB)

Apple stopped posting PDFs for some years and never posted them for WWDC 2003.

### 3. Video — three tiers of access

**Tier A (public, easy):** Modern WWDC sessions (2014+) have public HD/SD MOV URLs on `devstreaming-cdn.apple.com` (the same hashed-path pattern as PDFs). Direct `curl` works.

**Tier B (public, HLS):** Older sessions (2012, 2013) have HLS streams on `devstreaming-cdn.apple.com/videos/wwdc/<HASH>/<NUM>/ipad_c.m3u8`. Download with `ffmpeg -i <m3u8> -c copy output.mp4`.

**Tier C (auth-gated):** Some sessions only have downloadable MOVs behind Apple Developer login at `developer.apple.com/services-account/download?path=...`. Requires a logged-in browser session (cookies → curl).

**Tier D (not available):** WWDC 2003 video was never republished on the modern CDN. Whisper transcripts on nonstrict.eu are the only durable record.

### 4. Transcripts

Two sources:
- **Apple-posted transcripts** for some 2014+ sessions (rare; usually only video, no transcript)
- **Whisper-generated transcripts on nonstrict.eu** for older sessions where Apple posted only audio/video. Quality is OK; expect proper-noun and homophone errors. Always flagged as machine-generated in the file headers.

To scrape: `curl -sSL https://nonstrict.eu/wwdcindex/wwdc<YEAR>/<NUM>/ | python3 -c '<HTML→text>'`, then locate the "may have transcription errors" marker and strip to footer.

## What's actually in each session — the one-paragraph summary

### 2003 Session 306 — AppleScript Studio
Sal opens with the "hands and fingers into the world" line. Tim Bumgarner walks through Studio 1.0→1.3 history, builds a **BatchProcessor** app from scratch on stage (drag-and-drop, pasteboards, data sources with `make new data column` + `append`, document-based save/load via `data representation` handlers), then demos **Studio 1.3's killer feature: every Cocoa object gets a `script` property** — buttons can dynamically swap their `onClicked` handler at runtime, and external apps can read/write these scripts. Closing: a **Settings Viewer Xcode plug-in written entirely in AppleScript** that aggregates build settings across targets and styles.

### 2003 Session 401 — AppleScript Update
Sal's QuarkXPress 6 + iTunes + allmusic.com vanity-discography demo carries the "1992 vision has not dimmed" framing. Todd Fernandez covers: new `.scptd` / `.app` **bundle formats** with persistent script attributes; **Script Editor 2** with Code Assistant, library window, history; **Folder Action Setup** app; **Script Menu enhancements** (per-app folders in `~/Library/Scripts/Applications/<AppName>/`); **GUI Scripting introduced with strong "last resort" caveats** — four hard limitations spelled out; **Image Events** as a faceless background app; **PDF Workflow** via `~/Library/PDF Services/` folder; newly scriptable iChat AV and Xcode. Chris Nebel closes with **"Carbon Scripting is Cocoa Scripting"** — Carbon apps can adopt Foundation/Cocoa Scripting with a one-line init.

### 2003 Session 623 — AppleScript for SysAdmins *(Sal solo — the masterclass)*
**The most concentrated dose of pure Sal in the entire 2003 archive.** No co-presenter. Opens with "AppleScript is the cocaine of programming" and "AppleScript is a peer to Aqua." Teaches the **five reference types** (nested, path, alias, POSIX, file URL) and the full **coercion matrix** between them. Then the query grammar: **finding by index** (positive, negative, descriptive, relative position, `some` for random); **finding by property** (whose / where its + comparison operators); **recursion via `entire contents`** ("we're civilized — bohemian but civilized"). Live demo of the **"cleaning and waxing in one motion"** principle — find + act in one line. Tours the Script Editor and Open Dictionary as exploration tools. Three "free, free, free" emphases.

### 2003 Session 718 — AppleScript and QuickTime
Sal frames automation with the **four whys: consistency, accuracy, speed, scale**. Walks through the **~150-script QuickTime collection** (applets, droplets, script-menu items) — particularly the **droplet-with-preferences pattern**: double-click for prefs dialog, prefs stored in Finder comment, duplicate-and-rename to create new presets. Demos **three new QuickTime API features**: `enter/exit full screen` for smooth presentations, `current matrix` (3x3 transform get/set) for movie geometry hacks, `save export settings` (`.qtex` files) for batch-encoder presets. Ryan Lynch demos his **QuickTime Compression Helper** built on `save export settings`. Closes with **AppleScript Studio + QuickTime framework** — uses `call method` to invoke native QuickTime API calls (`IsMovieDone`) from AppleScript, bundling the QuickTime.framework into the Studio app. The Movie Player project (downloadable from `apple.com/applescript`) is a fully functional player app written in AppleScript.

### 2012 Session 206 — Secure Automation Techniques in OS X
Sal + Chris Nebel pair-present the **bridge talk** between 2003 AppleScript Studio and 2014/2016 modern era. Sal opens with the four-scenario decomposition (personal automation / distributing scripts / app-to-app / attaching scripts) and the engineering brief (preserve functionality, transparent interaction, minimize developer churn). Personal automation runs unrestricted ("scripts written by you, executed by the system" — the structural defense of WWSD #1 under sandboxing). Distribution requires `codesign` + bundle ID + `chmod a-w` (signing invalidates self-writing applets — breaks the 2003 Finder-comment-as-config pattern for distributed droplets). Chris introduces **Apple Event Access Groups** (sdef-level `<access-group>` markup, shipped in Mountain Lion's Mail and iTunes) replacing the over-broad `temporary-exception.apple-events` entitlement with the granular `scripting-targets` dictionary entitlement. Attached scripts use `NSUserScriptTask` + three typed subclasses, running out-of-process from `~/Library/Application Scripts/<bundle-id>/` — a folder the host app can read/enumerate but **cannot write to**, making user-placed-file = consent the architectural invariant. Two candidate WWSD principles emerge: **#39 user-placed-file = consent** and **#40 some powers belong to the user, period** (the explicit decision that `send` in Mail is in no access group). The Mastered-for-iTunes Droplet aside ("used by hundreds of thousands of professionals worldwide") is Apple eating its own automation dogfood at production scale.

### 2014 Session 306 — JavaScript for Automation
Sal + David Steinberg announce **JXA** — JavaScript becomes a peer language to AppleScript in OSA. Mavericks→Yosemite automation arc (notifications, code-signing, dictation commands, JXA). Script Editor's tri-lingual Open Dictionary viewer (AppleScript / JavaScript / Objective-C). Flagship example: a Keynote batch-export script using `Application('Keynote')`, `$.NSProgress`, `Path()`, JavaScript's record-syntax for named parameters. Full analysis: [`2014-session-306/analysis.md`](2014-session-306/analysis.md).

### 2016 Session 717 — Introduction to Siri Shortcuts and AppleScript
Lives in [`../wwdc2016-session-717/`](../wwdc2016-session-717/). Sal's final WWDC before the October 2016 layoff. The full 524-line transcript is the basis for WWSD Tier 2 (principles #28–30) and is analyzed in `analysis/sal/wwdc2016-session-717-transcript-analysis.md`.

## Future archival targets

Sessions we know exist but haven't yet pulled:

- **WWDC 2003 #311** — Automated GUI Testing (John Comiskey). Referenced in 401 as the GUI-Scripting-as-testing companion session.
- **WWDC 2003 #414** — Making Your Carbon and Cocoa Applications Scriptable. Referenced in 401 as the "if you're a developer making your app scriptable" companion.
- **WWDC 2002 sessions** featuring Sal or Chris Espinosa on AppleScript (Chris presented the AppleScript Update sessions 1998–2002 per 401's "last five years" mention).
- **WWDC 2008–2011 sessions** — gap in the archive between 2003 and 2012/206. Sal was at Apple this entire window; he must have presented multiple sessions.
- **WWDC 2015 sessions** — between JXA (2014) and Shortcuts (2016).

## Conventions

- Each session has its own directory: `<year>-session-<num>[-slug]/`
- `metadata.md` — title, speakers, duration, description, index URL, any known media URLs
- `transcript.md` — Whisper-generated transcript scraped from nonstrict.eu (flagged in header as machine-transcribed)
- `analysis.md` — Esa's notes: what the session announces, key examples, WWSD-relevant quotes, reusability for the apple repo
- PDF slides stored as `<num>_<slug>.pdf` when Apple posted them
- MP4/MOV video gitignored per repo `.gitignore` policy; transcripts public, video local-only

## Why this archive matters

These nine identified sessions span 13 years of Sal at Apple (2003–2016). Together they document:

- **2003 (×4)** — AppleScript Studio era; automation as a peer dev platform; "AppleScript is a peer to Aqua"
- **2012** — automation surviving Mountain Lion's security tightening
- **2014** — JavaScript joins as a peer language; speakable workflows; dictation commands
- **2016** — Siri Shortcuts lands; Sal's final WWDC; **524-line valedictory transcript** with the AND-not-OR framing

The 2003 transcripts in particular are **the earliest primary-source spoken Sal in the entire WWSD canon** — they predate every existing interview source by 9 years and validate the cross-decade stability of the principles. Detailed proposed WWSD additions sourced to these transcripts: [`analysis/sal/wwsd-updates-from-2003-transcripts.md`](../../../analysis/sal/wwsd-updates-from-2003-transcripts.md).
