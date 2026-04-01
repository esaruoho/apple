# App 001: Keynote Overview

Track: App Automation
Level: 3
Category: Keynote Automation

## Source

- Site: `iworkautomation`
- Page: `sources/sal/iworkautomation.com/mirror/keynote/index.html`

## Goal

Introduce Keynote as a scriptable object model for presentation generation.

## What This Lesson Allows

- Treat slides and documents as programmable objects
- Understand why iWork apps are ideal automation teaching material
- Move from general AppleScript to app-specific structure

## Repo Pairing

- Workflow: `scripts/workflows/keynote/keynote-new-presentation.applescript`

Why this pairing:
It is the simplest possible Keynote object-model action: create a document and activate the app.

## Suggested Teaching Flow

1. Read the Keynote overview page.
2. Explain document and slide objects.
3. Run the new-presentation workflow.
4. Explore the other Keynote scripts in `scripts/workflows/keynote/`.

## Practice

- Run `scripts/workflows/keynote/keynote-slide-count.applescript` on a sample deck.
- Explain the difference between creating, reading, and exporting a presentation.

## Modern Equivalent

- Type: `repo-workflow`
- Target: `scripts/workflows/keynote/keynote-new-presentation.applescript`

## Outcome

The learner sees how AppleScript becomes much more powerful once an app exposes a rich object model.
