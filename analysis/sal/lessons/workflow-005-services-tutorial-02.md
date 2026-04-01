# Workflow 005: Services Tutorial 02

Track: Workflow Building
Level: 2
Category: Services And Quick Actions

## Source

- Site: `macosxautomation`
- Page: `sources/sal/macosxautomation.com/mirror/services/learn/tut02/index.html`

## Goal

Extend the Services sequence with a second structured build that emphasizes input handling.

## What This Lesson Allows

- Teach how service inputs shape workflow behavior
- Show why selection and context are first-class concepts in Mac automation
- Continue Sal's Services sequence without collapsing back to a generic overview

## Repo Pairing

- Workflow: `scripts/workflows/finder/finder-get-selection.applescript`

Why this pairing:
It makes input visible. The learner sees that the workflow becomes meaningful only when it has something selected to operate on.

## Suggested Teaching Flow

1. Read the second Services tutorial page.
2. Explain what the workflow expects as input.
3. Run the Finder selection workflow on different selections.
4. Discuss how Services fail or change behavior when given the wrong context.

## Practice

- Compare `scripts/workflows/finder/finder-get-selection.applescript` with `scripts/workflows/finder/finder-copy-path.applescript`.
- Describe one service that should accept text and one that should accept files.

## Modern Equivalent

- Type: `repo-workflow`
- Target: `scripts/workflows/finder/finder-get-selection.applescript`

## Outcome

The learner understands that Services are fundamentally about typed input and contextual execution.
