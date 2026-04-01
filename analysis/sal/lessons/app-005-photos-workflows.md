# App 005: Photos Workflows

Track: App Automation
Level: 3
Category: Photos Automation

## Source

- Site: `photosautomation`
- Page: `sources/sal/photosautomation.com/mirror/wayback-20240721/web.archive.org/web/20240721142125/http:/photosautomation.com/workflows.html`

## Goal

Introduce Photos as a workflow surface rather than only a library browser.

## What This Lesson Allows

- Frame Photos actions as repeatable workflow components
- Show that media libraries can be automated like documents and tables
- Introduce the action families preserved from the Photos automation site

## Repo Pairing

- Workflow: `scripts/workflows/photos/photos-export-selected.applescript`

Why this pairing:
Export is one of the clearest workflow boundaries in Photos. It turns an in-app selection into reusable files outside the library.

## Suggested Teaching Flow

1. Read the preserved Photos workflows page.
2. List the action families shown in the site snapshot.
3. Run the export-selected workflow.
4. Compare Photos automation with filesystem and document workflows from earlier lessons.

## Practice

- Run `scripts/workflows/photos/photos-count-photos.applescript`.
- Explain where the workflow begins inside Photos and where its output lands outside Photos.

## Modern Equivalent

- Type: `repo-workflow`
- Target: `scripts/workflows/photos/photos-export-selected.applescript`

## Outcome

The learner understands that Photos automation is about moving from curated selections to reproducible workflows, not only browsing a library.
