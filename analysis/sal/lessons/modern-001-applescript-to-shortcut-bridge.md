# Modern 001: AppleScript To Shortcut Bridge

Track: Modern Translation Layer
Level: 4
Category: Workflow Modernization

## Source

- Site: `repo`
- Page: `scripts/workflows/homepod/homepod-good-night-scene.applescript`

## Goal

Show how Sal-era workflow thinking translates into AppleScript wrappers around Shortcuts.

## What This Lesson Allows

- Preserve AppleScript depth while using newer system surfaces
- Explain that tool changes do not invalidate workflow design patterns
- Connect legacy automation habits to current Home and Shortcut ecosystems

## Repo Pairing

- Workflow: `scripts/workflows/homepod/homepod-good-night-scene.applescript`

Why this pairing:
It is the translation layer directly: AppleScript remains the orchestration surface while Shortcuts handles newer app-intent territory.

## Suggested Teaching Flow

1. Read the workflow source itself.
2. Explain why some modern Apple surfaces are easier to reach through Shortcuts than direct AppleScript dictionaries.
3. Run the good-night scene workflow.
4. Compare this bridge model with older Automator recipe thinking.

## Practice

- Compare `scripts/workflows/homepod/homepod-good-night-scene.applescript` with `scripts/workflows/homepod/homepod-good-morning-scene.applescript`.
- Identify which parts belong to AppleScript orchestration and which belong to Shortcut execution.

## Modern Equivalent

- Type: `shortcut-bridge`
- Target: `scripts/workflows/homepod/homepod-good-night-scene.applescript`

## Outcome

The learner sees that Sal's automation philosophy survives by adapting the execution layer while preserving the workflow mindset.
