# Workflow 003: Automator Overview

Track: Workflow Building
Level: 2
Category: Automator

## Source

- Site: `macosxautomation`
- Page: `sources/sal/macosxautomation.com/mirror/automator/index.html`

## Goal

Introduce action-chaining and reusable workflow composition.

## What This Lesson Allows

- Explain why Automator mattered educationally
- Show how recipes differ from one-off scripts
- Frame multi-step automation as a chain of transforms

## Repo Pairing

- Workflow: `scripts/workflows/homepod/homepod-good-night-scene.applescript`

Why this pairing:
Although it is implemented as AppleScript plus Shortcuts, it behaves like an automation recipe: one trigger, multiple coordinated outcomes.

## Suggested Teaching Flow

1. Read the Automator overview page.
2. Describe Sal's recipe mentality.
3. Run the HomePod workflow and discuss how it wraps a Shortcut.
4. Identify the steps in the automation chain.

## Practice

- Trace one other HomePod or Shortcut-bridge workflow in the repo.
- Describe its steps as an Automator-style recipe.

## Modern Equivalent

- Type: `shortcut-bridge`
- Target: `scripts/workflows/homepod/homepod-good-night-scene.applescript`

## Outcome

The learner understands that automation recipes survive tool changes even when Automator itself is no longer central.
