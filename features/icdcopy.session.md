# icdcopy Session

## How to Get Back

- Transcript file: unavailable from this sandboxed turn.
- Session ID: unavailable from this sandboxed turn.
- Resume command: unavailable because the session ID is not exposed here.
- Date: 2026-09-10.

## Request

Esa needed a reliable way to copy very large iCloud Drive Ableton project folders,
especially HLER projects, to `/Volumes/T9/iCloudDrive AbletonCloud`.
Finder folder copies were failing with `error -8062`, and manual one-file-at-a-time
copying was not acceptable.

## Findings

`/Volumes/T9/iCloudDrive AbletonCloud` exists and has ample free space. The current
machine has `/opt/homebrew/bin/rsync` version 3.4.1, which supports the needed modern
flags. The specific project `082_HLER itis 2022-07-09 Project` reports roughly
33.29 GiB logical size while only about 11 GiB is resident locally, confirming that
ordinary disk-usage output under-reports iCloud placeholder content.

## Decision

The wrapper provides the command shape Esa asked for:

```bash
icdcopy SOURCE DESTINATION_FOLDER
```

It uses rsync for the actual copy, keeps partial files for resumability, verifies
with a checksum dry-run, and never deletes the source.

## Boundaries

The command deliberately avoids becoming an iCloud eviction or move tool. The safe
workflow is copy, verify, then make a separate decision about source cleanup.
