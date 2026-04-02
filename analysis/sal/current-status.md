# Sal Archive Status

Updated: 2026-04-02T07:10:24Z

## Current State

- Extracted inline AppleScript examples: `597`
- Curriculum lesson modules indexed: `38` across `6` tracks
- Download/media targets indexed: `359`
- Unique target status counts:
  - `recovered`: `232`
  - `captured-in-mirror`: `12`
  - `external-reference`: `18`
  - `missing`: `6`

## By Site

- `configautomation.com` -> `recovered`: `5`, `captured-in-mirror`: `1`, `external-reference`: `2`
- `dictationcommands.com` -> `captured-in-mirror`: `2`, `external-reference`: `3`
- `iworkautomation.com` -> `recovered`: `78`, `missing`: `1`
- `macosxautomation.com` -> `recovered`: `148`, `captured-in-mirror`: `9`, `external-reference`: `8`, `missing`: `3`
- `photosautomation.com` -> `recovered`: `1`, `external-reference`: `5`, `missing`: `2`

## Remaining Work

- Missing packages: `5`
- Missing videos: `1`
- `macosxautomation.com` missing packages are down to `3` dead URLs.
- `iworkautomation.com` is down to `0` missing videos plus `PresidentsSQLiteDB.zip`.
- `photosautomation.com` is down to `1` missing video plus `installer.zip`.

### Missing Packages

- `https://iworkautomation.com/numbers/PresidentsSQLiteDB.zip`
- `https://macosxautomation.com/405/us/media/apple/applescript/2008/aperturepdfworkflows.zip`
- `https://macosxautomation.com/applescript/apps/Script_Geek.zip`
- `https://macosxautomation.com/applescript/apps/Script_Geek_old.zip`
- `http://photosautomation.com/installer.zip`

### Priority Video Queue

- `photosautomation.com`: `1` remaining video

## Next Recommended Actions

- Transcribe retained local media and attach transcript paths to lessons and indexes.
- Extract recovered ZIP contents into curated script/example folders under `scripts/sal/`.
- Cross-link every recovered bundle, script, video, and transcript back into `indexes/sal-lessons.yaml`.
- Keep failure markers for dead URLs so the archive does not regress into false positives.
