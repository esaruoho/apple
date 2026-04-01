# Foundations 001: AppleScript First Tutorial

Track: Foundations
Level: 1
Category: AppleScript Basics

## Source

- Site: `macosxautomation`
- Page: `sources/sal/macosxautomation.com/mirror/applescript/firsttutorial/index.html`

## Goal

Introduce the AppleScript mental model through Sal's canonical beginner sequence.

## What This Lesson Allows

- Recognize `tell application ... end tell`
- Understand that AppleScript targets apps through Apple Events
- Establish a reading order for the first tutorial sequence

## Repo Pairing

- Workflow: `scripts/workflows/finder/finder-count-items.applescript`

Why this pairing:
The Finder example is small, visible, and easy to run. It demonstrates the same basic control model the first tutorial is meant to teach.

## Suggested Teaching Flow

1. Open Sal's tutorial index and explain the lesson arc.
2. Read the Finder example line by line.
3. Run it with `osascript`.
4. Change the notification text and run it again.

## Practice

- Replace Finder with another scriptable app you use daily.
- Change the script so it reports the folder name only.

## Modern Equivalent

- Type: `repo-workflow`
- Target: `scripts/workflows/finder/finder-count-items.applescript`

## Outcome

The learner understands that AppleScript is not magic English. It is a way of sending structured commands to apps that expose objects and properties.
