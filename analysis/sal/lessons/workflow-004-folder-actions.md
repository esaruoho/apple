# Workflow 004: Folder Actions

Track: Workflow Building
Level: 2
Category: Folder Actions

## Source

- Site: `macosxautomation`
- Page: `sources/sal/macosxautomation.com/mirror/automator/folder-action/index.html`

## Goal

Teach filesystem-triggered automation as an event-driven pattern.

## What This Lesson Allows

- Treat folders as automation surfaces
- Connect file arrival to automatic actions
- Introduce event-driven thinking without requiring GUI complexity

## Repo Pairing

- Workflow: `scripts/workflows/finder/finder-move-to-trash.applescript`

Why this pairing:
It is a simple filesystem action that helps explain how folder-oriented automation affects real files and objects.

## Suggested Teaching Flow

1. Read Sal's folder action overview.
2. Explain the difference between manual invocation and event-driven invocation.
3. Run the Finder trash workflow.
4. Design a hypothetical folder action around a real file workflow.

## Practice

- Describe a Downloads-folder action you would actually use.
- Pair it with another Finder workflow from this repo.

## Modern Equivalent

- Type: `repo-workflow`
- Target: `scripts/workflows/finder/finder-move-to-trash.applescript`

## Outcome

The learner understands the event-driven side of Mac automation, not just command invocation.
