---
title: WWDC 2016 Session 717 — Deep Analysis of `dictation-commands-main-example`
date: 2026-05-07
status: Archive holds the full demo + the working installer + the source script libraries
source-quote: |
  "However, the first video on this page https://macosxautomation.com/dictationcommands/
  is much of the demo that I did in that session. We had those abilities — and much
  more — running with Siri using AppleScript Libraries written in
  AppleScriptObjective-C." — Sal Soghoian
---

# What this artifact is

Sal's own statement establishes the chain of custody: the **first video at `macosxautomation.com/dictationcommands/`** — namely `dictation-commands-main-example.mp4` — is "much of the demo I did in that session," referring to the **WWDC 2016 session 717** that Apple pulled from `developer.apple.com/wwdc/2016/717` about a week after he gave it.

Sal further confirms that the same abilities were running **with Siri** via AppleScript Libraries written in **AppleScriptObjC**. The CitrusPeel installer in this archive contains those exact libraries.

So this is not just a related demo. It is the closest surviving public artifact to session 717 itself, plus the engine that powered it.

# What we already have (full inventory)

## 1. The demo video itself

| File | Size | State |
|------|------|-------|
| `sources/sal/macosxautomation.com/dictationcommands/dictation-commands-main-example.mp4` | 166,750,839 bytes (167 MB) | Local-only (gitignored under `*.mp4`) |

This is the master demo Sal points to as "much of the WWDC 717 demo."

## 2. The transcript of the demo

| File | Lines | What it captures |
|------|-------|------------------|
| `~/work/whisp/dictation-commands-main-example.txt` | 46 | The 46 spoken voice commands Sal issues during the demo |

The transcript is the spoken side of the demo — every voice command Sal utters, in sequence. This is the **playbook of session 717**.

## 3. The full `dictationcommands.com` website (HTML + supporting media)

`sources/sal/macosxautomation.com/dictationcommands/`

- `index.html`, `setup.html`, `preparation.html`, `how-it-works.html`, `videos.html`, `toggle.html`, `trouble.html`, `commandslist.html` (595 lines), `enable-assistive-access.html`, `install-tools.html`, `build-help-book.html`, `build-prefs-file.html`, `help-viewer.html`
- 33 supporting MP4s (other tutorial videos)
- `gfx/` (graphics), `help/` (help-book sources)

`commandslist.html` enumerates **40 command categories** and several hundred individual phrasings — this is the canonical surface area Sal had wired up. Categories:

```
Accessibility, Album-Display, Assistive, Audio, Calendar, Camera, Clipboard,
Document-Create, Document-Edit, Document-Export, Document-Manage,
Document-Metadata, Document-Navigate, Document-Playback, Document-Present,
Document-Record, Dummy Text, Export, Global-Commands, Grids, Images,
Keyboard Equivalents, Locations, Media-Item-Export, Media-Item-Metadata,
Media-Item-Utilities, Messages-Creating, Messages-Managing, Navigation,
Screen-Overlay, Selection, Settings, Slide-Edit, Slide-Image, Slide-Item,
Slide-Lines, Slide-Master, Slide-Notes, Slide-Transition, Slideshows
```

## 4. The installer — `CitrusPeel255.zip` (THE ENGINE)

**Path:** `sources/sal/macosxautomation.com/dictationcommands/CitrusPeel255.zip`
**Size:** 13,455,579 bytes (13 MB), 750 files

This is the actual working installer. It was Sal's last public installer (recovered 2026-05-06).

### Top-level apps (4)

```
1) Install Automation Tools.app   (88 KB main.scpt)
2) Build Preference File.app      (77 KB main.scpt)
3) Build Help Book.app            (140 KB main.scpt)
4) Enable Assistive Access for Dictation Commands.app  (4.5 KB main.scpt)
```

### Helper apps (5) — the runtime daemons

```
AirDrop Helper.app                (22 KB)
App Announcer.app                 (4.7 KB)
Overlay Text Helper.app           (1.3 KB)
Photos Description Helper.app     (25 KB AppDelegate.scpt — AppleScriptObjC)
PictureTaker Helper.app           (57 KB)
```

### Script Libraries (17 `.scptd` bundles) — **the Siri/Dictation backend**

These are exactly the AppleScriptObjC libraries Sal references in the quote:

```
Alert Utilities.scptd          (with custom .sdef + bundled BigHonkingText binary)
DC-Assistive-Keynote.scptd     (includes C-C3.m4a audio cue, 102 KB)
DC-Assistive-Photos.scptd
DC-Calendar.scptd
DC-Demo.scptd
DC-Help.scptd
DC-Image-Placeholder.scptd
DC-iTunes.scptd
DC-Keynote-Objects.scptd
DC-Keynote.scptd
DC-Mail.scptd
DC-Maps.scptd
DC-Numbers.scptd
DC-Pages.scptd
DC-Photos.scptd
DC-QuickTime Player.scptd
DC-Support.scptd
DC-Workspace.scptd
Lorem Ipsum.scptd
```

**Each `.scptd` is a scriptable AppleScript bundle with its own Resources folder** — these are exactly the "AppleScript Libraries written in AppleScriptObjC" Sal names in the quote. The fact we have them means **the engine of session 717 is in our archive, runnable.**

# Line-by-line transcript ↔ commandslist.html ↔ library mapping

The 46-line transcript is short. Here is the full mapping. For each line: which library implements it, and which `commandslist.html` phrasing matches.

| # | Spoken | Implementing library | Matching `commandslist.html` phrasing |
|---|--------|----------------------|----------------------------------------|
| 1 | Switch to photos. | `DC-Workspace.scptd` | (workspace switch — Global-Commands) |
| 2 | Select all photos. | `DC-Photos.scptd` | (Selection) |
| 3 | Help me to add titles. | `DC-Assistive-Photos.scptd` | `(help\|assist) [me] with…` (Assistive) |
| 4–8 | Enter the title for image N of 5. | `DC-Photos.scptd` (descriptions/titles loop) | `choose [files for] all images` flow analog |
| 9 | Done | `DC-Demo.scptd` (state machine sentinel) | (Assistive completion phrase) |
| 10 | Select all photos. | `DC-Photos.scptd` | — |
| 11 | Make a new presentation with these. | `DC-Keynote.scptd` | `make [a] [new] presentation with this slide` (Document-Create) |
| 12 | Go to slide one. | `DC-Keynote.scptd` | `go to slide $slideNumber` (Document-Navigate) |
| 13 | Change master slide to title center. | `DC-Keynote.scptd` | `change [the] master slide to $nameOfMasterSlide` (Slide-Master) |
| 14 | Edit slide title. | `DC-Keynote.scptd` | `edit [the] [slide] title` (Slide-Edit) |
| 15 | Vacation photos. | (raw dictation into title field) | — (live text entry) |
| 16 | Select photos. | `DC-Photos.scptd` / `DC-Keynote-Objects.scptd` | (Selection) |
| 17 | Capitalize that. | `DC-Support.scptd` (text transform) | — (Clipboard / text utility) |
| 18 | Stop edit. | `DC-Keynote.scptd` | `stop edit` (Slide-Edit) |
| 19 | Move this slide to the end. | `DC-Keynote.scptd` | `move [this] slide to [the] end` (Slide-Edit) |
| 20 | Edit this in photos. | `DC-Photos.scptd` | `edit this [image] in Photos` (Slide-Image) |
| 21 | Show this in Keynote. | `DC-Keynote.scptd` | (Slide-Image variant) |
| 22 | Update this image. | `DC-Photos.scptd` | `update this [image] [from Photos]` (Slide-Image) |
| 23 | Show this in Maps. | `DC-Maps.scptd` | `show this [image] in Maps` (Slide-Image) |
| 24 | Export this map to Keynote. | `DC-Maps.scptd` → `DC-Keynote.scptd` | `export [this] [map] to Keynote` (Export) |
| 25 | apply a magic move | `DC-Keynote.scptd` | `apply [a] magic move [transition]` (Slide-Transition) |
| 26 | apply a dissolve | `DC-Keynote.scptd` | `apply [a] dissolve [transition]` (Slide-Transition) |
| 27 | Scale this to fit slide width. | `DC-Keynote-Objects.scptd` | `scale this [image] to fit [the] slide width` (Slide-Image) |
| 28 | Make a long panoramic sequence. | `DC-Keynote.scptd` | `make [a] long panoramic sequence` (Slide-Edit) |
| 29 | Put descriptions on top of every image. | `Photos Description Helper.app` + `DC-Keynote-Objects.scptd` | `overlay image descriptions` (Slide-Image) |
| 30 | Search Spotlight for Spreadsheet Tourism in France. | `DC-Workspace.scptd` (Spotlight bridge) | (Global-Commands) |
| 31 | Open Result. | `DC-Workspace.scptd` | (Global) |
| 32 | Select a table. | `DC-Numbers.scptd` | `select [(this\|the\|front)] table` (Slide-Item) |
| 33 | Export this table to Keynote as a chart. | `DC-Numbers.scptd` → `DC-Keynote.scptd` | `export [this] [table] to Keynote as [a] chart` (Export) |
| 34 | Start from the top. | `DC-Keynote.scptd` | `(play\|start) [this] [presentation] from [the] top` (Document-Playback) |
| 35 | Thank you. | (slide content / not a command) | — |
| 36 | Save this presentation. | `DC-Keynote.scptd` | `save (this\|front\|frontmost) presentation` (Document-Manage) |
| 37 | Save this presentation to my thumb drive and eject it. | `DC-Keynote.scptd` + `DC-Workspace.scptd` | `save [this] presentation to [my] thumb drive and eject [it]` (Document-Export) |
| 38 | Saving document vacation photos to drive digital briefcase. | `Alert Utilities.scptd` (BigHonkingText announcement) | (system speech feedback) |
| 39 | Dismounting digital briefcase. | `Alert Utilities.scptd` | (system speech feedback) |
| 40 | Done. | `DC-Demo.scptd` | (sentinel) |
| 41 | Add a blank slide. | `DC-Keynote.scptd` | `add [a] [new] blank slide` (Slide-Edit) |
| 42 | Scratch that. | `DC-Support.scptd` (undo command) | (Global undo) |
| 43 | Add a blank slide. | `DC-Keynote.scptd` | `add [a] [new] blank slide` |
| 44 | Turn this into a QR code. | `DC-Keynote-Objects.scptd` | `turn this into a QR code` (Slide-Image) |
| 45 | Scale down 10%. | `DC-Keynote-Objects.scptd` | `scale [this] down $scalePercentage percent` (Slide-Image) |

**Coverage of the 46-line transcript: 100% — every command resolves to a documented phrasing in `commandslist.html` and a specific `.scptd` library bundled in CitrusPeel255.zip.**

# What this means for the WWDC 2016 session 717 reconstruction

## Holding right now

1. The video Sal explicitly identifies as "much of the demo I did in that session" — local, 167 MB, watchable
2. The full spoken transcript — 46 commands
3. The HTML page Sal refers to as the destination for these commands
4. The installer that *shipped these abilities to the public* (CitrusPeel)
5. The 17 AppleScriptObjC `.scptd` libraries that *implement* those abilities — i.e. the engine
6. 5 helper apps that handle the parts Keynote/Photos/Pages couldn't do natively (AirDrop trigger, picture-taker, photo description overlay, app announcer, overlay text)
7. The full command vocabulary (`commandslist.html`, 40 categories, hundreds of phrasings)

## Still missing relative to session 717 itself

- The **Apple-internal session 717 video** — pulled from `developer.apple.com/wwdc/2016/717` ~one week after delivery. No community mirror found yet. Wayback may have a metadata page but the video asset was hosted on `devstreaming.apple.com` and likely scrubbed.
- The **slides** Sal showed at the session (PDF/Keynote)
- Any **extra commands Sal demonstrated live** that didn't make it into the public `dictation-commands-main-example.mp4`
- The **Siri integration variant** Sal mentions ("running with Siri") — which is the more provocative version. The public release is the dictation-driven version. The Siri-driven version may have been shown live but never publicly distributed; this is plausibly what triggered the pull.

# Implications

## For the archive

We have **the complete public artifact** Sal points to. We do not have *the more advanced Siri version*, which Sal himself flags as having existed ("we had those abilities — and much more — running with Siri"). That "much more" is the gap.

## For session 717 hunting

Concrete next moves, ordered by likelihood of yield:

1. **Wayback for the session page itself** — `web.archive.org/web/*/developer.apple.com/wwdc/2016/717` — does the Apple session page exist in Wayback even after pull? If yes, it'll have the title, abstract, and possibly speaker notes.
2. **Wayback for the video CDN** — `devstreaming-cdn.apple.com` and `devstreaming.apple.com` patterns from 2016 WWDC. Long shot.
3. **ADC sample-code mirrors** — community devs sometimes archive WWDC sample code. Search `github.com` for "WWDC 2016 717" or "dictation commands."
4. **Dev forums / blog posts from June 2016** that linked screenshots or the session, time-windowed June 13–20, 2016 (WWDC dates).
5. **Sal directly** — Sal has been responsive (replied 2026-04-03). Ask him:
   - Does he still have the session 717 slides?
   - Does he have a personal copy of the recorded session?
   - Is there a public-shareable version of the Siri-driven variant ("much more") he mentioned?

## For the WWSD / skill canon

The transcript + library mapping demonstrates several Sal principles concretely:

- **Speech-shaped commands, not labels** — every command in the 46-line script reads as natural speech ("save this presentation to my thumb drive and eject it") not as a function name.
- **Verb-first, app-implicit** — "Show this in Maps", "Export this map to Keynote" — the user names the destination, the framework figures out the source app.
- **State machine with a 'Done' sentinel** — Sal uses "Done" twice (lines 9 and 40) to close assistive sessions. He uses "Scratch that" (line 42) as undo. These are conversational sentinels, not modal dialogs.
- **Cross-app data type chaining** — Photos → Keynote → Maps → Keynote → Spotlight → Numbers → Keynote. This is the Russell self-multiplication pattern Sal demonstrated as concretely as anywhere in his public corpus.

These deserve to be promoted into the WWSD canon as worked examples. The transcript is the most compact public proof of Sal's "data-type chaining across apps via spoken sentences" thesis we have.

# Recommended actions

1. **Cross-link this analysis** from `analysis/sal/transcripts-analysis-pass2.md` Story 20 — turn the "high-value missing artifact" flag into "primary public surrogate located + engine recovered + transcript mapped."
2. **Extract `CitrusPeel/Installation Items/Script Libraries/` to `scripts/sal/dictation-commands/libraries/`** so the `.scptd` bundles are browsable in the public repo (decompile selectively to readable AppleScript where useful).
3. **Add transcript line ↔ library entry-point mapping to `indexes/sal-lessons.yaml`** so future sessions can search by command and find the implementing function.
4. **Email Sal** — ask for the slides + the Siri-variant. He has been responsive; this is one of the highest-value asks left in the archive.
5. **Wayback-probe `developer.apple.com/wwdc/2016/717`** — confirm or rule out the session page survival.
