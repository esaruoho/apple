# Foundations 002: AppleScript Tutorial Chapter 01

Track: Foundations
Level: 1
Category: AppleScript Basics

## Source

- Site: `macosxautomation`
- Page: `sources/sal/macosxautomation.com/mirror/applescript/firsttutorial/01.html`

## Goal

Start the lesson sequence from the first actual chapter page, not only the hub.

## What This Lesson Allows

- Anchor the beginner sequence to a concrete page
- Teach a first observable script action
- Introduce the idea that scripts can query current application state

## Repo Pairing

- Workflow: `scripts/workflows/safari/safari-current-url.applescript`

Why this pairing:
It produces a visible result from a familiar app and gives beginners an immediate payoff.

## Suggested Teaching Flow

1. Read the chapter page and identify the first core concepts.
2. Run the Safari URL script.
3. Explain `front document` and why app dictionaries matter.
4. Change the script to also show the page title.

## Practice

- Open a different tab and rerun the script.
- Compare this script with `scripts/workflows/safari/safari-current-url-and-title.applescript`.

## Modern Equivalent

- Type: `repo-workflow`
- Target: `scripts/workflows/safari/safari-current-url.applescript`

## Outcome

The learner sees that AppleScript can inspect live app state, not just launch things.
