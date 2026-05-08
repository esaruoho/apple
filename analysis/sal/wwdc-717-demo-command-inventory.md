---
title: WWDC 717 / dictation-commands-main-example — Demo Command Inventory
date: 2026-05-08
purpose: Map every command Sal uttered in his two demos to (a) the chained workflow they belong to, (b) the implementation status today on Esa's Sequoia M3 Pro, (c) what we need to build to fill gaps
sources:
  - sources/sal/wwdc2016-session-717/717-transcript.txt (lines 277-475 = the embedded demo)
  - ~/work/whisp/dictation-commands-main-example.txt (the 46-line public surrogate)
---

# The demo arc — one continuous workflow

Sal didn't demo random commands. He performed **one coherent end-to-end workflow** that takes photos from a Rhône River trip, builds a Keynote presentation, integrates Maps and Numbers data, polishes it visually, saves to a thumb drive — all by voice, no mouse, no keyboard.

The arc has 8 stages, 46 spoken commands. Below: every command, what it does, and what works today.

# Stage 1 — Photo titling (assistive walkthrough)

| # | Spoken | What it does | Today |
|---|--------|--------------|-------|
| 1 | "Switch to photos" | Foreground Photos.app | ✅ "Switch To Photos" Shortcut works |
| 2 | "Select all photos" | Cmd-A in Photos | ⚠ Sal handler exists; not yet user Shortcut |
| 3 | "Help me to add titles" | Modal: prompts user for title image-by-image | ❌ Assistive flow needs custom build |
| 4-8 | "Enter the title for image N of 5" / dictated title | Loop with progress | ❌ Part of assistive |
| 9 | "Done" | Sentinel: end assistive session | ❌ State-machine sentinel |

**To build:** the Photos assistive title-loop. ~50 lines of AppleScript, manageable.

# Stage 2 — Build presentation from selected photos

| # | Spoken | What it does | Today |
|---|--------|--------------|-------|
| 10 | "Select all photos" | re-select after assistive | ⚠ |
| 11 | "Make a new presentation with these" | Photos selection → Keynote, one photo per slide | ❌ Cross-app handler — needs build |
| 12 | "Go to slide one" | Keynote slide nav | ⚠ Sal handler broken (bundle ID) |
| 13 | "Change master slide to title center" | Apply master template | ⚠ Sal handler broken |
| 14 | "Edit slide title" | Activate title text field | ⚠ Sal handler broken |
| 15 | "Vacation photos" | (raw dictation into title field) | n/a — system dictation |
| 16 | "Select photos" | (selection within title — different "select" context) | ⚠ |
| 17 | "Capitalize that" | Text transform on selection | ⚠ DC-Support handler |
| 18 | "Stop edit" | Deactivate title text field | ⚠ Sal handler broken |
| 19 | "Move this slide to the end" | Reorder current slide → last | ⚠ Sal handler broken |

**To build:** the photos→Keynote chain (line 11), plus thin native replacements for the broken Keynote handlers. The PHOTOS-to-KEYNOTE export verb is straightforward via AppleScript.

# Stage 3 — Round-trip image editing

| # | Spoken | What it does | Today |
|---|--------|--------------|-------|
| 20 | "Edit this in photos" | Take selected slide image → reveal source in Photos editor | ❌ Cross-app round-trip |
| 21 | "Show this in Keynote" | Reverse — Photos → Keynote slide | ❌ |
| 22 | "Update this image" | After editing in Photos, sync back into Keynote slide | ❌ |

**To build:** these are the most distinctive Sal commands — the ROUND-TRIP between Photos and Keynote with EXIF/identity preservation. Worth the time.

# Stage 4 — Geographic context (Maps integration)

| # | Spoken | What it does | Today |
|---|--------|--------------|-------|
| 23 | "Show this in Maps" | Reads selected image's GPS EXIF → opens that location in Maps | ❌ Cross-app — DC-Maps |
| 24 | "Export this map to Keynote" | Maps screenshot → new Keynote slide | ❌ |

**To build:** EXIF-GPS-read → Maps URL is doable (`open "maps://?ll=lat,lon"`). Maps screen capture → Keynote slide is harder but doable.

# Stage 5 — Visual polish (transitions + layout)

| # | Spoken | What it does | Today |
|---|--------|--------------|-------|
| 25 | "Apply a magic move" | Set slide transition to Magic Move | ⚠ Sal handler broken |
| 26 | "Apply a dissolve" | Set transition to Dissolve | ⚠ Sal handler broken |
| 27 | "Scale this to fit slide width" | Resize selected image to slide width | ⚠ Sal handler broken (DC-Keynote-Objects) |
| 28 | "Make a long panoramic sequence" | Multi-image auto-layout into panorama | ❌ Custom |
| 29 | "Put descriptions on top of every image" | EXIF descriptions → text overlays | ❌ Uses Overlay Text Helper |

**To build:** Keynote transition setters are 5-line AppleScripts each. Panoramic + description-overlay are bigger.

# Stage 6 — Embed external data (Spotlight + Numbers chain)

| # | Spoken | What it does | Today |
|---|--------|--------------|-------|
| 30 | "Search Spotlight for spreadsheet tourism in France" | Spotlight query | ❌ |
| 31 | "Open result" | Open top Spotlight hit | ❌ |
| 32 | "Select a table" | Select first table in Numbers doc | ⚠ DC-Numbers broken (bundle ID) |
| 33 | "Export this table to Keynote as a chart" | Numbers table → Keynote slide as chart | ❌ Cross-app |

**To build:** Spotlight via `mdfind`, then `open` first result. Numbers→Keynote chart conversion is the harder one.

# Stage 7 — Save + eject

| # | Spoken | What it does | Today |
|---|--------|--------------|-------|
| 34 | "Start from the top" | Restart presentation playback | ⚠ |
| 36 | "Save this presentation" | Cmd-S | ⚠ Trivial |
| 37 | "Save this presentation to my thumb drive and eject it" | save + cp + diskutil eject | ❌ Custom |

**To build:** thumb-drive-save+eject is a 10-line shell-script Shortcut.

# Stage 8 — Misc additions

| # | Spoken | What it does | Today |
|---|--------|--------------|-------|
| 41 | "Add a blank slide" | New empty slide | ✅ "Add A Blank Slide" Shortcut works |
| 42 | "Scratch that" | Undo previous voice command | ❌ Needs voice-action-history undo |
| 44 | "Turn this into a QR code" | Generate QR from URL or location | ❌ Uses `qrencode`-equivalent native |
| 45 | "Scale down 10%" | Resize selection by percentage | ⚠ DC-Keynote-Objects broken |

# Tally

| Status | Count | Notes |
|---|---|---|
| ✅ Working today (user Shortcut) | 4 | Switch to Photos, Add A Blank Slide, etc. (the 19 demo Shortcuts I built earlier) |
| ⚠ Sal handler exists but broken | 16 | Bundle ID issue (`com.apple.iWork.Keynote` deprecated). Native replacement easy. |
| ❌ Custom build needed | 22 | Cross-app chains, assistive loops, EXIF, etc. |
| n/a | 4 | Pure dictation into text fields, sentinels |

# Recommended build order (highest-leverage first)

## Tier A — easy wins, replace broken Sal handlers (1-2 hours total)

These are 5-line native Keynote AppleScripts that replace bundle-ID-broken handlers. Build all at once:

- "Go to slide ONE" / "go to slide N" / "next slide" / "previous slide"
- "Apply a magic move" / "apply a dissolve" / "no transition"
- "Edit slide title" / "stop edit"
- "Move this slide to the end"
- "Scale down 10%" / "scale up 10%" / "scale to fit width"
- "Save"

## Tier B — cross-app chains (the high-value Sal moves) (3-5 hours)

These ARE the WWSD demos. Each is one new Shortcut + AppleScript:

- **Photos → Keynote**: "make a new presentation with these"
- **Maps round-trip**: "show this in Maps", "export this map to Keynote"
- **Numbers → Keynote**: "export this table to Keynote as a chart"
- **Photos round-trip**: "edit this in photos", "show this in Keynote", "update this image"

## Tier C — custom assistive flows (more design work)

- Photos title walkthrough ("help me to add titles")
- Panoramic sequence layout
- Descriptions-on-every-image overlay
- Save-to-thumb-drive-and-eject
- "Scratch that" undo with voice-action history

## Tier D — meta features

- "Show this in Maps" needs EXIF GPS reader (one tiny CLI: `mdls -name kMDItemLatitude -name kMDItemLongitude file.jpg`)
- QR code generation native via `swift -e ...` using CIFilter `CIQRCodeGenerator`
- Spotlight query → first result via `mdfind`

# What to build first

If I were Esa, I'd start with **Tier A** as one batch — replaces the entire broken-Sal-handler space with 8-10 user Shortcuts that cover most of stages 2, 5, and 7. The matcher's USER_BOOST already prefers user Shortcuts, so once these are imported, "go to slide one", "apply a magic move" etc. all start working through Hey Sal in 1-2 hours of build time.

Then cherry-pick from Tier B based on which workflow you actually use. Photos→Keynote ("make a new presentation with these") is the most universal.

Tier C is fun but takes design time. Save for when the basics are sturdy.
