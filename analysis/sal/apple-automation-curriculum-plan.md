# Apple Automation Workflow Curriculum

Date: 2026-04-01

## Goal

Turn Sal Soghoian's preserved site corpus into a structured learning path that moves a learner from:

1. basic AppleScript literacy
2. to practical workflow construction
3. to app-specific automation
4. to reusable personal systems

The archive should not only preserve Sal's pages; it should become a curriculum engine.

## Curriculum Principles

- Teach workflows, not isolated syntax.
- Start with visible wins.
- Keep source attribution to Sal's original pages.
- Pair every lesson with a runnable example.
- Show the old toolchain and the modern equivalent when possible:
  AppleScript, Automator, Services, dictation commands, Shortcuts, shell bridges.

## Proposed Tracks

### Track 1: Foundations

Purpose:
- learn the AppleScript mental model

Primary source families:
- `macosxautomation.com/applescript/firsttutorial/`
- `macosxautomation.com/applescript/features/`
- `macosxautomation.com/training/applescript/`

Outcomes:
- read and write simple `tell application` scripts
- understand objects, properties, commands, and results
- run scripts from Script Editor and `osascript`

### Track 2: Workflow Building

Purpose:
- move from scripting to repeatable user workflows

Primary source families:
- `macosxautomation.com/automator/`
- `macosxautomation.com/services/`
- `macosxautomation.com/training/automator/`
- `macosxautomation.com/training/services/`

Outcomes:
- build Services and Quick Actions
- build folder actions
- package scripts as workflows and apps
- understand when Automator is a better teaching tool than raw AppleScript

### Track 3: App Automation

Purpose:
- automate real apps with real objects

Primary source families:
- `iworkautomation.com/keynote/`
- `iworkautomation.com/numbers/`
- `iworkautomation.com/pages/`
- `photosautomation.com/scripting/`
- `macosxautomation.com/applescript/imageevents/`

Outcomes:
- generate slides, documents, tables, and charts
- automate image and media workflows
- understand app dictionaries as the map of possibility

### Track 4: Accessibility And Voice

Purpose:
- treat automation as accessibility infrastructure

Primary source families:
- `dictationcommands.com/`
- `macosxautomation.com/mavericks/speakableworkflows/`
- `macosxautomation.com/mavericks/guiscripting/`

Outcomes:
- connect spoken phrases to actions
- understand UI scripting as a fallback for dark apps
- frame automation as empowerment, not only productivity

### Track 5: Admin And Deployment

Purpose:
- apply workflow thinking to systems and fleet tasks

Primary source families:
- `configautomation.com/`
- `macosxautomation.com/mavericks/codesign/`
- `macosxautomation.com/mavericks/libraries/`

Outcomes:
- understand provisioning, backup, restore, install, identity workflows
- understand script libraries and code-signing constraints
- connect personal automation to institutional deployment

### Track 6: Modern Translation Layer

Purpose:
- bridge Sal's material into today's Apple stack

Primary source families:
- repo workflows in `scripts/workflows/`
- repo dictionaries in `dictionaries/`
- captured Sal examples from `scripts/sal/` once extracted

Outcomes:
- map Automator concepts to Shortcuts and App Intents
- map AppleScript examples to repo-native workflows
- show where AppleScript still provides depth that Shortcuts does not

## Course Shape

### Level 1: Everyone Can Automate

- 10-15 short lessons
- visible wins in the first hour
- Finder, text, Safari, notifications, basic Services

### Level 2: Workflow Literacy

- 15-20 lessons
- Automator, folder actions, reusable scripts, variables, packaging

### Level 3: App Specialist Modules

- separate units for Keynote, Numbers, Pages, Photos, Finder, Safari, Music

### Level 4: Automation Architect

- script libraries
- GUI scripting fallback
- shell integration
- curriculum projects that chain multiple apps

## Repo Work Needed

1. Extract the best preserved examples into `scripts/sal/<site>/`.
2. Add page notes that map source pages to curriculum modules.
3. Build a lesson index:
   source page -> concept -> example script -> modern equivalent
4. Add a small set of canonical lesson scripts that actually run in this repo.
5. Create a reading order and project order.

Implemented scaffold:
- `indexes/sal-curriculum.yaml` for track/category taxonomy
- `indexes/sal-lessons.yaml` for lesson-level source-page mappings

## First Module Candidates

1. AppleScript first tutorial
2. Services and Quick Actions
3. Folder actions
4. Keynote slide generation
5. Numbers table automation
6. Photos selection and export actions
7. Dictation commands and speakable workflows

## Why Sal's Work Fits Curriculum

- He taught by example.
- He organized by task, not only by API.
- He linked screenshots, code, workflow shape, and user outcome.
- He treated automation as a human right on the Mac.

That makes his archive unusually suitable for a staged curriculum: beginner to power user, with real continuity between levels.
