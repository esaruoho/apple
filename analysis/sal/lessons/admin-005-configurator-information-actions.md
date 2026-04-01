# Admin 005: Configurator Information Actions

Track: Admin And Deployment
Level: 4
Category: Deployment Automation

## Source

- Site: `configautomation`
- Page: `sources/sal/configautomation.com/mirror/wayback-20240422/web.archive.org/web/20240422004004/https:/configautomation.com/information-actions.html`

## Goal

Teach inspection and reporting workflows as part of admin automation.

## What This Lesson Allows

- Show that reliable automation often starts with information gathering
- Distinguish read-only inspection from state-changing procedures
- Introduce reporting as an operational automation task

## Repo Pairing

- Workflow: `scripts/workflows/disk-utility/disk-utility-disk-info.applescript`

Why this pairing:
It is a clear example of inspection-first automation that does not immediately mutate state.

## Suggested Teaching Flow

1. Read the information-actions page.
2. Explain why safe admin workflows usually start with inspection.
3. Run the disk-info workflow.
4. Compare information gathering to action workflows from the other admin lessons.

## Practice

- Compare `scripts/workflows/disk-utility/disk-utility-disk-info.applescript` with `scripts/workflows/disk-utility/disk-utility-list-disks.applescript`.
- Identify which admin tasks should always begin with a read-only check.

## Modern Equivalent

- Type: `repo-workflow`
- Target: `scripts/workflows/disk-utility/disk-utility-disk-info.applescript`

## Outcome

The learner sees inspection and reporting as essential parts of operational automation, not optional extras.
