# Workflow 002: Services Tutorial 01

Track: Workflow Building
Level: 2
Category: Services And Quick Actions

## Source

- Site: `macosxautomation`
- Page: `sources/sal/macosxautomation.com/mirror/services/learn/tut01/index.html`

## Goal

Teach the first structured Services lesson from Sal's own tutorial sequence.

## What This Lesson Allows

- Understand a step-by-step Services build process
- Connect user input to downstream automation
- Show how small utilities become reusable tools

## Repo Pairing

- Workflow: `scripts/workflows/notes/notes-new-note-from-clipboard.applescript`

Why this pairing:
It fits the same mindset as a selection- or clipboard-driven service: take current context, transform it, store it somewhere useful.

## Suggested Teaching Flow

1. Follow Sal's tutorial page as the primary reading.
2. Run the Notes clipboard workflow.
3. Explain what the “input” and “output” are.
4. Ask how this would look as a Service in the menu bar or context menu.

## Practice

- Put different text on the clipboard and rerun.
- Adapt the pattern to create a reminder instead of a note.

## Modern Equivalent

- Type: `repo-workflow`
- Target: `scripts/workflows/notes/notes-new-note-from-clipboard.applescript`

## Outcome

The learner sees how a single-purpose utility becomes a reusable workflow building block.
