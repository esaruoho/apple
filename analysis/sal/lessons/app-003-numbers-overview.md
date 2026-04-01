# App 003: Numbers Overview

Track: App Automation
Level: 3
Category: Numbers Automation

## Source

- Site: `iworkautomation`
- Page: `sources/sal/iworkautomation.com/mirror/numbers/index.html`

## Goal

Introduce Numbers tables, rows, columns, and ranges as scriptable structures.

## What This Lesson Allows

- Frame spreadsheets as programmable data structures
- Introduce table-oriented automation thinking
- Connect business-style data automation to AppleScript

## Repo Pairing

- Workflow: `scripts/workflows/numbers/numbers-export-csv.applescript`

Why this pairing:
CSV export makes the data-flow value of Numbers automation obvious: get structured data out and reuse it elsewhere.

## Suggested Teaching Flow

1. Read the Numbers overview page.
2. Explain sheets, tables, rows, columns, and cells as objects.
3. Run the CSV export workflow.
4. Discuss how spreadsheet automation becomes part of a larger workflow.

## Practice

- Run `scripts/workflows/numbers/numbers-table-count.applescript` and compare it to export.
- Explain what kind of workflow starts in Numbers and ends elsewhere.

## Modern Equivalent

- Type: `repo-workflow`
- Target: `scripts/workflows/numbers/numbers-export-csv.applescript`

## Outcome

The learner sees Numbers as a scriptable data-processing surface, not just a manual spreadsheet UI.
