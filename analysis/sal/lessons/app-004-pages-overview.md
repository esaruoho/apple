# App 004: Pages Overview

Track: App Automation
Level: 3
Category: Pages Automation

## Source

- Site: `iworkautomation`
- Page: `sources/sal/iworkautomation.com/mirror/pages/index.html`

## Goal

Introduce document construction and page-item automation in Pages.

## What This Lesson Allows

- Treat Pages documents as structured objects rather than manual layouts
- Connect text, pages, and export workflows into one automation surface
- Show how document automation differs from spreadsheet and presentation automation

## Repo Pairing

- Workflow: `scripts/workflows/pages/pages-export-pdf.applescript`

Why this pairing:
Export makes the value of Pages automation concrete. A scriptable document is useful because it can be turned into a deliverable without manual menu work.

## Suggested Teaching Flow

1. Read the Pages overview page.
2. Explain document-oriented scripting versus slide- or table-oriented scripting.
3. Run the PDF export workflow.
4. Explore `scripts/workflows/pages/` to compare creation, inspection, and export tasks.

## Practice

- Run `scripts/workflows/pages/pages-word-count.applescript` on an open document.
- Compare `scripts/workflows/pages/pages-new-document.applescript` with export to separate creation from output.

## Modern Equivalent

- Type: `repo-workflow`
- Target: `scripts/workflows/pages/pages-export-pdf.applescript`

## Outcome

The learner sees Pages as a layout and publishing surface that can be automated with the same object-model discipline used in Keynote and Numbers.
