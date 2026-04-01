# App 006: Photos Selection Actions

Track: App Automation
Level: 3
Category: Photos Automation

## Source

- Site: `photosautomation`
- Page: `sources/sal/photosautomation.com/mirror/wayback-20240721/web.archive.org/web/20240721142125/http:/photosautomation.com/selection-actions.html`

## Goal

Teach selection-scoped actions as the basic Photos automation pattern.

## What This Lesson Allows

- Connect user selection to direct media actions
- Show how Photos automation often starts with the current set of chosen items
- Introduce favorites, export, and slideshow control as selection-driven patterns

## Repo Pairing

- Workflow: `scripts/workflows/photos/photos-favorite-selected.applescript`

Why this pairing:
Favoriting selected items is immediate, visible, and close to the preserved action-family model from Sal's Photos material.

## Suggested Teaching Flow

1. Read the selection-actions page.
2. Explain why selection is the primary input model in Photos automation.
3. Run the favorite-selected workflow.
4. Compare it to `scripts/workflows/photos/photos-export-selected.applescript` as another selection-driven action.

## Practice

- Run `scripts/workflows/photos/photos-start-slideshow.applescript`.
- Describe which selection-based actions affect metadata and which produce output.

## Modern Equivalent

- Type: `repo-workflow`
- Target: `scripts/workflows/photos/photos-favorite-selected.applescript`

## Outcome

The learner sees selection as the controlling idea behind Photos workflows, which makes later export, organization, and slideshow lessons easier to reason about.
