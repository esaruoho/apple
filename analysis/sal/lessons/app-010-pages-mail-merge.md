# App 010: Pages Mail Merge

Track: App Automation
Level: 3
Category: Pages Automation

## Source

- Site: `iworkautomation`
- Page: `sources/sal/iworkautomation.com/mirror/pages/examples-mail-merge.html`

## Goal

Introduce data-driven document generation through Pages examples.

## What This Lesson Allows

- Connect structured data to generated documents
- Show why templates matter in document automation
- Frame mail merge as a concrete case of data-to-layout transformation

## Repo Pairing

- Workflow: `scripts/workflows/pages/pages-new-document.applescript`

Why this pairing:
The repo does not yet have an extracted mail-merge script, so the best live pairing is document creation as the first step in a generated document pipeline.

## Suggested Teaching Flow

1. Read the Pages mail-merge example page.
2. Diagram the pipeline from source data to final document.
3. Run the new-document workflow.
4. Identify the missing transformation layer that would complete a full mail-merge workflow.

## Practice

- Compare `scripts/workflows/pages/pages-new-document.applescript` with `scripts/workflows/pages/pages-export-pdf.applescript`.
- Describe what data source you would use for a modern mail-merge workflow.

## Modern Equivalent

- Type: `repo-workflow`
- Target: `scripts/workflows/pages/pages-new-document.applescript`

## Outcome

The learner understands Pages automation as a route from data to polished output, even when the full example still needs extraction.
