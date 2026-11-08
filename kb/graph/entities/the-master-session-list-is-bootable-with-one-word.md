---
name: The master session list is bootable with one word
slug: the-master-session-list-is-bootable-with-one-word
kind: feature
confidence: 0.6
updated: 2026-11-08
---

## Summary
Convey feature: features/sesh.feature.

## Claims
- Scenario (L38): Sessions are open, so sesh saves them
- Scenario (L46): Nothing is open, so sesh boots the snapshot
- Scenario (L59): Never resume a session that is already open
- Scenario (L71): Never overwrite a good snapshot with an empty one
- Scenario (L81): Folders with spaces survive the round trip
- Scenario (L88): Dry run shows the plan without launching anything
- Scenario (L94): Session discovery has exactly one implementation
- Scenario (L102): A folder that no longer exists is skipped, not fatal
- Scenario (L110): iTerm launch failure falls back to printed commands
- Scenario (L116): Restore window/tab layout, not just the session set
- Scenario (L121): Boot sessions that were closed rather than only those live at save

## Relationships
