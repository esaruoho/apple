# Workflow 001: Services Overview

Track: Workflow Building
Level: 2
Category: Services And Quick Actions

## Source

- Site: `macosxautomation`
- Page: `sources/sal/macosxautomation.com/mirror/services.html`

## Goal

Introduce context-sensitive automation through Services and Quick Actions.

## What This Lesson Allows

- Understand why some automations should appear in user context
- Teach menu-driven and selection-driven workflow thinking
- Show that the same logic can be reusable from multiple entry points

## Repo Pairing

- Workflow: `scripts/workflows/finder/finder-copy-path.applescript`

Why this pairing:
Copying the path of the current selection is the kind of action that naturally belongs in a Service or Quick Action.

## Suggested Teaching Flow

1. Read the Services overview.
2. Explain what “context” means in automation.
3. Run the Finder path-copy workflow directly.
4. Discuss how it would feel when attached to a contextual menu.

## Practice

- Run it on different selections.
- Compare with `scripts/workflows/finder/finder-get-selection.applescript`.

## Modern Equivalent

- Type: `repo-workflow`
- Target: `scripts/workflows/finder/finder-copy-path.applescript`

## Outcome

The learner understands that workflow placement matters as much as script logic.
