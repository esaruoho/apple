# App 008: Keynote Presenter Notes

Track: App Automation
Level: 3
Category: Keynote Automation

## Source

- Site: `iworkautomation`
- Page: `sources/sal/iworkautomation.com/mirror/keynote/slide-presenter-notes.html`

## Goal

Show how Keynote automation reaches into presentation metadata, not only visible slides.

## What This Lesson Allows

- Teach the difference between audience-facing content and presenter-facing content
- Show how AppleScript can manage hidden or supporting presentation structure
- Deepen the learner's idea of what counts as app content

## Repo Pairing

- Workflow: `scripts/workflows/keynote/keynote-presenter-notes.applescript`

Why this pairing:
It is a direct match to the preserved source material and demonstrates non-obvious Keynote objects.

## Suggested Teaching Flow

1. Read the presenter-notes page.
2. Explain why notes are part of the document model.
3. Run the presenter-notes workflow.
4. Compare it to slide-listing and slideshow-control scripts.

## Practice

- Compare `scripts/workflows/keynote/keynote-presenter-notes.applescript` with `scripts/workflows/keynote/keynote-list-slides.applescript`.
- Identify another hidden or auxiliary object in an app that could be automated.

## Modern Equivalent

- Type: `repo-workflow`
- Target: `scripts/workflows/keynote/keynote-presenter-notes.applescript`

## Outcome

The learner understands that good app automation reaches beyond what is immediately visible on screen.
