---
title: Sal Demo Shortcut Library — architecture
date: 2026-05-08
purpose: Turn Sal's WWDC 717 demo into a replicable, voice-triggerable Shortcut library — organized into folders, with a master orchestrator that runs the whole arc automatically
---

# What this is

A Shortcut library structured as Sal's actual demo arc. Each Sal-spoken command from WWDC 717 / dictation-commands-main-example becomes:

1. **A user Shortcut** in Shortcuts.app — voice-triggerable via Hey Sal
2. **Tagged by stage** in Sal's demo arc (8 stages, see below)
3. **Grouped into a `Sal Demo` folder** in Shortcuts.app sidebar
4. **Callable from a master "Sal Vacation Demo" Shortcut** that runs them in sequence with narration

Result: anyone with this repo can `bash bin/install-sal-demo-library.sh` → import the .shortcut files → run "Hey Sal" → "Run Sal Demo" and watch the entire 717 workflow play out on their Mac.

# Folder structure

```
Shortcuts.app sidebar:
  📁 Sal Demo
    📜 Sal Vacation Demo            (master orchestrator — runs the whole arc)
    📁 Stage 1 - Photos Titling
       Switch To Photos
       Select All Photos
       Help Me Add Titles           (assistive)
    📁 Stage 2 - Build Presentation
       Make A New Presentation With These
       Make A New Presentation
       Go To First Slide
       Go To Last Slide
       Go To Slide N                (parametric)
       Edit Slide Title
       Stop Edit
       Move Slide To End
    📁 Stage 3 - Image Round Trip
       Edit This In Photos
       Show This In Keynote
       Update This Image
    📁 Stage 4 - Maps Integration
       Show This In Maps
       Export Map To Keynote
    📁 Stage 5 - Visual Polish
       Apply Magic Move
       Apply Dissolve
       No Transition
       Scale This To Fit Slide Width
       Scale Down 10 Percent
       Make Long Panoramic Sequence
       Put Descriptions On All Images
    📁 Stage 6 - Data Embed
       Search Spotlight
       Open Top Result
       Select The Table
       Export Table To Keynote As Chart
    📁 Stage 7 - Save & Eject
       Save Front Document
       Save Presentation To Thumb Drive
    📁 Stage 8 - Misc
       Add A Blank Slide
       Duplicate Current Slide
       Delete Current Slide
       Turn This Into A QR Code     (QR This)
       Scratch That                 (undo last voice command)
    📁 Layer 1 - Engine bypass / Native replacements
       Take My Picture              (native AVFoundation, replaces broken IKPictureTaker)
       Insert Clipboard To Title
       Insert Clipboard To Body
```

# The master "Sal Vacation Demo" Shortcut

A single Shortcut, voice-triggerable as **"Run Sal Demo"** or **"Sal Vacation Demo"**. When invoked:

1. Speaks: *"This is Sal Soghoian's WWDC 2016 session 717 demo, recreated. Have a presentation open, photos selected. Starting in five seconds."*
2. Runs each Stage's commands in order with brief `say` narration between
3. Waits for user input at multi-step points (the assistive flows)
4. Speaks: *"Demo complete. The thing Apple killed in 2016 just ran on your 2026 Mac."*

The orchestrator uses Shortcuts' "Run Shortcut" action to chain into each sub-Shortcut, with `say` text between for narration.

# Implementation pieces

| File | Purpose |
|---|---|
| `bin/build-sal-demo-shortcuts.py` | Already exists — builds the granular Shortcuts |
| `bin/build-sal-vacation-demo.py` | NEW — builds the master orchestrator Shortcut |
| `bin/organize-sal-shortcuts-into-folder.applescript` | NEW — runs once post-import to create folders and move Shortcuts in |
| `bin/install-sal-demo-library.sh` | NEW — orchestrates: build all .shortcut files → open them for batch import → after user imports all → run the folder organizer |

# Voice phrases

The matcher already prefers user Shortcuts. So once imported and Hey Sal is invoked:

- "Run Sal Demo" → master orchestrator
- "Sal Vacation Demo" → master orchestrator
- "Switch to Photos" → Stage 1 first command
- "Make a new presentation" → Stage 2
- (etc.)

# Replicability checklist

For someone NEW to use this:
1. Clone `github.com/esaruoho/apple`
2. `bash bin/dictation-commands-install.sh` (Sal libraries)
3. `bash bin/install-sal-demo-library.sh` (this new flow)
4. Click Add Shortcut on each opened file
5. Run `bin/organize-sal-shortcuts-into-folder.applescript` once via Script Editor (or Shortcuts will skip the folder organization if Shortcuts CLI lacks folder-create)
6. Add Vocal Shortcut "Hey Sal" → bind to Hey Sal Shortcut
7. Say "Hey Sal" → "Run Sal Demo"

The whole vacation-photos demo plays out on their Mac. Apple killed this in 2016. 2026: it runs.
