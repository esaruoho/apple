# Admin 002: Configurator Workflow Recipes

Track: Admin And Deployment
Level: 4
Category: Deployment Recipes

## Source

- Site: `configautomation`
- Page: `sources/sal/configautomation.com/mirror/wayback-20240422/web.archive.org/web/20240422004004/https:/configautomation.com/workflow-recipes.html`

## Goal

Teach device setup as a sequence of repeatable workflow recipes.

## What This Lesson Allows

- Present automation as repeatable operational procedure
- Show that recipe thinking scales beyond Automator into deployment work
- Connect sequence, order, and verification to admin automation design

## Repo Pairing

- Workflow: `scripts/workflows/system-events/system-events-spotlight-status.applescript`

Why this pairing:
It is a small operational check that fits recipe thinking: inspect state, decide action, and keep the system legible.

## Suggested Teaching Flow

1. Read the workflow-recipes page.
2. Diagram a deployment recipe as a sequence rather than a single script.
3. Run the Spotlight status workflow.
4. Explain where verification steps belong in an admin recipe.

## Practice

- Pair `scripts/workflows/system-events/system-events-spotlight-status.applescript` with `scripts/workflows/system-events/system-events-wifi-toggle.applescript` as a two-step admin flow.
- Describe which steps in a deployment recipe are idempotent and which are risky.

## Modern Equivalent

- Type: `repo-workflow`
- Target: `scripts/workflows/system-events/system-events-spotlight-status.applescript`

## Outcome

The learner understands that automation at admin scale is built from repeatable, testable recipes rather than isolated commands.
