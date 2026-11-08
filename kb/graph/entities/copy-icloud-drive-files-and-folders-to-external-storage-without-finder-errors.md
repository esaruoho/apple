---
name: Copy iCloud Drive files and folders to external storage without Finder errors
slug: copy-icloud-drive-files-and-folders-to-external-storage-without-finder-errors
kind: feature
confidence: 0.6
updated: 2026-11-08
---

## Summary
Convey feature: features/icdcopy.feature.

## Claims
- Scenario (L24): latest folder ranking can be copied by number
- Scenario (L33): folder ranking rows are actual folders
- Scenario (L41): folder ranking defaults to useful iCloud scope and reports scan progress
- Scenario (L51): folder ranking table has stable aligned numeric columns
- Scenario (L60): AbletonCloud can be ranked without typing the long iCloud path
- Scenario (L68): command has the one-and-done shape Esa asked for
- Scenario (L77): copy is resumable after iCloud or disk interruption
- Scenario (L85): verification is checksum-based before success is claimed
- Scenario (L93): Finder metadata does not make a verified copy fail
- Scenario (L101): verification differences are repaired automatically
- Scenario (L109): iCloud files are explicitly materialized before rsync copy
- Scenario (L118): Apple FileProvider enums are hidden in normal use
- Scenario (L129): stalled download progress says elapsed time and timeout remaining
- Scenario (L137): interrupted iCloud download phase exits cleanly
- Scenario (L145): a stuck iCloud download fails with the exact file instead of hanging
- Scenario (L153): slow iCloud completion is allowed to finish in one command
- Scenario (L161): resident bytes count as ready even if FileProvider status is stale
- Scenario (L170): zero visible progress is reported but not treated as failure
- Scenario (L179): wrapper script stays parse-clean after shell edits
- Scenario (L187): source data is never deleted by the wrapper
- Scenario (L195): quoted Terminal-escaped paths are accepted
- Scenario (L207): icdcheck confirms a fully-local folder is PERFECT
- Scenario (L216): icdcheck flags dataless placeholders and in-flight downloads
- Scenario (L226): icdcheck never triggers a download (read-only audit)
- Scenario (L234): icdcheck emits machine-readable JSON for tooling
- Scenario (L241): icdcheck reuses the materializer engine rather than re-rolling status logic

## Relationships
