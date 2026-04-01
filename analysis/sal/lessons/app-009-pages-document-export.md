# App 009: Pages Document Export

Track: App Automation
Level: 3
Category: Pages Automation

## Source

- Site: `iworkautomation`
- Page: `sources/sal/iworkautomation.com/mirror/pages/document-export.html`

## Goal

Teach Pages output workflows as part of document automation.

## What This Lesson Allows

- Show how document automation ends in an exported artifact
- Reinforce the export pattern across Keynote, Numbers, and Pages
- Connect layout logic to practical output

## Repo Pairing

- Workflow: `scripts/workflows/pages/pages-export-pdf.applescript`

Why this pairing:
It gives a direct runnable match to the export-centered Pages material.

## Suggested Teaching Flow

1. Read the Pages export page.
2. Explain export as a transition from editable object model to shareable document.
3. Run the Pages export workflow.
4. Compare Pages export to Keynote and Numbers export flows.

## Practice

- Run `scripts/workflows/pages/pages-list-documents.applescript`.
- Explain what information a script needs before it can export a document safely.

## Modern Equivalent

- Type: `repo-workflow`
- Target: `scripts/workflows/pages/pages-export-pdf.applescript`

## Outcome

The learner sees Pages automation as both authoring and publishing automation.
