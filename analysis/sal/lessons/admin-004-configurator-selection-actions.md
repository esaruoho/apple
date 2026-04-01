# Admin 004: Configurator Selection Actions

Track: Admin And Deployment
Level: 4
Category: Deployment Automation

## Source

- Site: `configautomation`
- Page: `sources/sal/configautomation.com/mirror/wayback-20240422/web.archive.org/web/20240422004004/https:/configautomation.com/selection-actions.html`

## Goal

Teach selection-scoped admin actions as a pattern for operating on device subsets.

## What This Lesson Allows

- Show that selection is an operational concept, not only a GUI concept
- Connect user-interface selection to bulk administrative action
- Reinforce the value of acting on the right subset instead of the whole fleet

## Repo Pairing

- Workflow: `scripts/workflows/finder/finder-get-selection.applescript`

Why this pairing:
It is simple, but it makes the selection pattern explicit and teachable.

## Suggested Teaching Flow

1. Read the selection-actions page.
2. Explain how selection changes meaning in deployment contexts.
3. Run the Finder get-selection workflow.
4. Translate the same idea from files to devices or records.

## Practice

- Compare `scripts/workflows/finder/finder-get-selection.applescript` with `scripts/workflows/finder/finder-duplicate-selected.applescript`.
- Describe a risky admin action that should require explicit selection.

## Modern Equivalent

- Type: `repo-workflow`
- Target: `scripts/workflows/finder/finder-get-selection.applescript`

## Outcome

The learner understands that careful scoping is part of safe automation design.
