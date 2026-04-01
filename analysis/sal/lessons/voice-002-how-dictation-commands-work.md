# Voice 002: How Dictation Commands Work

Track: Accessibility And Voice
Level: 3
Category: Accessibility Architecture

## Source

- Site: `dictationcommands`
- Page: `sources/sal/dictationcommands.com/mirror/wayback-20240424/web.archive.org/web/20240424181821/http:/dictationcommands.com/how-it-works.html`

## Goal

Explain the system model behind voice-triggered command routing.

## What This Lesson Allows

- Place Dictation Commands in a larger automation architecture
- Teach that environment awareness matters before an action fires
- Connect voice input to context detection and action selection

## Repo Pairing

- Workflow: `scripts/workflows/system-events/system-events-get-frontmost-app.applescript`

Why this pairing:
The frontmost-app pattern is a strong bridge to command routing because it shows how the system can decide what context a user is currently in.

## Suggested Teaching Flow

1. Read the How It Works page.
2. Describe the difference between hearing a phrase and deciding what action to run.
3. Run the frontmost-app workflow.
4. Discuss how voice systems often need current-context awareness.

## Practice

- Run `scripts/workflows/system-events/system-events-list-running-apps.applescript`.
- Explain how command routing changes when multiple candidate apps are available.

## Modern Equivalent

- Type: `repo-workflow`
- Target: `scripts/workflows/system-events/system-events-get-frontmost-app.applescript`

## Outcome

The learner understands that voice automation requires routing logic and environmental awareness, not just a phrase list.
