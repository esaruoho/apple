# App 002: Keynote Image Slides From Files

Track: App Automation
Level: 3
Category: Keynote Automation

## Source

- Site: `iworkautomation`
- Page: `sources/sal/iworkautomation.com/mirror/keynote/image-slides-from-files.html`

## Goal

Teach file-to-slide generation as a concrete automation project.

## What This Lesson Allows

- Show how automation transforms a folder of assets into a presentation
- Introduce generation workflows rather than only inspection workflows
- Connect Keynote to filesystem and media assets

## Repo Pairing

- Workflow: `scripts/workflows/keynote/keynote-export-pdf.applescript`

Why this pairing:
It complements generation with output: once automation creates a deck, automation should also export or distribute it.

## Suggested Teaching Flow

1. Read Sal's page about generating slides from files.
2. Diagram the input folder -> Keynote document -> exported output chain.
3. Run the Keynote export workflow on a sample deck.
4. Compare generation and export as two sides of the same automated pipeline.

## Practice

- Sketch a local folder-to-presentation workflow you would use.
- Identify what additional script step would be needed to fully recreate Sal's example.

## Modern Equivalent

- Type: `repo-workflow`
- Target: `scripts/workflows/keynote/keynote-export-pdf.applescript`

## Outcome

The learner understands automation as content pipeline construction, not only app control.
